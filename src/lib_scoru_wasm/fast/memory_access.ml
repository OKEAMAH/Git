open Tezos_scoru_wasm
module Memory = Tezos_wasmer.Memory

module Wasmer : Host_funcs.Memory_access with type t = Memory.t = struct
  type t = Memory.t

  let load_bytes memory addr size =
    let addr = Int32.to_int addr in
    let char_at (ptr : int) =
      Memory.get memory ptr |> Unsigned.UInt8.to_int |> Char.chr
    in

    Lwt.return @@ String.init size (fun idx -> char_at @@ (addr + idx))

  let store_bytes memory addr data =
    let char_to_uint8 char = Char.code char |> Unsigned.UInt8.of_int in
    let addr = Int32.to_int addr in
    let set_char idx chr =
      Memory.set memory (addr + idx) @@ char_to_uint8 chr
    in
    String.iteri set_char data ;
    Lwt.return ()

  let to_bits (num : Tezos_webassembly_interpreter.Values.num) : int * int64 =
    let open Tezos_webassembly_interpreter in
    let size = Types.num_size @@ Values.type_of_num num in
    let bits =
      match num with
      | Values.I32 x -> Int64.of_int32 x
      | Values.I64 x -> x
      | Values.F32 x -> Int64.of_int32 @@ F32.to_bits x
      | Values.F64 x -> F64.to_bits x
    in
    (size, bits)

  let store_num memory addr offset num =
    let abs_addr = Int32.to_int @@ Int32.add addr offset in
    let num_bytes, bits = to_bits num in

    let rec loop steps addr bits =
      if steps > 0 then (
        let lsb = Unsigned.UInt8.of_int @@ (Int64.to_int bits land 0xff) in
        let bits = Int64.shift_left bits 8 in

        Memory.set memory addr lsb ;
        loop (steps - 1) (addr + 1) bits)
    in

    loop num_bytes abs_addr bits ;
    Lwt.return ()

  let bound (memory : Memory.t) = Int64.of_int (Memory.length memory)

  let exn_to_error ~default = function
    | Invalid_argument msg when msg = "index out of bounds" ->
        Host_funcs.Error.Memory_out_of_bounds
    | _ -> default
end
