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
open Tx_rollup_l2_context
open Tx_rollup_l2_operation

type error +=
  | Balance_too_low of {
      account : Tx_rollup_l2_address.t;
      ticket_hash : Ticket_hash.t;
      requested : int64;
      actual : int64;
    }

type error +=
  | Balance_overflow of {
      account : Tx_rollup_l2_address.t;
      ticket_hash : Ticket_hash.t;
    }

type error += Invalid_deposit

type error += Invalid_transfer

type error +=
  | Counter_mismatch of {
      account : Tx_rollup_l2_address.t;
      requested : int64;
      actual : int64;
    }

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
       (req "account" Tx_rollup_l2_address.encoding)
       (req "ticket_hash" Ticket_hash.encoding)
       (req "requested" int64)
       (req "actual" int64))
    (function
      | Balance_too_low {account; ticket_hash; requested; actual} ->
          Some (account, ticket_hash, requested, actual)
      | _ -> None)
    (fun (account, ticket_hash, requested, actual) ->
      Balance_too_low {account; ticket_hash; requested; actual}) ;
  (* Balance overflow *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_balance_overflow"
    ~title:"Balance overflow"
    ~description:
      "Cannot transfer the requested amount of tickets because the current \
       balance would overflow."
    (obj2
       (req "account" Tx_rollup_l2_address.encoding)
       (req "ticket_hash" Ticket_hash.encoding))
    (function
      | Balance_overflow {account; ticket_hash} -> Some (account, ticket_hash)
      | _ -> None)
    (fun (account, ticket_hash) -> Balance_overflow {account; ticket_hash}) ;
  (* Invalid deposit *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_invalid_deposit"
    ~title:"Invalid deposit"
    ~description:"A deposit with erroneous arguments has been issued."
    empty
    (function Invalid_deposit -> Some () | _ -> None)
    (fun () -> Invalid_deposit) ;
  (* Invalid transfer *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_invalid_transfer"
    ~title:"Invalid transfer"
    ~description:"A transfer with erroneous arguments has been issued."
    empty
    (function Invalid_transfer -> Some () | _ -> None)
    (fun () -> Invalid_transfer) ;
  (* Counter mismatch *)
  register_error_kind
    `Permanent
    ~id:"tx_rollup_counter_mismatch"
    ~title:"Conuter mismatch"
    ~description:
      "A transaction rollup has been submitted with an incorrect counter."
    (obj3
       (req "account" Tx_rollup_l2_address.encoding)
       (req "requested" int64)
       (req "actual" int64))
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

module Account_set = Set.Make (Tx_rollup_l2_address)

module Make (Context : CONTEXT) = struct
  open Context

  let safe_balance_sub :
      t -> Tx_rollup_l2_address.t -> Ticket_hash.t -> int64 -> t m =
   fun ctxt source ticket_hash amount ->
    let open Syntax in
    let* src_balance = Ticket_ledger.get ctxt ticket_hash source in
    let remainder = Int64.sub src_balance amount in
    let* () =
      fail_unless Compare.Int64.(0L <= remainder)
      @@ Balance_too_low
           {
             account = source;
             ticket_hash;
             requested = amount;
             actual = src_balance;
           }
    in
    Ticket_ledger.set ctxt ticket_hash source remainder

  let safe_balance_add :
      t -> Tx_rollup_l2_address.t -> Ticket_hash.t -> int64 -> t m =
   fun ctxt destination ticket_hash amount ->
    let open Syntax in
    let* balance = Ticket_ledger.get ctxt ticket_hash destination in
    let new_balance = Int64.add balance amount in
    let* () =
      fail_unless Compare.Int64.(balance <= new_balance)
      @@ Balance_overflow {account = destination; ticket_hash}
    in
    Ticket_ledger.set ctxt ticket_hash destination new_balance

  let apply_transfer :
      t ->
      Tx_rollup_l2_address.t ->
      Tx_rollup_l2_address.t ->
      Ticket_hash.t ->
      int64 ->
      t m =
   fun ctxt source destination ticket_hash amount ->
    let open Syntax in
    let* () = fail_unless Compare.Int64.(0L < amount) Invalid_transfer in
    let* ctxt = safe_balance_sub ctxt source ticket_hash amount in
    let* ctxt = safe_balance_add ctxt destination ticket_hash amount in
    return ctxt

  let apply_operation : t -> int64 -> operation -> t m =
   fun ctxt counter op ->
    let open Syntax in
    let* () =
      fail_unless Compare.Int64.(counter = op.counter)
      @@ Counter_mismatch
           {account = op.signer; actual = counter; requested = op.counter}
    in
    match op.content with
    | Transfer {destination; ticket_hash; amount} ->
        apply_transfer ctxt op.signer destination ticket_hash amount

  let check_signatures :
      transaction list -> Tx_rollup_l2_operation.signature -> bool m =
   fun contents signatures ->
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
          (* Note that unique_signatures_rev is reversed, but we don't
             care about the order so we just leave it.*)
          List.filter_map (fun t -> t) unique_signatures_rev)
        contents
    in

    bls_verify transmitted signatures

  let apply_transaction : t -> transaction -> (transaction_status * t) m =
   fun initial_ctxt ops ->
    let open Syntax in
    let rec apply ctxt index = function
      | op :: rst ->
          let* counter = Counter.get ctxt op.signer in
          let* (status, ctxt) =
            catch
              (apply_operation ctxt counter op)
              (fun ctxt -> apply ctxt (index + 1) rst)
              (fun error ->
                return (Failure {index; reason = error}, initial_ctxt))
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
                let* ctxt =
                  Counter.set ctxt op.signer (Int64.succ op.counter)
                in
                return (ctxt, Account_set.add op.signer acc))
            (ctxt, Account_set.empty)
            ops
        in
        return (status, ctxt)

  let apply_transactions_batch :
      t -> transactions_batch -> ((transaction * transaction_status) list * t) m
      =
   fun ctxt {contents; aggregated_signatures} ->
    let open Syntax in
    let* is_correct_signature =
      check_signatures contents aggregated_signatures
    in
    let* () = fail_unless is_correct_signature Bad_aggregated_signature in

    let* (ctxt, rev_status) =
      list_fold_left_m
        (fun (ctxt, rev_status) ops ->
          let* (status, ctxt) = apply_transaction ctxt ops in
          return (ctxt, (ops, status) :: rev_status))
        (ctxt, [])
        contents
    in
    return (List.rev rev_status, ctxt)

  let apply_deposit : t -> Tx_rollup_inbox.deposit -> t m =
   fun ctxt {destination; key_hash; amount} ->
    let open Syntax in
    (* This should never happen if the layer-1 deposit implementation
       is correct. *)
    let* () = fail_unless Compare.Int64.(0L < amount) Invalid_deposit in
    safe_balance_add ctxt destination key_hash amount

  module Internal_for_tests = struct
    let apply_transaction = apply_transaction
  end
end
