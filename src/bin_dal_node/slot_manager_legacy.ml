(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(* In this legacy module, we only use legacy events. *)
module Event = Event_legacy

type error +=
  | Splitting_failed of string
  | Merging_failed of string
  | Invalid_slot_header of string * string
  | Missing_shards of {provided : int; required : int}
  | Illformed_shard
  | Slot_not_found
  | Illformed_pages
  | Invalid_shards_slot_header_association

let () =
  register_error_kind
    `Permanent
    ~id:"dal.node.split_failed"
    ~title:"Split failed"
    ~description:"Splitting the slot failed"
    ~pp:(fun ppf msg -> Format.fprintf ppf "%s" msg)
    Data_encoding.(obj1 (req "msg" string))
    (function Splitting_failed parameter -> Some parameter | _ -> None)
    (fun parameter -> Splitting_failed parameter) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.merge_failed"
    ~title:"Merge failed"
    ~description:"Merging the slot failed"
    ~pp:(fun ppf msg -> Format.fprintf ppf "%s" msg)
    Data_encoding.(obj1 (req "msg" string))
    (function Merging_failed parameter -> Some parameter | _ -> None)
    (fun parameter -> Merging_failed parameter) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.invalid_slot_header"
    ~title:"Invalid slot_header"
    ~description:"The slot header is not valid"
    ~pp:(fun ppf (msg, com) -> Format.fprintf ppf "%s : %s" msg com)
    Data_encoding.(obj2 (req "msg" string) (req "com" string))
    (function Invalid_slot_header (msg, com) -> Some (msg, com) | _ -> None)
    (fun (msg, com) -> Invalid_slot_header (msg, com)) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.missing_shards"
    ~title:"Missing shards"
    ~description:"Some shards are missing"
    ~pp:(fun ppf (provided, required) ->
      Format.fprintf
        ppf
        "Some shards are missing, expected at least %d, found %d. Store is \
         invalid."
        provided
        required)
    Data_encoding.(obj2 (req "provided" int31) (req "required" int31))
    (function
      | Missing_shards {provided; required} -> Some (provided, required)
      | _ -> None)
    (fun (provided, required) -> Missing_shards {provided; required}) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.slot_not_found"
    ~title:"Slot not found"
    ~description:"Slot not found at this slot header"
    ~pp:(fun ppf () -> Format.fprintf ppf "Slot not found on given slot header")
    Data_encoding.(unit)
    (function Slot_not_found -> Some () | _ -> None)
    (fun () -> Slot_not_found) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.illformed_shard"
    ~title:"Illformed shard"
    ~description:"Illformed shard found in the store"
    ~pp:(fun ppf () -> Format.fprintf ppf "Illformed shard found in the store")
    Data_encoding.(unit)
    (function Illformed_shard -> Some () | _ -> None)
    (fun () -> Illformed_shard) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.illformed_pages"
    ~title:"Illformed pages"
    ~description:"Illformed pages found in the store"
    ~pp:(fun ppf () -> Format.fprintf ppf "Illformed pages found in the store")
    Data_encoding.(unit)
    (function Illformed_pages -> Some () | _ -> None)
    (fun () -> Illformed_pages) ;
  register_error_kind
    `Permanent
    ~id:"dal.node.invalid_shards_slot_header_association"
    ~title:"Invalid shards with slot header association"
    ~description:"Shards commit to a different slot header."
    ~pp:(fun ppf () ->
      Format.fprintf ppf "Association between shards and slot header is invalid")
    Data_encoding.(unit)
    (function Invalid_shards_slot_header_association -> Some () | _ -> None)
    (fun () -> Invalid_shards_slot_header_association)

type slot = bytes

let save store watcher commitment key_values =
  let open Lwt_result_syntax in
  let* () = Key_value_store.write_values store key_values in
  let*! () = Event.(emit stored_slot_shards commitment) in
  Lwt_watcher.notify watcher commitment ;
  return_unit

let split_and_store watcher cryptobox store slot =
  let r =
    let open Result_syntax in
    let* polynomial = Cryptobox.polynomial_from_slot cryptobox slot in
    let commitment = Cryptobox.commit cryptobox polynomial in
    let proof = Cryptobox.prove_commitment cryptobox polynomial in
    return (polynomial, commitment, proof)
  in
  let open Lwt_result_syntax in
  match r with
  | Ok (polynomial, commitment, commitment_proof) ->
      let key_values =
        Cryptobox.shards_from_polynomial cryptobox polynomial
        |> Cryptobox.IntMap.to_seq
        |> Seq.map (fun (int, shard) -> ((commitment, int), shard))
      in
      let* () = save store watcher commitment key_values in
      Lwt.return_ok (commitment, commitment_proof)
  | Error (`Slot_wrong_size msg) -> Lwt.return_error [Splitting_failed msg]

let polynomial_from_shards cryptobox shards =
  match Cryptobox.polynomial_from_shards cryptobox shards with
  | Ok p -> Ok p
  | Error (`Invert_zero msg | `Not_enough_shards msg) ->
      Error [Merging_failed msg]

let save_shards store watcher cryptobox commitment shards =
  let open Lwt_result_syntax in
  let*? polynomial = polynomial_from_shards cryptobox shards in
  let rebuilt_commitment = Cryptobox.commit cryptobox polynomial in
  let*? () =
    if Cryptobox.Commitment.equal commitment rebuilt_commitment then Ok ()
    else Result_syntax.fail [Invalid_shards_slot_header_association]
  in
  let key_values =
    Cryptobox.shards_from_polynomial cryptobox polynomial
    |> Cryptobox.IntMap.to_seq
    |> Seq.map (fun (int, shard) -> ((commitment, int), shard))
  in
  save store watcher commitment key_values

(* FIXME: missing validation of data? *)
let get_shard store commitment shard_id =
  let open Lwt_result_syntax in
  let* share = Key_value_store.read_value store (commitment, shard_id) in
  return Cryptobox.{index = shard_id; share}

let get_shards store commitment shard_ids =
  let open Lwt_result_syntax in
  let* list =
    Key_value_store.read_values
      store
      (List.to_seq shard_ids |> Seq.map (fun shard_id -> (commitment, shard_id)))
    |> Seq_s.fold_left_e
         (fun acc ((_commitment, shard_id), v) ->
           match v with
           | Error err -> Error err
           | Ok v -> Ok (Cryptobox.{index = shard_id; share = v} :: acc))
         []
  in
  List.rev list |> return

let get_slot cryptobox store commitment =
  let open Lwt_result_syntax in
  let keys =
    0 -- ((Cryptobox.parameters cryptobox).number_of_shards - 1)
    |> List.to_seq
    |> Seq.map (fun shard_id -> (commitment, shard_id))
  in
  let* shards =
    Key_value_store.read_values store keys
    |> Seq_s.fold_left_e
         (fun map ((_commitment, shard_id), value) ->
           match value with
           | Error err -> Error err
           | Ok value -> Ok (Cryptobox.IntMap.add shard_id value map))
         Cryptobox.IntMap.empty
  in
  let*? polynomial = polynomial_from_shards cryptobox shards in
  let slot = Cryptobox.polynomial_to_bytes cryptobox polynomial in
  let*! () =
    Event.(
      emit fetched_slot (Bytes.length slot, Cryptobox.IntMap.cardinal shards))
  in
  return slot

let get_slot_pages cryptobox store slot_header =
  let open Lwt_result_syntax in
  let dal_parameters = Cryptobox.parameters cryptobox in
  let* slot = get_slot cryptobox store slot_header in
  (* The slot size `Bytes.length slot` should be an exact multiple of `page_size`.
     If this is not the case, we throw an `Illformed_pages` error.
  *)
  (* DAL/FIXME: https://gitlab.com/tezos/tezos/-/issues/3900
     Implement `Bytes.chunk_bytes` which returns a list of bytes directly. *)
  let*? pages =
    String.chunk_bytes
      dal_parameters.page_size
      slot
      ~error_on_partial_chunk:(TzTrace.make Illformed_pages)
  in
  return @@ List.map (fun page -> String.to_bytes page) pages
