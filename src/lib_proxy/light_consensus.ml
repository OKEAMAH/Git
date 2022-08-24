(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

module Store = Local_context
module Proof = Tezos_context_sigs.Context.Proof_types

module Storelike = struct
  type key = string list

  type t = Local_context.tree

  let mem = Local_context.Tree.mem

  let find_tree = Local_context.Tree.find_tree
end

module Get_data = Tezos_context_sigs.Context.With_get_data ((
  Storelike : Tezos_context_sigs.Context.Storelike))

type input = {
  printer : Tezos_client_base.Client_context.printer;
  min_agreement : float;
  chain : Tezos_shell_services.Block_services.chain;
  block : Tezos_shell_services.Block_services.block;
  key : string list;
  mproof : Proof.tree Proof.t;
  tree : Store.tree;
}

let key_to_string = String.concat ";"

let min_agreeing_endpoints min_agreement nb_endpoints =
  min_agreement *. float_of_int nb_endpoints |> Float.ceil |> int_of_float

module Make (Light_proto : Light_proto.PROTO_RPCS) = struct
  type validation_result = Valid | Invalid of string

  let validate uri key (store_tree : Storelike.t)
      (data_proof : Proof.tree Proof.t)
      (incoming_mproof : Proof.tree Proof.t option tzresult) =
    (* FIXME: can't use irmin [verify_proof] yet *)
    (* Store.verify_tree_proof  *)
    match incoming_mproof with
    | Error trace ->
        Lwt.return
        @@ Invalid
             (Format.asprintf
                "Light mode: endpoint %s failed to provide merkle tree for key \
                 %s. Error is: %a"
                (Uri.to_string uri)
                (key_to_string key)
                pp_print_trace
                trace)
    | Ok None ->
        Lwt.return
        @@ Invalid
             (Format.asprintf
                "Light mode: endpoint %s doesn't contain key %s"
                (Uri.to_string uri)
                (key_to_string key))
    | Ok (Some mproof) -> (
        let open Lwt_syntax in
        (* FIXME does verify_tree_proof take care of whatever we were using this for...? *)
        let _x = data_proof in
        let* res =
          Store.verify_tree_proof
            mproof
            (Get_data.get_data Proof.Raw_context key)
        in
        match res with
        | Ok (_, tree) ->
            let* found_tree = Store.Tree.find_tree store_tree key in
            return
              (match found_tree with
              | Some store_tree ->
                  if Store.Tree.equal tree store_tree then Valid
                  else Invalid "Light mode: trees were not equal"
              | None -> Invalid "Light mode: no tree found")
        | Error _ ->
            return
              (Invalid
                 "Light mode: proof could not be verified to derive a tree"))

  let count_valids validations =
    let count_valid = function Valid -> 1 | Invalid _ -> 0 in
    List.fold_left
      (fun sum validation -> sum + count_valid validation)
      0
      validations

  let warn_invalids (printer : Tezos_client_base.Client_context.printer)
      validations =
    Lwt_list.iter_s
      (fun v ->
        match v with
        | Valid -> Lwt.return_unit
        | Invalid errmsg -> printer#warning "%s\n" errmsg)
      validations

  let consensus
      ({printer; min_agreement; chain; block; key; tree; mproof} : input)
      validating_endpoints =
    let open Lwt_syntax in
    (* + 1 because there's the endpoint that provides data, that doesn't
       validate *)
    let nb_endpoints = List.length validating_endpoints + 1 in
    let min_agreeing_endpoints =
      min_agreeing_endpoints min_agreement nb_endpoints
    in
    assert (min_agreeing_endpoints <= nb_endpoints) ;
    (* When checking that shapes agree, we must ignore the key where the
       data is, because the validating endpoints return trees that do NOT
       contain this key. *)
    let check_merkle_tree_with_endpoint (uri, rpc_context) =
      let* other_mproof =
        Light_proto.merkle_tree_v2
          ({rpc_context; chain; block; mode = Client}
            : Proxy.proxy_getter_input)
          key
          Proof.Hole
      in
      validate uri key tree mproof other_mproof
    in
    let* validations =
      Lwt_list.map_p check_merkle_tree_with_endpoint validating_endpoints
    in
    (* +1 because the endpoint that provided data obviously agrees *)
    let nb_agreements = count_valids validations + 1 in
    let agreement_reached = nb_agreements >= min_agreeing_endpoints in
    let* () = warn_invalids printer validations in
    let* () =
      if agreement_reached then Lwt.return_unit
      else
        printer#warning
          "Light mode: min_agreement=%f, %d endpoints, %s%d agreeing \
           endpoints, whereas %d (%d*%f rounded up) is the minimum; so about \
           to fail."
          min_agreement
          nb_endpoints
          (if nb_agreements > 0 then "only " else "")
          nb_agreements
          min_agreeing_endpoints
          nb_endpoints
          min_agreement
    in
    return agreement_reached
end
