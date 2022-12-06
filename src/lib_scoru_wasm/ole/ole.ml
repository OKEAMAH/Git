module Context = Tezos_context_memory.Context_binary

let empty_tree () =
  let open Lwt.Syntax in
  let* index = Context.init "/tmp" in
  let empty_store = Context.empty index in
  Lwt.return @@ Context.Tree.empty empty_store

type Tezos_lazy_containers.Lazy_map.tree += Tree of Context.tree

module Tree = struct
  type tree = Context.tree

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tezos_tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

let hex_encode (input : string) : string =
  match Hex.of_string input with `Hex s -> s

let reveal_builtins =
  let reveal_preimage hash =
    let hash =
      (* (\* The payload represents the encoded [Sc_rollup_reveal_hash.t]. We must *)
      (*    decode it properly, instead of converting it byte-for-byte. *\) *)
      (* Data_encoding.Binary.of_string_exn Sc_rollup_reveal_hash.encoding hash *)
      hex_encode hash
    in
    (* let*! data = get_reveal ~data_dir:node_ctxt.data_dir reveal_map hash in *)
    Lwt_io.with_file ~mode:Lwt_io.Input ("./reveals/" ^ hash) Lwt_io.read
  in
  let reveal_metadata () =
    Stdlib.failwith "reveal_metadata is not available out of the box in tests"
  in
  Tezos_scoru_wasm.Builtins.{reveal_metadata; reveal_preimage}

module Make (PVM : Tezos_scoru_wasm.Wasm_pvm_sig.S with type tree = Tree.tree) =
struct
  let rec eval_until_input_requested ?(max_steps = Int64.max_int) tree =
    let open Lwt_syntax in
    let run =
      PVM.Internal_for_tests.compute_step_many_with_hooks
        ~write_debug:
          Tezos_scoru_wasm.Builtins.(
            Printer (fun s -> Lwt_io.printf "DEBUG: %s\n%!" s))
      (* Printer (fun s -> Lwt.return @@ Printf.printf "DEBUG: %s\n" s)) *)
    in
    let* info = PVM.get_info tree in
    match info.input_request with
    | No_input_required ->
        let* tree, _ = run ~reveal_builtins ~max_steps tree in
        eval_until_input_requested ~max_steps tree
    | Input_required | Reveal_required _ -> return tree

  let rec eval_to_snapshot ?(reveal_builtins = reveal_builtins)
      ?(max_steps = Int64.max_int) tree =
    let open Lwt.Syntax in
    let eval tree =
      let* tree, _ =
        PVM.compute_step_many
          ~reveal_builtins
          ~stop_at_snapshot:true
          ~max_steps
          tree
      in
      let* state = PVM.Internal_for_tests.get_tick_state tree in
      match state with
      | Snapshot | Collect -> Lwt.return tree
      | _ -> eval_to_snapshot ~max_steps tree
    in
    let* info = PVM.get_info tree in
    match info.input_request with
    | No_input_required -> eval tree
    | Input_required | Reveal_required _ ->
        Stdlib.failwith "Cannot reach snapshot point"

  let input_info level message_counter =
    Tezos_scoru_wasm.Wasm_pvm_state.
      {
        inbox_level =
          Option.value_f ~default:(fun () -> assert false)
          @@ Tezos_base.Bounded.Non_negative_int32.of_value level;
        message_counter;
      }

  let new_message_counter () =
    let c = ref Z.zero in
    fun () ->
      c := Z.succ !c ;
      Z.pred !c

  let set_sol_input level tree =
    let sol_input =
      Tezos_scoru_wasm.Pvm_input_kind.(
        Internal_for_tests.to_binary_input (Internal Start_of_level) None)
    in
    PVM.set_input_step (input_info level Z.zero) sol_input tree

  let set_internal_message level counter message tree =
    PVM.set_input_step (input_info level counter) message tree

  let set_eol_input level counter tree =
    let sol_input =
      Tezos_scoru_wasm.Pvm_input_kind.(
        Internal_for_tests.to_binary_input (Internal End_of_level) None)
    in
    PVM.set_input_step (input_info level counter) sol_input tree

  let set_inputs_step set_internal_message messages level tree =
    let open Lwt.Syntax in
    let next_message_counter = new_message_counter () in
    let (_ : Z.t) = next_message_counter () in
    let* tree = set_sol_input level tree in
    let* tree =
      List.fold_left_s
        (fun tree message ->
          set_internal_message level (next_message_counter ()) message tree)
        tree
        messages
    in
    set_eol_input level (next_message_counter ()) tree

  let set_full_input_step_gen set_internal_message messages level tree =
    let open Lwt.Syntax in
    let* tree = set_inputs_step set_internal_message messages level tree in
    eval_to_snapshot ~max_steps:Int64.max_int tree

  let set_full_input_step = set_full_input_step_gen set_internal_message

  let run ~kernel ~messages =
    let open Lwt.Syntax in
    let go index (tree, timings) message =
      let t0 = Sys.time () in
      let* tree = eval_until_input_requested tree in
      let* stuck = PVM.Internal_for_tests.is_stuck tree in
      (match stuck with Some _ -> assert false | None -> ()) ;
      let* tree = set_full_input_step [message] (Int32.of_int index) tree in
      let* stuck = PVM.Internal_for_tests.is_stuck tree in
      (match stuck with Some _ -> assert false | None -> ()) ;
      let* tree = eval_until_input_requested tree in
      let+ stuck = PVM.Internal_for_tests.is_stuck tree in
      (match stuck with
      | Some _error -> Stdlib.failwith "oops"
      (* (Tezos_scoru_wasm.Wasm_pvm_errors.show error) *)
      | None -> ()) ;
      let t1 = Sys.time () in
      (tree, timings @ [t1 -. t0])
    in
    let* tree = empty_tree () in
    let* tree = PVM.initial_state tree in
    let* tree =
      PVM.install_boot_sector
        ~ticks_per_snapshot:(Z.of_int64 11_000_000_000L)
        ~outbox_validity_period:10l
        ~outbox_message_limit:(Z.of_int32 100l)
        kernel
        tree
    in
    let+ tree, timings = List.fold_left_i_s go (tree, []) messages in
    (Tree.hash tree, timings)
end

module Wasm_slow = Tezos_scoru_wasm.Wasm_pvm.Make (Tree)
module Wasm_fast = Tezos_scoru_wasm_fast.Pvm.Make (Tree)
module Bench_slow = Make (Wasm_slow)
module Bench_fast = Make (Wasm_fast)

module type Bench = sig
  val run :
    kernel:string ->
    messages:string list ->
    (Tezos_crypto.Hashed.Context_hash.t * float list) Lwt.t
end

let bench ~title ?(samples = 1) (module B : Bench) =
  let open Lwt.Syntax in
  let* kernel =
    Lwt_io.with_file
      ~mode:Lwt_io.Input
      (* "./tezos/installer-computed.wasm" *)
      "./tx-kernel.wasm"
      (* "/home/emma/sources/wasm-kernel/installer.wasm" *)
      Lwt_io.read
  in
  let* messages =
    List.map_s
      (fun path -> Lwt_io.with_file ~mode:Lwt_io.Input path Lwt_io.read)
      (List.map (fun f ->
           Printf.printf "Reading message: %s\n" f ;
           "./actual_messages/" ^ f)
      @@ List.fast_sort String.compare
      @@ Array.to_list
      @@ Sys.readdir "./actual_messages/")
  in
  let trigger = Stdlib.List.init samples (fun _ -> ()) in
  let+ hashes = List.map_s (fun () -> B.run ~kernel ~messages) trigger in
  let time_spent =
    List.fold_left
      (fun time (_, timings) -> time +. List.fold_left ( +. ) 0.0 timings)
      0.0
      hashes
  in
  let hash = match hashes with (hash, _) :: _ -> hash | _ -> assert false in
  Format.printf
    "> %s: %fms to %a\n%!"
    title
    (time_spent /. Float.of_int samples *. 1000.0)
    Tezos_crypto.Hashed.Context_hash.pp
    hash ;
  let timings =
    match List.map (fun (_, t) -> t) hashes with
    | t1 :: ts ->
        List.fold_left
          (fun lhs rhs ->
            Stdlib.List.combine lhs rhs
            |> List.map (fun (lhs, rhs) -> lhs +. rhs))
          t1
          ts
    | _ -> assert false
  in
  Format.printf
    "> %s: %a\n%!"
    title
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.pp_print_string fmt ", ")
       (fun fmt time_spent ->
         Format.fprintf fmt "%fms" (time_spent /. Float.of_int samples *. 1000.0)))
    timings

let main () =
  let open Lwt.Syntax in
  let* () = bench ~title:"fast" ~samples:1 (module Bench_fast) in
  (* let* () = bench ~title:"slow" (module Bench_slow) in *)
  Lwt.return_unit

let () = Lwt_main.run (main ())
