module Wasmer = Tezos_wasmer
module Lazy_containers = Tezos_lazy_containers

let kernel_key = Durable.key_of_string_exn "/kernel/boot.wasm"

let load_kernel store durable =
  let open Lwt.Syntax in
  let* kernel = Durable.find_value_exn durable kernel_key in
  let+ kernel = Lazy_containers.Chunked_byte_vector.to_string kernel in
  Wasmer.Module.create_from_wasm store kernel

let to_ref_memory min max mem =
  let length = Wasmer.Memory.length mem |> Int64.of_int in
  let get_chunk page_id =
    let start_address =
      Int64.mul page_id Lazy_containers.Chunked_byte_vector.Chunk.size
    in
    let body =
      Bytes.init
        (Int64.to_int Lazy_containers.Chunked_byte_vector.Chunk.size)
        (fun i ->
          Wasmer.Memory.get mem Int64.(add start_address (of_int i) |> to_int)
          |> Unsigned.UInt8.to_int |> Char.chr)
    in
    Lwt.return (Lazy_containers.Chunked_byte_vector.Chunk.of_bytes body)
  in

  let chunked = Lazy_containers.Chunked_byte_vector.create ~get_chunk length in
  let min = Unsigned.UInt32.to_int32 min in
  let max = Unsigned.UInt32.to_int32 max in
  Tezos_webassembly_interpreter.(
    Partial_memory.of_chunks
      (MemoryType {min; max = (if max >= 0l then Some max else None)})
      chunked)

let commit_memory mem partial_memory =
  let chunks =
    Lazy_containers.Chunked_byte_vector.loaded_chunks
      (Tezos_webassembly_interpreter.Partial_memory.content partial_memory)
  in
  List.iter
    (fun (chunk_id, chunk) ->
      let start =
        Int64.mul chunk_id Lazy_containers.Chunked_byte_vector.Chunk.size
      in
      let body = Lazy_containers.Chunked_byte_vector.Chunk.to_bytes chunk in
      Bytes.iteri
        (fun i char ->
          let addr = Int64.(add start (of_int i) |> to_int) in
          Wasmer.Memory.set mem addr (Char.code char |> Unsigned.UInt8.of_int))
        body)
    chunks

let compute store durable (buffers : Tezos_webassembly_interpreter.Eval.buffers)
    =
  let open Lwt.Syntax in
  let* module_ = load_kernel store durable in

  let main_mem = ref None in
  let retrieve_mem () =
    match !main_mem with Some x -> x () | None -> assert false
  in
  let with_mem f =
    let mem, min, max = retrieve_mem () in
    let ref_mem = to_ref_memory min max mem in
    let+ value = f ref_mem in
    commit_memory mem ref_mem ;
    value
  in

  let durable_ref = ref durable in

  let host_funcs =
    let open Wasmer in
    let read_input =
      fn
        (i32 @-> i32 @-> i32 @-> i32 @-> i32 @-> returning1 i32)
        (fun rtype_offset level_offset id_offset dst max_bytes () ->
          with_mem @@ fun memory ->
          let+ result =
            Host_funcs.Internal_for_tests.aux_write_input_in_memory
              ~input_buffer:buffers.input
              ~output_buffer:buffers.output
              ~memory
              ~rtype_offset
              ~level_offset
              ~id_offset
              ~dst
              ~max_bytes
          in
          Int32.of_int result)
    in
    let write_output =
      fn
        (i32 @-> i32 @-> returning1 i32)
        (fun src num_bytes () ->
          with_mem @@ fun memory ->
          Host_funcs.Internal_for_tests.aux_write_output
            ~input_buffer:buffers.input
            ~output_buffer:buffers.output
            ~memory
            ~src
            ~num_bytes)
    in
    let store_has =
      fn
        (i32 @-> i32 @-> returning1 i32)
        (fun key_offset key_length () ->
          with_mem @@ fun memory ->
          let+ result =
            Host_funcs.Internal_for_tests.aux_store_has
              ~durable:!durable_ref
              ~memory
              ~key_offset
              ~key_length
          in
          result)
    in
    let store_list_size =
      fn
        (i32 @-> i32 @-> returning1 i64)
        (fun key_offset key_length () ->
          with_mem @@ fun memory ->
          let+ durable, result =
            Host_funcs.Internal_for_tests.aux_store_list_size
              ~durable:!durable_ref
              ~memory
              ~key_offset
              ~key_length
          in
          durable_ref := durable ;
          result)
    in
    let store_delete =
      fn
        (i32 @-> i32 @-> void)
        (fun key_offset key_length () ->
          with_mem @@ fun memory ->
          let+ durable =
            Host_funcs.Internal_for_tests.aux_store_delete
              ~durable:!durable_ref
              ~memory
              ~key_offset
              ~key_length
          in
          durable_ref := durable ;
          ())
    in
    let write_debug =
      fn
        (i32 @-> i32 @-> void)
        (fun key_offset key_length () ->
          let mem, _, _ = retrieve_mem () in
          let str =
            String.init (Int32.to_int key_length) (fun i ->
                Wasmer.Memory.get mem (Int32.to_int key_offset + i)
                |> Unsigned.UInt8.to_int |> Char.chr)
          in
          Printf.printf "DEBUG: %s\n" str ;
          Lwt.return ())
    in
    [
      ("rollup_safe_core", "read_input", read_input);
      ("rollup_safe_core", "write_output", write_output);
      ("rollup_safe_core", "write_debug", write_debug);
      ("rollup_safe_core", "store_has", store_has);
      ("rollup_safe_core", "store_list_size", store_list_size);
      ("rollup_safe_core", "store_delete", store_delete);
    ]
  in

  let* instance = Wasmer.Instance.create store module_ host_funcs in

  let exports = Wasmer.Exports.from_instance instance in
  let kernel_next = Wasmer.(Exports.fn exports "kernel_next" void) in

  main_mem :=
    Some
      (fun () ->
        let mem, min, max = Wasmer.Exports.mem0 exports in
        (mem, min, max)) ;

  let* () = kernel_next () in

  Wasmer.Instance.delete instance ;
  Wasmer.Module.delete module_ ;
  Lwt.return !durable_ref
