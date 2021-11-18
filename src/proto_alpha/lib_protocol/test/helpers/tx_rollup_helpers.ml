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

open Protocol
open Protocol.Alpha_context
open Protocol.Tx_rollup_l2_storage
open Protocol.Tx_rollup_l2_repr
open Protocol.Tx_rollup_l2_operation
module Map = Map.Make (Bytes)

let z_testable = Alcotest.testable Z.pp_print Z.equal

let l1_contract1 : Contract.t =
  Contract.implicit_contract
    (Signature.Public_key_hash.of_b58check_exn
       "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU")

let l1_contract2 : Contract.t =
  Contract.implicit_contract
    (Signature.Public_key_hash.of_b58check_exn
       "tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx")

let gen_l2_account =
  let seed = ref 0 in
  let next () =
    if 255 < !seed then
      raise (Invalid_argument "create_account: too many calls") ;
    let ikm = Bytes.make 32 (char_of_int !seed) in
    seed := !seed + 1 ;
    ikm
  in
  fun ?(seed = next ()) () ->
    let secret_key = Bls12_381.Signature.generate_sk seed in
    let public_key = Bls12_381.Signature.derive_pk secret_key in
    (secret_key, public_key)

let unit_ticket_metadata =
  let open Tezos_micheline.Micheline in
  let open Protocol.Michelson_v1_primitives in
  ( strip_locations @@ Prim (-1, D_Unit, [], []),
    strip_locations @@ Prim (-1, T_unit, [], []) )

let hash_key_exn ctxt ~ticketer ~typ ~contents ~owner =
  let ticketer = Micheline.root @@ Expr.from_string ticketer in
  let typ = Micheline.root @@ Expr.from_string typ in
  let contents = Micheline.root @@ Expr.from_string contents in
  let owner = Micheline.root @@ Expr.from_string owner in
  match
    Alpha_context.Ticket_balance.make_key_hash
      ctxt
      ~ticketer
      ~typ
      ~contents
      ~owner
  with
  | Ok x -> x
  | Error _ -> raise (Invalid_argument "hash_key_exn")

(* FIXME: Use a rollup address for the [owner] *)
let make_key ctxt content =
  hash_key_exn
    ctxt
    ~ticketer:{|"KT1ThEdxfUcWUwqsdergy3QnbCWGHSUHeHJq"|}
    ~typ:"string"
    ~contents:(Printf.sprintf {|"%s"|} content)
    ~owner:{|"KT1ThEdxfUcWUwqsdergy3QnbCWGHSUHeHJq"|}

module Sk_set = Set.Make (Bytes)

let sign_ops : Bls12_381.Signature.sk list -> transaction -> signature list =
 fun sks ops ->
  assert (List.length sks = List.length ops) ;

  let buf = Data_encoding.Binary.to_bytes_exn transaction_encoding ops in

  let seen = Sk_set.empty in

  let f (acc, seen) sk =
    let key = Bls12_381.Signature.sk_to_bytes sk in
    let keep = not @@ Sk_set.mem key seen in
    if keep then
      let acc = Bls12_381.Signature.Aug.sign sk buf :: acc in
      let seen = Sk_set.add key seen in
      (acc, seen)
    else (acc, seen)
  in

  let (unique_sks_rev, _) = List.fold_left f ([], seen) sks in
  (* Note that unique_sks_rev is reversed, but we don't care about the order so
      we just leave it.*)
  unique_sks_rev

let aggregate_signature_exn : signature list -> signature =
 fun signatures ->
  match Bls12_381.Signature.aggregate_signature_opt signatures with
  | Some res -> res
  | None -> raise (Invalid_argument "aggregate_signature_exn")

let batch :
    transaction list ->
    signature list ->
    Protocol.Alpha_context.Gas.Arith.fp ->
    transactions_batch =
 fun contents signatures allocated_gas ->
  let aggregated_signatures = aggregate_signature_exn signatures in
  {contents; aggregated_signatures; allocated_gas}

module type TEST_SUITE_CONTEXT = sig
  include Tx_rollup_l2_context.CONTEXT

  val empty : t

  val to_lwt : (unit -> 'a m) -> unit -> ('a, 'b) result Lwt.t

  val storage_name : string
end

module Map_storage :
  STORAGE
    with type t = bytes Map.t
     and type 'a m = ('a, Environment.Error_monad.error) result = struct
  type t = bytes Map.t

  type 'a m = ('a, Environment.Error_monad.error) result

  module Syntax = struct
    let ( let+ ) x k =
      match x with Ok x -> Ok (k x) | Error trace -> Error trace

    let ( let* ) x k = match x with Ok x -> k x | Error trace -> Error trace

    let fail : type a. Environment.Error_monad.error -> a m =
     fun error -> Error error

    let catch m k h = match m with Ok x -> k x | Error err -> h err

    let return : type a. a -> a m = fun x -> Ok x

    let list_fold_left_m f =
      let rec fold_left_m acc = function
        | x :: rst -> (
            match f acc x with
            | Ok acc -> fold_left_m acc rst
            | Error err -> Error err)
        | [] -> return acc
      in
      fold_left_m
  end

  let get store key = Tzresult_syntax.return (Map.find key store)

  let set store key value = Tzresult_syntax.return (Map.add key value store)
end

module Map_context : TEST_SUITE_CONTEXT = struct
  open Tx_rollup_l2_context
  include Make (Map_storage)

  let empty = {storage = Map.empty; remaining_gas = None}

  let to_lwt : (unit -> 'a m) -> unit -> ('a, 'b) result Lwt.t =
   fun test _ ->
    match test () with Ok x -> Error_monad.return x | Error _ -> assert false

  let storage_name = "map_storage"
end
