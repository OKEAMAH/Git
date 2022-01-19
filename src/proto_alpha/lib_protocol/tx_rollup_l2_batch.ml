(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

open Alpha_context
module Ticket_indexable = Indexable.Make (Ticket_hash)

let tag_size = `Uint8

let bls_signature_size = 96

let signer_encoding =
  Data_encoding.(
    conv
      Bls_signature.pk_to_bytes
      (fun x ->
        match Bls_signature.pk_of_bytes_opt x with
        | Some x -> x
        | None -> raise (Invalid_argument "not a BLS public key"))
      (Fixed.bytes bls_signature_size))

module Signer_indexable = Indexable.Make (struct
  type t = Bls_signature.pk

  let pp fmt _ = Format.pp_print_string fmt "<bls_signature>"

  let compare x y =
    Bytes.compare (Bls_signature.pk_to_bytes x) (Bls_signature.pk_to_bytes y)

  let encoding = signer_encoding
end)

type 'status destination =
  | Layer1 of Signature.Public_key_hash.t
  | Layer2 of 'status Tx_rollup_l2_address.Indexable.indexable

let compact_destination =
  Compact_encoding.(
    conv
      (function Layer1 x -> Case_0 x | Layer2 x -> Case_1 x)
      (function Case_0 x -> Layer1 x | Case_1 x -> Layer2 x)
      (case2
         (case "layer1" @@ singleton Signature.Public_key_hash.encoding)
         (case "layer2" @@ Indexable.compact Tx_rollup_l2_address.encoding)))

module V_unused = struct
  type t = Compact_encoding.void

  let compact = Compact_encoding.void

  let encoding =
    Data_encoding.(
      conv_with_guard
        Compact_encoding.refute
        (fun _ -> Error "unused tag")
        empty)
end

module V1 = struct
  type 'status operation_content = {
    destination : 'status destination;
    ticket_hash : 'status Ticket_indexable.indexable;
    qty : int64;
  }

  type ('signer, 'content) operation = {
    signer : 'signer Signer_indexable.indexable;
    counter : int64;
    contents : 'content operation_content list;
  }

  type ('signer, 'content) transaction = ('signer, 'content) operation list

  type signature = bytes

  type ('signer, 'content) t = {
    contents : ('signer, 'content) transaction list;
    aggregated_signatures : signature;
  }

  (* --- ENCODING ------------------------------------------------------------- *)

  (* --- [operation_content]                                                    *)

  let compact_operation_content =
    Compact_encoding.(
      conv
        (fun {destination; ticket_hash; qty} -> (destination, ticket_hash, qty))
        (fun (destination, ticket_hash, qty) -> {destination; ticket_hash; qty})
      @@ obj3
           (req "destination" compact_destination)
           (req "ticket_hash" Ticket_indexable.compact)
           (req "qty" int64))

  let operation_content_encoding =
    Compact_encoding.make ~tag_size compact_operation_content

  let compact_operation =
    Compact_encoding.(
      conv
        (fun {signer; counter; contents} -> (signer, counter, contents))
        (fun (signer, counter, contents) -> {signer; counter; contents})
      @@ obj3
           (req "signer" @@ Signer_indexable.compact)
           (req "counter" int64)
           (req "contents" @@ list 4 operation_content_encoding))

  let operation_encoding = Compact_encoding.(make ~tag_size compact_operation)

  let transaction_encoding :
      (Indexable.unknown, Indexable.unknown) transaction Data_encoding.t =
    Compact_encoding.(make ~tag_size @@ list 8 operation_encoding)

  let compact n : (Indexable.unknown, Indexable.unknown) t Compact_encoding.t =
    Compact_encoding.(
      conv
        (fun {aggregated_signatures; contents} ->
          (aggregated_signatures, contents))
        (fun (aggregated_signatures, contents) ->
          {aggregated_signatures; contents})
      @@ obj2
           (req "aggregated_signatures" @@ singleton Data_encoding.bytes)
           (req "contents" @@ list n transaction_encoding))

  let encoding n : (Indexable.unknown, Indexable.unknown) t Data_encoding.t =
    Compact_encoding.make ~tag_size @@ compact n
end

module V2 = V_unused
module V3 = V_unused
module V_next = V_unused

type ('signer, 'content) t =
  | V1 of ('signer, 'content) V1.t
  | V2 of V2.t
  | V3 of V3.t
  | V_next of V_next.t

(** We use two bits to two bits for the versioning of the layer-2
    batches. This means that six bits are dedicated to encode batches
    of sixty-two transactions more efficiently.

    To ensure backward compatibility, the combinator [case4] cannot be
    changed. This means that [V4] and greater will have to be treated in
    dedicated compact encoding, and the last case of [case4] *)
let compact =
  Compact_encoding.(
    conv
      (function
        | V1 x -> Case_00 x
        | V2 x -> Case_01 x
        | V3 x -> Case_10 x
        | V_next x -> Case_11 x)
      (function
        | Case_00 x -> V1 x
        | Case_01 x -> V2 x
        | Case_10 x -> V3 x
        | Case_11 x -> V_next x)
      (case4
         (case "V1" (V1.compact 6))
         (case "V2" V2.compact)
         (case "V3" V3.compact)
         (case "V_next" @@ singleton V_next.encoding)))

(** An encoding for [t] that uses a specialized, space-efficient encoding
    for the list of transactions. *)
let encoding : (Indexable.unknown, Indexable.unknown) t Data_encoding.t =
  Compact_encoding.make ~tag_size compact
