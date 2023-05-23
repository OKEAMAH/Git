(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech, <contact@trili.tech>                        *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
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

(* TODO: https://gitlab.com/tezos/tezos/-/issues/5073
   Update Certificate repr to handle a dynamic dac.
*)
module V0 = struct
  (** Current version of the [Certificate]
      must be equal to the version of the module, 0 in this case. *)
  let version = 0

  (** Representation of a Data Availibility Committee Certificate.
     Type is private to make sure correct [version] is used.
     Use [make] function to create a [Certificate_repr.V0.t] *)
  type certificate = {
    root_hash : Dac_plugin.raw_hash;
    aggregate_signature : Tezos_crypto.Aggregate_signature.signature;
    witnesses : Z.t;
        (* TODO: https://gitlab.com/tezos/tezos/-/issues/4853
           Use BitSet for witnesses field in external message
        *)
  }

  let make_certificate root_hash aggregate_signature witnesses =
    {root_hash; aggregate_signature; witnesses}

  let encoding_certificate =
    let obj_enc =
      Data_encoding.(
        obj4
          (req "version" Data_encoding.uint8)
          (req "root_hash" Dac_plugin.raw_hash_encoding)
          (req "aggregate_signature" Tezos_crypto.Aggregate_signature.encoding)
          (req "witnesses" z))
    in
    Data_encoding.(
      conv_with_guard
        (fun {root_hash; aggregate_signature; witnesses} ->
          (0, root_hash, aggregate_signature, witnesses))
        (fun (version, root_hash, aggregate_signature, witnesses) ->
          if version == 0 then Ok {root_hash; aggregate_signature; witnesses}
          else Error "invalid version of certificate.")
        obj_enc)

  let all_committee_members_have_signed committee_members {witnesses; _} =
    let length = List.length committee_members in
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/4562
       The following is equivalent to Bitset.fill length. The Bitset module
       should be used once it is moved from the protocol to the environment. *)
    let expected_witnesses = Z.(pred (shift_left one length)) in
    (* Equivalent to Bitset.diff expected_witnesses witnesses. *)
    let missing_witnesses = Z.logand expected_witnesses (Z.lognot witnesses) in
    Z.(equal missing_witnesses zero)


    (** Binary_certificiate is the same as Certificiate_repr.certificiate
        but with Dac_plugin.hash instead of Dac_plugin.raw_hash *)
  type binary_certificate = {
    root_hash : Dac_plugin.hash;
    aggregate_signature : Tezos_crypto.Aggregate_signature.signature;
    witnesses : Z.t;
  }

  (** This function is returning the encoded bytes of provided parameters,
      which is basically a Certificiate_repr.certificiate but with Dac_plugin.hash *)
  let serialize_certificate dac_plugin root_hash aggregate_signature witnesses =
    let open Lwt_result_syntax in
    let ((module Plugin) : Dac_plugin.t) = dac_plugin in
    let*? root_hash = Dac_plugin.raw_to_hash dac_plugin root_hash in
    let to_serialize = {root_hash; aggregate_signature; witnesses} in
    let binary_certificiate_encoding =
      let untagged =
        Data_encoding.(
          conv
            (fun {root_hash; aggregate_signature; witnesses} ->
              (root_hash, aggregate_signature, witnesses))
            (fun (root_hash, aggregate_signature, witnesses) ->
              {root_hash; aggregate_signature; witnesses})
            (obj3
               (req "root_hash" Plugin.encoding)
               (req
                  "aggregate_signature"
                  Tezos_crypto.Aggregate_signature.encoding)
               (req "witnesses" z)))
      in
      Data_encoding.(
        union
          ~tag_size:`Uint8
          [
            case
              ~title:"certificate_V0"
              (Tag 0)
              untagged
              (fun certificate -> Some certificate)
              (fun certificate -> certificate);
          ])
    in
    let serialized =
      Data_encoding.Binary.to_bytes binary_certificiate_encoding to_serialize
    in
    match serialized with
    | Ok serialized_certificiate -> return serialized_certificiate
    | Error _ -> Stdlib.failwith ""

  type t = {certificate : certificate; serialized_certificate : bytes}

  (** Encoding of the `type t` *)
  let encoding =
    let obj_enc =
      Data_encoding.(
        obj2
          (req "certificate" encoding_certificate)
          (req "serialized_certificiate" Data_encoding.bytes))
    in
    Data_encoding.(
      conv
        (fun {certificate; serialized_certificate} ->
          (certificate, serialized_certificate))
        (fun (certificate, serialized_certificate) ->
          {certificate; serialized_certificate})
        obj_enc)

  let make dac_plugin root_hash aggregate_signature witnesses =
    let open Lwt_result_syntax in
    let certificate =
      make_certificate root_hash aggregate_signature witnesses
    in
    let* serialized_certificate =
      serialize_certificate dac_plugin root_hash aggregate_signature witnesses
    in
    return {certificate; serialized_certificate}
end

type t = V0 of V0.t

let encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"certificate_repr_V0"
        Json_only
        V0.encoding
        (function V0 s -> Some s)
        (fun s -> V0 s);
    ]

let get_root_hash t = match t with V0 t -> t.certificate.root_hash

let get_aggregate_signature t =
  match t with V0 t -> t.certificate.aggregate_signature

let get_witnesses t = match t with V0 t -> t.certificate.witnesses

let get_version t = match t with V0 _t -> V0.version

let all_committee_members_have_signed committee_members certificate =
  match certificate with
  | V0 t -> V0.all_committee_members_have_signed committee_members t.certificate
