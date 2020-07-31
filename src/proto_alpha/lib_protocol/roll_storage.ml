(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2019 Metastate AG <contact@metastate.ch>                    *)
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

open Misc

type error +=
  | (* `Permanent *)
      Consume_roll_change
  | (* `Permanent *)
      No_roll_for_baker
  | (* `Permanent *)
      No_roll_snapshot_for_cycle of Cycle_repr.t

let () =
  let open Data_encoding in
  (* Consume roll change *)
  register_error_kind
    `Permanent
    ~id:"contract.manager.consume_roll_change"
    ~title:"Consume roll change"
    ~description:"Change is not enough to consume a roll."
    ~pp:(fun ppf () ->
      Format.fprintf ppf "Not enough change to consume a roll.")
    empty
    (function Consume_roll_change -> Some () | _ -> None)
    (fun () -> Consume_roll_change) ;
  (* No roll for baker *)
  register_error_kind
    `Permanent
    ~id:"contract.manager.no_roll_for_baker"
    ~title:"No roll for baker"
    ~description:"Baker has no roll."
    ~pp:(fun ppf () -> Format.fprintf ppf "Baker has no roll.")
    empty
    (function No_roll_for_baker -> Some () | _ -> None)
    (fun () -> No_roll_for_baker) ;
  (* No roll snapshot for cycle *)
  register_error_kind
    `Permanent
    ~id:"contract.manager.no_roll_snapshot_for_cycle"
    ~title:"No roll snapshot for cycle"
    ~description:
      "A snapshot of the rolls distribution does not exist for this cycle."
    ~pp:(fun ppf c ->
      Format.fprintf
        ppf
        "A snapshot of the rolls distribution does not exist for cycle %a"
        Cycle_repr.pp
        c)
    (obj1 (req "cycle" Cycle_repr.encoding))
    (function No_roll_snapshot_for_cycle c -> Some c | _ -> None)
    (fun c -> No_roll_snapshot_for_cycle c)

let get_contract_delegate ctxt contract =
  (* if the contract is a baker, treat it as if it was self-delegated *)
  match Contract_repr.is_baker contract with
  | Some baker ->
      return_some baker
  | None ->
      Storage.Contract.Delegate.get_option ctxt contract

let clear_cycle ctxt cycle =
  Storage.Roll.Snapshot_for_cycle.get ctxt cycle
  >>=? fun index ->
  Storage.Roll.Snapshot_for_cycle.delete ctxt cycle
  >>=? fun ctxt ->
  Storage.Roll.Last_for_snapshot.delete (ctxt, cycle) index
  >>=? fun ctxt ->
  Storage.Roll.Owner.delete_snapshot ctxt (cycle, index) >|= ok

let fold ctxt ~f init =
  Storage.Roll.Next.get ctxt
  >>=? fun last ->
  let rec loop ctxt roll acc =
    if Roll_repr.(roll = last) then return acc
    else
      Storage.Roll.Owner.get_option ctxt roll
      >>=? function
      | None ->
          loop ctxt (Roll_repr.succ roll) acc
      | Some baker ->
          f roll baker acc >>=? fun acc -> loop ctxt (Roll_repr.succ roll) acc
  in
  loop ctxt Roll_repr.first init

let snapshot_rolls_for_cycle ctxt cycle =
  Storage.Roll.Snapshot_for_cycle.get ctxt cycle
  >>=? fun index ->
  Storage.Roll.Snapshot_for_cycle.set ctxt cycle (index + 1)
  >>=? fun ctxt ->
  Storage.Roll.Owner.snapshot ctxt (cycle, index)
  >>=? fun ctxt ->
  Storage.Roll.Next.get ctxt
  >>=? fun last -> Storage.Roll.Last_for_snapshot.init (ctxt, cycle) index last

(* NOTE: Deletes all snapshots for a given cycle that are not randomly selected. *)
let freeze_rolls_for_cycle ctxt cycle =
  Storage.Roll.Snapshot_for_cycle.get ctxt cycle
  >>=? fun max_index ->
  Storage.Seed.For_cycle.get ctxt cycle
  >>=? fun seed ->
  let rd = Seed_repr.initialize_new seed [Bytes.of_string "roll_snapshot"] in
  let seq = Seed_repr.sequence rd 0l in
  let selected_index =
    Seed_repr.take_int32 seq (Int32.of_int max_index) |> fst |> Int32.to_int
  in
  Storage.Roll.Snapshot_for_cycle.set ctxt cycle selected_index
  >>=? fun ctxt ->
  fold_left_s
    (fun ctxt index ->
      if Compare.Int.(index = selected_index) then return ctxt
      else
        Storage.Roll.Owner.delete_snapshot ctxt (cycle, index)
        >>= fun ctxt ->
        Storage.Roll.Last_for_snapshot.delete (ctxt, cycle) index)
    ctxt
    Misc.(0 --> (max_index - 1))

(* Roll selection *)
module Random = struct
  let int32_to_bytes i =
    let b = Bytes.create 4 in
    TzEndian.set_int32 b 0 i ; b

  let level_random seed use level =
    let position = level.Level_repr.cycle_position in
    Seed_repr.initialize_new
      seed
      [Bytes.of_string ("level " ^ use ^ ":"); int32_to_bytes position]

  let owner c kind level offset =
    let cycle = level.Level_repr.cycle in
    Seed_storage.for_cycle c cycle
    >>=? fun random_seed ->
    let rd = level_random random_seed kind level in
    let sequence = Seed_repr.sequence rd (Int32.of_int offset) in
    Storage.Roll.Snapshot_for_cycle.get c cycle
    >>=? fun index ->
    Storage.Roll.Last_for_snapshot.get (c, cycle) index
    >>=? fun bound ->
    let rec loop sequence =
      let (roll, sequence) = Roll_repr.random sequence ~bound in
      Storage.Roll.Owner.Snapshot.get_option c ((cycle, index), roll)
      >>=? function None -> loop sequence | Some baker -> return baker
    in
    Storage.Roll.Owner.snapshot_exists c (cycle, index)
    >>= fun snapshot_exists ->
    error_unless snapshot_exists (No_roll_snapshot_for_cycle cycle)
    >>?= fun () -> loop sequence
end

let baking_rights_owner c level ~priority =
  Random.owner c "baking" level priority

let endorsement_rights_owner c level ~slot =
  Random.owner c "endorsement" level slot

let traverse_rolls ctxt head =
  let rec loop acc roll =
    Storage.Roll.Successor.get_option ctxt roll
    >>=? function
    | None -> return (List.rev acc) | Some next -> loop (next :: acc) next
  in
  loop [head] head

let get_rolls ctxt baker =
  Storage.Roll.Baker_roll_list.get_option ctxt baker
  >>=? function
  | None -> return_nil | Some head_roll -> traverse_rolls ctxt head_roll

let count_rolls ctxt baker =
  Storage.Roll.Baker_roll_list.get_option ctxt baker
  >>=? function
  | None ->
      return 0
  | Some head_roll ->
      let rec loop acc roll =
        Storage.Roll.Successor.get_option ctxt roll
        >>=? function None -> return acc | Some next -> loop (succ acc) next
      in
      loop 1 head_roll

let get_change ctxt baker =
  Storage.Roll.Baker_change.get_option ctxt baker
  >|=? function None -> Tez_repr.zero | Some change -> change

module Delegate = struct
  let fresh_roll ctxt =
    Storage.Roll.Next.get ctxt
    >>=? fun roll ->
    Storage.Roll.Next.set ctxt (Roll_repr.succ roll)
    >|=? fun ctxt -> (roll, ctxt)

  let get_limbo_roll ctxt =
    Storage.Roll.Limbo.get_option ctxt
    >>=? function
    | None ->
        fresh_roll ctxt
        >>=? fun (roll, ctxt) ->
        Storage.Roll.Limbo.init ctxt roll >|=? fun ctxt -> (roll, ctxt)
    | Some roll ->
        return (roll, ctxt)

  let consume_roll_change ctxt baker =
    let tokens_per_roll = Constants_storage.tokens_per_roll ctxt in
    Storage.Roll.Baker_change.get ctxt baker
    >>=? fun change ->
    record_trace Consume_roll_change Tez_repr.(change -? tokens_per_roll)
    >>?= fun new_change -> Storage.Roll.Baker_change.set ctxt baker new_change

  let recover_roll_change ctxt baker =
    let tokens_per_roll = Constants_storage.tokens_per_roll ctxt in
    Storage.Roll.Baker_change.get ctxt baker
    >>=? fun change ->
    Tez_repr.(change +? tokens_per_roll)
    >>?= fun new_change -> Storage.Roll.Baker_change.set ctxt baker new_change

  let pop_roll_from_baker ctxt baker =
    recover_roll_change ctxt baker
    >>=? fun ctxt ->
    (* beginning:
       baker : roll -> successor_roll -> ...
       limbo : limbo_head -> ...
    *)
    Storage.Roll.Limbo.get_option ctxt
    >>=? fun limbo_head ->
    Storage.Roll.Baker_roll_list.get_option ctxt baker
    >>=? function
    | None ->
        fail No_roll_for_baker
    | Some roll ->
        Storage.Roll.Owner.delete ctxt roll
        >>=? fun ctxt ->
        Storage.Roll.Successor.get_option ctxt roll
        >>=? fun successor_roll ->
        Storage.Roll.Baker_roll_list.set_option ctxt baker successor_roll
        >>= fun ctxt ->
        (* baker : successor_roll -> ...
           roll ------^
           limbo : limbo_head -> ... *)
        Storage.Roll.Successor.set_option ctxt roll limbo_head
        >>= fun ctxt ->
        (* baker : successor_roll -> ...
           roll ------v
           limbo : limbo_head -> ... *)
        Storage.Roll.Limbo.init_set ctxt roll
        >|= fun ctxt ->
        (* baker : successor_roll -> ...
           limbo : roll -> limbo_head -> ... *)
        ok (roll, ctxt)

  let create_roll_in_baker ctxt baker =
    consume_roll_change ctxt baker
    >>=? fun ctxt ->
    (* beginning:
       baker : baker_head -> ...
       limbo : roll -> limbo_successor -> ...
    *)
    Storage.Roll.Baker_roll_list.get_option ctxt baker
    >>=? fun baker_head ->
    get_limbo_roll ctxt
    >>=? fun (roll, ctxt) ->
    Storage.Roll.Owner.init ctxt roll baker
    >>=? fun ctxt ->
    Storage.Roll.Successor.get_option ctxt roll
    >>=? fun limbo_successor ->
    Storage.Roll.Limbo.set_option ctxt limbo_successor
    >>= fun ctxt ->
    (* baker : baker_head -> ...
       roll ------v
       limbo : limbo_successor -> ... *)
    Storage.Roll.Successor.set_option ctxt roll baker_head
    >>= fun ctxt ->
    (* baker : baker_head -> ...
       roll ------^
       limbo : limbo_successor -> ... *)
    Storage.Roll.Baker_roll_list.init_set ctxt baker roll
    (* baker : roll -> baker_head -> ...
       limbo : limbo_successor -> ... *)
    >|= ok

  let ensure_inited ctxt baker =
    Storage.Roll.Baker_change.mem ctxt baker
    >>= function
    | true ->
        return ctxt
    | false ->
        Storage.Roll.Baker_change.init ctxt baker Tez_repr.zero

  let is_inactive ctxt baker =
    Storage.Baker.Inactive.mem ctxt baker
    >>= fun inactive ->
    if inactive then return inactive
    else
      Storage.Baker.Deactivation.get_option ctxt baker
      >|=? function
      | Some last_active_cycle ->
          let {Level_repr.cycle = current_cycle} =
            Raw_context.current_level ctxt
          in
          Cycle_repr.(last_active_cycle < current_cycle)
      | None ->
          (* This case is only when called from `set_active`, when creating
             a contract. *)
          false

  let add_amount ctxt baker amount =
    ensure_inited ctxt baker
    >>=? fun ctxt ->
    let tokens_per_roll = Constants_storage.tokens_per_roll ctxt in
    Storage.Roll.Baker_change.get ctxt baker
    >>=? fun change ->
    Tez_repr.(amount +? change)
    >>?= fun change ->
    Storage.Roll.Baker_change.set ctxt baker change
    >>=? fun ctxt ->
    let rec loop ctxt change =
      if Tez_repr.(change < tokens_per_roll) then return ctxt
      else
        Tez_repr.(change -? tokens_per_roll)
        >>?= fun change ->
        create_roll_in_baker ctxt baker >>=? fun ctxt -> loop ctxt change
    in
    is_inactive ctxt baker
    >>=? fun inactive ->
    if inactive then return ctxt
    else
      loop ctxt change
      >>=? fun ctxt ->
      Storage.Roll.Baker_roll_list.get_option ctxt baker
      >>=? fun rolls ->
      match rolls with
      | None ->
          return ctxt
      | Some _ ->
          Storage.Baker.Active_with_rolls.add ctxt baker >|= ok

  let remove_amount ctxt baker amount =
    let tokens_per_roll = Constants_storage.tokens_per_roll ctxt in
    let rec loop ctxt change =
      if Tez_repr.(amount <= change) then return (ctxt, change)
      else
        pop_roll_from_baker ctxt baker
        >>=? fun (_, ctxt) ->
        Tez_repr.(change +? tokens_per_roll)
        >>?= fun change -> loop ctxt change
    in
    Storage.Roll.Baker_change.get ctxt baker
    >>=? fun change ->
    is_inactive ctxt baker
    >>=? fun inactive ->
    ( if inactive then return (ctxt, change)
    else
      loop ctxt change
      >>=? fun (ctxt, change) ->
      Storage.Roll.Baker_roll_list.get_option ctxt baker
      >>=? fun rolls ->
      match rolls with
      | None ->
          Storage.Baker.Active_with_rolls.del ctxt baker
          >|= fun ctxt -> ok (ctxt, change)
      | Some _ ->
          return (ctxt, change) )
    >>=? fun (ctxt, change) ->
    Tez_repr.(change -? amount)
    >>?= fun change -> Storage.Roll.Baker_change.set ctxt baker change

  let set_inactive ctxt baker =
    ensure_inited ctxt baker
    >>=? fun ctxt ->
    let tokens_per_roll = Constants_storage.tokens_per_roll ctxt in
    Storage.Roll.Baker_change.get ctxt baker
    >>=? fun change ->
    Storage.Baker.Inactive.add ctxt baker
    >>= fun ctxt ->
    Storage.Baker.Active_with_rolls.del ctxt baker
    >>= fun ctxt ->
    let rec loop ctxt change =
      Storage.Roll.Baker_roll_list.get_option ctxt baker
      >>=? function
      | None ->
          return (ctxt, change)
      | Some _roll ->
          pop_roll_from_baker ctxt baker
          >>=? fun (_, ctxt) ->
          Tez_repr.(change +? tokens_per_roll)
          >>?= fun change -> loop ctxt change
    in
    loop ctxt change
    >>=? fun (ctxt, change) -> Storage.Roll.Baker_change.set ctxt baker change

  let set_active ctxt baker =
    is_inactive ctxt baker
    >>=? fun inactive ->
    let current_cycle = (Raw_context.current_level ctxt).cycle in
    let preserved_cycles = Constants_storage.preserved_cycles ctxt in
    (* When the baker is new or inactive, she will become active in
       `1+preserved_cycles`, and we allow `preserved_cycles` for the
       baker to start baking. When the baker is active, we only
       give her at least `preserved_cycles` after the current cycle
       before to be deactivated.  *)
    Storage.Baker.Deactivation.get_option ctxt baker
    >>=? fun current_expiration ->
    let expiration =
      match current_expiration with
      | None ->
          Cycle_repr.add current_cycle (1 + (2 * preserved_cycles))
      | Some current_expiration ->
          let delay =
            if inactive then 1 + (2 * preserved_cycles)
            else 1 + preserved_cycles
          in
          let updated = Cycle_repr.add current_cycle delay in
          Cycle_repr.max current_expiration updated
    in
    Storage.Baker.Deactivation.init_set ctxt baker expiration
    >>= fun ctxt ->
    if not inactive then return ctxt
    else
      ensure_inited ctxt baker
      >>=? fun ctxt ->
      let tokens_per_roll = Constants_storage.tokens_per_roll ctxt in
      Storage.Roll.Baker_change.get ctxt baker
      >>=? fun change ->
      Storage.Baker.Inactive.del ctxt baker
      >>= fun ctxt ->
      let rec loop ctxt change =
        if Tez_repr.(change < tokens_per_roll) then return ctxt
        else
          Tez_repr.(change -? tokens_per_roll)
          >>?= fun change ->
          create_roll_in_baker ctxt baker >>=? fun ctxt -> loop ctxt change
      in
      loop ctxt change
      >>=? fun ctxt ->
      Storage.Roll.Baker_roll_list.get_option ctxt baker
      >>=? fun rolls ->
      match rolls with
      | None ->
          return ctxt
      | Some _ ->
          Storage.Baker.Active_with_rolls.add ctxt baker >|= ok
end

module Contract = struct
  let add_amount c contract amount =
    get_contract_delegate c contract
    >>=? function
    | None -> return c | Some delegate -> Delegate.add_amount c delegate amount

  let remove_amount c contract amount =
    get_contract_delegate c contract
    >>=? function
    | None ->
        return c
    | Some delegate ->
        Delegate.remove_amount c delegate amount
end

let init ctxt = Storage.Roll.Next.init ctxt Roll_repr.first

let init_first_cycles ctxt =
  let preserved = Constants_storage.preserved_cycles ctxt in
  (* Precompute rolls for cycle (0 --> preserved_cycles) *)
  fold_left_s
    (fun ctxt c ->
      let cycle = Cycle_repr.of_int32_exn (Int32.of_int c) in
      Storage.Roll.Snapshot_for_cycle.init ctxt cycle 0
      >>=? fun ctxt ->
      snapshot_rolls_for_cycle ctxt cycle
      >>=? fun ctxt -> freeze_rolls_for_cycle ctxt cycle)
    ctxt
    (0 --> preserved)
  >>=? fun ctxt ->
  let cycle = Cycle_repr.of_int32_exn (Int32.of_int (preserved + 1)) in
  (* Precomputed a snapshot for cycle (preserved_cycles + 1) *)
  Storage.Roll.Snapshot_for_cycle.init ctxt cycle 0
  >>=? fun ctxt ->
  snapshot_rolls_for_cycle ctxt cycle
  >>=? fun ctxt ->
  (* Prepare storage for storing snapshots for cycle (preserved_cycles+2) *)
  let cycle = Cycle_repr.of_int32_exn (Int32.of_int (preserved + 2)) in
  Storage.Roll.Snapshot_for_cycle.init ctxt cycle 0

let snapshot_rolls ctxt =
  let current_level = Raw_context.current_level ctxt in
  let preserved = Constants_storage.preserved_cycles ctxt in
  let cycle = Cycle_repr.add current_level.cycle (preserved + 2) in
  snapshot_rolls_for_cycle ctxt cycle

let cycle_end ctxt last_cycle =
  let preserved = Constants_storage.preserved_cycles ctxt in
  ( match Cycle_repr.sub last_cycle preserved with
  | None ->
      return ctxt
  | Some cleared_cycle ->
      clear_cycle ctxt cleared_cycle )
  >>=? fun ctxt ->
  let frozen_roll_cycle = Cycle_repr.add last_cycle (preserved + 1) in
  freeze_rolls_for_cycle ctxt frozen_roll_cycle
  >>=? fun ctxt ->
  Storage.Roll.Snapshot_for_cycle.init
    ctxt
    (Cycle_repr.succ (Cycle_repr.succ frozen_roll_cycle))
    0

let update_tokens_per_roll ctxt new_tokens_per_roll =
  let constants = Raw_context.constants ctxt in
  let old_tokens_per_roll = constants.tokens_per_roll in
  Raw_context.patch_constants ctxt (fun constants ->
      {constants with Constants_repr.tokens_per_roll = new_tokens_per_roll})
  >>= fun ctxt ->
  let decrease = Tez_repr.(new_tokens_per_roll < old_tokens_per_roll) in
  ( if decrease then Tez_repr.(old_tokens_per_roll -? new_tokens_per_roll)
  else Tez_repr.(new_tokens_per_roll -? old_tokens_per_roll) )
  >>?= fun abs_diff ->
  Storage.Baker.Registered.fold ctxt (Ok ctxt) (fun pkh ctxt_opt ->
      ctxt_opt
      >>?= fun ctxt ->
      count_rolls ctxt pkh
      >>=? fun rolls ->
      Tez_repr.(abs_diff *? Int64.of_int rolls)
      >>?= fun amount ->
      if decrease then Delegate.add_amount ctxt pkh amount
      else Delegate.remove_amount ctxt pkh amount)
