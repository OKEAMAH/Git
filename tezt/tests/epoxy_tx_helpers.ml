(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

[@@@warning "-32"]

open Epoxy_tx
module T = Tx_rollup.P
module HashPV = Plompiler.Poseidon128
module SchnorrPV = Plompiler.Schnorr (HashPV)
module Schnorr = SchnorrPV.P

module type User = sig
  val id : int

  (* val pos : Z.t *)

  val next_cnt : unit -> Z.t

  val l2_pk : Schnorr.pk

  val l2_sk : Schnorr.sk
end

module UserMk (Id : sig
  val id : int

  val l2_sk : Schnorr.sk
end) : User = struct
  let cnt = ref 0

  let id = Id.id

  let l2_sk = Id.l2_sk

  let l2_pk = Schnorr.neuterize l2_sk

  (* let pos = Z.of_int id *)

  let next_cnt () =
    cnt := !cnt + 1 ;
    Z.of_int !cnt
end

let get_id m =
  let module M = (val m : User) in
  M.id

module type DefaultUsers = sig
  module User0 : User

  module User1 : User

  module User2 : User

  module User3 : User
end

module MakeUsers (D : sig
  val l2_sks : Schnorr.sk array
end) : DefaultUsers = struct
  module User0 = UserMk (struct
    let id = 0

    let l2_sk = D.l2_sks.(id)
  end)

  module User1 = UserMk (struct
    let id = 1

    let l2_sk = D.l2_sks.(id)
  end)

  module User2 = UserMk (struct
    let id = 2

    let l2_sk = D.l2_sks.(id)
  end)

  module User3 = UserMk (struct
    let id = 3

    let l2_sk = D.l2_sks.(id)
  end)
end

module type TICKET = sig
  val c_id : Bls12_381.Fr.t

  val p_id : bytes

  val c_of_bounded :
    'a Tx_rollup.Types.P.Bounded.t -> 'a Tx_rollup.Types.P.ticket

  val c_amount : int -> Tx_rollup.Constants.amount Tx_rollup.Types.P.ticket

  val c_bal : int -> Tx_rollup.Constants.balance Tx_rollup.Types.P.ticket

  (* val p : int -> ticket *)
end

module TicketMk (Id : sig
  val c_id : Bls12_381.Fr.t
end) : TICKET = struct
  include Id

  let p_id = Data_encoding.Binary.to_bytes_exn Plompiler.S.data_encoding c_id

  let c_of_bounded amount : 'a Tx_rollup.Types.P.ticket = {id = c_id; amount}

  let c_amount amount : 'a Tx_rollup.Types.P.ticket =
    {
      id = c_id;
      amount =
        Tx_rollup.(
          Types.P.Bounded.make
            ~unsafe:true
            ~bound:Constants.Bound.max_amount
            (Z.of_int amount));
    }

  let c_bal amount : 'a Tx_rollup.Types.P.ticket =
    {
      id = c_id;
      amount =
        Tx_rollup.(
          Types.P.Bounded.make
            ~unsafe:true
            ~bound:Constants.Bound.max_balance
            (Z.of_int amount));
    }

  (* let p x : ticket = {id = p_id; amount = Int32.of_int x} *)
end

module Tez = TicketMk (struct
  let c_id = Tx_rollup.Constants.tez_id
end)

module Blue = TicketMk (struct
  let c_id = Bls12_381.Fr.one
end)

module Red = TicketMk (struct
  let c_id = Bls12_381.Fr.of_int 2
end)

let pos_of_index ?(offset = 0) index =
  Z.of_int @@ ((Tx_rollup.Constants.max_nb_tickets * index) + offset)

(* let dummy_pk = Protocol.Sig.dummy_pk *)
(* let open Data_encoding in
   (* let open Tezos_crypto.Ed25519 in *)
   let size = Binary.fixed_length Public_key.encoding |> Option.get in
   Binary.of_bytes_exn Public_key.encoding (Bytes.init size (fun _ -> '\x00')) *)

let make_transfer ?(unsafe = false) ~(src : (module User))
    ~(dst : (module User)) ~amount ~fee () =
  let module Src = (val src) in
  let module Dst = (val dst) in
  let module Bounded = Tx_rollup.Types.P.Bounded in
  let open Tx_rollup.Constants.Bound in
  let open Tx_rollup.Types.P in
  let offset = Z.to_int @@ Bls12_381.Fr.to_z amount.id in
  let src_pos =
    Bounded.make ~unsafe ~bound:max_nb_leaves (pos_of_index ~offset Src.id)
  in
  let dst_pos =
    Bounded.make ~unsafe ~bound:max_nb_leaves (pos_of_index ~offset Dst.id)
  in
  let fee = Bounded.make ~unsafe ~bound:max_fee fee in
  let cnt = Bounded.make ~unsafe ~bound:max_counter (Src.next_cnt ()) in
  let unsigned_payload : unsigned_transfer_payload =
    {cnt; src = src_pos; dst = dst_pos; amount; fee}
  in
  let header =
    {
      op_code = Bounded.make ~unsafe ~bound:max_op_code Z.zero;
      price = Tez.c_of_bounded @@ Bounded.make ~unsafe ~bound:max_balance Z.zero;
      l1_dst = Types.P.Dummy.tezos_pkh;
      rollup_id = Types.P.Dummy.tezos_zkru;
    }
  in
  let unsigned_op : unsigned_transfer = {header; payload = unsigned_payload} in
  Tx_rollup.P.sign_op Src.l2_sk (Transfer unsigned_op)

let make_create ?(unsafe = false) ~(dst : (module User)) ~fee () =
  let module Dst = (val dst) in
  let module Bounded = Tx_rollup.Types.P.Bounded in
  let open Tx_rollup.Constants.Bound in
  let open Tx_rollup.Types.P in
  let fee = Bounded.make ~unsafe ~bound:max_fee fee in
  let unsigned_payload : unsigned_create_payload = {pk = Dst.l2_pk; fee} in
  let header =
    {
      op_code = Bounded.make ~unsafe ~bound:max_op_code Z.one;
      price = Tez.c_of_bounded Bounded.(make ~bound:max_balance (v fee));
      l1_dst = Types.P.Dummy.tezos_pkh;
      rollup_id = Types.P.Dummy.tezos_zkru;
    }
  in
  let unsigned_op : unsigned_create = {header; payload = unsigned_payload} in
  Tx_rollup.P.sign_op Dst.l2_sk (Create unsigned_op)

let make_credit ?(unsafe = false) ~(dst : (module User)) ~amount () : Types.P.tx
    =
  let module Dst = (val dst) in
  let module Bounded = Tx_rollup.Types.P.Bounded in
  let open Tx_rollup.Constants.Bound in
  let open Tx_rollup.Types.P in
  let offset = Z.to_int @@ Bls12_381.Fr.to_z amount.id in
  let dst_pos =
    Bounded.make ~unsafe ~bound:max_nb_leaves (pos_of_index ~offset Dst.id)
  in
  let cnt = Bounded.make ~unsafe ~bound:max_counter (Dst.next_cnt ()) in
  let payload : credit_payload = {cnt; dst = dst_pos; amount} in
  let header =
    {
      op_code = Bounded.make ~unsafe ~bound:max_op_code Z.(of_int 2);
      price =
        {
          id = amount.id;
          amount = Bounded.(make ~unsafe ~bound:max_balance (v amount.amount));
        };
      l1_dst = Types.P.Dummy.tezos_pkh;
      rollup_id = Types.P.Dummy.tezos_zkru;
    }
  in
  let op : credit = {header; payload} in
  Credit op

let make_debit ?(unsafe = false) ~(src : (module User)) ~amount () =
  let module Src = (val src) in
  let module Bounded = Tx_rollup.Types.P.Bounded in
  let open Tx_rollup.Constants.Bound in
  let open Tx_rollup.Types.P in
  let offset = Z.to_int @@ Bls12_381.Fr.to_z amount.id in
  let src_pos =
    Bounded.make ~unsafe ~bound:max_nb_leaves (pos_of_index ~offset Src.id)
  in
  let cnt = Bounded.make ~unsafe ~bound:max_counter (Src.next_cnt ()) in
  let unsigned_payload : unsigned_debit_payload =
    {cnt; src = src_pos; amount}
  in
  let header =
    {
      op_code = Bounded.make ~unsafe ~bound:max_op_code Z.(of_int 3);
      price =
        {
          id = amount.id;
          amount = Bounded.(make ~unsafe ~bound:max_balance (v amount.amount));
        };
      l1_dst = Types.P.Dummy.tezos_pkh;
      rollup_id = Types.P.Dummy.tezos_zkru;
    }
  in
  let unsigned_op : unsigned_debit = {header; payload = unsigned_payload} in
  Tx_rollup.P.(sign_op Src.l2_sk (Debit unsigned_op))

type c_ticket = Tx_rollup.Constants.balance Tx_rollup.Types.P.ticket
(*
let assert_ctx_s (ctx : ctx) (s : Tx_rollup.Types.P.state)
    (users :
      ((module User) * int * ticket list * (int * c_ticket list) option) list) =
  let to_proto_state s : Protocol.state =
    let Tx_rollup.Types.P.{accounts_tree; next_position; _} = s in
    let root = TestOperator.Merkle.root accounts_tree in
    Protocol.{root; next_position}
  in
  assert (
    (get_ru ctx).state
    = Data_encoding.Binary.to_bytes_exn
        Protocol.state_data_encoding
        (to_proto_state s)) ;
  let module Bounded = Tx_rollup.Types.P.Bounded in
  let check_one ((usr : (module User)), l1_tez_bal, l1_tickets, l2_bals) =
    let module U = (val usr) in
    let check_l1_bal id expected =
      let l1acc = Protocol.get_balance ~id U.l1_key ctx in
      if Z.(not (l1acc = of_int32 expected)) then
        failwith
        @@ Printf.sprintf
             "User %d has an L1 balance for token %s of %d, expected %d"
             U.id
             (Bls12_381.Fr.to_string
             @@ Data_encoding.Binary.of_bytes_exn
                  Protocol.scalar_data_encoding
                  id)
             (Z.to_int @@ l1acc)
             (Int32.to_int expected)
    in
    check_l1_bal Tez.p_id (Int32.of_int l1_tez_bal) ;
    List.iter (fun t -> check_l1_bal t.id t.amount) l1_tickets ;
    match (Tx_rollup.Types.P.IMap.find_opt U.id s.accounts, l2_bals) with
    | Some (l2acc, _, _), None when l2acc.pk <> Schnorr.g ->
        failwith
        @@ Printf.sprintf
             "User %d has an L2 account with a tez balance of %d, but it \
              shouldn't have an L2 account"
             U.id
             (Z.to_int @@ Bounded.v l2acc.tez_balance)
    | None, Some (l2_bal, _) ->
        failwith
        @@ Printf.sprintf
             "User %d does not have an L2 account, but it should have one with \
              a tez balance of %d"
             U.id
             l2_bal
    | Some (l2acc, leaves, _), Some (l2_tez_bal, l2_tickets) ->
        if Z.(not (Bounded.v l2acc.tez_balance = of_int l2_tez_bal)) then
          failwith
          @@ Printf.sprintf
               "User %d has an L2 tez balance of %d, expected %d"
               U.id
               (Z.to_int @@ Bounded.v l2acc.tez_balance)
               l2_tez_bal ;
        let check_l2_ticket (t : c_ticket) =
          let i = Z.to_int @@ Bls12_381.Fr.to_z t.id in
          let bal = leaves.(i) in
          if not (Bounded.v t.amount = Bounded.v bal.ticket.amount) then
            failwith
            @@ Printf.sprintf
                 "User %d has an L2 tez balance for ticketd %d of %d, expected \
                  %d"
                 U.id
                 i
                 (Z.to_int @@ Bounded.v bal.ticket.amount)
                 (Z.to_int @@ Bounded.v t.amount)
        in
        List.iter check_l2_ticket l2_tickets
    | _ -> ()
  in
  List.fold_left (fun () -> check_one) () users *)
