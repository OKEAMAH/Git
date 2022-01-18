(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

open Tx_rollup_l2_storage

type signature = bytes

let signature_encoding = Data_encoding.bytes

type address_index = Tx_rollup_l2_address.Indexable.index

type ticket_index = Tx_rollup_l2_batch.Ticket_indexable.index

type metadata = {counter : int64; public_key : Bls_signature.pk}

let pk_encoding : Bls_signature.pk Data_encoding.t =
  Data_encoding.(
    conv_with_guard
      Bls_signature.pk_to_bytes
      (fun x ->
        Option.fold
          ~none:(Error "not a valid bls public key")
          ~some:ok
          (Bls_signature.pk_of_bytes_opt x))
      bytes)

let metadata_encoding =
  Data_encoding.(
    conv
      (fun {counter; public_key} -> (counter, public_key))
      (fun (counter, public_key) -> {counter; public_key})
      (obj2 (req "counter" int64) (req "public_key" pk_encoding)))

type error +=
  | Unknown_address_index of address_index
  | Balance_too_low
  | Balance_overflow

module type CONTEXT = sig
  type t

  type 'a m

  module Syntax : sig
    val ( let+ ) : 'a m -> ('a -> 'b) -> 'b m

    val ( let* ) : 'a m -> ('a -> 'b m) -> 'b m

    val fail : error -> 'a m

    val catch : 'a m -> ('a -> 'b m) -> (error -> 'b m) -> 'b m

    val return : 'a -> 'a m

    val list_fold_left_m : ('a -> 'b -> 'a m) -> 'a -> 'b list -> 'a m

    val fail_unless : bool -> error -> unit m
  end

  val bls_verify : (Bls_signature.pk * bytes) list -> signature -> bool m

  module Address_metadata : sig
    val get : t -> address_index -> metadata option m

    val incr_counter : t -> address_index -> t m

    val init_with_public_key : t -> address_index -> Bls_signature.pk -> t m
  end

  module Address_index : sig
    val associate_index : t -> Tx_rollup_l2_address.t -> (t * address_index) m

    val get : t -> Tx_rollup_l2_address.t -> address_index option m

    val count : t -> int32 m
  end

  module Ticket_index : sig
    val associate_index : t -> Ticket_hash_repr.t -> (t * ticket_index) m

    val get : t -> Ticket_hash_repr.t -> ticket_index option m

    val count : t -> int32 m
  end

  module Ticket_ledger : sig
    val get : t -> ticket_index -> address_index -> int64 m

    val credit : t -> ticket_index -> address_index -> int64 -> t m

    val spend : t -> ticket_index -> address_index -> int64 -> t m
  end
end

(** {1 Type-Safe Storage Access and Gas Accounting} *)

(** A value of type ['a key] identifies a value of type ['a] in an
    underlying, untyped storage.

    This GADT is used to enforce type-safety of the abstraction of
    the transactions rollup context. For this abstraction to work,
    it is necessary to ensure that the serialization of values ['a
    key] and ['b key] cannot collide. To that end, we use
    [Data_encoding] (see {!packed_key_encoding}). *)
type _ key =
  | Address_metadata : address_index -> metadata key
  | Address_count : int32 key
  | Address_index : Tx_rollup_l2_address.t -> address_index key
  | Ticket_count : int32 key
  | Ticket_index : Ticket_hash_repr.t -> ticket_index key
  | Ticket_ledger : ticket_index * address_index -> int64 key

(** A monomorphic version of {!Key}, used for serialization purposes. *)
type packed_key = Key : 'a key -> packed_key

(** The encoding used to serialize keys to be used with an untyped storage. *)
let packed_key_encoding : packed_key Data_encoding.t =
  Data_encoding.(
    union
      ~tag_size:`Uint8
      [
        case
          (Tag 0)
          ~title:"Address_metadata"
          Tx_rollup_l2_address.Indexable.index_encoding
          (function Key (Address_metadata idx) -> Some idx | _ -> None)
          (fun idx -> Key (Address_metadata idx));
        case
          (Tag 1)
          ~title:"Address_count"
          empty
          (function Key Address_count -> Some () | _ -> None)
          (fun () -> Key Address_count);
        case
          (Tag 2)
          ~title:"Address_index"
          Tx_rollup_l2_address.encoding
          (function Key (Address_index addr) -> Some addr | _ -> None)
          (fun addr -> Key (Address_index addr));
        case
          (Tag 3)
          ~title:"Ticket_count"
          empty
          (function Key Ticket_count -> Some () | _ -> None)
          (fun () -> Key Ticket_count);
        case
          (Tag 4)
          ~title:"Ticket_index"
          Ticket_hash_repr.encoding
          (function Key (Ticket_index ticket) -> Some ticket | _ -> None)
          (fun ticket -> Key (Ticket_index ticket));
        case
          (Tag 5)
          ~title:"Ticket_ledger"
          (tup2
             Tx_rollup_l2_batch.Ticket_indexable.index_encoding
             Tx_rollup_l2_address.Indexable.index_encoding)
          (function
            | Key (Ticket_ledger (ticket, address)) -> Some (ticket, address)
            | _ -> None)
          (fun (ticket, address) -> Key (Ticket_ledger (ticket, address)));
      ])

(** [value_encoding key] returns the encoding to be used to serialize
    and deserialize values associated to a [key] from and to the
    underlying storage. *)
let value_encoding : type a. a key -> a Data_encoding.t =
  let open Data_encoding in
  function
  | Address_metadata _ -> metadata_encoding
  | Address_count -> int32
  | Address_index _ -> Tx_rollup_l2_address.Indexable.index_encoding
  | Ticket_count -> int32
  | Ticket_index _ -> Tx_rollup_l2_batch.Ticket_indexable.index_encoding
  | Ticket_ledger _ -> int64

(** {1 Errors} *)

type error += Key_cannot_be_serialized

type error += Value_cannot_be_serialized

type error += Value_cannot_be_unserialized

let () =
  let open Data_encoding in
  (* Key cannot be serialized *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_key_cannot_be_serialized"
    ~title:"Key cannot be serialized"
    ~description:"Tried to serialize an invalid key."
    empty
    (function Key_cannot_be_serialized -> Some () | _ -> None)
    (fun () -> Key_cannot_be_serialized) ;
  (* Value cannot be serialized *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_value_cannot_be_serialized"
    ~title:"Value cannot be serialized"
    ~description:"Tried to serialize an invalid value."
    empty
    (function Value_cannot_be_serialized -> Some () | _ -> None)
    (fun () -> Value_cannot_be_serialized) ;
  (* Value cannot be unserialized *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_value_cannot_be_unserialized"
    ~title:"Value cannot be unserialized"
    ~description:
      "A value has been serialized in the Tx_rollup store, but cannot be \
       unserialized."
    empty
    (function Value_cannot_be_serialized -> Some () | _ -> None)
    (fun () -> Value_cannot_be_serialized) ;
  (* Not enough gas *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_not_enough_gas"
    ~title:"Not enough gas"
    ~description:
      "A transactions batch has been submitted with not enough allocated gas, \
       making its application imposible"
    empty
    (function Value_cannot_be_serialized -> Some () | _ -> None)
    (fun () -> Value_cannot_be_serialized)

(** {1 The Context Functor} *)

module Make (S : STORAGE) : CONTEXT with type t = S.t and type 'a m = 'a S.m =
struct
  type t = S.t

  type 'a m = 'a S.m

  module Syntax = struct
    include S.Syntax

    let fail_unless cond error =
      let open S.Syntax in
      if cond then return () else fail error
  end

  let bls_verify : (Bls_signature.pk * bytes) list -> signature -> bool m =
   fun accounts aggregated_signature ->
    let open Syntax in
    return (Bls_signature.aggregate_verify accounts aggregated_signature)

  let unwrap_or : type a. a option -> error -> a S.m =
   fun opt err ->
    match opt with Some x -> S.Syntax.return x | None -> S.Syntax.fail err

  (** [get ctxt key] is a type-safe [get] function. *)
  let get : type a. t -> a key -> a option m =
   fun ctxt key ->
    let open Syntax in
    let value_encoding = value_encoding key in
    let* key =
      unwrap_or
        (Data_encoding.Binary.to_bytes_opt packed_key_encoding (Key key))
        Key_cannot_be_serialized
    in
    let* value = S.get ctxt key in
    match value with
    | Some value ->
        let* value =
          unwrap_or
            (Data_encoding.Binary.of_bytes_opt value_encoding value)
            Value_cannot_be_unserialized
        in
        return (Some value)
    | None -> return None

  (** [set ctxt key value] is a type-safe [set] function. *)
  let set : type a. t -> a key -> a -> t m =
   fun ctxt key value ->
    let open Syntax in
    let value_encoding = value_encoding key in
    let* key =
      unwrap_or
        (Data_encoding.Binary.to_bytes_opt packed_key_encoding (Key key))
        Key_cannot_be_serialized
    in
    let* value =
      unwrap_or
        (Data_encoding.Binary.to_bytes_opt value_encoding value)
        Value_cannot_be_serialized
    in
    S.set ctxt key value

  module Address_metadata = struct
    let get ctxt idx = get ctxt (Address_metadata idx)

    let incr_counter ctxt idx =
      let open S.Syntax in
      let* metadata = get ctxt idx in
      match metadata with
      | Some meta ->
          set
            ctxt
            (Address_metadata idx)
            {meta with counter = Int64.succ meta.counter}
      | None -> fail (Unknown_address_index idx)

    let init_with_public_key ctxt idx public_key =
      let open S.Syntax in
      let* metadata = get ctxt idx in
      match metadata with
      | None -> set ctxt (Address_metadata idx) {counter = 0L; public_key}
      | Some _ -> fail (assert false)
  end

  module Address_index = struct
    let count ctxt =
      let open Syntax in
      let+ count = get ctxt Address_count in
      Option.value ~default:0l count

    let associate_index ctxt addr =
      let open Syntax in
      let* idx = count ctxt in
      let* ctxt = set ctxt (Address_index addr) (Index idx) in
      let+ ctxt = set ctxt Address_count (Int32.succ idx) in
      (ctxt, Indexable.Index idx)

    let get ctxt addr = get ctxt (Address_index addr)
  end

  module Ticket_index = struct
    let count ctxt =
      let open Syntax in
      let+ count = get ctxt Ticket_count in
      Option.value ~default:0l count

    let associate_index ctxt ticket =
      let open Syntax in
      let* idx = count ctxt in
      let* ctxt = set ctxt (Ticket_index ticket) (Index idx) in
      let+ ctxt = set ctxt Ticket_count (Int32.succ idx) in
      (ctxt, Indexable.Index idx)

    let get ctxt ticket = get ctxt (Ticket_index ticket)
  end

  module Ticket_ledger = struct
    let get ctxt tidx aidx =
      let open Syntax in
      let+ res = get ctxt (Ticket_ledger (tidx, aidx)) in
      Option.value res ~default:0L

    let set ctxt tidx aidx = set ctxt (Ticket_ledger (tidx, aidx))

    let spend ctxt tidx aidx qty =
      let open Syntax in
      let* src_balance = get ctxt tidx aidx in
      let remainder = Int64.sub src_balance qty in
      let* () = fail_unless Compare.Int64.(0L <= remainder) Balance_too_low in
      set ctxt tidx aidx remainder

    let credit ctxt tidx aidx qty =
      let open Syntax in
      let* balance = get ctxt tidx aidx in
      let new_balance = Int64.add balance qty in
      let* () =
        fail_unless Compare.Int64.(balance <= new_balance) Balance_overflow
      in
      set ctxt tidx aidx new_balance
  end
end
