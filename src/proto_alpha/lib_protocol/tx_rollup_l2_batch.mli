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

(** This module introduces the batches of transactions that the
    layer-2 (1) reads from its inboxes (see
    {!Tx_rollup_message_repr.Batch}), and (2) interprets off-chain.

    One of the main concerns of the transaction rollups is to provide
    a high-throughput to its participants. That is, transaction
    rollups are expected to be able to process a significant number of
    operations “per second.”

    Putting aside the computational power required by the rollup node,
    the main limit to the throughput of a transaction rollup is the
    number of operations that can fit in a Tezos block. As such, the
    number of bytes that are necessary to store the batches is of key
    importance.

    To estimate the theoritical maximum throughput of the transaction
    rollups as a feature, we can use the following methodology:

    {ul {li Determine the number of bytes that can be allocated to
            layer-2 batches in a Tezos block, under the hypothesis
            that only layer-2 batch submissions and the
            consensus-related operations are included in said
            block. Ideally, this needs to take into account the
            limitation of the size of a layer-2 batch imposed by the
            layer-1 protocol, and the size of the signature that comes
            with an individual batch.}
        {li Divide this number by the average size of a layer-2
            operation, this gives an estimate of the maximum layer-2
            operations per block.}
        {li Divide again the result by the average time (in seconds)
            between two Tezos blocks; the result is the theoretical
            maximum operation per second the transaction rollups allow
            to process.}}

   That is, there is three parameters that decide the throughput of
   transaction rollups, and the average size of an operation is the
   only one under the control of the layer-2 implementation.
   Henceforth, both the definitions of types of this module and the
   implementation of their encodings have been carefully crafted in
   order to allow for compact batches. *)

(** {1 Indexes} *)

(** The first design choice that has been made is to allow to replace
    replace several fields of the operations by integer indexes.

    For instance, the address of a layer-2 address is a 21 bytes hash,
    but they can also be designated by bounded integers of only 4
    bytes, dividing the memory footprint of said address per 5. *)

module Ticket_indexable : sig
  type nonrec 'state indexable = ('state, Ticket_hash.t) Indexable.indexable

  type nonrec index = Ticket_hash.t Indexable.index

  type t = Ticket_hash.t Indexable.t

  val encoding : t Data_encoding.t

  val compare : t -> t -> int

  val pp : Format.formatter -> t -> unit
end

module Signer_indexable : sig
  type nonrec 'state indexable = ('state, Bls_signature.pk) Indexable.indexable

  type nonrec index = Bls_signature.pk Indexable.index

  type t = Bls_signature.pk Indexable.t

  val encoding : t Data_encoding.t

  val compare : t -> t -> int

  val pp : Format.formatter -> t -> unit
end

(** {1 Layer-2 Batches Definitions} *)

type 'status destination =
  | Layer1 of Signature.Public_key_hash.t
  | Layer2 of 'status Tx_rollup_l2_address.Indexable.indexable

val compact_destination : Indexable.unknown destination Compact_encoding.t

(** The operations are versioned, to let the possibility to propose
    new features in future iterations of the protocol. *)

module V1 : sig
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

  (** [encoding n] is a specialized, space-efficient encoding for a
      batch of layer-2 operations, such as the [n] first bits of the
      first byte of the resulting binary array are used to encode
      small lists of transactions. *)
  val encoding : int -> (Indexable.unknown, Indexable.unknown) t Data_encoding.t

  (** A specialized, space-efficient encoding for [transaction].

      The first byte of the resulting binary array is used to encode
      the size of lists of less than 254 elements. For larger lists,
      the tag is [11111111] and the list is prefixed by its size,
      which consumes eight bytes. *)
  val transaction_encoding :
    (Indexable.unknown, Indexable.unknown) transaction Data_encoding.t

  (** A specialized, space-efficient encoding for [operation].

      The first byte of the binary output describes precisely the layout
      of the encoded value.

      Considering the tag [ooooccss], [ss] describes the format of
      [signer], [cc] of [counter] and [oooo] of [contents].

      More precisely, for [signer],

      {ul {li [00] means an index fitting on 1 byte.}
          {li [01] means an index fitting on 2 bytes.}
          {li [10] means an index fitting on 4 bytes.}
          {li [11] means a value of type {!Bls_signature.pk}.}}

      The [counter] field follows a similar logic,

      {ul {li [00] means an index fitting on 1 byte.}
          {li [01] means an index fitting on 2 bytes.}
          {li [10] means an index fitting on 4 bytes.}
          {li [11] means an integer fitting on 8 bytes.}

      Finally, the [contents] field follows this pattern

      {ul {li From [0000] to [t110], the tag encodes the size of the
              list of [operation_content], {i e.g.}, [010] means that
              there is two elements in [contents].}
          {li [1111] means that [contents] is prefixed by its number
              of elements.} *)
  val operation_encoding :
    (Indexable.unknown, Indexable.unknown) operation Data_encoding.t

  (** A specialized, space-efficient encoding for [operation_content].

      The first byte of the binary output describes precisely the layout
      of the encoded value.

      Considering the tag [0qqttddd], [dd] describes the format of
      [destination], [tt] of [ticket_hash] and [qq] of [qty]. More
      precisely, for [destination],

      {ul {li [000] means a value of type {!}, that is a layer-1 address.}
          {li [100] means an index for a layer-2 address, fitting on 1 byte.}
          {li [101] means an index for a layer-2 address, fitting on 2 bytes.}
          {li [110] means an index for a layer-2 address, fitting on 4 bytes.}
          {li [111] means a value (of type {!Tx_rollup_l2_address.t},
              that is a layer-2 address.}

      The [ticket_hash] is encoded using this logic:

      {ul {li [00] means an index for a ticket hash, fitting on 1 byte.}
          {li [01] means an index for a ticket hash, fitting on 2 bytes.}
          {li [10] means an index for a ticket hash, fitting on 4 bytes.}
          {li [11] means a value (of type {!Ticket_hash.t}.}

      The [qty] field follows a similar logic,

      {ul {li [00] means an integer fitting on 1 byte.}
          {li [01] means an integer fitting on 2 bytes.}
          {li [10] means an integer fitting on 4 bytes.}
          {li [11] means an integer fitting on 8 bytes.} *)
  val operation_content_encoding :
    Indexable.unknown operation_content Data_encoding.t
end

(** {1 Versioning} *)

(** To pave the road towards being able to update the semantics of the
    transaction rollups without having to interfere with the rejection
    mechanism, we preemptively back the notion of semantics versioning
    into the definition of a layer-2 batch.

    In practice, the last two bits of the first byte of a batch will
    determine which version to use. If more than three versions are
    necessary, then for version 4 and greater, the payload will have
    to have a dedicated way to distinguish between them.

    This is a precaution. We do not anticipate the need to update the
    semantics of the transaction rollups in a way which would break
    the backward compatibility of the implementation. But, with
    software development, you are never really sure. *)

module V_unused : sig
  type t = Compact_encoding.void
end

module V2 = V_unused
module V3 = V_unused
module V_next = V_unused

(** The  *)
type ('signer, 'content) t =
  | V1 of ('signer, 'content) V1.t
  | V2 of V_unused.t
  | V3 of V_unused.t
  | V_next of V_unused.t

(** An encoding for [t] that uses a specialized, space-efficient encoding
    for the list of transactions. *)
val encoding : (Indexable.unknown, Indexable.unknown) t Data_encoding.t
