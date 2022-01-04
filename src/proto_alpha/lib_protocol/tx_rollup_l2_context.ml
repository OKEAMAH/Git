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

open Alpha_context
open Tx_rollup_l2_storage

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

  val bls_verify : (Tx_rollup_l2_address.t * bytes) list -> bytes -> bool m

  module Counter : sig
    val get : t -> Tx_rollup_l2_address.t -> int64 m

    val set : t -> Tx_rollup_l2_address.t -> int64 -> t m
  end

  module Ticket_ledger : sig
    val get : t -> Ticket_hash.t -> Tx_rollup_l2_address.t -> int64 m

    val set : t -> Ticket_hash.t -> Tx_rollup_l2_address.t -> int64 -> t m
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
  | Counter : Tx_rollup_l2_address.t -> int64 key
  | Ticket_ledger : Ticket_hash.t * Tx_rollup_l2_address.t -> int64 key

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
          ~title:"Counter"
          Tx_rollup_l2_address.encoding
          (function Key (Counter account) -> Some account | _ -> None)
          (fun account -> Key (Counter account));
        case
          (Tag 1)
          ~title:"Ticket_ledger"
          (tup2 Ticket_hash.encoding Tx_rollup_l2_address.encoding)
          (function
            | Key (Ticket_ledger (hash, account)) -> Some (hash, account)
            | _ -> None)
          (fun (hash, account) -> Key (Ticket_ledger (hash, account)));
      ])

(** [value_encoding key value] returns the encoding to be used to
    serialize and deserialize values associated to a [key] from and to
    the underlying storage. *)
let value_encoding : type a. a key -> a Data_encoding.t = function
  | Counter _ -> Data_encoding.int64
  | Ticket_ledger _ -> Data_encoding.int64

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

  let bls_verify : (Tx_rollup_l2_address.t * bytes) list -> bytes -> bool m =
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

  module Counter = struct
    let get ctxt key =
      let open Syntax in
      let+ res = get ctxt (Counter key) in
      Option.value res ~default:0L

    let set store key = set store (Counter key)
  end

  module Ticket_ledger = struct
    let get store hash account =
      let open S.Syntax in
      let+ res = get store (Ticket_ledger (hash, account)) in
      Option.value res ~default:0L

    let set store hash account = set store (Ticket_ledger (hash, account))
  end
end
