module Wasmer = Tezos_wasmer
module Preimage_map = Map.Make (String)
module Lazy_containers = Tezos_lazy_containers

module Wasmer_mem = struct
  include Tezos_wasmer.Memory

  let to_ref_memory mem =
    let open Wasmer.Memory in
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
    let length = Wasmer.Memory.length mem |> Int64.of_int in
    let chunked =
      Lazy_containers.Chunked_byte_vector.create ~get_chunk length
    in
    let min = Unsigned.UInt32.to_int32 mem.min in
    let max = Option.map Unsigned.UInt32.to_int32 mem.max in
    Tezos_webassembly_interpreter.(
      Partial_memory.of_chunks (MemoryType {min; max}) chunked)

  let of_ref_memory mem partial_memory =
    let chunks =
      Lazy_containers.Chunked_byte_vector.loaded_chunks
        (Tezos_webassembly_interpreter.Partial_memory.content partial_memory)
    in
    List.iter
      (function
        | chunk_id, Some chunk ->
            let start =
              Int64.mul chunk_id Lazy_containers.Chunked_byte_vector.Chunk.size
            in
            let body =
              Lazy_containers.Chunked_byte_vector.Chunk.to_bytes chunk
            in
            Bytes.iteri
              (fun i char ->
                let addr = Int64.(add start (of_int i) |> to_int) in
                Wasmer.Memory.set
                  mem
                  addr
                  (Char.code char |> Unsigned.UInt8.of_int))
              body
        | _ -> ())
      chunks
end

module Memory_access_fast = Tezos_scoru_wasm_fast.Memory_access.Wasmer
module Memory_access_slow =
  Tezos_scoru_wasm.Host_funcs.Memory_access_interpreter

let are_equivalent initial_content f_ref f_wasmer =
  let open Lwt.Syntax in
  let result1 =
    Lwt_main.run
    @@ Lwt.catch
         (fun () ->
           let wasmer_mem = Wasmer_mem.of_list initial_content in
           let ref_mem = Wasmer_mem.to_ref_memory @@ wasmer_mem in
           let* ret = f_ref ref_mem in
           Wasmer_mem.of_ref_memory wasmer_mem ref_mem ;
           Lwt.return @@ Result.ok @@ (ret, Wasmer_mem.to_list wasmer_mem))
         (fun exn ->
           Lwt.return @@ Result.error @@ Memory_access_slow.exn_to_error exn)
  in

  let result2 =
    Lwt_main.run
    @@ Lwt.catch
         (fun () ->
           let wasmer_mem = Wasmer_mem.of_list initial_content in
           let* ret = f_wasmer wasmer_mem in
           Lwt.return @@ Result.ok @@ (ret, Wasmer_mem.to_list wasmer_mem))
         (fun exn ->
           Lwt.return @@ Result.error @@ Memory_access_fast.exn_to_error exn)
  in

  Result.equal
    ~ok:(fun (ret1, content1) (ret2, content2) ->
      ret1 == ret2 && List.equal Unsigned.UInt8.equal content1 content2)
    ~error:Stdlib.( == )
    result1
    result2

module QCheck = struct
  include QCheck

  let uint8 = map Unsigned.UInt8.of_int int
end

let test_store_bytes =
  let open QCheck in
  Test.make
    ~count:1000
    ~name:"store_bytes is the same on both memory implementations"
    (triple (list uint8) int32 string)
    (fun (content, address, data) ->
      are_equivalent
        content
        (fun mem -> Memory_access_slow.store_bytes mem address data)
        (fun mem -> Memory_access_fast.store_bytes mem address data))

let test_load_bytes =
  let open QCheck in
  Test.make
    ~count:1000
    ~name:"store_bytes is the same on both memory implementations"
    (triple (list uint8) int32 int)
    (fun (content, address, size) ->
      are_equivalent
        content
        (fun mem -> Memory_access_slow.load_bytes mem address size)
        (fun mem -> Memory_access_fast.load_bytes mem address size))

let tests = List.map QCheck_alcotest.to_alcotest [test_store_bytes]
