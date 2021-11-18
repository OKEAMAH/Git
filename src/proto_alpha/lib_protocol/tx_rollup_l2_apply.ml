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
open Tx_rollup_l2_repr
open Tx_rollup_l2_context
open Tx_rollup_l2_operation

type error +=
  | Balance_too_low of {
      account : account;
      ticket_hash : Ticket_balance.key_hash;
      requested : Z.t;
      actual : Z.t;
    }

type error += Invalid_deposit

type error +=
  | Counter_mismatch of {account : account; requested : Z.t; actual : Z.t}

type error += Bad_aggregated_signature

let () =
  let open Data_encoding in
  (* Balance too low *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_balance_too_low"
    ~title:"Balance too low"
    ~description:
      "Cannot transfer the requested amount of tickets because the current \
       balance is too low."
    (obj4
       (req "account" account_encoding)
       (req "ticket_hash" Ticket_balance.key_hash_encoding)
       (req "requested" z)
       (req "actual" z))
    (function
      | Balance_too_low {account; ticket_hash; requested; actual} ->
          Some (account, ticket_hash, requested, actual)
      | _ -> None)
    (fun (account, ticket_hash, requested, actual) ->
      Balance_too_low {account; ticket_hash; requested; actual}) ;
  (* Invalid deposit *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_invalid_deposit"
    ~title:"Invalid deposit"
    ~description:"A deposit with erroneous arguments has been issued."
    empty
    (function Invalid_deposit -> Some () | _ -> None)
    (fun () -> Invalid_deposit) ;
  (* Counter mismatch *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_counter_mismatch"
    ~title:"Conuter mismatch"
    ~description:
      "A transaction rollup has been submitted with an incorrect counter."
    (obj3 (req "account" account_encoding) (req "requested" z) (req "actual" z))
    (function
      | Counter_mismatch {account; requested; actual} ->
          Some (account, requested, actual)
      | _ -> None)
    (fun (account, requested, actual) ->
      Counter_mismatch {account; requested; actual}) ;
  (* Bad aggregated signature *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_bad_aggregated_signature"
    ~title:"Bad aggregated signature"
    ~description:
      "An incorrect aggregated signature has been provided with a transactions \
       batch."
    empty
    (function Bad_aggregated_signature -> Some () | _ -> None)
    (fun () -> Bad_aggregated_signature)

type transaction_status = Success | Failure of {index : int; reason : error}

module Account_set = Set.Make (Account)

module Make (Context : CONTEXT) = struct
  open Context

  let apply_transfer :
      t -> account -> account -> Ticket_balance.key_hash -> Z.t -> t m =
   fun ctxt source destination ticket_hash amount ->
    let open Syntax in
    let* (src_balance, ctxt) = Ticket_ledger.get ctxt ticket_hash source in
    let remainder = Z.sub src_balance amount in
    let* () =
      fail_unless Compare.Z.(remainder >= Z.of_int 0)
      @@ Balance_too_low
           {
             account = source;
             ticket_hash;
             requested = amount;
             actual = src_balance;
           }
    in
    let* (dest_balance, ctxt) =
      Ticket_ledger.get ctxt ticket_hash destination
    in
    let* ctxt = Ticket_ledger.set ctxt ticket_hash source remainder in
    let new_balance = Z.add dest_balance amount in
    let* ctxt = Ticket_ledger.set ctxt ticket_hash destination new_balance in
    return ctxt

  let apply_operation : t -> Z.t -> operation -> t m =
   fun ctxt counter op ->
    let open Syntax in
    let* () =
      fail_unless Compare.Z.(counter = op.counter)
      @@ Counter_mismatch
           {account = op.signer; actual = counter; requested = op.counter}
    in
    match op.content with
    | Transfer {destination; ticket_hash; amount} ->
        apply_transfer ctxt op.signer destination ticket_hash amount

  let check_signatures : t -> transaction list -> signature -> (bool * t) m =
   fun ctxt contents signatures ->
    let to_bytes contents =
      Data_encoding.Binary.to_bytes_exn transaction_encoding contents
    in

    let transmitted =
      List.concat_map
        (fun transaction ->
          let buf = to_bytes transaction in
          let seen = Account_set.empty in

          let f (acc, seen) op =
            let signer = op.signer in
            let keep = not @@ Account_set.mem signer seen in
            if keep then
              let acc = Some (signer, buf) :: acc in
              let seen = Account_set.add signer seen in
              (acc, seen)
            else (None :: acc, seen)
          in

          let (unique_signatures_rev, _) =
            List.fold_left f ([], seen) transaction
          in
          (* Note that unique_signatures_rev is reversed, but we don't care about the order so
             we just leave it.*)
          List.filter_map (fun t -> t) unique_signatures_rev)
        contents
    in

    bls_verify ctxt transmitted signatures

  let apply_transaction : t -> transaction -> (transaction_status * t) m =
   fun initial_ctxt ops ->
    let open Syntax in
    let rec apply ctxt index = function
      | op :: rst ->
          let* (counter, ctxt) = Counter.get ctxt op.signer in
          let* (status, ctxt) =
            catch
              (apply_operation ctxt counter op)
              (fun ctxt -> apply ctxt (index + 1) rst)
              (function
                | Not_enough_gas -> fail Not_enough_gas
                | error ->
                    let ctxt =
                      match remaining_gas ctxt with
                      | Some remaining_gas ->
                          set_gas_limit initial_ctxt remaining_gas
                      | None -> initial_ctxt
                    in
                    return (Failure {index; reason = error}, ctxt))
          in
          return (status, ctxt)
      | [] -> return (Success, ctxt)
    in

    let* (status, ctxt) = apply initial_ctxt 0 ops in
    match status with
    | Failure {reason = Counter_mismatch _; _} -> return (status, ctxt)
    | _ ->
        (* We know the operations’ counters are correct, so we can use
           them to increment the counter of the signer. We avoid to
           due unnecessary writes by remembering which public keys we
           have already treated. *)
        let* (ctxt, _) =
          list_fold_left_m
            (fun (ctxt, acc) op ->
              if Account_set.mem op.signer acc then return (ctxt, acc)
              else
                let* ctxt = Counter.set ctxt op.signer (Z.succ op.counter) in
                return (ctxt, Account_set.add op.signer acc))
            (ctxt, Account_set.empty)
            ops
        in
        return (status, ctxt)

  let apply_transactions_batch :
      t ->
      transactions_batch ->
      ((transaction * transaction_status) list * Gas.Arith.fp * t) m =
   fun ctxt {contents; aggregated_signatures; allocated_gas} ->
    let open Syntax in
    let* (is_correct_signature, ctxt) =
      check_signatures ctxt contents aggregated_signatures
    in
    let* () = fail_unless is_correct_signature Bad_aggregated_signature in

    let (ctxt as reference_ctxt) = set_gas_limit ctxt allocated_gas in
    let* (ctxt, rev_status) =
      list_fold_left_m
        (fun (ctxt, rev_status) ops ->
          let* (status, ctxt) = apply_transaction ctxt ops in
          return (ctxt, (ops, status) :: rev_status))
        (ctxt, [])
        contents
    in
    let consumed_gas =
      Option.value
        (consumed_gas ctxt ~since:reference_ctxt)
        ~default:Gas.Arith.zero
    in
    let ctxt = unset_gas_limit ctxt in
    return (List.rev rev_status, consumed_gas, ctxt)

  let apply_deposit : t -> deposit -> t m =
   fun ctxt deposit ->
    let open Syntax in
    (* This should never happen in the L1 is correct *)
    let* () = fail_unless Compare.Z.(Z.zero < deposit.amount) Invalid_deposit in
    let* (current, ctxt) =
      Ticket_ledger.get ctxt deposit.ticket_hash deposit.destination
    in
    Ticket_ledger.set
      ctxt
      deposit.ticket_hash
      deposit.destination
      (Z.add current deposit.amount)

  module Internal_for_tests = struct
    let apply_transaction = apply_transaction
  end
end
