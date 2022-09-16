module Context = Tezos_context_memory.Context_binary
module Wasmer = Tezos_wasmer

type Tezos_lazy_containers.Lazy_map.tree += Tree of Context.tree

module T = struct
  type tree = Context.tree

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tezos_tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

module TE = Tezos_tree_encoding.Runner.Make (T)

let empty_tree () =
  let open Lwt.Syntax in
  let+ index = Context.init "/tmp" in
  let empty_store = Context.empty index in
  Context.Tree.empty empty_store

let unsafe_main () =
  let open Lwt.Syntax in
  let engine = Wasmer.Engine.create Wasmer.Config.default in
  let store = Wasmer.Store.create engine in

  let* deposit_msg =
    let* f = Lwt_io.open_file ~mode:Lwt_io.Input "deposit.out" in
    Lwt_io.read f
  in

  let* withdrawal_msg =
    let* f = Lwt_io.open_file ~mode:Lwt_io.Input "withdrawal.out" in
    Lwt_io.read f
  in

  let input = Tezos_webassembly_interpreter.Input_buffer.alloc () in
  let* () =
    Tezos_webassembly_interpreter.Input_buffer.(
      enqueue
        input
        {
          rtype = 0l;
          raw_level = 1l;
          message_counter = Z.of_int 0;
          payload = Bytes.of_string deposit_msg;
        })
  in
  let* () =
    Tezos_webassembly_interpreter.Input_buffer.(
      enqueue
        input
        {
          rtype = 0l;
          raw_level = 2l;
          message_counter = Z.of_int 1;
          payload = Bytes.of_string withdrawal_msg;
        })
  in

  let output = Tezos_webassembly_interpreter.Output_buffer.alloc () in
  let buffers = Tezos_webassembly_interpreter.Eval.{input; output} in

  let* kernel =
    let* f = Lwt_io.open_file ~mode:Lwt_io.Input "kernel_core.wasm" in
    Lwt_io.read f
  in

  let* durable_tree = empty_tree () in
  let* durable_tree =
    TE.encode
      Tezos_tree_encoding.(
        scope ["kernel"; "boot.wasm"; "_"] chunked_byte_vector)
      (Tezos_lazy_containers.Chunked_byte_vector.of_string kernel)
      durable_tree
  in
  let* durable_tree = TE.decode Tezos_tree_encoding.wrapped_tree durable_tree in
  let durable =
    Tezos_scoru_wasm.Durable.of_storage_exn
      (Tezos_webassembly_interpreter.Durable_storage.of_tree
         (Tezos_tree_encoding.Wrapped.wrap durable_tree))
  in

  let t0 = Sys.time () in
  let* _durable = Tezos_scoru_wasm.Fast_exec.compute store durable buffers in
  let t1 = Sys.time () in

  Printf.printf "took %fms\n%!" ((t1 -. t0) *. 1000.0) ;

  Tezos_webassembly_interpreter.Output_buffer.(
    Level_Vector.snapshot output
    |> Level_Vector.Vector.loaded_bindings
    |> List.map (fun (lvl, vec) ->
           let vs =
             Index_Vector.snapshot vec |> Index_Vector.Vector.loaded_bindings
           in
           List.map (fun (idx, payload) -> (lvl, idx, payload)) vs)
    |> List.concat)
  |> List.iter (fun (lvl, idx, payload) ->
         Printf.printf
           "output_message(%li, %s): %i bytes\n%!"
           lvl
           (Z.to_string idx)
           (Bytes.length payload)) ;

  Lwt.return_unit

let () =
  Printexc.record_backtrace true ;
  Lwt_main.run (unsafe_main ())
