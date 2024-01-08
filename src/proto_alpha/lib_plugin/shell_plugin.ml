(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

(*
    The purpose of the plugin is to reduce repeated information that appears
    in the consensus operations to obtain a more compact form of storage.

    INPUT: operations : Operation.t trace trace
    OUTPUT: refactored_operations : Operation.t trace trace

                      operations : Operation.t trace trace
                     /                                    \
           consensus_operations : Operation.t trace   non_consensus_operations
                    |                                       |
           consensus_operations : packed_operation trace    |
              /            \                                /
       attestations   non_attestations                     /
             |              |                             /
   refactored_attestation   |                            /
              \             |                           /
               \            |                          /
              refactored_operations : refactored_operations
                            | (encoding)
              operation : Operation.t trace trace

   The transformation from attestations : packed_operation trace trace
   to a refactored_attestation is done in the following way:

   attestations :
    -----------------------------------------------------------
   | - shell                                                   |
   | - protocol_data : --------------------------------------  |
   |                  | - signature                          | |
   |                  | - contents : ----------------------  | |
   |                  |             | - slot               | | |
   |                  |             | - level              | | |   list
   |                  |             | - round              | | |
   |                  |             | - block_payload_hash | | |
   |                  |              ----------------------  | |
   |                  | - dal_content                        | |
   |                   --------------------------------------  |
    -----------------------------------------------------------

  In the `attestations` list, the following fields are duplicated:
  - shell
  - level
  - round
  - block_payload_hash
  Therefore, the only fields that differ remain:
  - signature
  - slot
  - dal_content
  These two will be grouped in a pair, and put into a list, which
  will accompany the other 4 common fields in a new type of object
  `refactored_attestation`:
  
  refactored_attestation :
    ------------------------------------------------
   | - shell                                        |
   | - contents : ----------------------            |
   |             | - level              |           |
   |             | - round              |           |
   |             | - block_payload_hash |           |
   |              ----------------------            |
   | - unique_contents_list : ---------------       |
   |                         | - dal_conte   |      |
   |                         | - slot        | list |
   |                         | - signature   |      |
   |                          ---------------       |
    ------------------------------------------------

   At the end, the refactored_operations is transformed into an Operation.t 
   trace trace object via the [refactoring_encoding].
*)

open Protocol
open Alpha_context

(* TYPES *)

type refactored_consensus_content = {
  level : Raw_level.t;
  round : Round.t;
  block_payload_hash : Block_payload_hash.t;
}

type refactored_attestation = {
  shell : Tezos_base.Operation.shell_header;
  contents : refactored_consensus_content;
  unique_contents_list : (dal_content option * Slot.t * Signature.t) trace;
}

type refactored_operations = {
  refactored_attestation : refactored_attestation option;
  consensus_operations : Tezos_base.Operation.t trace;
  other_operations : Tezos_base.Operation.t trace trace;
}

(* TRANSFORMATOR FUNCTIONS *)

let to_packed_operation {Operation.shell; proto} =
  {
    shell;
    protocol_data =
      Data_encoding.Binary.of_bytes_exn
        Protocol.operation_data_encoding_with_legacy_attestation_name
        proto;
  }

let to_operation {shell; protocol_data} =
  {
    Operation.shell;
    proto =
      Data_encoding.Binary.to_bytes_exn
        Protocol.operation_data_encoding_with_legacy_attestation_name
        protocol_data;
  }

let add_to_refactored_attestation refactored_attestation shell contents
    unique_content =
  match refactored_attestation with
  | None -> Some {unique_contents_list = [unique_content]; shell; contents}
  | Some ({unique_contents_list; _} as refactored_attestation) ->
      Some
        {
          refactored_attestation with
          unique_contents_list = unique_content :: unique_contents_list;
        }

(* [refactor_attestations] takes a list of consensus operations and returns a
   refactored_attestation object which contains all the attestations in a
   compacted form, together with the rest of the consensus operations *)
let refactor_attestations consensus_operations =
  let (accumulator : refactored_attestation option * packed_operation trace) =
    (None, [])
  in
  let refactored_attestation, non_attestations =
    List.fold_left
      (fun (refactored_attestation, non_attestations)
           {shell; protocol_data = Operation_data protocol_data} ->
        match protocol_data.contents with
        | Single
            (Attestation
              {
                consensus_content = {slot; level; round; block_payload_hash};
                dal_content;
              }) -> (
            let contents = {level; round; block_payload_hash} in
            match protocol_data.signature with
            | Some signature ->
                let unique_content = (dal_content, slot, signature) in
                ( add_to_refactored_attestation
                    refactored_attestation
                    shell
                    contents
                    unique_content,
                  non_attestations )
            | None -> (refactored_attestation, non_attestations))
        | _ ->
            ( refactored_attestation,
              {shell; protocol_data = Operation_data protocol_data}
              :: non_attestations ))
      accumulator
      consensus_operations
  in
  match refactored_attestation with
  | None -> (None, non_attestations)
  | Some ({unique_contents_list; _} as refactored_attestation) ->
      ( Some
          {
            refactored_attestation with
            unique_contents_list = List.rev unique_contents_list;
          },
        non_attestations )

let expand_refactored_attestation {shell; contents; unique_contents_list} =
  let {level; round; block_payload_hash} = contents in
  let packed_protocol_data_list =
    List.map
      (fun (dal_content, slot, signature) ->
        let consensus_content = {slot; level; round; block_payload_hash} in
        let contents = Single (Attestation {consensus_content; dal_content}) in
        Operation_data {signature = Some signature; contents})
      unique_contents_list
  in
  List.map
    (fun packed_protocol_data ->
      let proto =
        Data_encoding.Binary.to_bytes_exn
          Protocol.operation_data_encoding_with_legacy_attestation_name
          packed_protocol_data
      in
      {Operation.shell; proto})
    packed_protocol_data_list

(* ENCODINGS *)

let refactored_consensus_content_encoding =
  let open Data_encoding in
  conv
    (fun {level; round; block_payload_hash} ->
      (level, round, block_payload_hash))
    (fun (level, round, block_payload_hash) ->
      {level; round; block_payload_hash})
    (obj3
       (req "level" Raw_level.encoding)
       (req "round" Round.encoding)
       (req "block_payload_hash" Block_payload_hash.encoding))

let dal_content_encoding =
  let open Data_encoding in
  conv
    (fun {attestation} -> attestation)
    (fun attestation -> {attestation})
    (obj1 (req "attestation" Dal.Attestation.encoding))

let refactored_attestation_type_encoding =
  let open Data_encoding in
  conv
    (fun {shell; contents; unique_contents_list} ->
      (shell, contents, unique_contents_list))
    (fun (shell, contents, unique_contents_list) ->
      {shell; contents; unique_contents_list})
    (obj3
       (req "shell" Tezos_base.Operation.shell_header_encoding)
       (req "contents" refactored_consensus_content_encoding)
       (req
          "unique_contents_list"
          (list
             (dynamic_size
                (tup3
                   (option dal_content_encoding)
                   Slot.encoding
                   Signature.encoding)))))

let refactored_operations_encoding =
  let open Data_encoding in
  conv
    (fun {refactored_attestation; consensus_operations; other_operations} ->
      (refactored_attestation, consensus_operations, other_operations))
    (fun (refactored_attestation, consensus_operations, other_operations) ->
      {refactored_attestation; consensus_operations; other_operations})
    (obj3
       (req
          "refactored_attestation"
          (option refactored_attestation_type_encoding))
       (req
          "consensus_operations"
          (list (dynamic_size Tezos_base.Operation.encoding)))
       (req
          "other_operations"
          (list (list (dynamic_size Tezos_base.Operation.encoding)))))

let refactoring_encoding : Tezos_base.Operation.t trace trace Data_encoding.t =
  let open Data_encoding in
  conv
    (fun operations ->
      match operations with
      | [] -> assert false
      | consensus_operations :: other_operations ->
          let refactored_attestation, non_attestations =
            refactor_attestations
            @@ List.map to_packed_operation consensus_operations
          in
          let consensus_operations = List.map to_operation non_attestations in
          {refactored_attestation; consensus_operations; other_operations})
    (fun {refactored_attestation; consensus_operations; other_operations} ->
      match refactored_attestation with
      | None -> consensus_operations :: other_operations
      | Some refactored_attestation ->
          let attestations =
            expand_refactored_attestation refactored_attestation
          in
          (attestations @ consensus_operations) :: other_operations)
    refactored_operations_encoding
