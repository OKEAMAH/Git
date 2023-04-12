(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Trili Tech, <contact@trili.tech>                       *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

type hash = bytes

let hash_to_bytes = Fun.id

let hash_to_hex hash = Hex.of_bytes hash

type supported_hashes = Blake2B

type raw_hash = bytes

let raw_hash_to_bytes = Fun.id

let non_proto_encoding_unsafe = Data_encoding.bytes' Hex

let raw_hash_to_hex hash =
  let (`Hex hash) =
    (* The [encoding] of a hash here never, so [to_string_exn] is safe. *)
    Hex.of_string
    @@ Data_encoding.Binary.to_string_exn non_proto_encoding_unsafe hash
  in
  hash

let raw_hash_of_hex hex =
  let open Option_syntax in
  let* hash = Hex.to_bytes (`Hex hex) in
  Data_encoding.Binary.of_bytes_opt non_proto_encoding_unsafe hash

let scheme_of_raw_hash _raw_hash = Blake2B

let equal _rh1 _rh2 = true

let hex_to_raw_hash : string -> raw_hash = function
  | hex -> (
      let hash = Hex.to_bytes (`Hex hex) in
      match hash with
      | Some hash -> (
          match
            Data_encoding.Binary.of_bytes_opt non_proto_encoding_unsafe hash
          with
          | Some raw_hash -> raw_hash
          | _ -> Stdlib.failwith "error while decoding")
      | None -> Stdlib.failwith "error")

let raw_hash_rpc_arg =
  let construct = raw_hash_to_hex in
  let destruct hash =
    match raw_hash_of_hex hash with
    | None -> Error "Cannot parse reveal hash"
    | Some reveal_hash -> Ok reveal_hash
  in
  Tezos_rpc.Arg.make
    ~descr:"A reveal hash"
    ~name:"reveal_hash"
    ~destruct
    ~construct
    ()

module type T = sig
  val raw_hash_to_hash : raw_hash -> hash

  val hash_to_raw : hash -> raw_hash

  val encoding : hash Data_encoding.t

  val equal : hash -> hash -> bool

  val hash_string :
    scheme:supported_hashes -> ?key:string -> string list -> hash

  val hash_bytes : scheme:supported_hashes -> ?key:bytes -> bytes list -> hash

  val scheme_of_hash : hash -> supported_hashes

  val of_hex : string -> hash option

  val to_hex : hash -> string

  val size : scheme:supported_hashes -> int

  val hash_rpc_arg : hash Tezos_rpc.Arg.arg

  module Proto : Registered_protocol.T
end

type t = (module T)

let table : t Protocol_hash.Table.t = Protocol_hash.Table.create 5

let register (make_plugin : (bytes -> hash) -> t) : unit =
  let dac_plugin = make_plugin Fun.id in
  let module Plugin = (val dac_plugin) in
  assert (not (Protocol_hash.Table.mem table Plugin.Proto.hash)) ;
  Protocol_hash.Table.add table Plugin.Proto.hash (module Plugin)

let get hash = Protocol_hash.Table.find table hash
