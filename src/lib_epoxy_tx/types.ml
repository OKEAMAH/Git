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

module U = Utils
open Plompiler
module HashPV = Anemoi128
module MerklePV = Gadget.Merkle (HashPV)
module SchnorrPV = Plompiler.Schnorr (HashPV)
module Curve = Mec.Curve.Jubjub.AffineEdwards
open Constants
module Bounded = Bounded.Make (Bound)

module P = struct
  module Schnorr = SchnorrPV.P
  module Merkle = MerklePV.P
  module Bounded = Bounded.P

  type 'a ticket = {id : S.t; amount : 'a Bounded.t}

  let ticket_balance_data_encoding : balance ticket Data_encoding.t =
    let amount_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {id; amount} -> (id, amount))
        (fun (id, amount) -> {id; amount})
        (obj2 (req "id" S.data_encoding) (req "amount" amount_encoding)))

  let ticket_amount_data_encoding : amount ticket Data_encoding.t =
    let amount_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {id; amount} -> (id, amount))
        (fun (id, amount) -> {id; amount})
        (obj2 (req "id" S.data_encoding) (req "amount" amount_encoding)))

  type tezos_pkh = bytes

  type tezos_zkru = bytes

  type account = {
    pk : Schnorr.pk;
    tez_balance : balance Bounded.t;
    cnt : counter Bounded.t;
    tickets_root : S.t;
  }

  type leaf = {pos : position Bounded.t; ticket : balance ticket}

  module IMap = Map.Make (Int)

  type state = {
    (* account index*)
    accounts : (account * leaf array * Merkle.tree) IMap.t;
    accounts_tree : Merkle.tree;
    (* First leaf of an empty account *)
    next_position : int;
  }

  type proof = {path : Merkle.path; root : S.t}

  type account_tree_el = {before : account; after : account; proof : proof}

  type leaf_tree_el = {before : leaf; after : leaf; path : Merkle.path}

  type tree_el = {account : account_tree_el; leaf : leaf_tree_el}

  type header = {
    op_code : op_code Bounded.t;
    price : balance ticket;
    l1_dst : tezos_pkh;
    rollup_id : tezos_zkru;
  }

  let header_data_encoding : header Data_encoding.t =
    let op_code_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {op_code; price; l1_dst; rollup_id} ->
          (op_code, price, l1_dst, rollup_id))
        (fun (op_code, price, l1_dst, rollup_id) ->
          {op_code; price; l1_dst; rollup_id})
        (obj4
           (req "op_code" op_code_encoding)
           (req "price" ticket_balance_data_encoding)
           (req "l1_dst" bytes)
           (req "rollup_id" bytes)))

  type unsigned_transfer_payload = {
    cnt : counter Bounded.t;
    src : position Bounded.t;
    dst : position Bounded.t;
    amount : amount ticket;
    fee : fee Bounded.t;
  }

  let unsigned_transfer_payload_data_encoding :
      unsigned_transfer_payload Data_encoding.t =
    let cnt_encoding = Bounded.data_encoding in
    let pos_encoding = Bounded.data_encoding in
    let fee_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {cnt; src; dst; amount; fee} -> (cnt, src, dst, amount, fee))
        (fun (cnt, src, dst, amount, fee) -> {cnt; src; dst; amount; fee})
        (obj5
           (req "cnt" cnt_encoding)
           (req "src" pos_encoding)
           (req "dst" pos_encoding)
           (req "amount" ticket_amount_data_encoding)
           (req "fee" fee_encoding)))

  type transfer_payload = {
    msg : unsigned_transfer_payload;
    signature : Schnorr.signature;
  }

  let curve_data_encoding =
    Data_encoding.(conv Curve.to_bytes Curve.of_bytes_exn bytes)

  let signature_data_encoding : Schnorr.signature Data_encoding.t =
    let open Schnorr in
    Data_encoding.(
      conv
        (fun {sig_u_bytes; sig_r; c_bytes} -> (sig_u_bytes, sig_r, c_bytes))
        (fun (sig_u_bytes, sig_r, c_bytes) -> {sig_u_bytes; sig_r; c_bytes})
        (obj3
           (req "sig_u_bytes" (list bool))
           (req "sig_r" curve_data_encoding)
           (req "c_bytes" (list bool))))

  let transfer_payload_data_encoding : transfer_payload Data_encoding.t =
    Data_encoding.(
      conv
        (fun {msg; signature} -> (msg, signature))
        (fun (msg, signature) -> {msg; signature})
        (obj2
           (req "msg" unsigned_transfer_payload_data_encoding)
           (req "signature" signature_data_encoding)))

  type unsigned_transfer = {
    header : header;
    payload : unsigned_transfer_payload;
  }

  type transfer = {header : header; payload : transfer_payload}

  let transfer_data_encoding =
    Data_encoding.(
      conv
        (fun {header; payload} -> (header, payload))
        (fun (header, payload) -> {header; payload})
        (obj2
           (req "header" header_data_encoding)
           (req "payload" transfer_payload_data_encoding)))

  type transfer_storage = {src : tree_el; dst : tree_el; valid : bool}

  type unsigned_create_payload = {pk : Schnorr.pk; fee : fee Bounded.t}

  let unsigned_create_payload_data_encoding :
      unsigned_create_payload Data_encoding.t =
    let fee_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {pk; fee} -> (pk, fee))
        (fun (pk, fee) -> {pk; fee})
        (obj2 (req "pk" curve_data_encoding) (req "fee" fee_encoding)))

  type create_payload = {
    msg : unsigned_create_payload;
    signature : Schnorr.signature;
  }

  let create_payload_data_encoding : create_payload Data_encoding.t =
    Data_encoding.(
      conv
        (fun {msg; signature} -> (msg, signature))
        (fun (msg, signature) -> {msg; signature})
        (obj2
           (req "msg" unsigned_create_payload_data_encoding)
           (req "signature" signature_data_encoding)))

  type unsigned_create = {header : header; payload : unsigned_create_payload}

  type create = {header : header; payload : create_payload}

  let create_data_encoding =
    Data_encoding.(
      conv
        (fun {header; payload} -> (header, payload))
        (fun (header, payload) -> {header; payload})
        (obj2
           (req "header" header_data_encoding)
           (req "payload" create_payload_data_encoding)))

  type create_storage = {dst : tree_el; next_empty : tree_el; valid : bool}

  type credit_payload = {
    cnt : counter Bounded.t;
    dst : position Bounded.t;
    amount : amount ticket;
  }

  let credit_payload_data_encoding : credit_payload Data_encoding.t =
    let cnt_encoding = Bounded.data_encoding in
    let pos_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {cnt; dst; amount} -> (cnt, dst, amount))
        (fun (cnt, dst, amount) -> {cnt; dst; amount})
        (obj3
           (req "cnt" cnt_encoding)
           (req "dst" pos_encoding)
           (req "amount" ticket_amount_data_encoding)))

  type credit = {header : header; payload : credit_payload}

  let credit_data_encoding =
    Data_encoding.(
      conv
        (fun {header; payload} -> (header, payload))
        (fun (header, payload) -> {header; payload})
        (obj2
           (req "header" header_data_encoding)
           (req "payload" credit_payload_data_encoding)))

  type credit_storage = {dst : tree_el; valid : bool}

  type unsigned_debit_payload = {
    cnt : counter Bounded.t;
    src : position Bounded.t;
    amount : amount ticket;
  }

  let unsigned_debit_payload_data_encoding :
      unsigned_debit_payload Data_encoding.t =
    let cnt_encoding = Bounded.data_encoding in
    let pos_encoding = Bounded.data_encoding in
    Data_encoding.(
      conv
        (fun {cnt; src; amount} -> (cnt, src, amount))
        (fun (cnt, src, amount) -> {cnt; src; amount})
        (obj3
           (req "cnt" cnt_encoding)
           (req "src" pos_encoding)
           (req "amount" ticket_amount_data_encoding)))

  type debit_payload = {
    msg : unsigned_debit_payload;
    signature : Schnorr.signature;
  }

  let debit_payload_data_encoding : debit_payload Data_encoding.t =
    Data_encoding.(
      conv
        (fun {msg; signature} -> (msg, signature))
        (fun (msg, signature) -> {msg; signature})
        (obj2
           (req "msg" unsigned_debit_payload_data_encoding)
           (req "signature" signature_data_encoding)))

  type unsigned_debit = {header : header; payload : unsigned_debit_payload}

  type debit = {header : header; payload : debit_payload}

  let debit_data_encoding =
    Data_encoding.(
      conv
        (fun {header; payload} -> (header, payload))
        (fun (header, payload) -> {header; payload})
        (obj2
           (req "header" header_data_encoding)
           (req "payload" debit_payload_data_encoding)))

  type debit_storage = {src : tree_el; valid : bool}

  type unsigned_tx =
    | Transfer of unsigned_transfer
    | Create of unsigned_create
    | Credit of credit
    | Debit of unsigned_debit

  type tx =
    | Transfer of transfer
    | Create of create
    | Credit of credit
    | Debit of debit

  let tx_data_encoding =
    let open Data_encoding in
    let transfer_tag = 0 in
    let create_tag = 1 in
    let credit_tag = 2 in
    let debit_tag = 3 in
    matching
      (function
        | Transfer tx -> matched transfer_tag transfer_data_encoding tx
        | Create tx -> matched create_tag create_data_encoding tx
        | Credit tx -> matched credit_tag credit_data_encoding tx
        | Debit tx -> matched debit_tag debit_data_encoding tx)
      [
        case
          ~title:"Transfer"
          (Tag transfer_tag)
          transfer_data_encoding
          (function Transfer tx -> Some tx | _ -> None)
          (fun tx -> Transfer tx);
        case
          ~title:"Create"
          (Tag create_tag)
          create_data_encoding
          (function Create tx -> Some tx | _ -> None)
          (fun tx -> Create tx);
        case
          ~title:"Credit"
          (Tag credit_tag)
          credit_data_encoding
          (function Credit tx -> Some tx | _ -> None)
          (fun tx -> Credit tx);
        case
          ~title:"Debit"
          (Tag debit_tag)
          debit_data_encoding
          (function Debit tx -> Some tx | _ -> None)
          (fun tx -> Debit tx);
      ]

  type tx_storage =
    | Transfer of transfer_storage
    | Create of create_storage
    | Credit of credit_storage
    | Debit of debit_storage

  module Dummy = struct
    let cnt = Bounded.make ~bound:Bound.max_counter Z.zero

    let fee = Bounded.make ~bound:Bound.max_fee Z.zero

    let pos = Bounded.make ~bound:Bound.max_nb_leaves Z.zero

    let amount = Bounded.make ~bound:Bound.max_amount Z.zero

    let balance = Bounded.make ~bound:Bound.max_balance Z.zero

    let ticket_amount = {id = S.zero; amount}

    let ticket_balance = {id = S.zero; amount = balance}

    let op_code = Bounded.make ~bound:Bound.max_op_code Z.zero

    let root = Bls12_381.Fr.random ()

    let sk = Curve.Scalar.random ()

    let pk = Schnorr.neuterize sk

    let tezos_pkh = Bytes.init 21 (fun i -> char_of_int i)

    let tezos_zkru = Bytes.init 20 (fun _i -> char_of_int 0)

    let signature =
      let rand = Curve.Scalar.random () in
      Schnorr.sign sk S.zero rand

    let leaf : leaf = {pos; ticket = ticket_balance}

    let account : account =
      {pk; tez_balance = balance; cnt; tickets_root = root}

    let proof depth : proof =
      {path = List.init depth (fun _ -> (Bls12_381.Fr.random (), true)); root}

    let account_tree_el : account_tree_el =
      {
        before = account;
        after = account;
        proof = proof Constants.accounts_depth;
      }

    let leaf_tree_el : leaf_tree_el =
      {before = leaf; after = leaf; path = (proof Constants.tickets_depth).path}

    let tree_el : tree_el = {account = account_tree_el; leaf = leaf_tree_el}

    let header =
      {
        op_code;
        price = ticket_balance;
        l1_dst = tezos_pkh;
        rollup_id = tezos_zkru;
      }

    let unsigned_transfer_payload =
      {cnt; src = pos; dst = pos; amount = ticket_amount; fee}

    let transfer_payload : transfer_payload =
      {msg = unsigned_transfer_payload; signature}

    let transfer : transfer = {header; payload = transfer_payload}

    let transfer_storage : transfer_storage =
      {src = tree_el; dst = tree_el; valid = true}

    let unsigned_create_payload = {pk; fee}

    let create_payload : create_payload =
      {msg = unsigned_create_payload; signature}

    let create : create = {header; payload = create_payload}

    let create_storage : create_storage =
      {dst = tree_el; next_empty = tree_el; valid = true}

    let credit_payload = {cnt; dst = pos; amount = ticket_amount}

    let credit : credit = {header; payload = credit_payload}

    let credit_storage : credit_storage = {dst = tree_el; valid = true}

    let unsgined_debit_payload = {cnt; src = pos; amount = ticket_amount}

    let debit_payload : debit_payload =
      {msg = unsgined_debit_payload; signature}

    let debit : debit = {header; payload = debit_payload}

    let debit_storage : debit_storage = {src = tree_el; valid = true}
  end
end

module V (L : LIB) = struct
  open L
  module Schnorr = SchnorrPV.V (L)
  module Merkle = MerklePV.V (L)
  module Bounded_u = Bounded.V (L)

  type curve_t_u = (scalar * scalar) repr

  type curve_base_t_u = scalar repr

  type curve_scalar_t_u = scalar repr

  type 'a ticket_u = {id : scalar repr; amount : 'a Bounded_u.t}

  type tezos_pkh_u = scalar repr

  type tezos_zkru_u = scalar repr

  type account_u = {
    pk : Schnorr.pk repr;
    tez_balance : balance Bounded_u.t;
    cnt : counter Bounded_u.t;
    tickets_root : scalar repr;
  }

  type leaf_u = {pos : position Bounded_u.t; ticket : balance ticket_u}

  type proof_u = {path : Merkle.path; root : scalar repr}

  type account_tree_el_u = {
    before : account_u;
    after : account_u;
    proof : proof_u;
  }

  type leaf_tree_el_u = {before : leaf_u; after : leaf_u; path : Merkle.path}

  type tree_el_u = {account : account_tree_el_u; leaf : leaf_tree_el_u}

  type header_u = {
    op_code : op_code Bounded_u.t;
    price : balance ticket_u;
    l1_dst : tezos_pkh_u;
    rollup_id : tezos_zkru_u;
  }

  type unsigned_transfer_payload_u = {
    cnt : counter Bounded_u.t;
    src : position Bounded_u.t;
    dst : position Bounded_u.t;
    amount : amount ticket_u;
    fee : fee Bounded_u.t;
  }

  type transfer_payload_u = {
    msg : unsigned_transfer_payload_u;
    signature : Schnorr.signature;
  }

  type transfer_u = {header : header_u; payload : transfer_payload_u}

  type transfer_storage_u = {
    src : tree_el_u;
    dst : tree_el_u;
    valid : bool repr;
  }

  type unsigned_create_payload_u = {pk : Schnorr.pk repr; fee : fee Bounded_u.t}

  type create_payload_u = {
    msg : unsigned_create_payload_u;
    signature : Schnorr.signature;
  }

  type create_u = {header : header_u; payload : create_payload_u}

  type create_storage_u = {
    dst : tree_el_u;
    next_empty : tree_el_u;
    valid : bool repr;
  }

  type credit_payload_u = {
    cnt : counter Bounded_u.t;
    dst : position Bounded_u.t;
    amount : amount ticket_u;
  }

  type credit_u = {header : header_u; payload : credit_payload_u}

  type credit_storage_u = {dst : tree_el_u; valid : bool repr}

  type unsigned_debit_payload_u = {
    cnt : counter Bounded_u.t;
    src : position Bounded_u.t;
    amount : amount ticket_u;
  }

  type debit_payload_u = {
    msg : unsigned_debit_payload_u;
    signature : Schnorr.signature;
  }

  type debit_u = {header : header_u; payload : debit_payload_u}

  type debit_storage_u = {src : tree_el_u; valid : bool repr}
end

module Encodings (L : LIB) = struct
  module Bounded_e = Bounded.Encoding (L)
  open P
  open L

  open V (L)

  open Encodings (L)

  module Anemoi = Anemoi128.V
  module Plompiler_Curve = JubjubEdwards (L)
  module Plompiler_Hash = Anemoi (L)
  open U

  let s_of_int x = S.of_z (Z.of_int x)

  let curve_base_t_encoding : (Curve.Base.t, curve_base_t_u, _) encoding =
    conv
      (fun r -> r)
      (fun r -> r)
      curve_base_to_s
      curve_base_of_s
      scalar_encoding

  let curve_scalar_t_encoding : (Curve.Scalar.t, curve_scalar_t_u, _) encoding =
    conv
      (fun r -> r)
      (fun r -> r)
      curve_scalar_to_s
      curve_scalar_of_s
      scalar_encoding

  let curve_t_encoding : (Curve.t, curve_t_u, _) encoding =
    with_implicit_bool_check Plompiler_Curve.is_on_curve
    @@ conv
         (fun r -> of_pair r)
         (fun (u, v) -> pair u v)
         (fun c ->
           ( curve_base_to_s @@ Curve.get_u_coordinate c,
             curve_base_to_s @@ Curve.get_v_coordinate c ))
         (fun (u, v) ->
           Curve.from_coordinates_exn
             ~u:(curve_base_of_s u)
             ~v:(curve_base_of_s v))
         (obj2_encoding scalar_encoding scalar_encoding)

  let balance_encoding ~safety =
    Bounded_e.encoding ~safety Constants.Bound.max_balance

  let amount_encoding ~safety =
    Bounded_e.encoding ~safety Constants.Bound.max_amount

  let fee_encoding ~safety = Bounded_e.encoding ~safety Constants.Bound.max_fee

  let pos_encoding ~safety =
    Bounded_e.encoding ~safety Constants.Bound.max_nb_leaves

  let cnt_encoding ~safety =
    Bounded_e.encoding ~safety Constants.Bound.max_counter

  let op_code_encoding ~safety =
    Bounded_e.encoding ~safety Constants.Bound.max_op_code

  let tezos_pkh_encoding : (tezos_pkh, tezos_pkh_u, _) encoding =
    conv
      (fun pkhu -> pkhu)
      (fun w -> w)
      U.scalar_of_bytes
      U.scalar_to_bytes
      scalar_encoding

  let tezos_zkru_encoding : (tezos_zkru, tezos_zkru_u, _) encoding =
    conv
      (fun zkru -> zkru)
      (fun w -> w)
      U.scalar_of_bytes
      U.scalar_to_bytes
      scalar_encoding

  let ticket_encoding ~safety (bound : 'a Bound.t) :
      ('a ticket, 'a ticket_u, _) encoding =
    conv
      (fun {id; amount} -> (id, amount))
      (fun (id, amount) -> {id; amount})
      (fun ({id; amount} : 'a ticket) -> (id, amount))
      (fun (id, amount) -> {id; amount})
      (obj2_encoding scalar_encoding (Bounded_e.encoding ~safety bound))

  let ticket_balance_encoding ~safety =
    ticket_encoding ~safety Constants.Bound.max_balance

  let ticket_amount_encoding ~safety =
    ticket_encoding ~safety Constants.Bound.max_amount

  let account_encoding : (account, account_u, _) encoding =
    conv
      (fun {pk; tez_balance; cnt; tickets_root} ->
        (pk, (tez_balance, (cnt, tickets_root))))
      (fun (pk, (tez_balance, (cnt, tickets_root))) ->
        {pk; tez_balance; cnt; tickets_root})
      (fun (acc : account) ->
        (acc.pk, (acc.tez_balance, (acc.cnt, acc.tickets_root))))
      (fun (pk, (tez_balance, (cnt, tickets_root))) ->
        {pk; tez_balance; cnt; tickets_root})
      (obj4_encoding
         Schnorr.pk_encoding
         (balance_encoding ~safety:NoCheck)
         (cnt_encoding ~safety:NoCheck)
         scalar_encoding)

  let leaf_encoding : (leaf, leaf_u, _) encoding =
    conv
      (fun {pos; ticket} -> (pos, ticket))
      (fun (pos, ticket) -> {pos; ticket})
      (fun ({pos; ticket} : leaf) -> (pos, ticket))
      (fun (pos, ticket) -> {pos; ticket})
      (obj2_encoding
         (pos_encoding ~safety:NoCheck)
         (ticket_balance_encoding ~safety:NoCheck))

  let proof_encoding : (proof, proof_u, _) encoding =
    conv
      (fun {path; root} -> (path, root))
      (fun (path, root) -> {path; root})
      (fun ({path; root} : proof) -> (path, root))
      (fun (path, root) -> {path; root})
      (obj2_encoding Merkle.path_encoding scalar_encoding)

  let account_tree_el_encoding :
      (account_tree_el, account_tree_el_u, _) encoding =
    conv
      (fun {before; after; proof} -> (before, (after, proof)))
      (fun (before, (after, proof)) -> {before; after; proof})
      (fun ({before; after; proof} : account_tree_el) ->
        (before, (after, proof)))
      (fun (before, (after, proof)) -> {before; after; proof})
      (obj3_encoding account_encoding account_encoding proof_encoding)

  let leaf_tree_el_encoding : (leaf_tree_el, leaf_tree_el_u, _) encoding =
    conv
      (fun {before; after; path} -> (before, (after, path)))
      (fun (before, (after, path)) -> {before; after; path})
      (fun ({before; after; path} : leaf_tree_el) -> (before, (after, path)))
      (fun (before, (after, path)) -> {before; after; path})
      (obj3_encoding leaf_encoding leaf_encoding Merkle.path_encoding)

  let tree_el_encoding : (tree_el, tree_el_u, _) encoding =
    conv
      (fun {account; leaf} -> (account, leaf))
      (fun (account, leaf) -> {account; leaf})
      (fun ({account; leaf} : tree_el) -> (account, leaf))
      (fun (account, leaf) -> {account; leaf})
      (obj2_encoding account_tree_el_encoding leaf_tree_el_encoding)

  let header_encoding ~safety : (header, header_u, _) encoding =
    conv
      (fun {op_code; price; l1_dst; rollup_id} ->
        (op_code, (price, (l1_dst, rollup_id))))
      (fun (op_code, (price, (l1_dst, rollup_id))) ->
        {op_code; price; l1_dst; rollup_id})
      (fun ({op_code; price; l1_dst; rollup_id} : header) ->
        (op_code, (price, (l1_dst, rollup_id))))
      (fun (op_code, (price, (l1_dst, rollup_id))) ->
        {op_code; price; l1_dst; rollup_id})
      (obj4_encoding
         (op_code_encoding ~safety)
         (ticket_balance_encoding ~safety)
         tezos_pkh_encoding
         tezos_zkru_encoding)

  let unsigned_transfer_payload_encoding ~safety :
      (unsigned_transfer_payload, unsigned_transfer_payload_u, _) encoding =
    conv
      (fun (tx : unsigned_transfer_payload_u) ->
        (tx.cnt, (tx.src, (tx.dst, (tx.amount, tx.fee)))))
      (fun (cnt, (src, (dst, (amount, fee)))) -> {cnt; src; dst; amount; fee})
      (fun (tx : unsigned_transfer_payload) ->
        (tx.cnt, (tx.src, (tx.dst, (tx.amount, tx.fee)))))
      (fun (cnt, (src, (dst, (amount, fee)))) -> {cnt; src; dst; amount; fee})
      (obj5_encoding
         (cnt_encoding ~safety)
         (pos_encoding ~safety)
         (pos_encoding ~safety)
         (ticket_amount_encoding ~safety)
         (fee_encoding ~safety))

  let transfer_payload_encoding ~safety :
      (transfer_payload, transfer_payload_u, _) encoding =
    conv
      (fun ({msg; signature} : transfer_payload_u) -> (msg, signature))
      (fun (msg, signature) -> {msg; signature})
      (fun ({msg; signature} : transfer_payload) -> (msg, signature))
      (fun (msg, signature) -> {msg; signature})
      (obj2_encoding
         (unsigned_transfer_payload_encoding ~safety)
         Schnorr.signature_encoding)

  let transfer_encoding ~safety : (transfer, transfer_u, _) encoding =
    conv
      (fun (tx : transfer_u) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (fun (tx : transfer) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (obj2_encoding
         (header_encoding ~safety)
         (transfer_payload_encoding ~safety))

  let transfer_storage_encoding :
      (transfer_storage, transfer_storage_u, _) encoding =
    conv
      (fun (tx : transfer_storage_u) -> (tx.src, (tx.dst, tx.valid)))
      (fun (src, (dst, valid)) -> {src; dst; valid})
      (fun (tx : transfer_storage) -> (tx.src, (tx.dst, tx.valid)))
      (fun (src, (dst, valid)) -> {src; dst; valid})
      (obj3_encoding tree_el_encoding tree_el_encoding bool_encoding)

  let unsigned_create_payload_encoding ~safety :
      (unsigned_create_payload, unsigned_create_payload_u, _) encoding =
    conv
      (fun (tx : unsigned_create_payload_u) -> (tx.pk, tx.fee))
      (fun (pk, fee) -> {pk; fee})
      (fun (tx : unsigned_create_payload) -> (tx.pk, tx.fee))
      (fun (pk, fee) -> {pk; fee})
      (obj2_encoding Schnorr.pk_encoding (fee_encoding ~safety))

  let create_payload_encoding ~safety :
      (create_payload, create_payload_u, _) encoding =
    conv
      (fun ({msg; signature} : create_payload_u) -> (msg, signature))
      (fun (msg, signature) -> {msg; signature})
      (fun ({msg; signature} : create_payload) -> (msg, signature))
      (fun (msg, signature) -> {msg; signature})
      (obj2_encoding
         (unsigned_create_payload_encoding ~safety)
         Schnorr.signature_encoding)

  let create_encoding ~safety : (create, create_u, _) encoding =
    conv
      (fun (tx : create_u) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (fun (tx : create) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (obj2_encoding
         (header_encoding ~safety)
         (create_payload_encoding ~safety))

  let create_storage_encoding : (create_storage, create_storage_u, _) encoding =
    conv
      (fun (tx : create_storage_u) -> (tx.dst, (tx.next_empty, tx.valid)))
      (fun (dst, (next_empty, valid)) -> {dst; next_empty; valid})
      (fun (tx : create_storage) -> (tx.dst, (tx.next_empty, tx.valid)))
      (fun (dst, (next_empty, valid)) -> {dst; next_empty; valid})
      (obj3_encoding tree_el_encoding tree_el_encoding bool_encoding)

  let credit_payload_encoding ~safety :
      (credit_payload, credit_payload_u, _) encoding =
    conv
      (fun (tx : credit_payload_u) -> (tx.cnt, (tx.dst, tx.amount)))
      (fun (cnt, (dst, amount)) -> {cnt; dst; amount})
      (fun (tx : credit_payload) -> (tx.cnt, (tx.dst, tx.amount)))
      (fun (cnt, (dst, amount)) -> {cnt; dst; amount})
      (obj3_encoding
         (cnt_encoding ~safety)
         (pos_encoding ~safety)
         (ticket_amount_encoding ~safety))

  let credit_encoding ~safety : (credit, credit_u, _) encoding =
    conv
      (fun (tx : credit_u) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (fun (tx : credit) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (obj2_encoding
         (header_encoding ~safety)
         (credit_payload_encoding ~safety))

  let credit_storage_encoding : (credit_storage, credit_storage_u, _) encoding =
    conv
      (fun (tx : credit_storage_u) -> (tx.dst, tx.valid))
      (fun (dst, valid) -> {dst; valid})
      (fun (tx : credit_storage) -> (tx.dst, tx.valid))
      (fun (dst, valid) -> {dst; valid})
      (obj2_encoding tree_el_encoding bool_encoding)

  let unsigned_debit_payload_encoding ~safety :
      (unsigned_debit_payload, unsigned_debit_payload_u, _) encoding =
    conv
      (fun (tx : unsigned_debit_payload_u) -> (tx.cnt, (tx.src, tx.amount)))
      (fun (cnt, (src, amount)) -> {cnt; src; amount})
      (fun (tx : unsigned_debit_payload) -> (tx.cnt, (tx.src, tx.amount)))
      (fun (cnt, (src, amount)) -> {cnt; src; amount})
      (obj3_encoding
         (cnt_encoding ~safety)
         (pos_encoding ~safety)
         (ticket_amount_encoding ~safety))

  let debit_payload_encoding ~safety :
      (debit_payload, debit_payload_u, _) encoding =
    conv
      (fun ({msg; signature} : debit_payload_u) -> (msg, signature))
      (fun (msg, signature) -> {msg; signature})
      (fun ({msg; signature} : debit_payload) -> (msg, signature))
      (fun (msg, signature) -> {msg; signature})
      (obj2_encoding
         (unsigned_debit_payload_encoding ~safety)
         Schnorr.signature_encoding)

  let debit_encoding ~safety : (debit, debit_u, _) encoding =
    conv
      (fun (tx : debit_u) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (fun (tx : debit) -> (tx.header, tx.payload))
      (fun (header, payload) -> {header; payload})
      (obj2_encoding (header_encoding ~safety) (debit_payload_encoding ~safety))

  let debit_storage_encoding : (debit_storage, debit_storage_u, _) encoding =
    conv
      (fun (tx : debit_storage_u) -> (tx.src, tx.valid))
      (fun (src, valid) -> {src; valid})
      (fun (tx : debit_storage) -> (tx.src, tx.valid))
      (fun (src, valid) -> {src; valid})
      (obj2_encoding tree_el_encoding bool_encoding)
end
