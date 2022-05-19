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
}

(** Create a random network with [nodes] nodes. *)
let create_from_graph graph =
  let nodes = S.G.nb_vertex graph in
  let sm =
    Springmodel.spherical_configuration
      ~radius:15.0
      ~relax_length:10.
      ~stiffness:1.0
      ~anchor:(Springmodel.Random {count = 1 + (nodes / 10)})
      ~add_edges:false
      graph
      ()
  in
  {
    node_table = Table.create nodes;
    node_info = Array.init nodes (fun _ -> {node = None; peer_id = None});
    embedding = sm;
    elapse = ref false;
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
    Springmodel.perform_relaxation_step
      ~model:st.embedding
      ~drag_factor:0.7
      ~coulomb_factor:1.
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
    let switch =
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

    if switch then st.elapse := not !(st.elapse) ;

    if !(st.elapse) then Tezos_shims_shared.Internal_for_tests.elapse dt ;
    loop camera st

let () =
  let cam = Display.setup 900 800 in
  let graph =
    (* Random connexion graph *)
    Springmodel.erdos_renyi node_count edge_p (Random.State.make_self_init ())
  in
  let state = create_from_graph graph in
  let open Lwt_result_syntax in
  let _ =
    Lwt_main.run
    @@ let* () =
         make_n_nodes_and_start state node_count (fun _nodes ->
             let open Lwt_result_syntax in
             let*! () = Lwt_unix.sleep 1.0 in
             S.G.iter_edges
               (fun i j ->
                 assert (i <> j) ;
                 match
                   (state.node_info.(i).peer_id, state.node_info.(j).peer_id)
                 with
                 | Some p1, Some p2 -> (
                     assert (not (P2p_peer.Id.equal p1 p2)) ;
                     Springmodel.add_edge state.embedding i j ;
                     match
                       P2p.Internal_for_tests.connect_peers
                         (handle ())
                         ~a:p1
                         ~b:p2
                         ~a_meta:(Tezos_p2p_services.Peer_metadata.empty ())
                         ~b_meta:(Tezos_p2p_services.Peer_metadata.empty ())
                         ~ab_conn_meta:
                           Tezos_p2p_services.Connection_metadata.
                             {disable_mempool = false; private_node = false}
                         ~ba_conn_meta:
                           Tezos_p2p_services.Connection_metadata.
                             {disable_mempool = false; private_node = false}
                     with
                     | Ok () -> ()
                     | Error msg -> Stdlib.failwith msg)
                 | _ -> assert false)
               graph ;
             let*! () = Lwt_unix.sleep 1.0 in
             let* _ = activate_alpha state 0 in
             Lwt_result_syntax.return_unit)
       and* () = loop cam state in
       return_unit
  in
  ()
