open Tezos_shell
module N = Node
module I = Node.Internal_for_tests
module S = Springmodel
module Table = P2p_peer.Id.Table

type peer_table = N.t Table.t

type peer_id = P2p_peer.Id.t

type node = {node : Node.t; id : int}

type node_info = {
  mutable node : Node.t option;
  mutable peer_id : peer_id option;
}

type simulation_state = {
  node_table : node Table.t;  (** A table from [peer_id] to [Node.t]. *)
  node_info : node_info array;  (** Mapping indices to [node_info] *)
  embedding : S.t;  (** Embedding the p2p graph in R^3 using a spring model *)
  elapse : bool ref;
  step_spring : bool ref;
  mutex : Mutex.t;
}

(** Create a random network with [nodes] nodes. *)
let create node_count =
  let vertices = List.init node_count Fun.id in
  let graph = Springmodel.G.create () in
  List.iter (fun v -> Springmodel.G.add_vertex graph v) vertices ;
  let sm =
    Springmodel.spherical_configuration
      ~radius:15.0
      ~relax_length:1.
      ~stiffness:0.001
      ~anchor:(Springmodel.Random {count = 1 + (node_count / 10)})
      graph
      ()
  in
  {
    node_table = Table.create node_count;
    node_info = Array.init node_count (fun _ -> {node = None; peer_id = None});
    embedding = sm;
    elapse = ref false;
    step_spring = ref false;
    mutex = Mutex.create ();
  }

let stop = ref false

let do_once =
  let done_ = ref false in
  fun f ->
    if not !done_ then f ()
    else (
      done_ := true ;
      Lwt.return_unit)

let network_handle :
    ( Distributed_db_message.t,
      Tezos_p2p_services.Peer_metadata.t,
      Tezos_p2p_services.Connection_metadata.t )
    P2p.Internal_for_tests.mocked_network
    option
    ref =
  ref None

let handle () = match !network_handle with None -> assert false | Some h -> h

let make_node (st : simulation_state) id =
  let open Lwt_result_syntax in
  let name = Format.asprintf "%d" id in
  let config = Config.config name Lwt_log_sink_unix.Output.Stdout in
  let node_config = Config.node_config config in
  let*! () =
    do_once @@ fun () ->
    Tezos_base_unix.Internal_event_unix.init
      ~lwt_log_sink:config.log
      ~configuration:config.internal_events
      ()
  in
  let* node =
    Node.create
      node_config
      ~singleprocess:true
      config.shell.peer_validator_limits
      config.shell.block_validator_limits
      config.shell.prevalidator_limits
      config.shell.chain_validator_limits
      None
  in
  let p2p = I.p2p node in
  let peer_id = P2p.peer_id p2p in
  if Option.is_none !network_handle then
    network_handle :=
      P2p.Internal_for_tests.find_handle_opt (P2p.announced_version p2p) ;
  Table.add st.node_table peer_id {node; id} ;
  st.node_info.(id).node <- Some node ;
  st.node_info.(id).peer_id <- Some peer_id ;
  return (node, id)

let activate_alpha state node_index =
  let open Lwt_result_syntax in
  let nodes = Table.to_seq state.node_table in
  let peers = Array.of_seq nodes in
  let _peer_id, {node; id = _} = peers.(node_index) in
  let* _hash = Proto_activation.activate_alpha node in
  return_unit

let make_n_nodes_and_start st n f =
  let open Lwt_result_syntax in
  let* nodes = tzall (List.init n (fun i -> make_node st i)) in
  let* () = f nodes in
  return_unit

(* ------------------------------------------------------------------------- *)

let node_count, edge_p, dt =
  let usage exe_name =
    Format.printf
      "Usage: %s nodes <node_count> p <edge_probability> dt <dt>@."
      exe_name
  in
  match Array.to_list Sys.argv with
  | [exe_name; "nodes"; count; "p"; edge_p; "dt"; dt] -> (
      match
        (int_of_string count, float_of_string edge_p, float_of_string dt)
      with
      | exception _ ->
          usage exe_name ;
          exit 1
      | count, p, dt ->
          if p <= 0.0 || p > 1.0 || dt <= 0.0 then (
            usage exe_name ;
            exit 1)
          else (count, p, dt))
  | [] -> assert false
  | exe_name :: _ ->
      usage exe_name ;
      exit 1

let rec loop camera st =
  let open Raylib in
  let open Lwt_result_syntax in
  let*! () = Lwt.pause () in
  if window_should_close () || !stop then (
    close_window () ;
    return_unit)
  else
    let camera =
      if is_key_down Key.Z then
        Camera.(
          create
            (position camera)
            (Vector3.create 0.0 0.0 0.0) (* target *)
            (up camera)
            45.0
            (* FOV *) CameraProjection.Perspective)
      else camera
    in
    update_camera (addr camera) ;
    let*! () = Lwt.pause () in
    if !(st.step_spring) then
      Springmodel.perform_relaxation_step
        ~model:st.embedding
        ~drag_factor:0.99
        ~coulomb_factor:1e-10
        ~delta_t:0.1 ;
    let*! () = Lwt.pause () in
    let* levels =
      Lwtreslib.Bare.List.map_es
        (fun {node; _} ->
          match node with
          | None -> assert false
          | Some node ->
              let store = Node.Internal_for_tests.store node in
              let chain_store = Tezos_store.Store.main_chain_store store in
              let*! head = Tezos_store.Store.Chain.current_head chain_store in
              return (Tezos_store.Store.Block.level head))
        (Array.to_list st.node_info)
    in
    let levels = Array.of_list levels in
    Mutex.lock st.mutex ;
    let switch, step_spring =
      Display.draw_all
        st.embedding
        camera
        ~draw_node:(fun id pos ->
          let text = Int32.to_string levels.(id) in
          Display.draw_text camera pos 1.0 Raylib.Color.black text)
        ~draw_edge:(fun src srcpos tgt tgtpos ->
          let src_id = Option.get st.node_info.(src).peer_id in
          let tgt_id = Option.get st.node_info.(tgt).peer_id in
          let src_to_tgt =
            let near =
              P2p.Internal_for_tests.neighbourhood (handle ()) src_id
            in
            let outgoing = List.assoc tgt_id near in
            Lwt_pipe.Unbounded.length outgoing
          in
          let tgt_to_src =
            let near =
              P2p.Internal_for_tests.neighbourhood (handle ()) src_id
            in
            let outgoing = List.assoc tgt_id near in
            Lwt_pipe.Unbounded.length outgoing
          in
          let offset = Raylib.Vector3.create 0.0 0.0 0.5 in
          Display.draw_text
            camera
            (Raylib.Vector3.add srcpos offset)
            0.3
            Raylib.Color.black
            (Printf.sprintf "%d" tgt_to_src) ;
          Display.draw_text
            camera
            (Raylib.Vector3.add tgtpos offset)
            0.3
            Raylib.Color.black
            (Printf.sprintf "%d" src_to_tgt))
    in
    Mutex.unlock st.mutex ;
    if switch then st.elapse := not !(st.elapse) ;
    if step_spring then st.step_spring := not !(st.step_spring) ;
    loop camera st

[@@@ocaml.alert "-deprecated"]

let run st p =
  let rec run_loop () =
    (* Fulfill paused promises now. *)
    Lwt.wakeup_paused () ;
    match Lwt.poll p with
    | Some x -> x
    | None ->
        (* Do the main loop call. *)
        let paused = Lwt.paused_count () in
        let should_block_waiting_for_io = paused = 0 in
        let can_elapse = paused = 1 in
        Lwt_engine.iter should_block_waiting_for_io ;

        if can_elapse && !(st.elapse) then
          Tezos_shims_shared.Internal_for_tests.elapse dt
        else () ;

        (* Repeat. *)
        run_loop ()
  in

  run_loop ()

let () =
  let cam = Display.setup 900 800 in
  let state = create node_count in
  let rng_state = Random.State.make [|13908120983|] in
  let open Lwt_result_syntax in
  let _ =
    run state
    @@ let* () =
         make_n_nodes_and_start state node_count (fun _nodes ->
             let open Lwt_result_syntax in
             let*! () = Lwt_unix.sleep 1.0 in
             let graph = state.embedding.Springmodel.graph in
             let vertices =
               Springmodel.G.fold_vertex (fun v l -> v :: l) graph []
             in
             Mutex.lock state.mutex ;
             let coin = Stats.Gen.bernoulli edge_p in
             List.iter
               (fun i ->
                 List.iter
                   (fun j ->
                     if i < j && coin rng_state then
                       Springmodel.add_edge state.embedding i j
                     else ())
                   vertices)
               vertices ;
             S.G.iter_edges
               (fun i j ->
                 let i, j = if i < j then (i, j) else (j, i) in
                 assert (i <> j) ;
                 match
                   (state.node_info.(i).peer_id, state.node_info.(j).peer_id)
                 with
                 | Some p1, Some p2 -> (
                     assert (not (P2p_peer.Id.equal p1 p2)) ;
                     match
                       P2p.Internal_for_tests.connect_peers
                         (handle ())
                         ~a:p1
                         ~b:p2
                         ~peer_meta_initial:
                           Tezos_p2p_services.Peer_metadata.empty
                         ~ab_conn_meta:
                           Tezos_p2p_services.Connection_metadata.
                             {disable_mempool = false; private_node = false}
                         ~ba_conn_meta:
                           Tezos_p2p_services.Connection_metadata.
                             {disable_mempool = false; private_node = false}
                         ~propagation_delay:(5. +. Random.float 5.0)
                     with
                     | Ok () -> ()
                     | Error msg -> Stdlib.failwith msg)
                 | _ -> assert false)
               state.embedding.Springmodel.graph ;
             Mutex.unlock state.mutex ;

             S.G.iter_vertex
               (fun i ->
                 let self = Option.get state.node_info.(i).peer_id in
                 P2p.Internal_for_tests.on_disconnection
                   (handle ())
                   self
                   (fun peer ->
                     Mutex.lock state.mutex ;
                     let peer_index =
                       (Option.get (Table.find state.node_table peer)).id
                     in
                     Springmodel.remove_edge state.embedding i peer_index ;
                     Mutex.unlock state.mutex))
               state.embedding.Springmodel.graph ;
             let*! () = Lwt_unix.sleep 1.0 in
             let* _ = activate_alpha state 0 in
             Lwt_result_syntax.return_unit)
       and* () = loop cam state in
       return_unit
  in
  ()
