(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Protocol.Alpha_context

type t =
  | Add_messages of {
      messages : string list;
      instant : Epoxy_tx.Types.P.tx option;
    }
  | Cement of {
      rollup : Sc_rollup.t;
      commitment : Sc_rollup.Commitment.Hash.t;
      new_state : Sc_rollup.State_hash.t option;
    }
  | Publish of {rollup : Sc_rollup.t; commitment : Sc_rollup.Commitment.t}
  | Refute of {
      rollup : Sc_rollup.t;
      opponent : Sc_rollup.Staker.t;
      refutation : Sc_rollup.Game.refutation;
    }
  | Timeout of {rollup : Sc_rollup.t; stakers : Sc_rollup.Game.Index.t}
  | Instant_update of {
      rollup : Sc_rollup.t;
      commitment : Sc_rollup.Commitment.t;
      proof : bytes;
    }

let encoding : t Data_encoding.t =
  let open Data_encoding in
  let case tag kind encoding proj inj =
    case
      ~title:kind
      (Tag tag)
      (merge_objs (obj1 (req "kind" (constant kind))) encoding)
      (fun o -> Option.map (fun p -> ((), p)) (proj o))
      (fun ((), p) -> inj p)
  in
  def "sc_rollup_node_l1_operation"
  @@ union
       [
         case
           0
           "add_messages"
           (obj2
              (req "message" (list (string' Hex)))
              (req "instant" (option Epoxy_tx.Types.P.tx_data_encoding)))
           (function
             | Add_messages {messages; instant} -> Some (messages, instant)
             | _ -> None)
           (fun (messages, instant) -> Add_messages {messages; instant});
         case
           1
           "cement"
           (obj3
              (req "rollup" Sc_rollup.Address.encoding)
              (req "commitment" Sc_rollup.Commitment.Hash.encoding)
              (req "new_state" @@ option Sc_rollup.State_hash.encoding))
           (function
             | Cement {rollup; commitment; new_state} ->
                 Some (rollup, commitment, new_state)
             | _ -> None)
           (fun (rollup, commitment, new_state) ->
             Cement {rollup; commitment; new_state});
         case
           2
           "publish"
           (obj2
              (req "rollup" Sc_rollup.Address.encoding)
              (req "commitment" Sc_rollup.Commitment.encoding))
           (function
             | Publish {rollup; commitment} -> Some (rollup, commitment)
             | _ -> None)
           (fun (rollup, commitment) -> Publish {rollup; commitment});
         case
           3
           "refute"
           (obj3
              (req "rollup" Sc_rollup.Address.encoding)
              (req "opponent" Sc_rollup.Staker.encoding)
              (req "refutation" Sc_rollup.Game.refutation_encoding))
           (function
             | Refute {rollup; opponent; refutation} ->
                 Some (rollup, opponent, refutation)
             | _ -> None)
           (fun (rollup, opponent, refutation) ->
             Refute {rollup; opponent; refutation});
         case
           4
           "timeout"
           (obj2
              (req "rollup" Sc_rollup.Address.encoding)
              (req "stakers" Sc_rollup.Game.Index.encoding))
           (function
             | Timeout {rollup; stakers} -> Some (rollup, stakers) | _ -> None)
           (fun (rollup, stakers) -> Timeout {rollup; stakers});
         case
           5
           "instant_update"
           (obj3
              (req "rollup" Sc_rollup.Address.encoding)
              (req "commitment" Sc_rollup.Commitment.encoding)
              (req "proof" Data_encoding.bytes))
           (function
             | Instant_update {rollup; commitment; proof} ->
                 Some (rollup, commitment, proof)
             | _ -> None)
           (fun (rollup, commitment, proof) ->
             Instant_update {rollup; commitment; proof});
       ]

let pp_opt pp =
  Format.pp_print_option ~none:(fun fmtr () -> Format.fprintf fmtr "None") pp

let pp ppf = function
  | Add_messages {messages; instant} ->
      Format.fprintf
        ppf
        "publishing %d messages%s to smart rollups' inbox"
        (List.length messages)
        Option.(
          value ~default:"" (map (Fun.const " and an instant message") instant))
  | Cement {rollup = _; commitment; new_state} ->
      Format.fprintf
        ppf
        "cementing commitment %a, with state %a"
        Sc_rollup.Commitment.Hash.pp
        commitment
        (pp_opt Sc_rollup.State_hash.pp)
        new_state
  | Publish {rollup = _; commitment = Sc_rollup.Commitment.{inbox_level; _}} ->
      Format.fprintf
        ppf
        "publish commitment for level %a"
        Raw_level.pp
        inbox_level
  | Refute {rollup = _; opponent; refutation = Start _} ->
      Format.fprintf
        ppf
        "start refutation game against %a"
        Signature.Public_key_hash.pp
        opponent
  | Refute
      {
        rollup = _;
        opponent;
        refutation = Move {step = Dissection (first :: _ as d); _};
      } ->
      let last = List.last first d in
      Format.fprintf
        ppf
        "dissection between ticks %a and %a (against %a)"
        Sc_rollup.Tick.pp
        first.tick
        Sc_rollup.Tick.pp
        last.tick
        Signature.Public_key_hash.pp
        opponent
  | Refute {rollup = _; opponent; refutation = Move {step = Dissection []; _}}
    ->
      Format.fprintf
        ppf
        "dissection (against %a)"
        Signature.Public_key_hash.pp
        opponent
  | Refute {rollup = _; opponent; refutation = Move {choice; step = Proof _}} ->
      Format.fprintf
        ppf
        "proof for tick %a  (against %a)"
        Sc_rollup.Tick.pp
        choice
        Signature.Public_key_hash.pp
        opponent
  | Timeout {rollup = _; stakers = _} -> Format.fprintf ppf "timeout"
  | Instant_update
      {rollup = _; commitment = Sc_rollup.Commitment.{inbox_level; _}; _} ->
      Format.fprintf ppf "instant update for level %a" Raw_level.pp inbox_level

let to_manager_operation : t -> packed_manager_operation = function
  | Add_messages {messages; instant} ->
      Manager (Sc_rollup_add_messages {messages; instant})
  | Cement {rollup; commitment; new_state} ->
      Manager (Sc_rollup_cement {rollup; commitment; new_state})
  | Publish {rollup; commitment} ->
      Manager (Sc_rollup_publish {rollup; commitment})
  | Refute {rollup; opponent; refutation} ->
      Manager (Sc_rollup_refute {rollup; opponent; refutation})
  | Timeout {rollup; stakers} -> Manager (Sc_rollup_timeout {rollup; stakers})
  | Instant_update {rollup; commitment; proof} ->
      Manager (Sc_rollup_instant_update {rollup; commitment; proof})

let of_manager_operation : type kind. kind manager_operation -> t option =
  function
  | Sc_rollup_add_messages {messages; instant} ->
      Some (Add_messages {messages; instant})
  | Sc_rollup_cement {rollup; commitment; new_state} ->
      Some (Cement {rollup; commitment; new_state})
  | Sc_rollup_publish {rollup; commitment} ->
      Some (Publish {rollup; commitment})
  | Sc_rollup_refute {rollup; opponent; refutation} ->
      Some (Refute {rollup; opponent; refutation})
  | Sc_rollup_timeout {rollup; stakers} -> Some (Timeout {rollup; stakers})
  | Sc_rollup_instant_update {rollup; commitment; proof} ->
      Some (Instant_update {rollup; commitment; proof})
  | _ -> None

let unique = function
  | Add_messages _ -> false
  | Cement _ | Publish _ | Refute _ | Timeout _ | Instant_update _ -> true
