(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020 Metastate AG <hello@metastate.dev>                     *)
(* Copyright (c) 2021-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
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
open Script_int
open Dependent_bool

(*

    The step function of the interpreter is parametrized by a bunch of values called the step constants.
    These values are indeed constants during the call of a smart contract with the notable exception of
    the IView instruction which modifies `source`, `self`, and `amount` and the KView_exit continuation
    which restores them.
    ======================

*)
type step_constants = {
  source : Contract.t;
      (** The address calling this contract, as returned by SENDER. *)
  payer : Signature.public_key_hash;
      (** The address of the implicit account that initiated the chain of contract calls, as returned by SOURCE. *)
  self : Contract_hash.t;
      (** The address of the contract being executed, as returned by SELF and SELF_ADDRESS.
     Also used:
     - as ticketer in TICKET
     - as caller in VIEW, TRANSFER_TOKENS, and CREATE_CONTRACT *)
  amount : Tez.t;
      (** The amount of the current transaction, as returned by AMOUNT. *)
  balance : Tez.t;  (** The balance of the contract as returned by BALANCE. *)
  chain_id : Chain_id.t;
      (** The chain id of the chain, as returned by CHAIN_ID. *)
  now : Script_timestamp.t;
      (** The earliest time at which the current block could have been timestamped, as returned by NOW. *)
  level : Script_int.n Script_int.num;
      (** The level of the current block, as returned by LEVEL. *)
}

(* Preliminary definitions. *)

type never = |

type address = {destination : Destination.t; entrypoint : Entrypoint.t}

module Script_signature = struct
  type t = Signature_tag of signature [@@ocaml.unboxed]

  let make s = Signature_tag s

  let get (Signature_tag s) = s

  let encoding =
    Data_encoding.conv
      (fun (Signature_tag x) -> x)
      (fun x -> Signature_tag x)
      Signature.encoding

  let of_b58check_opt x = Option.map make (Signature.of_b58check_opt x)

  let check ?watermark pub_key (Signature_tag s) bytes =
    Signature.check ?watermark pub_key s bytes

  let compare (Signature_tag x) (Signature_tag y) = Signature.compare x y

  let size = Signature.size
end

type signature = Script_signature.t

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2466
   The various attributes of this type should be checked with
   appropriate testing. *)
type tx_rollup_l2_address = Tx_rollup_l2_address.Indexable.value

type ('a, 'b) pair = 'a * 'b

type ('a, 'b) union = L of 'a | R of 'b

module Script_chain_id = struct
  type t = Chain_id_tag of Chain_id.t [@@ocaml.unboxed]

  let make x = Chain_id_tag x

  let compare (Chain_id_tag x) (Chain_id_tag y) = Chain_id.compare x y

  let size = Chain_id.size

  let encoding =
    Data_encoding.conv (fun (Chain_id_tag x) -> x) make Chain_id.encoding

  let to_b58check (Chain_id_tag x) = Chain_id.to_b58check x

  let of_b58check_opt x = Option.map make (Chain_id.of_b58check_opt x)
end

module Script_bls = struct
  module type S = sig
    type t

    type fr

    val add : t -> t -> t

    val mul : t -> fr -> t

    val negate : t -> t

    val of_bytes_opt : Bytes.t -> t option

    val to_bytes : t -> Bytes.t
  end

  module Fr = struct
    type t = Fr_tag of Bls12_381.Fr.t [@@ocaml.unboxed]

    open Bls12_381.Fr

    let add (Fr_tag x) (Fr_tag y) = Fr_tag (add x y)

    let mul (Fr_tag x) (Fr_tag y) = Fr_tag (mul x y)

    let negate (Fr_tag x) = Fr_tag (negate x)

    let of_bytes_opt bytes = Option.map (fun x -> Fr_tag x) (of_bytes_opt bytes)

    let to_bytes (Fr_tag x) = to_bytes x

    let of_z z = Fr_tag (of_z z)

    let to_z (Fr_tag x) = to_z x
  end

  module G1 = struct
    type t = G1_tag of Bls12_381.G1.t [@@ocaml.unboxed]

    open Bls12_381.G1

    let add (G1_tag x) (G1_tag y) = G1_tag (add x y)

    let mul (G1_tag x) (Fr.Fr_tag y) = G1_tag (mul x y)

    let negate (G1_tag x) = G1_tag (negate x)

    let of_bytes_opt bytes = Option.map (fun x -> G1_tag x) (of_bytes_opt bytes)

    let to_bytes (G1_tag x) = to_bytes x
  end

  module G2 = struct
    type t = G2_tag of Bls12_381.G2.t [@@ocaml.unboxed]

    open Bls12_381.G2

    let add (G2_tag x) (G2_tag y) = G2_tag (add x y)

    let mul (G2_tag x) (Fr.Fr_tag y) = G2_tag (mul x y)

    let negate (G2_tag x) = G2_tag (negate x)

    let of_bytes_opt bytes = Option.map (fun x -> G2_tag x) (of_bytes_opt bytes)

    let to_bytes (G2_tag x) = to_bytes x
  end

  let pairing_check l =
    let l = List.map (fun (G1.G1_tag x, G2.G2_tag y) -> (x, y)) l in
    Bls12_381.pairing_check l
end

module Script_timelock = struct
  type chest_key = Chest_key_tag of Timelock.chest_key [@@ocaml.unboxed]

  let make_chest_key chest_key = Chest_key_tag chest_key

  let chest_key_encoding =
    Data_encoding.conv
      (fun (Chest_key_tag x) -> x)
      (fun x -> Chest_key_tag x)
      Timelock.chest_key_encoding

  type chest = Chest_tag of Timelock.chest [@@ocaml.unboxed]

  let make_chest chest = Chest_tag chest

  let chest_encoding =
    Data_encoding.conv
      (fun (Chest_tag x) -> x)
      (fun x -> Chest_tag x)
      Timelock.chest_encoding

  let open_chest (Chest_tag chest) (Chest_key_tag chest_key) ~time =
    Timelock.open_chest chest chest_key ~time

  let get_plaintext_size (Chest_tag x) = Timelock.get_plaintext_size x
end

type 'a ticket = {ticketer : Contract.t; contents : 'a; amount : n num}

module type TYPE_SIZE = sig
  (* A type size represents the size of its type parameter.
     This constraint is enforced inside this module (Script_typed_ir), hence there
     should be no way to construct a type size outside of it.

     It allows keeping type metadata and types non-private.

     The size of a type is the number of nodes in its AST
     representation. In other words, the size of a type is 1 plus the size of
     its arguments. For instance, the size of [Unit] is 1 and the size of
     [Pair ty1 ty2] is [1] plus the size of [ty1] and [ty2].

     This module is here because we want three levels of visibility over this
     code:
     - inside this submodule, we have [type 'a t = int]
     - outside of [Script_typed_ir], the ['a t] type is abstract and we have
        the invariant that whenever [x : 'a t] we have that [x] is exactly
        the size of ['a].
     - in-between (inside [Script_typed_ir] but outside the [Type_size]
        submodule), the type is abstract but we have access to unsafe
        constructors that can break the invariant.
  *)
  type 'a t

  val to_int : 'a t -> Saturation_repr.mul_safe Saturation_repr.t

  (* Unsafe constructors, to be used only safely and inside this module *)

  val one : _ t

  val two : _ t

  val three : _ t

  val four : (_, _) pair option t

  val compound1 : Script.location -> _ t -> _ t tzresult

  val compound2 : Script.location -> _ t -> _ t -> _ t tzresult
end

module Type_size : TYPE_SIZE = struct
  type 'a t = int

  let () =
    (* static-like check that all [t] values fit in a [mul_safe] *)
    let (_ : Saturation_repr.mul_safe Saturation_repr.t) =
      Saturation_repr.mul_safe_of_int_exn Constants.michelson_maximum_type_size
    in
    ()

  let to_int = Saturation_repr.mul_safe_of_int_exn

  let one = 1

  let two = 2

  let three = 3

  let four = 4

  let of_int loc size =
    let max_size = Constants.michelson_maximum_type_size in
    if Compare.Int.(size <= max_size) then ok size
    else error (Script_tc_errors.Type_too_large (loc, max_size))

  let compound1 loc size = of_int loc (1 + size)

  let compound2 loc size1 size2 = of_int loc (1 + size1 + size2)
end

type empty_cell = EmptyCell

type end_of_stack = empty_cell * empty_cell

type 'a ty_metadata = {size : 'a Type_size.t} [@@unboxed]

(*

   This signature contains the exact set of functions used in the
   protocol. We do not include all [Set.S] because this would
   increase the size of the first class modules used to represent
   [boxed_set].

   Warning: for any change in this signature, there must be a
   change in [Script_typed_ir_size.value_size] which updates
   [boxing_space] in the case for sets.

*)
module type Boxed_set_OPS = sig
  type t

  type elt

  val elt_size : elt -> int (* Gas_input_size.t *)

  val empty : t

  val add : elt -> t -> t

  val mem : elt -> t -> bool

  val remove : elt -> t -> t

  val fold : (elt -> 'a -> 'a) -> t -> 'a -> 'a
end

module type Boxed_set = sig
  type elt

  module OPS : Boxed_set_OPS with type elt = elt

  val boxed : OPS.t

  val size : int
end

type 'elt set = Set_tag of (module Boxed_set with type elt = 'elt)
[@@ocaml.unboxed]

(*

   Same remark as for [Boxed_set_OPS]. (See below.)

*)
module type Boxed_map_OPS = sig
  type 'a t

  type key

  val key_size : key -> int (* Gas_input_size.t *)

  val empty : 'value t

  val add : key -> 'value -> 'value t -> 'value t

  val remove : key -> 'value t -> 'value t

  val find : key -> 'value t -> 'value option

  val fold : (key -> 'value -> 'a -> 'a) -> 'value t -> 'a -> 'a

  val fold_es :
    (key -> 'value -> 'a -> 'a tzresult Lwt.t) ->
    'value t ->
    'a ->
    'a tzresult Lwt.t
end

module type Boxed_map = sig
  type key

  type value

  module OPS : Boxed_map_OPS with type key = key

  val boxed : value OPS.t

  val size : int
end

type ('key, 'value) map =
  | Map_tag of (module Boxed_map with type key = 'key and type value = 'value)
[@@ocaml.unboxed]

module Big_map_overlay = Map.Make (struct
  type t = Script_expr_hash.t

  let compare = Script_expr_hash.compare
end)

type ('key, 'value) big_map_overlay = {
  map : ('key * 'value option) Big_map_overlay.t;
  size : int;
}

type 'elt boxed_list = {elements : 'elt list; length : int}

type view = {
  input_ty : Script.node;
  output_ty : Script.node;
  view_code : Script.node;
}

type view_map = (Script_string.t, view) map

type entrypoint_info = {name : Entrypoint.t; original_type_expr : Script.node}

type 'arg entrypoints_node = {
  at_node : entrypoint_info option;
  nested : 'arg nested_entrypoints;
}

and 'arg nested_entrypoints =
  | Entrypoints_Union : {
      left : 'l entrypoints_node;
      right : 'r entrypoints_node;
    }
      -> ('l, 'r) union nested_entrypoints
  | Entrypoints_None : _ nested_entrypoints

let no_entrypoints = {at_node = None; nested = Entrypoints_None}

type logging_event = LogEntry | LogExit of Script.location

type 'arg entrypoints = {
  root : 'arg entrypoints_node;
  original_type_expr : Script.node;
}

module rec Ty_value : sig
  type _ t =
    | Unit_t : (unit * yes) t
    | Int_t : (z num * yes) t
    | Nat_t : (n num * yes) t
    | Signature_t : (signature * yes) t
    | String_t : (Script_string.t * yes) t
    | Bytes_t : (bytes * yes) t
    | Mutez_t : (Tez.t * yes) t
    | Key_hash_t : (public_key_hash * yes) t
    | Key_t : (public_key * yes) t
    | Timestamp_t : (Script_timestamp.t * yes) t
    | Address_t : (address * yes) t
    | Tx_rollup_l2_address_t : (tx_rollup_l2_address * yes) t
    | Bool_t : (bool * yes) t
    | Pair_t :
        ('a * 'ac) Ty.t
        * ('b * 'bc) Ty.t
        * ('a, 'b) pair ty_metadata
        * ('ac, 'bc, 'rc) dand
        -> (('a, 'b) pair * 'rc) t
    | Union_t :
        ('a * 'ac) Ty.t
        * ('b * 'bc) Ty.t
        * ('a, 'b) union ty_metadata
        * ('ac, 'bc, 'rc) dand
        -> (('a, 'b) union * 'rc) t
    | Lambda_t :
        ('arg * _) Ty.t * ('ret * _) Ty.t * ('arg, 'ret) Lambda.t ty_metadata
        -> (('arg, 'ret) Lambda.t * no) t
    | Option_t :
        ('v * 'c) Ty.t * 'v option ty_metadata * 'c dbool
        -> ('v option * 'c) t
    | List_t :
        ('v * _) Ty.t * 'v boxed_list ty_metadata
        -> ('v boxed_list * no) t
    | Set_t : ('v * yes) Ty.t * 'v set ty_metadata -> ('v set * no) t
    | Map_t :
        ('k * yes) Ty.t * ('v * _) Ty.t * ('k, 'v) map ty_metadata
        -> (('k, 'v) map * no) t
    | Big_map_t :
        ('k * yes) Ty.t * ('v * _) Ty.t * ('k, 'v) Big_map.t ty_metadata
        -> (('k, 'v) Big_map.t * no) t
    | Contract_t :
        ('arg * _) Ty.t * 'arg Typed_contract.t ty_metadata
        -> ('arg Typed_contract.t * no) t
    | Sapling_transaction_t :
        Sapling.Memo_size.t
        -> (Sapling.transaction * no) t
    | Sapling_transaction_deprecated_t :
        Sapling.Memo_size.t
        -> (Sapling.Legacy.transaction * no) t
    | Sapling_state_t : Sapling.Memo_size.t -> (Sapling.state * no) t
    | Operation_t : (Operation.t * no) t
    | Chain_id_t : (Script_chain_id.t * yes) t
    | Never_t : (never * yes) t
    | Bls12_381_g1_t : (Script_bls.G1.t * no) t
    | Bls12_381_g2_t : (Script_bls.G2.t * no) t
    | Bls12_381_fr_t : (Script_bls.Fr.t * no) t
    | Ticket_t : ('a * yes) Ty.t * 'a ticket ty_metadata -> ('a ticket * no) t
    | Chest_key_t : (Script_timelock.chest_key * no) t
    | Chest_t : (Script_timelock.chest * no) t

  type _ s =
    | Bot_t : (empty_cell * empty_cell) s
    | Item_t : ('a * _) Ty.t * ('top * 'rest) Ty.s -> ('a * ('top * 'rest)) s

  val is_comparable : ('a * 'ac) t -> 'ac dbool
end = struct
  type _ t =
    | Unit_t : (unit * yes) t
    | Int_t : (z num * yes) t
    | Nat_t : (n num * yes) t
    | Signature_t : (signature * yes) t
    | String_t : (Script_string.t * yes) t
    | Bytes_t : (bytes * yes) t
    | Mutez_t : (Tez.t * yes) t
    | Key_hash_t : (public_key_hash * yes) t
    | Key_t : (public_key * yes) t
    | Timestamp_t : (Script_timestamp.t * yes) t
    | Address_t : (address * yes) t
    | Tx_rollup_l2_address_t : (tx_rollup_l2_address * yes) t
    | Bool_t : (bool * yes) t
    | Pair_t :
        ('a * 'ac) Ty.t
        * ('b * 'bc) Ty.t
        * ('a, 'b) pair ty_metadata
        * ('ac, 'bc, 'rc) dand
        -> (('a, 'b) pair * 'rc) t
    | Union_t :
        ('a * 'ac) Ty.t
        * ('b * 'bc) Ty.t
        * ('a, 'b) union ty_metadata
        * ('ac, 'bc, 'rc) dand
        -> (('a, 'b) union * 'rc) t
    | Lambda_t :
        ('arg * _) Ty.t * ('ret * _) Ty.t * ('arg, 'ret) Lambda.t ty_metadata
        -> (('arg, 'ret) Lambda.t * no) t
    | Option_t :
        ('v * 'c) Ty.t * 'v option ty_metadata * 'c dbool
        -> ('v option * 'c) t
    | List_t :
        ('v * _) Ty.t * 'v boxed_list ty_metadata
        -> ('v boxed_list * no) t
    | Set_t : ('v * yes) Ty.t * 'v set ty_metadata -> ('v set * no) t
    | Map_t :
        ('k * yes) Ty.t * ('v * _) Ty.t * ('k, 'v) map ty_metadata
        -> (('k, 'v) map * no) t
    | Big_map_t :
        ('k * yes) Ty.t * ('v * _) Ty.t * ('k, 'v) Big_map.t ty_metadata
        -> (('k, 'v) Big_map.t * no) t
    | Contract_t :
        ('arg * _) Ty.t * 'arg Typed_contract.t ty_metadata
        -> ('arg Typed_contract.t * no) t
    | Sapling_transaction_t :
        Sapling.Memo_size.t
        -> (Sapling.transaction * no) t
    | Sapling_transaction_deprecated_t :
        Sapling.Memo_size.t
        -> (Sapling.Legacy.transaction * no) t
    | Sapling_state_t : Sapling.Memo_size.t -> (Sapling.state * no) t
    | Operation_t : (Operation.t * no) t
    | Chain_id_t : (Script_chain_id.t * yes) t
    | Never_t : (never * yes) t
    | Bls12_381_g1_t : (Script_bls.G1.t * no) t
    | Bls12_381_g2_t : (Script_bls.G2.t * no) t
    | Bls12_381_fr_t : (Script_bls.Fr.t * no) t
    | Ticket_t : ('a * yes) Ty.t * 'a ticket ty_metadata -> ('a ticket * no) t
    | Chest_key_t : (Script_timelock.chest_key * no) t
    | Chest_t : (Script_timelock.chest * no) t

  type _ s =
    | Bot_t : (empty_cell * empty_cell) s
    | Item_t : ('a * _) Ty.t * ('top * 'rest) Ty.s -> ('a * ('top * 'rest)) s

  let is_comparable : type a ac. (a * ac) t -> ac dbool = function
    | Unit_t -> Yes
    | Int_t -> Yes
    | Nat_t -> Yes
    | Signature_t -> Yes
    | String_t -> Yes
    | Bytes_t -> Yes
    | Mutez_t -> Yes
    | Key_hash_t -> Yes
    | Key_t -> Yes
    | Timestamp_t -> Yes
    | Address_t -> Yes
    | Tx_rollup_l2_address_t -> Yes
    | Bool_t -> Yes
    | Pair_t (_, _, _, dand) -> dbool_of_dand dand
    | Union_t (_, _, _, dand) -> dbool_of_dand dand
    | Lambda_t _ -> No
    | Option_t (_, _, cmp) -> cmp
    | List_t _ -> No
    | Set_t _ -> No
    | Map_t _ -> No
    | Big_map_t _ -> No
    | Contract_t _ -> No
    | Sapling_transaction_t _ -> No
    | Sapling_transaction_deprecated_t _ -> No
    | Sapling_state_t _ -> No
    | Operation_t -> No
    | Chain_id_t -> Yes
    | Never_t -> Yes
    | Bls12_381_g1_t -> No
    | Bls12_381_g2_t -> No
    | Bls12_381_fr_t -> No
    | Ticket_t _ -> No
    | Chest_key_t -> No
    | Chest_t -> No
end

and Ty : sig
  type 'a t = 'a Michelson_type_constructor.HashConsing(Ty_value).t

  type ('a, 'ac) ty = ('a * 'ac) t

  type 'a s = 'a Michelson_type_constructor.HashConsing(Ty_value).s

  type ('top, 'rest) stack = ('top * 'rest) s

  type 'a comparable_ty = ('a, yes) ty

  type _ ty_ex_c = Ty_ex_c : ('a, _) ty -> 'a ty_ex_c [@@unboxed]

  val is_comparable : ('a, 'ac) ty -> 'ac dbool

  val ty_size : ('a, _) ty -> 'a Type_size.t

  val unit_t : unit comparable_ty

  val int_t : z num comparable_ty

  val nat_t : n num comparable_ty

  val signature_t : signature comparable_ty

  val string_t : Script_string.t comparable_ty

  val bytes_t : bytes comparable_ty

  val mutez_t : Tez.t comparable_ty

  val key_hash_t : public_key_hash comparable_ty

  val key_t : public_key comparable_ty

  val timestamp_t : Script_timestamp.t comparable_ty

  val address_t : address comparable_ty

  val tx_rollup_l2_address_t : tx_rollup_l2_address comparable_ty

  val bool_t : bool comparable_ty

  val pair_t :
    Script.location ->
    ('a, _) ty ->
    ('b, _) ty ->
    ('a, 'b) pair ty_ex_c tzresult

  val pair_3_t :
    Script.location ->
    ('a, _) ty ->
    ('b, _) ty ->
    ('c, _) ty ->
    ('a, ('b, 'c) pair) pair ty_ex_c tzresult

  val comparable_pair_t :
    Script.location ->
    'a comparable_ty ->
    'b comparable_ty ->
    ('a, 'b) pair comparable_ty tzresult

  val comparable_pair_3_t :
    Script.location ->
    'a comparable_ty ->
    'b comparable_ty ->
    'c comparable_ty ->
    ('a, ('b, 'c) pair) pair comparable_ty tzresult

  val union_t :
    Script.location ->
    ('a, _) ty ->
    ('b, _) ty ->
    ('a, 'b) union ty_ex_c tzresult

  val comparable_union_t :
    Script.location ->
    'a comparable_ty ->
    'b comparable_ty ->
    ('a, 'b) union comparable_ty tzresult

  val union_bytes_bool_t : (bytes, bool) union comparable_ty

  val lambda_t :
    Script.location ->
    ('arg, _) ty ->
    ('ret, _) ty ->
    (('arg, 'ret) Lambda.t, no) ty tzresult

  val option_t : Script.location -> ('v, 'c) ty -> ('v option, 'c) ty tzresult

  val comparable_option_t :
    Script.location -> 'v comparable_ty -> 'v option comparable_ty tzresult

  val option_mutez_t : Tez.t option comparable_ty

  val option_string_t : Script_string.t option comparable_ty

  val option_bytes_t : Bytes.t option comparable_ty

  val option_nat_t : n num option comparable_ty

  val option_pair_nat_nat_t : (n num, n num) pair option comparable_ty

  val option_pair_nat_mutez_t : (n num, Tez.t) pair option comparable_ty

  val option_pair_mutez_mutez_t : (Tez.t, Tez.t) pair option comparable_ty

  val option_pair_int_nat_t : (z num, n num) pair option comparable_ty

  val list_t : Script.location -> ('v, _) ty -> ('v boxed_list, no) ty tzresult

  val operation_t : (Operation.t, no) ty

  val list_operation_t : (Operation.t boxed_list, no) ty

  val set_t : Script.location -> 'v comparable_ty -> ('v set, no) ty tzresult

  val map_t :
    Script.location ->
    'k comparable_ty ->
    ('v, _) ty ->
    (('k, 'v) map, no) ty tzresult

  val big_map_t :
    Script.location ->
    'k comparable_ty ->
    ('v, _) ty ->
    (('k, 'v) Big_map.t, no) ty tzresult

  val contract_t :
    Script.location -> ('arg, _) ty -> ('arg Typed_contract.t, no) ty tzresult

  val contract_unit_t : (unit Typed_contract.t, no) ty

  val sapling_transaction_t :
    memo_size:Sapling.Memo_size.t -> (Sapling.transaction, no) ty

  val sapling_transaction_deprecated_t :
    memo_size:Sapling.Memo_size.t -> (Sapling.Legacy.transaction, no) ty

  val sapling_state_t : memo_size:Sapling.Memo_size.t -> (Sapling.state, no) ty

  val chain_id_t : Script_chain_id.t comparable_ty

  val never_t : never comparable_ty

  val bls12_381_g1_t : (Script_bls.G1.t, no) ty

  val bls12_381_g2_t : (Script_bls.G2.t, no) ty

  val bls12_381_fr_t : (Script_bls.Fr.t, no) ty

  val ticket_t :
    Script.location -> 'arg comparable_ty -> ('arg ticket, no) ty tzresult

  val chest_key_t : (Script_timelock.chest_key, no) ty

  val chest_t : (Script_timelock.chest, no) ty

  type 'a ty_traverse = {apply : 'b 'bc. 'a -> ('b, 'bc) ty -> 'a}

  val ty_traverse : ('a, 'ac) ty -> 'accu -> 'accu ty_traverse -> 'accu

  type 'a ty_value_traverse = {apply : 'b 'bc. 'a -> ('b, 'bc) ty -> 'b -> 'a}

  val ty_value_traverse :
    ('a, 'ac) ty -> 'a -> 'accu -> 'accu ty_value_traverse -> 'accu

  val bot_t : (empty_cell, empty_cell) stack

  val stack_t : ('a, _) ty -> ('top, 'rest) stack -> ('a, 'top * 'rest) stack

  val stack_top : ('a, 'b * 'r) stack -> 'a ty_ex_c

  type 'accu stack_traverse = {
    apply : 'ty 'r. 'accu -> ('ty, 'r) stack -> 'accu;
  }

  val stack_traverse : ('a, 'r) stack -> 'accu -> 'accu stack_traverse -> 'accu
end = struct
  include Michelson_type_constructor.HashConsing (Ty_value)

  type ('a, 'ac) ty = ('a * 'ac) t

  type ('top, 'rest) stack = ('top * 'rest) s

  type 'a comparable_ty = ('a, yes) ty

  type _ ty_ex_c = Ty_ex_c : ('a, _) ty -> 'a ty_ex_c [@@unboxed]

  let is_comparable : type a ac. (a, ac) ty -> ac dbool =
   fun {value; _} -> Ty_value.is_comparable value

  let ty_size : type a ac. (a, ac) ty -> a Type_size.t =
   fun {value; _} ->
    match value with
    | Unit_t | Never_t | Int_t | Nat_t | Signature_t | String_t | Bytes_t
    | Mutez_t | Bool_t | Key_hash_t | Key_t | Timestamp_t | Chain_id_t
    | Address_t | Tx_rollup_l2_address_t ->
        Type_size.one
    | Pair_t (_, _, meta, _) -> meta.size
    | Union_t (_, _, meta, _) -> meta.size
    | Option_t (_, meta, _) -> meta.size
    | Lambda_t (_, _, meta) -> meta.size
    | List_t (_, meta) -> meta.size
    | Set_t (_, meta) -> meta.size
    | Map_t (_, _, meta) -> meta.size
    | Big_map_t (_, _, meta) -> meta.size
    | Ticket_t (_, meta) -> meta.size
    | Contract_t (_, meta) -> meta.size
    | Sapling_transaction_t _ | Sapling_transaction_deprecated_t _
    | Sapling_state_t _ | Operation_t | Bls12_381_g1_t | Bls12_381_g2_t
    | Bls12_381_fr_t | Chest_t | Chest_key_t ->
        Type_size.one

  let unit_t = constant_t Unit_t

  let int_t = constant_t Int_t

  let nat_t = constant_t Nat_t

  let signature_t = constant_t Signature_t

  let string_t = constant_t String_t

  let bytes_t = constant_t Bytes_t

  let mutez_t = constant_t Mutez_t

  let key_hash_t = constant_t Key_hash_t

  let key_t = constant_t Key_t

  let timestamp_t = constant_t Timestamp_t

  let address_t = constant_t Address_t

  let tx_rollup_l2_address_t = constant_t Tx_rollup_l2_address_t

  let bool_t = constant_t Bool_t

  module Pair_Input = struct
    type (_, _, _) witness =
      | W :
          ('a, 'b) pair ty_metadata * ('ac, 'bc, 'rc) dand
          -> ('a * 'ac, 'b * 'bc, ('a, 'b) pair * 'rc) witness

    let witness_is_a_function :
        type a b c1 c2.
        (a, b, c1) witness ->
        (a, b, c2) witness ->
        (c1, c2) Michelson_type_constructor.eq =
     fun (W (_m1, d1)) (W (_m2, d2)) ->
      let Eq = merge_dand d1 d2 in
      Michelson_type_constructor.Refl

    let mk : type a b c. a t -> b t -> (a, b, c) witness -> c Ty_value.t =
     fun i1 i2 (W (m, d)) -> Ty_value.Pair_t (i1, i2, m, d)
  end

  module Pair = Parametric2 (Pair_Input)

  let pair_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    let (Ex_dand d) = dand (is_comparable i1) (is_comparable i2) in
    Ty_ex_c (Pair.mk i1 i2 (W (m, d)))

  let pair_3_t loc i1 i2 i3 =
    let open Result_syntax in
    let* (Ty_ex_c i2) = pair_t loc i2 i3 in
    pair_t loc i1 i2

  let comparable_pair_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    Pair.mk i1 i2 (W (m, YesYes))

  let comparable_pair_3_t loc i1 i2 i3 =
    let open Result_syntax in
    let* i2 = comparable_pair_t loc i2 i3 in
    comparable_pair_t loc i1 i2

  module Union_Input = struct
    type (_, _, _) witness =
      | W :
          ('a, 'b) union ty_metadata * ('ac, 'bc, 'rc) dand
          -> ('a * 'ac, 'b * 'bc, ('a, 'b) union * 'rc) witness

    let witness_is_a_function :
        type a b c1 c2.
        (a, b, c1) witness ->
        (a, b, c2) witness ->
        (c1, c2) Michelson_type_constructor.eq =
     fun (W (_m1, d1)) (W (_m2, d2)) ->
      let Eq = merge_dand d1 d2 in
      Michelson_type_constructor.Refl

    let mk : type a b c. a t -> b t -> (a, b, c) witness -> c Ty_value.t =
     fun i1 i2 (W (m, d)) -> Ty_value.Union_t (i1, i2, m, d)
  end

  module Union = Parametric2 (Union_Input)

  let union_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    let (Ex_dand d) = dand (is_comparable i1) (is_comparable i2) in
    Ty_ex_c (Union.mk i1 i2 (W (m, d)))

  let comparable_union_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    Union.mk i1 i2 (W (m, YesYes))

  let union_bytes_bool_t =
    let size = Type_size.three in
    let m = {size} in
    Union.mk bytes_t bool_t (W (m, YesYes))

  module Lambda_Input = struct
    type (_, _, _) witness =
      | W :
          ('a, 'b) Lambda.t ty_metadata
          -> ('a * _, 'b * _, ('a, 'b) Lambda.t * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b c1 c2.
        (a, b, c1) witness ->
        (a, b, c2) witness ->
        (c1, c2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b c. a t -> b t -> (a, b, c) witness -> c Ty_value.t =
     fun i1 i2 (W m) -> Ty_value.Lambda_t (i1, i2, m)
  end

  module Lambda = Parametric2 (Lambda_Input)

  let lambda_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    Lambda.mk i1 i2 (W m)

  module Option_Input = struct
    type (_, _) witness =
      | W : 'a option ty_metadata -> ('a * 'ac, 'a option * 'ac) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b1 b2.
        (a, b1) witness ->
        (a, b2) witness ->
        (b1, b2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b. a t -> (a, b) witness -> b Ty_value.t =
     fun i (W m) -> Ty_value.Option_t (i, m, is_comparable i)
  end

  module Option = Parametric1 (Option_Input)

  let option_t loc i =
    let open Result_syntax in
    let+ size = Type_size.compound1 loc (ty_size i) in
    let m = {size} in
    Option.mk i (W m)

  let comparable_option_t = option_t

  let option_mutez_t =
    let size = Type_size.two in
    let m = {size} in
    Option.mk mutez_t (W m)

  let option_string_t =
    let size = Type_size.two in
    let m = {size} in
    Option.mk string_t (W m)

  let option_bytes_t =
    let size = Type_size.two in
    let m = {size} in
    Option.mk bytes_t (W m)

  let option_nat_t =
    let size = Type_size.two in
    let m = {size} in
    Option.mk nat_t (W m)

  let option_pair_nat_nat_t =
    let size = Type_size.three in
    let m = {size} in
    let pair_nat_nat_t = Pair.mk nat_t nat_t (W (m, YesYes)) in
    let size = Type_size.four in
    let m = {size} in
    Option.mk pair_nat_nat_t (W m)

  let option_pair_nat_mutez_t =
    let size = Type_size.three in
    let m = {size} in
    let pair_nat_mutez_t = Pair.mk nat_t mutez_t (W (m, YesYes)) in
    let size = Type_size.four in
    let m = {size} in
    Option.mk pair_nat_mutez_t (W m)

  let option_pair_mutez_mutez_t =
    let size = Type_size.three in
    let m = {size} in
    let pair_mutez_mutez_t = Pair.mk mutez_t mutez_t (W (m, YesYes)) in
    let size = Type_size.four in
    let m = {size} in
    Option.mk pair_mutez_mutez_t (W m)

  let option_pair_int_nat_t =
    let size = Type_size.three in
    let m = {size} in
    let pair_int_nat_t = Pair.mk int_t nat_t (W (m, YesYes)) in
    let size = Type_size.four in
    let m = {size} in
    Option.mk pair_int_nat_t (W m)

  module List_Input = struct
    type (_, _) witness =
      | W : 'a boxed_list ty_metadata -> ('a * _, 'a boxed_list * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b1 b2.
        (a, b1) witness ->
        (a, b2) witness ->
        (b1, b2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b. a t -> (a, b) witness -> b Ty_value.t =
     fun i (W m) -> Ty_value.List_t (i, m)
  end

  module List = Parametric1 (List_Input)

  let list_t loc i =
    let open Result_syntax in
    let+ size = Type_size.compound1 loc (ty_size i) in
    let m = {size} in
    List.mk i (W m)

  let operation_t = constant_t Operation_t

  let list_operation_t =
    let size = Type_size.two in
    let m = {size} in
    List.mk operation_t (W m)

  module Set_Input = struct
    type (_, _) witness =
      | W : 'a set ty_metadata -> ('a * yes, 'a set * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b1 b2.
        (a, b1) witness ->
        (a, b2) witness ->
        (b1, b2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b. a t -> (a, b) witness -> b Ty_value.t =
     fun i (W m) -> Ty_value.Set_t (i, m)
  end

  module Set = Parametric1 (Set_Input)

  let set_t loc i =
    let open Result_syntax in
    let+ size = Type_size.compound1 loc (ty_size i) in
    let m = {size} in
    Set.mk i (W m)

  module Map_Input = struct
    type (_, _, _) witness =
      | W :
          ('a, 'b) map ty_metadata
          -> ('a * yes, 'b * _, ('a, 'b) map * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b c1 c2.
        (a, b, c1) witness ->
        (a, b, c2) witness ->
        (c1, c2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b c. a t -> b t -> (a, b, c) witness -> c Ty_value.t =
     fun i1 i2 (W m) -> Ty_value.Map_t (i1, i2, m)
  end

  module Map = Parametric2 (Map_Input)

  let map_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    Map.mk i1 i2 (W m)

  module Big_map_Input = struct
    type (_, _, _) witness =
      | W :
          ('a, 'b) Big_map.t ty_metadata
          -> ('a * yes, 'b * _, ('a, 'b) Big_map.t * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b c1 c2.
        (a, b, c1) witness ->
        (a, b, c2) witness ->
        (c1, c2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b c. a t -> b t -> (a, b, c) witness -> c Ty_value.t =
     fun i1 i2 (W m) -> Ty_value.Big_map_t (i1, i2, m)
  end

  module Big_map = Parametric2 (Big_map_Input)

  let big_map_t loc i1 i2 =
    let open Result_syntax in
    let+ size = Type_size.compound2 loc (ty_size i1) (ty_size i2) in
    let m = {size} in
    Big_map.mk i1 i2 (W m)

  module Contract_Input = struct
    type (_, _) witness =
      | W :
          'a Typed_contract.t ty_metadata
          -> ('a * _, 'a Typed_contract.t * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b1 b2.
        (a, b1) witness ->
        (a, b2) witness ->
        (b1, b2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b. a t -> (a, b) witness -> b Ty_value.t =
     fun i (W m) -> Ty_value.Contract_t (i, m)
  end

  module Contract = Parametric1 (Contract_Input)

  let contract_t loc i =
    let open Result_syntax in
    let+ size = Type_size.compound1 loc (ty_size i) in
    let m = {size} in
    Contract.mk i (W m)

  let contract_unit_t =
    let size = Type_size.two in
    let m = {size} in
    Contract.mk unit_t (W m)

  module Sapling_transaction = Parametric1_Type (struct
    type t = Sapling.Memo_size.t

    type v = Sapling.transaction * no

    let mk i = Ty_value.Sapling_transaction_t i
  end)

  let sapling_transaction_t ~memo_size:i = Sapling_transaction.mk i

  module Sapling_transaction_deprecated = Parametric1_Type (struct
    type t = Sapling.Memo_size.t

    type v = Sapling.Legacy.transaction * no

    let mk i = Ty_value.Sapling_transaction_deprecated_t i
  end)

  let sapling_transaction_deprecated_t ~memo_size:i =
    Sapling_transaction_deprecated.mk i

  module Sapling_state = Parametric1_Type (struct
    type t = Sapling.Memo_size.t

    type v = Sapling.state * no

    let mk i = Ty_value.Sapling_state_t i
  end)

  let sapling_state_t ~memo_size:i = Sapling_state.mk i

  let chain_id_t = constant_t Chain_id_t

  let never_t = constant_t Never_t

  let bls12_381_g1_t = constant_t Bls12_381_g1_t

  let bls12_381_g2_t = constant_t Bls12_381_g2_t

  let bls12_381_fr_t = constant_t Bls12_381_fr_t

  module Ticket_Input = struct
    type (_, _) witness =
      | W : 'a ticket ty_metadata -> ('a * yes, 'a ticket * no) witness
    [@@unboxed]

    let witness_is_a_function :
        type a b1 b2.
        (a, b1) witness ->
        (a, b2) witness ->
        (b1, b2) Michelson_type_constructor.eq =
     fun (W _m1) (W _m2) -> Michelson_type_constructor.Refl

    let mk : type a b. a t -> (a, b) witness -> b Ty_value.t =
     fun i (W m) -> Ty_value.Ticket_t (i, m)
  end

  module Ticket = Parametric1 (Ticket_Input)

  let ticket_t loc i =
    let open Result_syntax in
    let+ size = Type_size.compound1 loc (ty_size i) in
    let m = {size} in
    Ticket.mk i (W m)

  let chest_key_t = constant_t Chest_key_t

  let chest_t = constant_t Chest_t

  type 'a ty_traverse = {apply : 'b 'bc. 'a -> ('b, 'bc) ty -> 'a}

  let ty_traverse =
    let rec aux :
        type ret a ac accu.
        accu ty_traverse -> accu -> (a, ac) ty -> (accu -> ret) -> ret =
     fun f accu ty continue ->
      let accu = f.apply accu ty in
      match ty.value with
      | Unit_t | Int_t | Nat_t | Signature_t | String_t | Bytes_t | Mutez_t
      | Key_hash_t | Key_t | Timestamp_t | Address_t | Tx_rollup_l2_address_t
      | Bool_t | Sapling_transaction_t _ | Sapling_transaction_deprecated_t _
      | Sapling_state_t _ | Operation_t | Chain_id_t | Never_t | Bls12_381_g1_t
      | Bls12_381_g2_t | Bls12_381_fr_t ->
          (continue [@ocaml.tailcall]) accu
      | Ticket_t (cty, _) -> aux f accu cty continue
      | Chest_key_t | Chest_t -> (continue [@ocaml.tailcall]) accu
      | Pair_t (ty1, ty2, _, _) ->
          (next2 [@ocaml.tailcall]) f accu ty1 ty2 continue
      | Union_t (ty1, ty2, _, _) ->
          (next2 [@ocaml.tailcall]) f accu ty1 ty2 continue
      | Lambda_t (ty1, ty2, _) ->
          (next2 [@ocaml.tailcall]) f accu ty1 ty2 continue
      | Option_t (ty1, _, _) -> (next [@ocaml.tailcall]) f accu ty1 continue
      | List_t (ty1, _) -> (next [@ocaml.tailcall]) f accu ty1 continue
      | Set_t (cty, _) -> (aux [@ocaml.tailcall]) f accu cty continue
      | Map_t (cty, ty1, _) ->
          (aux [@ocaml.tailcall]) f accu cty (fun accu ->
              (next [@ocaml.tailcall]) f accu ty1 continue)
      | Big_map_t (cty, ty1, _) ->
          (aux [@ocaml.tailcall]) f accu cty (fun accu ->
              (next [@ocaml.tailcall]) f accu ty1 continue)
      | Contract_t (ty1, _) -> (next [@ocaml.tailcall]) f accu ty1 continue
    and next2 :
        type a ac b bc ret accu.
        accu ty_traverse ->
        accu ->
        (a * ac) t ->
        (b * bc) t ->
        (accu -> ret) ->
        ret =
     fun f accu ty1 ty2 continue ->
      (aux [@ocaml.tailcall]) f accu ty1 (fun accu ->
          (aux [@ocaml.tailcall]) f accu ty2 (fun accu ->
              (continue [@ocaml.tailcall]) accu))
    and next :
        type a ac ret accu.
        accu ty_traverse -> accu -> (a * ac) t -> (accu -> ret) -> ret =
     fun f accu ty1 continue ->
      (aux [@ocaml.tailcall]) f accu ty1 (fun accu ->
          (continue [@ocaml.tailcall]) accu)
    in
    fun ty init f -> aux f init ty (fun accu -> accu)

  type 'a ty_value_traverse = {apply : 'b 'bc. 'a -> ('b, 'bc) ty -> 'b -> 'a}

  let ty_value_traverse (type a ac) (ty : (a, ac) ty) (x : a) init f =
    let rec aux :
        type ret a ac. 'accu -> (a, ac) ty -> a -> ('accu -> ret) -> ret =
     fun accu ty x continue ->
      let accu = f.apply accu ty x in
      let next2 ty1 ty2 x1 x2 =
        (aux [@ocaml.tailcall]) accu ty1 x1 (fun accu ->
            (aux [@ocaml.tailcall]) accu ty2 x2 (fun accu ->
                (continue [@ocaml.tailcall]) accu))
      in
      let next ty1 x1 =
        (aux [@ocaml.tailcall]) accu ty1 x1 (fun accu ->
            (continue [@ocaml.tailcall]) accu)
      in
      let return () = (continue [@ocaml.tailcall]) accu in
      let rec on_list ty' accu = function
        | [] -> (continue [@ocaml.tailcall]) accu
        | x :: xs ->
            (aux [@ocaml.tailcall]) accu ty' x (fun accu ->
                (on_list [@ocaml.tailcall]) ty' accu xs)
      in
      match ty.value with
      | Unit_t | Int_t | Nat_t | Signature_t | String_t | Bytes_t | Mutez_t
      | Key_hash_t | Key_t | Timestamp_t | Address_t | Tx_rollup_l2_address_t
      | Bool_t | Sapling_transaction_t _ | Sapling_transaction_deprecated_t _
      | Sapling_state_t _ | Operation_t | Chain_id_t | Never_t | Bls12_381_g1_t
      | Bls12_381_g2_t | Bls12_381_fr_t | Chest_key_t | Chest_t
      | Lambda_t (_, _, _) ->
          (return [@ocaml.tailcall]) ()
      | Pair_t (ty1, ty2, _, _) ->
          (next2 [@ocaml.tailcall]) ty1 ty2 (fst x) (snd x)
      | Union_t (ty1, ty2, _, _) -> (
          match x with
          | L l -> (next [@ocaml.tailcall]) ty1 l
          | R r -> (next [@ocaml.tailcall]) ty2 r)
      | Option_t (ty, _, _) -> (
          match x with
          | None -> return ()
          | Some v -> (next [@ocaml.tailcall]) ty v)
      | Ticket_t (cty, _) ->
          (aux [@ocaml.tailcall]) accu cty x.contents continue
      | List_t (ty', _) -> on_list ty' accu x.elements
      | Map_t (kty, ty', _) ->
          let (Map_tag (module M)) = x in
          let bindings = M.OPS.fold (fun k v bs -> (k, v) :: bs) M.boxed [] in
          on_bindings accu kty ty' continue bindings
      | Set_t (ty', _) ->
          let (Set_tag (module M)) = x in
          let elements = M.OPS.fold (fun x s -> x :: s) M.boxed [] in
          on_list ty' accu elements
      | Big_map_t (_, _, _) ->
          (* For big maps, there is no obvious recursion scheme so we
             delegate this case to the client. *)
          (return [@ocaml.tailcall]) ()
      | Contract_t (_, _) -> (return [@ocaml.tailcall]) ()
    and on_bindings :
        type ret k v vc.
        'accu ->
        k comparable_ty ->
        (v * vc) t ->
        ('accu -> ret) ->
        (k * v) list ->
        ret =
     fun accu kty ty' continue xs ->
      match xs with
      | [] -> (continue [@ocaml.tailcall]) accu
      | (k, v) :: xs ->
          (aux [@ocaml.tailcall]) accu kty k (fun accu ->
              (aux [@ocaml.tailcall]) accu ty' v (fun accu ->
                  (on_bindings [@ocaml.tailcall]) accu kty ty' continue xs))
    in
    aux init ty x (fun accu -> accu)

  let bot_t = constant_s Bot_t

  module Stack_Input = struct
    type (_, _, _) witness =
      | W : ('a * _, 'top * 'rest, 'a * ('top * 'rest)) witness

    let witness_is_a_function :
        type a b c1 c2.
        (a, b, c1) witness ->
        (a, b, c2) witness ->
        (c1, c2) Michelson_type_constructor.eq =
     fun W W -> Michelson_type_constructor.Refl

    let mk : type a b c. a t -> b s -> (a, b, c) witness -> c Ty_value.s =
     fun ty s W -> Ty_value.Item_t (ty, s)
  end

  module Stack = Parametric_Stack (Stack_Input)

  let stack_t ty s = Stack.mk ty s W

  let stack_top : type a b r. (a, b * r) stack -> a ty_ex_c =
   fun {value = Item_t (t, _); _} -> Ty_ex_c t

  type 'accu stack_traverse = {
    apply : 'ty 's. 'accu -> ('ty, 's) stack -> 'accu;
  }

  let stack_traverse (type a r) (sty : (a, r) stack) init f =
    let rec aux : type b u. 'accu -> (b, u) stack -> 'accu =
     fun accu sty ->
      match sty.value with
      | Bot_t -> f.apply accu sty
      | Item_t (_, sty') -> aux (f.apply accu sty) sty'
    in
    aux init sty
end

(* ---- Instructions --------------------------------------------------------*)
and Instruction : sig
  type ('before_top, 'before, 'result_top, 'result) kinstr =
    (*
     Stack
     -----
  *)
    | IDrop :
        Script.location * ('b, 's, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IDup :
        Script.location * ('a, 'a * ('b * 's), 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | ISwap :
        Script.location * ('b, 'a * ('c * 's), 'r, 'f) kinstr
        -> ('a, 'b * ('c * 's), 'r, 'f) kinstr
    | IConst :
        Script.location * ('ty, _) Ty.ty * 'ty * ('ty, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    (*
     Pairs
     -----
  *)
    | ICons_pair :
        Script.location * ('a * 'b, 'c * 's, 'r, 'f) kinstr
        -> ('a, 'b * ('c * 's), 'r, 'f) kinstr
    | ICar :
        Script.location * ('a, 's, 'r, 'f) kinstr
        -> ('a * 'b, 's, 'r, 'f) kinstr
    | ICdr :
        Script.location * ('b, 's, 'r, 'f) kinstr
        -> ('a * 'b, 's, 'r, 'f) kinstr
    | IUnpair :
        Script.location * ('a, 'b * 's, 'r, 'f) kinstr
        -> ('a * 'b, 's, 'r, 'f) kinstr
    (*
     Options
     -------
   *)
    | ICons_some :
        Script.location * ('v option, 'a * 's, 'r, 'f) kinstr
        -> ('v, 'a * 's, 'r, 'f) kinstr
    | ICons_none :
        Script.location * ('b, _) Ty.ty * ('b option, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IIf_none : {
        loc : Script.location;
        branch_if_none : ('b, 's, 'c, 't) kinstr;
        branch_if_some : ('a, 'b * 's, 'c, 't) kinstr;
        k : ('c, 't, 'r, 'f) kinstr;
      }
        -> ('a option, 'b * 's, 'r, 'f) kinstr
    | IOpt_map : {
        loc : Script.location;
        body : ('a, 's, 'b, 's) kinstr;
        k : ('b option, 's, 'c, 't) kinstr;
      }
        -> ('a option, 's, 'c, 't) kinstr
    (*
     Unions
     ------
   *)
    | ICons_left :
        Script.location
        * ('b, _) Ty.ty
        * (('a, 'b) union, 'c * 's, 'r, 'f) kinstr
        -> ('a, 'c * 's, 'r, 'f) kinstr
    | ICons_right :
        Script.location
        * ('a, _) Ty.ty
        * (('a, 'b) union, 'c * 's, 'r, 'f) kinstr
        -> ('b, 'c * 's, 'r, 'f) kinstr
    | IIf_left : {
        loc : Script.location;
        branch_if_left : ('a, 's, 'c, 't) kinstr;
        branch_if_right : ('b, 's, 'c, 't) kinstr;
        k : ('c, 't, 'r, 'f) kinstr;
      }
        -> (('a, 'b) union, 's, 'r, 'f) kinstr
    (*
     Lists
     -----
  *)
    | ICons_list :
        Script.location * ('a boxed_list, 's, 'r, 'f) kinstr
        -> ('a, 'a boxed_list * 's, 'r, 'f) kinstr
    | INil :
        Script.location
        * ('b, _) Ty.ty
        * ('b boxed_list, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IIf_cons : {
        loc : Script.location;
        branch_if_cons : ('a, 'a boxed_list * ('b * 's), 'c, 't) kinstr;
        branch_if_nil : ('b, 's, 'c, 't) kinstr;
        k : ('c, 't, 'r, 'f) kinstr;
      }
        -> ('a boxed_list, 'b * 's, 'r, 'f) kinstr
    | IList_map :
        Script.location
        * ('a, 'c * 's, 'b, 'c * 's) kinstr
        * ('b boxed_list, _) Ty.ty
        * ('b boxed_list, 'c * 's, 'r, 'f) kinstr
        -> ('a boxed_list, 'c * 's, 'r, 'f) kinstr
    | IList_iter :
        Script.location
        * ('a, _) Ty.ty
        * ('a, 'b * 's, 'b, 's) kinstr
        * ('b, 's, 'r, 'f) kinstr
        -> ('a boxed_list, 'b * 's, 'r, 'f) kinstr
    | IList_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> ('a boxed_list, 's, 'r, 'f) kinstr
    (*
    Sets
    ----
  *)
    | IEmpty_set :
        Script.location * 'b Ty.comparable_ty * ('b set, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISet_iter :
        Script.location
        * 'a Ty.comparable_ty
        * ('a, 'b * 's, 'b, 's) kinstr
        * ('b, 's, 'r, 'f) kinstr
        -> ('a set, 'b * 's, 'r, 'f) kinstr
    | ISet_mem :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ('a, 'a set * 's, 'r, 'f) kinstr
    | ISet_update :
        Script.location * ('a set, 's, 'r, 'f) kinstr
        -> ('a, bool * ('a set * 's), 'r, 'f) kinstr
    | ISet_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> ('a set, 's, 'r, 'f) kinstr
    (*
     Maps
     ----
   *)
    | IEmpty_map :
        Script.location
        * 'b Ty.comparable_ty
        * ('c, _) Ty.ty
        * (('b, 'c) map, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IMap_map :
        Script.location
        * (('a, 'c) map, _) Ty.ty
        * ('a * 'b, 'd * 's, 'c, 'd * 's) kinstr
        * (('a, 'c) map, 'd * 's, 'r, 'f) kinstr
        -> (('a, 'b) map, 'd * 's, 'r, 'f) kinstr
    | IMap_iter :
        Script.location
        * ('a * 'b, _) Ty.ty
        * ('a * 'b, 'c * 's, 'c, 's) kinstr
        * ('c, 's, 'r, 'f) kinstr
        -> (('a, 'b) map, 'c * 's, 'r, 'f) kinstr
    | IMap_mem :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) map * 's, 'r, 'f) kinstr
    | IMap_get :
        Script.location * ('b option, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) map * 's, 'r, 'f) kinstr
    | IMap_update :
        Script.location * (('a, 'b) map, 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) map * 's), 'r, 'f) kinstr
    | IMap_get_and_update :
        Script.location * ('b option, ('a, 'b) map * 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) map * 's), 'r, 'f) kinstr
    | IMap_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (('a, 'b) map, 's, 'r, 'f) kinstr
    (*
     Big maps
     --------
  *)
    | IEmpty_big_map :
        Script.location
        * 'b Ty.comparable_ty
        * ('c, _) Ty.ty
        * (('b, 'c) Big_map.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IBig_map_mem :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) Big_map.t * 's, 'r, 'f) kinstr
    | IBig_map_get :
        Script.location * ('b option, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) Big_map.t * 's, 'r, 'f) kinstr
    | IBig_map_update :
        Script.location * (('a, 'b) Big_map.t, 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) Big_map.t * 's), 'r, 'f) kinstr
    | IBig_map_get_and_update :
        Script.location * ('b option, ('a, 'b) Big_map.t * 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) Big_map.t * 's), 'r, 'f) kinstr
    (*
     Strings
     -------
  *)
    | IConcat_string :
        Script.location * (Script_string.t, 's, 'r, 'f) kinstr
        -> (Script_string.t boxed_list, 's, 'r, 'f) kinstr
    | IConcat_string_pair :
        Script.location * (Script_string.t, 's, 'r, 'f) kinstr
        -> (Script_string.t, Script_string.t * 's, 'r, 'f) kinstr
    | ISlice_string :
        Script.location * (Script_string.t option, 's, 'r, 'f) kinstr
        -> (n num, n num * (Script_string.t * 's), 'r, 'f) kinstr
    | IString_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (Script_string.t, 's, 'r, 'f) kinstr
    (*
     Bytes
     -----
  *)
    | IConcat_bytes :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes boxed_list, 's, 'r, 'f) kinstr
    | IConcat_bytes_pair :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, bytes * 's, 'r, 'f) kinstr
    | ISlice_bytes :
        Script.location * (bytes option, 's, 'r, 'f) kinstr
        -> (n num, n num * (bytes * 's), 'r, 'f) kinstr
    | IBytes_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    (*
     Timestamps
     ----------
   *)
    | IAdd_seconds_to_timestamp :
        Script.location * (Script_timestamp.t, 's, 'r, 'f) kinstr
        -> (z num, Script_timestamp.t * 's, 'r, 'f) kinstr
    | IAdd_timestamp_to_seconds :
        Script.location * (Script_timestamp.t, 's, 'r, 'f) kinstr
        -> (Script_timestamp.t, z num * 's, 'r, 'f) kinstr
    | ISub_timestamp_seconds :
        Script.location * (Script_timestamp.t, 's, 'r, 'f) kinstr
        -> (Script_timestamp.t, z num * 's, 'r, 'f) kinstr
    | IDiff_timestamps :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> (Script_timestamp.t, Script_timestamp.t * 's, 'r, 'f) kinstr
    (*
     Tez
     ---
    *)
    | IAdd_tez :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | ISub_tez :
        Script.location * (Tez.t option, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | ISub_tez_legacy :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | IMul_teznat :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (Tez.t, n num * 's, 'r, 'f) kinstr
    | IMul_nattez :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (n num, Tez.t * 's, 'r, 'f) kinstr
    | IEdiv_teznat :
        Script.location * ((Tez.t, Tez.t) pair option, 's, 'r, 'f) kinstr
        -> (Tez.t, n num * 's, 'r, 'f) kinstr
    | IEdiv_tez :
        Script.location * ((n num, Tez.t) pair option, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    (*
     Booleans
     --------
   *)
    | IOr :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, bool * 's, 'r, 'f) kinstr
    | IAnd :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, bool * 's, 'r, 'f) kinstr
    | IXor :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, bool * 's, 'r, 'f) kinstr
    | INot :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, 's, 'r, 'f) kinstr
    (*
     Integers
     --------
  *)
    | IIs_nat :
        Script.location * (n num option, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | INeg :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 's, 'r, 'f) kinstr
    | IAbs_int :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IInt_nat :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> (n num, 's, 'r, 'f) kinstr
    | IAdd_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IAdd_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | ISub_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IMul_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IMul_nat :
        Script.location * ('a num, 's, 'r, 'f) kinstr
        -> (n num, 'a num * 's, 'r, 'f) kinstr
    | IEdiv_int :
        Script.location * ((z num, n num) pair option, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IEdiv_nat :
        Script.location * (('a num, n num) pair option, 's, 'r, 'f) kinstr
        -> (n num, 'a num * 's, 'r, 'f) kinstr
    | ILsl_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | ILsr_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | IOr_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    (* Even though `IAnd_nat` and `IAnd_int_nat` could be merged into a single
       instruction from both the type and behavior point of views, their gas costs
       differ too much (see `cost_N_IAnd_nat` and `cost_N_IAnd_int_nat` in
       `Michelson_v1_gas.Cost_of.Generated_costs`), so we keep them separated. *)
    | IAnd_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | IAnd_int_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (z num, n num * 's, 'r, 'f) kinstr
    | IXor_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | INot_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 's, 'r, 'f) kinstr
    (*
     Control
     -------
  *)
    | IIf : {
        loc : Script.location;
        branch_if_true : ('a, 's, 'b, 'u) kinstr;
        branch_if_false : ('a, 's, 'b, 'u) kinstr;
        k : ('b, 'u, 'r, 'f) kinstr;
      }
        -> (bool, 'a * 's, 'r, 'f) kinstr
    | ILoop :
        Script.location
        * ('a, 's, bool, 'a * 's) kinstr
        * ('a, 's, 'r, 'f) kinstr
        -> (bool, 'a * 's, 'r, 'f) kinstr
    | ILoop_left :
        Script.location
        * ('a, 's, ('a, 'b) union, 's) kinstr
        * ('b, 's, 'r, 'f) kinstr
        -> (('a, 'b) union, 's, 'r, 'f) kinstr
    | IDip :
        Script.location
        * ('b, 's, 'c, 't) kinstr
        * ('a, _) Ty.ty
        * ('a, 'c * 't, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IExec :
        Script.location * ('b, 's) Ty.stack * ('b, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) Lambda.t * 's, 'r, 'f) kinstr
    | IApply :
        Script.location * ('a, _) Ty.ty * (('b, 'c) Lambda.t, 's, 'r, 'f) kinstr
        -> ('a, ('a * 'b, 'c) Lambda.t * 's, 'r, 'f) kinstr
    | ILambda :
        Script.location
        * ('b, 'c) Lambda.t
        * (('b, 'c) Lambda.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IFailwith : Script.location * ('a, _) Ty.ty -> ('a, 's, 'r, 'f) kinstr
    (*
     Comparison
     ----------
  *)
    | ICompare :
        Script.location * 'a Ty.comparable_ty * (z num, 'b * 's, 'r, 'f) kinstr
        -> ('a, 'a * ('b * 's), 'r, 'f) kinstr
    (*
     Comparators
     -----------
  *)
    | IEq :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | INeq :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | ILt :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IGt :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | ILe :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IGe :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    (*
     Protocol
     --------
  *)
    | IAddress :
        Script.location * (address, 's, 'r, 'f) kinstr
        -> ('a Typed_contract.t, 's, 'r, 'f) kinstr
    | IContract :
        Script.location
        * ('a, _) Ty.ty
        * Entrypoint.t
        * ('a Typed_contract.t option, 's, 'r, 'f) kinstr
        -> (address, 's, 'r, 'f) kinstr
    | IView :
        Script.location
        * ('a, 'b) view_signature
        * ('b, 'c * 's) Ty.stack
        * ('b option, 'c * 's, 'r, 'f) kinstr
        -> ('a, address * ('c * 's), 'r, 'f) kinstr
    | ITransfer_tokens :
        Script.location * (Operation.t, 's, 'r, 'f) kinstr
        -> ('a, Tez.t * ('a Typed_contract.t * 's), 'r, 'f) kinstr
    | IImplicit_account :
        Script.location * (unit Typed_contract.t, 's, 'r, 'f) kinstr
        -> (public_key_hash, 's, 'r, 'f) kinstr
    | ICreate_contract : {
        loc : Script.location;
        storage_type : ('a, _) Ty.ty;
        code : Script.expr;
        k : (Operation.t, address * ('c * 's), 'r, 'f) kinstr;
      }
        -> (public_key_hash option, Tez.t * ('a * ('c * 's)), 'r, 'f) kinstr
    | ISet_delegate :
        Script.location * (Operation.t, 's, 'r, 'f) kinstr
        -> (public_key_hash option, 's, 'r, 'f) kinstr
    | INow :
        Script.location * (Script_timestamp.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IMin_block_time :
        Script.location * (n num, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IBalance :
        Script.location * (Tez.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ILevel :
        Script.location * (n num, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ICheck_signature :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (public_key, signature * (bytes * 's), 'r, 'f) kinstr
    | IHash_key :
        Script.location * (public_key_hash, 's, 'r, 'f) kinstr
        -> (public_key, 's, 'r, 'f) kinstr
    | IPack :
        Script.location * ('a, _) Ty.ty * (bytes, 'b * 's, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IUnpack :
        Script.location * ('a, _) Ty.ty * ('a option, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | IBlake2b :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISha256 :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISha512 :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISource :
        Script.location * (address, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISender :
        Script.location * (address, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISelf :
        Script.location
        * ('b, _) Ty.ty
        * Entrypoint.t
        * ('b Typed_contract.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISelf_address :
        Script.location * (address, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IAmount :
        Script.location * (Tez.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISapling_empty_state :
        Script.location
        * Sapling.Memo_size.t
        * (Sapling.state, 'a * 's, 'b, 'f) kinstr
        -> ('a, 's, 'b, 'f) kinstr
    | ISapling_verify_update :
        Script.location
        * ((bytes, (z num, Sapling.state) pair) pair option, 's, 'r, 'f) kinstr
        -> (Sapling.transaction, Sapling.state * 's, 'r, 'f) kinstr
    | ISapling_verify_update_deprecated :
        Script.location
        * ((z num, Sapling.state) pair option, 's, 'r, 'f) kinstr
        -> (Sapling.Legacy.transaction, Sapling.state * 's, 'r, 'f) kinstr
    | IDig :
        Script.location
        * int
        * ( 'b,
            'c * 't,
            'c,
            't,
            'a,
            's,
            'd,
            'u )
          stack_prefix_preservation_witness
        * ('b, 'd * 'u, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IDug :
        Script.location
        * int
        * ( 'c,
            't,
            'a,
            'c * 't,
            'b,
            's,
            'd,
            'u )
          stack_prefix_preservation_witness
        * ('d, 'u, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IDipn :
        Script.location
        * int
        * ('c, 't, 'd, 'v, 'a, 's, 'b, 'u) stack_prefix_preservation_witness
        * ('c, 't, 'd, 'v) kinstr
        * ('b, 'u, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IDropn :
        Script.location
        * int
        * ('b, 'u, 'b, 'u, 'a, 's, 'a, 's) stack_prefix_preservation_witness
        * ('b, 'u, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IChainId :
        Script.location * (Script_chain_id.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | INever : Script.location -> (never, 's, 'r, 'f) kinstr
    | IVoting_power :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (public_key_hash, 's, 'r, 'f) kinstr
    | ITotal_voting_power :
        Script.location * (n num, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IKeccak :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISha3 :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | IAdd_bls12_381_g1 :
        Script.location * (Script_bls.G1.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G1.t, Script_bls.G1.t * 's, 'r, 'f) kinstr
    | IAdd_bls12_381_g2 :
        Script.location * (Script_bls.G2.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G2.t, Script_bls.G2.t * 's, 'r, 'f) kinstr
    | IAdd_bls12_381_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_g1 :
        Script.location * (Script_bls.G1.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G1.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_g2 :
        Script.location * (Script_bls.G2.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G2.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_z_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, 'a num * 's, 'r, 'f) kinstr
    | IMul_bls12_381_fr_z :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> ('a num, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IInt_bls12_381_fr :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, 's, 'r, 'f) kinstr
    | INeg_bls12_381_g1 :
        Script.location * (Script_bls.G1.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G1.t, 's, 'r, 'f) kinstr
    | INeg_bls12_381_g2 :
        Script.location * (Script_bls.G2.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G2.t, 's, 'r, 'f) kinstr
    | INeg_bls12_381_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, 's, 'r, 'f) kinstr
    | IPairing_check_bls12_381 :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ( (Script_bls.G1.t, Script_bls.G2.t) pair boxed_list,
             's,
             'r,
             'f )
           kinstr
    | IComb :
        Script.location
        * int
        * ('a, 'b, 's, 'c, 'd, 't) comb_gadt_witness
        * ('c, 'd * 't, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IUncomb :
        Script.location
        * int
        * ('a, 'b, 's, 'c, 'd, 't) uncomb_gadt_witness
        * ('c, 'd * 't, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IComb_get :
        Script.location
        * int
        * ('t, 'v) comb_get_gadt_witness
        * ('v, 'a * 's, 'r, 'f) kinstr
        -> ('t, 'a * 's, 'r, 'f) kinstr
    | IComb_set :
        Script.location
        * int
        * ('a, 'b, 'c) comb_set_gadt_witness
        * ('c, 'd * 's, 'r, 'f) kinstr
        -> ('a, 'b * ('d * 's), 'r, 'f) kinstr
    | IDup_n :
        Script.location
        * int
        * ('a, 'b, 's, 't) dup_n_gadt_witness
        * ('t, 'a * ('b * 's), 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | ITicket :
        Script.location * 'a Ty.comparable_ty * ('a ticket, 's, 'r, 'f) kinstr
        -> ('a, n num * 's, 'r, 'f) kinstr
    | IRead_ticket :
        Script.location
        * 'a Ty.comparable_ty
        * (address * ('a * n num), 'a ticket * 's, 'r, 'f) kinstr
        -> ('a ticket, 's, 'r, 'f) kinstr
    | ISplit_ticket :
        Script.location * (('a ticket * 'a ticket) option, 's, 'r, 'f) kinstr
        -> ('a ticket, (n num * n num) * 's, 'r, 'f) kinstr
    | IJoin_tickets :
        Script.location
        * 'a Ty.comparable_ty
        * ('a ticket option, 's, 'r, 'f) kinstr
        -> ('a ticket * 'a ticket, 's, 'r, 'f) kinstr
    | IOpen_chest :
        Script.location * ((bytes, bool) union, 's, 'r, 'f) kinstr
        -> ( Script_timelock.chest_key,
             Script_timelock.chest * (n num * 's),
             'r,
             'f )
           kinstr
    | IEmit : {
        loc : Script.location;
        tag : Entrypoint.t;
        ty : ('a, _) Ty.ty;
        unparsed_ty : Script.expr;
        k : (Operation.t, 's, 'r, 'f) kinstr;
      }
        -> ('a, 's, 'r, 'f) kinstr
    (*
     Internal control instructions
     -----------------------------
  *)
    | IHalt : Script.location -> ('a, 's, 'a, 's) kinstr
    | ILog :
        Script.location
        * ('a, 's) Ty.stack
        * logging_event
        * logger
        * ('a, 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr

  and (_, _, _, _) continuation =
    | KNil : ('r, 'f, 'r, 'f) continuation
    | KCons :
        ('a, 's, 'b, 't) kinstr * ('b, 't, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KReturn :
        's * ('a, 's) Ty.stack * ('a, 's, 'r, 'f) continuation
        -> ('a, end_of_stack, 'r, 'f) continuation
    | KMap_head :
        ('a -> 'b) * ('b, 's, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KUndip :
        'b * ('b, _) Ty.ty * ('b, 'a * 's, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KLoop_in :
        ('a, 's, bool, 'a * 's) kinstr * ('a, 's, 'r, 'f) continuation
        -> (bool, 'a * 's, 'r, 'f) continuation
    | KLoop_in_left :
        ('a, 's, ('a, 'b) union, 's) kinstr * ('b, 's, 'r, 'f) continuation
        -> (('a, 'b) union, 's, 'r, 'f) continuation
    | KIter :
        ('a, 'b * 's, 'b, 's) kinstr
        * ('a, _) Ty.ty
        * 'a list
        * ('b, 's, 'r, 'f) continuation
        -> ('b, 's, 'r, 'f) continuation
    | KList_enter_body :
        ('a, 'c * 's, 'b, 'c * 's) kinstr
        * 'a list
        * 'b list
        * ('b boxed_list, _) Ty.ty
        * int
        * ('b boxed_list, 'c * 's, 'r, 'f) continuation
        -> ('c, 's, 'r, 'f) continuation
    | KList_exit_body :
        ('a, 'c * 's, 'b, 'c * 's) kinstr
        * 'a list
        * 'b list
        * ('b boxed_list, _) Ty.ty
        * int
        * ('b boxed_list, 'c * 's, 'r, 'f) continuation
        -> ('b, 'c * 's, 'r, 'f) continuation
    | KMap_enter_body :
        ('a * 'b, 'd * 's, 'c, 'd * 's) kinstr
        * ('a * 'b) list
        * ('a, 'c) map
        * (('a, 'c) map, _) Ty.ty
        * (('a, 'c) map, 'd * 's, 'r, 'f) continuation
        -> ('d, 's, 'r, 'f) continuation
    | KMap_exit_body :
        ('a * 'b, 'd * 's, 'c, 'd * 's) kinstr
        * ('a * 'b) list
        * ('a, 'c) map
        * 'a
        * (('a, 'c) map, _) Ty.ty
        * (('a, 'c) map, 'd * 's, 'r, 'f) continuation
        -> ('c, 'd * 's, 'r, 'f) continuation
    | KView_exit :
        step_constants * ('a, 's, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KLog :
        ('a, 's, 'r, 'f) continuation * ('a, 's) Ty.stack * logger
        -> ('a, 's, 'r, 'f) continuation

  and ('a, 's, 'b, 'f, 'c, 'u) logging_function =
    ('a, 's, 'b, 'f) kinstr ->
    context ->
    Script.location ->
    ('c, 'u) Ty.stack ->
    'c * 'u ->
    unit

  and execution_trace = (Script.location * Gas.t * Script.expr list) list

  and logger = {
    log_interp : 'a 's 'b 'f 'c 'u. ('a, 's, 'b, 'f, 'c, 'u) logging_function;
    log_entry : 'a 's 'b 'f. ('a, 's, 'b, 'f, 'a, 's) logging_function;
    log_control : 'a 's 'b 'f. ('a, 's, 'b, 'f) continuation -> unit;
    log_exit : 'a 's 'b 'f 'c 'u. ('a, 's, 'b, 'f, 'c, 'u) logging_function;
    get_log : unit -> execution_trace option tzresult Lwt.t;
  }

  and ('a, 's, 'r, 'f) kdescr = {
    kloc : Script.location;
    kbef : ('a, 's) Ty.stack;
    kaft : ('r, 'f) Ty.stack;
    kinstr : ('a, 's, 'r, 'f) kinstr;
  }

  and (_, _, _, _, _, _, _, _) stack_prefix_preservation_witness =
    | KPrefix :
        Script.location
        * ('a, _) Ty.ty
        * ('c, 'v, 'd, 'w, 'x, 's, 'y, 'u) stack_prefix_preservation_witness
        -> ( 'c,
             'v,
             'd,
             'w,
             'a,
             'x * 's,
             'a,
             'y * 'u )
           stack_prefix_preservation_witness
    | KRest : ('a, 's, 'b, 'u, 'a, 's, 'b, 'u) stack_prefix_preservation_witness

  and (_, _, _, _, _, _) comb_gadt_witness =
    | Comb_one : ('a, 'x, 'before, 'a, 'x, 'before) comb_gadt_witness
    | Comb_succ :
        ('b, 'c, 's, 'd, 'e, 't) comb_gadt_witness
        -> ('a, 'b, 'c * 's, 'a * 'd, 'e, 't) comb_gadt_witness

  and (_, _, _, _, _, _) uncomb_gadt_witness =
    | Uncomb_one : ('a, 'x, 'before, 'a, 'x, 'before) uncomb_gadt_witness
    | Uncomb_succ :
        ('b, 'c, 's, 'd, 'e, 't) uncomb_gadt_witness
        -> ('a * 'b, 'c, 's, 'a, 'd, 'e * 't) uncomb_gadt_witness

  and ('before, 'after) comb_get_gadt_witness =
    | Comb_get_zero : ('b, 'b) comb_get_gadt_witness
    | Comb_get_one : ('a * 'b, 'a) comb_get_gadt_witness
    | Comb_get_plus_two :
        ('before, 'after) comb_get_gadt_witness
        -> ('a * 'before, 'after) comb_get_gadt_witness

  and ('value, 'before, 'after) comb_set_gadt_witness =
    | Comb_set_zero : ('value, _, 'value) comb_set_gadt_witness
    | Comb_set_one : ('value, 'hd * 'tl, 'value * 'tl) comb_set_gadt_witness
    | Comb_set_plus_two :
        ('value, 'before, 'after) comb_set_gadt_witness
        -> ('value, 'a * 'before, 'a * 'after) comb_set_gadt_witness

  and (_, _, _, _) dup_n_gadt_witness =
    | Dup_n_zero : ('a, _, _, 'a) dup_n_gadt_witness
    | Dup_n_succ :
        ('b, 'c, 'stack, 'd) dup_n_gadt_witness
        -> ('a, 'b, 'c * 'stack, 'd) dup_n_gadt_witness

  and ('input, 'output) view_signature =
    | View_signature : {
        name : Script_string.t;
        input_ty : ('input, _) Ty.ty;
        output_ty : ('output, _) Ty.ty;
      }
        -> ('input, 'output) view_signature

  val kinstr_location : ('a, 's, 'b, 'f) kinstr -> Script.location

  type 'a kinstr_traverse = {
    apply : 'b 'u 'r 'f. 'a -> ('b, 'u, 'r, 'f) kinstr -> 'a;
  }

  val kinstr_traverse :
    ('a, 's, 'b, 'f) kinstr -> 'accu -> 'accu kinstr_traverse -> 'accu
end = struct
  type ('before_top, 'before, 'result_top, 'result) kinstr =
    | IDrop :
        Script.location * ('b, 's, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IDup :
        Script.location * ('a, 'a * ('b * 's), 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | ISwap :
        Script.location * ('b, 'a * ('c * 's), 'r, 'f) kinstr
        -> ('a, 'b * ('c * 's), 'r, 'f) kinstr
    | IConst :
        Script.location * ('ty, _) Ty.ty * 'ty * ('ty, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ICons_pair :
        Script.location * ('a * 'b, 'c * 's, 'r, 'f) kinstr
        -> ('a, 'b * ('c * 's), 'r, 'f) kinstr
    | ICar :
        Script.location * ('a, 's, 'r, 'f) kinstr
        -> ('a * 'b, 's, 'r, 'f) kinstr
    | ICdr :
        Script.location * ('b, 's, 'r, 'f) kinstr
        -> ('a * 'b, 's, 'r, 'f) kinstr
    | IUnpair :
        Script.location * ('a, 'b * 's, 'r, 'f) kinstr
        -> ('a * 'b, 's, 'r, 'f) kinstr
    | ICons_some :
        Script.location * ('v option, 'a * 's, 'r, 'f) kinstr
        -> ('v, 'a * 's, 'r, 'f) kinstr
    | ICons_none :
        Script.location * ('b, _) Ty.ty * ('b option, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IIf_none : {
        loc : Script.location;
        branch_if_none : ('b, 's, 'c, 't) kinstr;
        branch_if_some : ('a, 'b * 's, 'c, 't) kinstr;
        k : ('c, 't, 'r, 'f) kinstr;
      }
        -> ('a option, 'b * 's, 'r, 'f) kinstr
    | IOpt_map : {
        loc : Script.location;
        body : ('a, 's, 'b, 's) kinstr;
        k : ('b option, 's, 'c, 't) kinstr;
      }
        -> ('a option, 's, 'c, 't) kinstr
    | ICons_left :
        Script.location
        * ('b, _) Ty.ty
        * (('a, 'b) union, 'c * 's, 'r, 'f) kinstr
        -> ('a, 'c * 's, 'r, 'f) kinstr
    | ICons_right :
        Script.location
        * ('a, _) Ty.ty
        * (('a, 'b) union, 'c * 's, 'r, 'f) kinstr
        -> ('b, 'c * 's, 'r, 'f) kinstr
    | IIf_left : {
        loc : Script.location;
        branch_if_left : ('a, 's, 'c, 't) kinstr;
        branch_if_right : ('b, 's, 'c, 't) kinstr;
        k : ('c, 't, 'r, 'f) kinstr;
      }
        -> (('a, 'b) union, 's, 'r, 'f) kinstr
    | ICons_list :
        Script.location * ('a boxed_list, 's, 'r, 'f) kinstr
        -> ('a, 'a boxed_list * 's, 'r, 'f) kinstr
    | INil :
        Script.location
        * ('b, _) Ty.ty
        * ('b boxed_list, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IIf_cons : {
        loc : Script.location;
        branch_if_cons : ('a, 'a boxed_list * ('b * 's), 'c, 't) kinstr;
        branch_if_nil : ('b, 's, 'c, 't) kinstr;
        k : ('c, 't, 'r, 'f) kinstr;
      }
        -> ('a boxed_list, 'b * 's, 'r, 'f) kinstr
    | IList_map :
        Script.location
        * ('a, 'c * 's, 'b, 'c * 's) kinstr
        * ('b boxed_list, _) Ty.ty
        * ('b boxed_list, 'c * 's, 'r, 'f) kinstr
        -> ('a boxed_list, 'c * 's, 'r, 'f) kinstr
    | IList_iter :
        Script.location
        * ('a, _) Ty.ty
        * ('a, 'b * 's, 'b, 's) kinstr
        * ('b, 's, 'r, 'f) kinstr
        -> ('a boxed_list, 'b * 's, 'r, 'f) kinstr
    | IList_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> ('a boxed_list, 's, 'r, 'f) kinstr
    | IEmpty_set :
        Script.location * 'b Ty.comparable_ty * ('b set, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISet_iter :
        Script.location
        * 'a Ty.comparable_ty
        * ('a, 'b * 's, 'b, 's) kinstr
        * ('b, 's, 'r, 'f) kinstr
        -> ('a set, 'b * 's, 'r, 'f) kinstr
    | ISet_mem :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ('a, 'a set * 's, 'r, 'f) kinstr
    | ISet_update :
        Script.location * ('a set, 's, 'r, 'f) kinstr
        -> ('a, bool * ('a set * 's), 'r, 'f) kinstr
    | ISet_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> ('a set, 's, 'r, 'f) kinstr
    | IEmpty_map :
        Script.location
        * 'b Ty.comparable_ty
        * ('c, _) Ty.ty
        * (('b, 'c) map, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IMap_map :
        Script.location
        * (('a, 'c) map, _) Ty.ty
        * ('a * 'b, 'd * 's, 'c, 'd * 's) kinstr
        * (('a, 'c) map, 'd * 's, 'r, 'f) kinstr
        -> (('a, 'b) map, 'd * 's, 'r, 'f) kinstr
    | IMap_iter :
        Script.location
        * ('a * 'b, _) Ty.ty
        * ('a * 'b, 'c * 's, 'c, 's) kinstr
        * ('c, 's, 'r, 'f) kinstr
        -> (('a, 'b) map, 'c * 's, 'r, 'f) kinstr
    | IMap_mem :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) map * 's, 'r, 'f) kinstr
    | IMap_get :
        Script.location * ('b option, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) map * 's, 'r, 'f) kinstr
    | IMap_update :
        Script.location * (('a, 'b) map, 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) map * 's), 'r, 'f) kinstr
    | IMap_get_and_update :
        Script.location * ('b option, ('a, 'b) map * 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) map * 's), 'r, 'f) kinstr
    | IMap_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (('a, 'b) map, 's, 'r, 'f) kinstr
    | IEmpty_big_map :
        Script.location
        * 'b Ty.comparable_ty
        * ('c, _) Ty.ty
        * (('b, 'c) Big_map.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IBig_map_mem :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) Big_map.t * 's, 'r, 'f) kinstr
    | IBig_map_get :
        Script.location * ('b option, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) Big_map.t * 's, 'r, 'f) kinstr
    | IBig_map_update :
        Script.location * (('a, 'b) Big_map.t, 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) Big_map.t * 's), 'r, 'f) kinstr
    | IBig_map_get_and_update :
        Script.location * ('b option, ('a, 'b) Big_map.t * 's, 'r, 'f) kinstr
        -> ('a, 'b option * (('a, 'b) Big_map.t * 's), 'r, 'f) kinstr
    | IConcat_string :
        Script.location * (Script_string.t, 's, 'r, 'f) kinstr
        -> (Script_string.t boxed_list, 's, 'r, 'f) kinstr
    | IConcat_string_pair :
        Script.location * (Script_string.t, 's, 'r, 'f) kinstr
        -> (Script_string.t, Script_string.t * 's, 'r, 'f) kinstr
    | ISlice_string :
        Script.location * (Script_string.t option, 's, 'r, 'f) kinstr
        -> (n num, n num * (Script_string.t * 's), 'r, 'f) kinstr
    | IString_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (Script_string.t, 's, 'r, 'f) kinstr
    | IConcat_bytes :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes boxed_list, 's, 'r, 'f) kinstr
    | IConcat_bytes_pair :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, bytes * 's, 'r, 'f) kinstr
    | ISlice_bytes :
        Script.location * (bytes option, 's, 'r, 'f) kinstr
        -> (n num, n num * (bytes * 's), 'r, 'f) kinstr
    | IBytes_size :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | IAdd_seconds_to_timestamp :
        Script.location * (Script_timestamp.t, 's, 'r, 'f) kinstr
        -> (z num, Script_timestamp.t * 's, 'r, 'f) kinstr
    | IAdd_timestamp_to_seconds :
        Script.location * (Script_timestamp.t, 's, 'r, 'f) kinstr
        -> (Script_timestamp.t, z num * 's, 'r, 'f) kinstr
    | ISub_timestamp_seconds :
        Script.location * (Script_timestamp.t, 's, 'r, 'f) kinstr
        -> (Script_timestamp.t, z num * 's, 'r, 'f) kinstr
    | IDiff_timestamps :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> (Script_timestamp.t, Script_timestamp.t * 's, 'r, 'f) kinstr
    | IAdd_tez :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | ISub_tez :
        Script.location * (Tez.t option, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | ISub_tez_legacy :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | IMul_teznat :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (Tez.t, n num * 's, 'r, 'f) kinstr
    | IMul_nattez :
        Script.location * (Tez.t, 's, 'r, 'f) kinstr
        -> (n num, Tez.t * 's, 'r, 'f) kinstr
    | IEdiv_teznat :
        Script.location * ((Tez.t, Tez.t) pair option, 's, 'r, 'f) kinstr
        -> (Tez.t, n num * 's, 'r, 'f) kinstr
    | IEdiv_tez :
        Script.location * ((n num, Tez.t) pair option, 's, 'r, 'f) kinstr
        -> (Tez.t, Tez.t * 's, 'r, 'f) kinstr
    | IOr :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, bool * 's, 'r, 'f) kinstr
    | IAnd :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, bool * 's, 'r, 'f) kinstr
    | IXor :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, bool * 's, 'r, 'f) kinstr
    | INot :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (bool, 's, 'r, 'f) kinstr
    | IIs_nat :
        Script.location * (n num option, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | INeg :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 's, 'r, 'f) kinstr
    | IAbs_int :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IInt_nat :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> (n num, 's, 'r, 'f) kinstr
    | IAdd_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IAdd_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | ISub_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IMul_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IMul_nat :
        Script.location * ('a num, 's, 'r, 'f) kinstr
        -> (n num, 'a num * 's, 'r, 'f) kinstr
    | IEdiv_int :
        Script.location * ((z num, n num) pair option, 's, 'r, 'f) kinstr
        -> ('a num, 'b num * 's, 'r, 'f) kinstr
    | IEdiv_nat :
        Script.location * (('a num, n num) pair option, 's, 'r, 'f) kinstr
        -> (n num, 'a num * 's, 'r, 'f) kinstr
    | ILsl_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | ILsr_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | IOr_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | IAnd_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | IAnd_int_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (z num, n num * 's, 'r, 'f) kinstr
    | IXor_nat :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (n num, n num * 's, 'r, 'f) kinstr
    | INot_int :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> ('a num, 's, 'r, 'f) kinstr
    | IIf : {
        loc : Script.location;
        branch_if_true : ('a, 's, 'b, 'u) kinstr;
        branch_if_false : ('a, 's, 'b, 'u) kinstr;
        k : ('b, 'u, 'r, 'f) kinstr;
      }
        -> (bool, 'a * 's, 'r, 'f) kinstr
    | ILoop :
        Script.location
        * ('a, 's, bool, 'a * 's) kinstr
        * ('a, 's, 'r, 'f) kinstr
        -> (bool, 'a * 's, 'r, 'f) kinstr
    | ILoop_left :
        Script.location
        * ('a, 's, ('a, 'b) union, 's) kinstr
        * ('b, 's, 'r, 'f) kinstr
        -> (('a, 'b) union, 's, 'r, 'f) kinstr
    | IDip :
        Script.location
        * ('b, 's, 'c, 't) kinstr
        * ('a, _) Ty.ty
        * ('a, 'c * 't, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IExec :
        Script.location * ('b, 's) Ty.stack * ('b, 's, 'r, 'f) kinstr
        -> ('a, ('a, 'b) Lambda.t * 's, 'r, 'f) kinstr
    | IApply :
        Script.location * ('a, _) Ty.ty * (('b, 'c) Lambda.t, 's, 'r, 'f) kinstr
        -> ('a, ('a * 'b, 'c) Lambda.t * 's, 'r, 'f) kinstr
    | ILambda :
        Script.location
        * ('b, 'c) Lambda.t
        * (('b, 'c) Lambda.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IFailwith : Script.location * ('a, _) Ty.ty -> ('a, 's, 'r, 'f) kinstr
    | ICompare :
        Script.location * 'a Ty.comparable_ty * (z num, 'b * 's, 'r, 'f) kinstr
        -> ('a, 'a * ('b * 's), 'r, 'f) kinstr
    | IEq :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | INeq :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | ILt :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IGt :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | ILe :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IGe :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (z num, 's, 'r, 'f) kinstr
    | IAddress :
        Script.location * (address, 's, 'r, 'f) kinstr
        -> ('a Typed_contract.t, 's, 'r, 'f) kinstr
    | IContract :
        Script.location
        * ('a, _) Ty.ty
        * Entrypoint.t
        * ('a Typed_contract.t option, 's, 'r, 'f) kinstr
        -> (address, 's, 'r, 'f) kinstr
    | IView :
        Script.location
        * ('a, 'b) view_signature
        * ('b, 'c * 's) Ty.stack
        * ('b option, 'c * 's, 'r, 'f) kinstr
        -> ('a, address * ('c * 's), 'r, 'f) kinstr
    | ITransfer_tokens :
        Script.location * (Operation.t, 's, 'r, 'f) kinstr
        -> ('a, Tez.t * ('a Typed_contract.t * 's), 'r, 'f) kinstr
    | IImplicit_account :
        Script.location * (unit Typed_contract.t, 's, 'r, 'f) kinstr
        -> (public_key_hash, 's, 'r, 'f) kinstr
    | ICreate_contract : {
        loc : Script.location;
        storage_type : ('a, _) Ty.ty;
        code : Script.expr;
        k : (Operation.t, address * ('c * 's), 'r, 'f) kinstr;
      }
        -> (public_key_hash option, Tez.t * ('a * ('c * 's)), 'r, 'f) kinstr
    | ISet_delegate :
        Script.location * (Operation.t, 's, 'r, 'f) kinstr
        -> (public_key_hash option, 's, 'r, 'f) kinstr
    | INow :
        Script.location * (Script_timestamp.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IMin_block_time :
        Script.location * (n num, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IBalance :
        Script.location * (Tez.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ILevel :
        Script.location * (n num, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ICheck_signature :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> (public_key, signature * (bytes * 's), 'r, 'f) kinstr
    | IHash_key :
        Script.location * (public_key_hash, 's, 'r, 'f) kinstr
        -> (public_key, 's, 'r, 'f) kinstr
    | IPack :
        Script.location * ('a, _) Ty.ty * (bytes, 'b * 's, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IUnpack :
        Script.location * ('a, _) Ty.ty * ('a option, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | IBlake2b :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISha256 :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISha512 :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISource :
        Script.location * (address, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISender :
        Script.location * (address, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISelf :
        Script.location
        * ('b, _) Ty.ty
        * Entrypoint.t
        * ('b Typed_contract.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISelf_address :
        Script.location * (address, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IAmount :
        Script.location * (Tez.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | ISapling_empty_state :
        Script.location
        * Sapling.Memo_size.t
        * (Sapling.state, 'a * 's, 'b, 'f) kinstr
        -> ('a, 's, 'b, 'f) kinstr
    | ISapling_verify_update :
        Script.location
        * ((bytes, (z num, Sapling.state) pair) pair option, 's, 'r, 'f) kinstr
        -> (Sapling.transaction, Sapling.state * 's, 'r, 'f) kinstr
    | ISapling_verify_update_deprecated :
        Script.location
        * ((z num, Sapling.state) pair option, 's, 'r, 'f) kinstr
        -> (Sapling.Legacy.transaction, Sapling.state * 's, 'r, 'f) kinstr
    | IDig :
        Script.location
        * int
        * ( 'b,
            'c * 't,
            'c,
            't,
            'a,
            's,
            'd,
            'u )
          stack_prefix_preservation_witness
        * ('b, 'd * 'u, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IDug :
        Script.location
        * int
        * ( 'c,
            't,
            'a,
            'c * 't,
            'b,
            's,
            'd,
            'u )
          stack_prefix_preservation_witness
        * ('d, 'u, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IDipn :
        Script.location
        * int
        * ('c, 't, 'd, 'v, 'a, 's, 'b, 'u) stack_prefix_preservation_witness
        * ('c, 't, 'd, 'v) kinstr
        * ('b, 'u, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IDropn :
        Script.location
        * int
        * ('b, 'u, 'b, 'u, 'a, 's, 'a, 's) stack_prefix_preservation_witness
        * ('b, 'u, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IChainId :
        Script.location * (Script_chain_id.t, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | INever : Script.location -> (never, 's, 'r, 'f) kinstr
    | IVoting_power :
        Script.location * (n num, 's, 'r, 'f) kinstr
        -> (public_key_hash, 's, 'r, 'f) kinstr
    | ITotal_voting_power :
        Script.location * (n num, 'a * 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr
    | IKeccak :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | ISha3 :
        Script.location * (bytes, 's, 'r, 'f) kinstr
        -> (bytes, 's, 'r, 'f) kinstr
    | IAdd_bls12_381_g1 :
        Script.location * (Script_bls.G1.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G1.t, Script_bls.G1.t * 's, 'r, 'f) kinstr
    | IAdd_bls12_381_g2 :
        Script.location * (Script_bls.G2.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G2.t, Script_bls.G2.t * 's, 'r, 'f) kinstr
    | IAdd_bls12_381_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_g1 :
        Script.location * (Script_bls.G1.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G1.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_g2 :
        Script.location * (Script_bls.G2.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G2.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IMul_bls12_381_z_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, 'a num * 's, 'r, 'f) kinstr
    | IMul_bls12_381_fr_z :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> ('a num, Script_bls.Fr.t * 's, 'r, 'f) kinstr
    | IInt_bls12_381_fr :
        Script.location * (z num, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, 's, 'r, 'f) kinstr
    | INeg_bls12_381_g1 :
        Script.location * (Script_bls.G1.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G1.t, 's, 'r, 'f) kinstr
    | INeg_bls12_381_g2 :
        Script.location * (Script_bls.G2.t, 's, 'r, 'f) kinstr
        -> (Script_bls.G2.t, 's, 'r, 'f) kinstr
    | INeg_bls12_381_fr :
        Script.location * (Script_bls.Fr.t, 's, 'r, 'f) kinstr
        -> (Script_bls.Fr.t, 's, 'r, 'f) kinstr
    | IPairing_check_bls12_381 :
        Script.location * (bool, 's, 'r, 'f) kinstr
        -> ( (Script_bls.G1.t, Script_bls.G2.t) pair boxed_list,
             's,
             'r,
             'f )
           kinstr
    | IComb :
        Script.location
        * int
        * ('a, 'b, 's, 'c, 'd, 't) comb_gadt_witness
        * ('c, 'd * 't, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IUncomb :
        Script.location
        * int
        * ('a, 'b, 's, 'c, 'd, 't) uncomb_gadt_witness
        * ('c, 'd * 't, 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | IComb_get :
        Script.location
        * int
        * ('t, 'v) comb_get_gadt_witness
        * ('v, 'a * 's, 'r, 'f) kinstr
        -> ('t, 'a * 's, 'r, 'f) kinstr
    | IComb_set :
        Script.location
        * int
        * ('a, 'b, 'c) comb_set_gadt_witness
        * ('c, 'd * 's, 'r, 'f) kinstr
        -> ('a, 'b * ('d * 's), 'r, 'f) kinstr
    | IDup_n :
        Script.location
        * int
        * ('a, 'b, 's, 't) dup_n_gadt_witness
        * ('t, 'a * ('b * 's), 'r, 'f) kinstr
        -> ('a, 'b * 's, 'r, 'f) kinstr
    | ITicket :
        Script.location * 'a Ty.comparable_ty * ('a ticket, 's, 'r, 'f) kinstr
        -> ('a, n num * 's, 'r, 'f) kinstr
    | IRead_ticket :
        Script.location
        * 'a Ty.comparable_ty
        * (address * ('a * n num), 'a ticket * 's, 'r, 'f) kinstr
        -> ('a ticket, 's, 'r, 'f) kinstr
    | ISplit_ticket :
        Script.location * (('a ticket * 'a ticket) option, 's, 'r, 'f) kinstr
        -> ('a ticket, (n num * n num) * 's, 'r, 'f) kinstr
    | IJoin_tickets :
        Script.location
        * 'a Ty.comparable_ty
        * ('a ticket option, 's, 'r, 'f) kinstr
        -> ('a ticket * 'a ticket, 's, 'r, 'f) kinstr
    | IOpen_chest :
        Script.location * ((bytes, bool) union, 's, 'r, 'f) kinstr
        -> ( Script_timelock.chest_key,
             Script_timelock.chest * (n num * 's),
             'r,
             'f )
           kinstr
    | IEmit : {
        loc : Script.location;
        tag : Entrypoint.t;
        ty : ('a, _) Ty.ty;
        unparsed_ty : Script.expr;
        k : (Operation.t, 's, 'r, 'f) kinstr;
      }
        -> ('a, 's, 'r, 'f) kinstr
    | IHalt : Script.location -> ('a, 's, 'a, 's) kinstr
    | ILog :
        Script.location
        * ('a, 's) Ty.stack
        * logging_event
        * logger
        * ('a, 's, 'r, 'f) kinstr
        -> ('a, 's, 'r, 'f) kinstr

  and (_, _, _, _) continuation =
    | KNil : ('r, 'f, 'r, 'f) continuation
    | KCons :
        ('a, 's, 'b, 't) kinstr * ('b, 't, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KReturn :
        's * ('a, 's) Ty.stack * ('a, 's, 'r, 'f) continuation
        -> ('a, end_of_stack, 'r, 'f) continuation
    | KMap_head :
        ('a -> 'b) * ('b, 's, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KUndip :
        'b * ('b, _) Ty.ty * ('b, 'a * 's, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KLoop_in :
        ('a, 's, bool, 'a * 's) kinstr * ('a, 's, 'r, 'f) continuation
        -> (bool, 'a * 's, 'r, 'f) continuation
    | KLoop_in_left :
        ('a, 's, ('a, 'b) union, 's) kinstr * ('b, 's, 'r, 'f) continuation
        -> (('a, 'b) union, 's, 'r, 'f) continuation
    | KIter :
        ('a, 'b * 's, 'b, 's) kinstr
        * ('a, _) Ty.ty
        * 'a list
        * ('b, 's, 'r, 'f) continuation
        -> ('b, 's, 'r, 'f) continuation
    | KList_enter_body :
        ('a, 'c * 's, 'b, 'c * 's) kinstr
        * 'a list
        * 'b list
        * ('b boxed_list, _) Ty.ty
        * int
        * ('b boxed_list, 'c * 's, 'r, 'f) continuation
        -> ('c, 's, 'r, 'f) continuation
    | KList_exit_body :
        ('a, 'c * 's, 'b, 'c * 's) kinstr
        * 'a list
        * 'b list
        * ('b boxed_list, _) Ty.ty
        * int
        * ('b boxed_list, 'c * 's, 'r, 'f) continuation
        -> ('b, 'c * 's, 'r, 'f) continuation
    | KMap_enter_body :
        ('a * 'b, 'd * 's, 'c, 'd * 's) kinstr
        * ('a * 'b) list
        * ('a, 'c) map
        * (('a, 'c) map, _) Ty.ty
        * (('a, 'c) map, 'd * 's, 'r, 'f) continuation
        -> ('d, 's, 'r, 'f) continuation
    | KMap_exit_body :
        ('a * 'b, 'd * 's, 'c, 'd * 's) kinstr
        * ('a * 'b) list
        * ('a, 'c) map
        * 'a
        * (('a, 'c) map, _) Ty.ty
        * (('a, 'c) map, 'd * 's, 'r, 'f) continuation
        -> ('c, 'd * 's, 'r, 'f) continuation
    | KView_exit :
        step_constants * ('a, 's, 'r, 'f) continuation
        -> ('a, 's, 'r, 'f) continuation
    | KLog :
        ('a, 's, 'r, 'f) continuation * ('a, 's) Ty.stack * logger
        -> ('a, 's, 'r, 'f) continuation

  and ('a, 's, 'b, 'f, 'c, 'u) logging_function =
    ('a, 's, 'b, 'f) kinstr ->
    context ->
    Script.location ->
    ('c, 'u) Ty.stack ->
    'c * 'u ->
    unit

  and execution_trace = (Script.location * Gas.t * Script.expr list) list

  and logger = {
    log_interp : 'a 's 'b 'f 'c 'u. ('a, 's, 'b, 'f, 'c, 'u) logging_function;
    log_entry : 'a 's 'b 'f. ('a, 's, 'b, 'f, 'a, 's) logging_function;
    log_control : 'a 's 'b 'f. ('a, 's, 'b, 'f) continuation -> unit;
    log_exit : 'a 's 'b 'f 'c 'u. ('a, 's, 'b, 'f, 'c, 'u) logging_function;
    get_log : unit -> execution_trace option tzresult Lwt.t;
  }

  and ('a, 's, 'r, 'f) kdescr = {
    kloc : Script.location;
    kbef : ('a, 's) Ty.stack;
    kaft : ('r, 'f) Ty.stack;
    kinstr : ('a, 's, 'r, 'f) kinstr;
  }

  and (_, _, _, _, _, _, _, _) stack_prefix_preservation_witness =
    | KPrefix :
        Script.location
        * ('a, _) Ty.ty
        * ('c, 'v, 'd, 'w, 'x, 's, 'y, 'u) stack_prefix_preservation_witness
        -> ( 'c,
             'v,
             'd,
             'w,
             'a,
             'x * 's,
             'a,
             'y * 'u )
           stack_prefix_preservation_witness
    | KRest : ('a, 's, 'b, 'u, 'a, 's, 'b, 'u) stack_prefix_preservation_witness

  and (_, _, _, _, _, _) comb_gadt_witness =
    | Comb_one : ('a, 'x, 'before, 'a, 'x, 'before) comb_gadt_witness
    | Comb_succ :
        ('b, 'c, 's, 'd, 'e, 't) comb_gadt_witness
        -> ('a, 'b, 'c * 's, 'a * 'd, 'e, 't) comb_gadt_witness

  and (_, _, _, _, _, _) uncomb_gadt_witness =
    | Uncomb_one : ('a, 'x, 'before, 'a, 'x, 'before) uncomb_gadt_witness
    | Uncomb_succ :
        ('b, 'c, 's, 'd, 'e, 't) uncomb_gadt_witness
        -> ('a * 'b, 'c, 's, 'a, 'd, 'e * 't) uncomb_gadt_witness

  and ('before, 'after) comb_get_gadt_witness =
    | Comb_get_zero : ('b, 'b) comb_get_gadt_witness
    | Comb_get_one : ('a * 'b, 'a) comb_get_gadt_witness
    | Comb_get_plus_two :
        ('before, 'after) comb_get_gadt_witness
        -> ('a * 'before, 'after) comb_get_gadt_witness

  and ('value, 'before, 'after) comb_set_gadt_witness =
    | Comb_set_zero : ('value, _, 'value) comb_set_gadt_witness
    | Comb_set_one : ('value, 'hd * 'tl, 'value * 'tl) comb_set_gadt_witness
    | Comb_set_plus_two :
        ('value, 'before, 'after) comb_set_gadt_witness
        -> ('value, 'a * 'before, 'a * 'after) comb_set_gadt_witness

  and (_, _, _, _) dup_n_gadt_witness =
    | Dup_n_zero : ('a, _, _, 'a) dup_n_gadt_witness
    | Dup_n_succ :
        ('b, 'c, 'stack, 'd) dup_n_gadt_witness
        -> ('a, 'b, 'c * 'stack, 'd) dup_n_gadt_witness

  and ('input, 'output) view_signature =
    | View_signature : {
        name : Script_string.t;
        input_ty : ('input, _) Ty.ty;
        output_ty : ('output, _) Ty.ty;
      }
        -> ('input, 'output) view_signature

  let kinstr_location : type a s b f. (a, s, b, f) kinstr -> Script.location =
   fun i ->
    match i with
    | IDrop (loc, _) -> loc
    | IDup (loc, _) -> loc
    | ISwap (loc, _) -> loc
    | IConst (loc, _, _, _) -> loc
    | ICons_pair (loc, _) -> loc
    | ICar (loc, _) -> loc
    | ICdr (loc, _) -> loc
    | IUnpair (loc, _) -> loc
    | ICons_some (loc, _) -> loc
    | ICons_none (loc, _, _) -> loc
    | IIf_none {loc; _} -> loc
    | IOpt_map {loc; _} -> loc
    | ICons_left (loc, _, _) -> loc
    | ICons_right (loc, _, _) -> loc
    | IIf_left {loc; _} -> loc
    | ICons_list (loc, _) -> loc
    | INil (loc, _, _) -> loc
    | IIf_cons {loc; _} -> loc
    | IList_map (loc, _, _, _) -> loc
    | IList_iter (loc, _, _, _) -> loc
    | IList_size (loc, _) -> loc
    | IEmpty_set (loc, _, _) -> loc
    | ISet_iter (loc, _, _, _) -> loc
    | ISet_mem (loc, _) -> loc
    | ISet_update (loc, _) -> loc
    | ISet_size (loc, _) -> loc
    | IEmpty_map (loc, _, _, _) -> loc
    | IMap_map (loc, _, _, _) -> loc
    | IMap_iter (loc, _, _, _) -> loc
    | IMap_mem (loc, _) -> loc
    | IMap_get (loc, _) -> loc
    | IMap_update (loc, _) -> loc
    | IMap_get_and_update (loc, _) -> loc
    | IMap_size (loc, _) -> loc
    | IEmpty_big_map (loc, _, _, _) -> loc
    | IBig_map_mem (loc, _) -> loc
    | IBig_map_get (loc, _) -> loc
    | IBig_map_update (loc, _) -> loc
    | IBig_map_get_and_update (loc, _) -> loc
    | IConcat_string (loc, _) -> loc
    | IConcat_string_pair (loc, _) -> loc
    | ISlice_string (loc, _) -> loc
    | IString_size (loc, _) -> loc
    | IConcat_bytes (loc, _) -> loc
    | IConcat_bytes_pair (loc, _) -> loc
    | ISlice_bytes (loc, _) -> loc
    | IBytes_size (loc, _) -> loc
    | IAdd_seconds_to_timestamp (loc, _) -> loc
    | IAdd_timestamp_to_seconds (loc, _) -> loc
    | ISub_timestamp_seconds (loc, _) -> loc
    | IDiff_timestamps (loc, _) -> loc
    | IAdd_tez (loc, _) -> loc
    | ISub_tez (loc, _) -> loc
    | ISub_tez_legacy (loc, _) -> loc
    | IMul_teznat (loc, _) -> loc
    | IMul_nattez (loc, _) -> loc
    | IEdiv_teznat (loc, _) -> loc
    | IEdiv_tez (loc, _) -> loc
    | IOr (loc, _) -> loc
    | IAnd (loc, _) -> loc
    | IXor (loc, _) -> loc
    | INot (loc, _) -> loc
    | IIs_nat (loc, _) -> loc
    | INeg (loc, _) -> loc
    | IAbs_int (loc, _) -> loc
    | IInt_nat (loc, _) -> loc
    | IAdd_int (loc, _) -> loc
    | IAdd_nat (loc, _) -> loc
    | ISub_int (loc, _) -> loc
    | IMul_int (loc, _) -> loc
    | IMul_nat (loc, _) -> loc
    | IEdiv_int (loc, _) -> loc
    | IEdiv_nat (loc, _) -> loc
    | ILsl_nat (loc, _) -> loc
    | ILsr_nat (loc, _) -> loc
    | IOr_nat (loc, _) -> loc
    | IAnd_nat (loc, _) -> loc
    | IAnd_int_nat (loc, _) -> loc
    | IXor_nat (loc, _) -> loc
    | INot_int (loc, _) -> loc
    | IIf {loc; _} -> loc
    | ILoop (loc, _, _) -> loc
    | ILoop_left (loc, _, _) -> loc
    | IDip (loc, _, _, _) -> loc
    | IExec (loc, _, _) -> loc
    | IApply (loc, _, _) -> loc
    | ILambda (loc, _, _) -> loc
    | IFailwith (loc, _) -> loc
    | ICompare (loc, _, _) -> loc
    | IEq (loc, _) -> loc
    | INeq (loc, _) -> loc
    | ILt (loc, _) -> loc
    | IGt (loc, _) -> loc
    | ILe (loc, _) -> loc
    | IGe (loc, _) -> loc
    | IAddress (loc, _) -> loc
    | IContract (loc, _, _, _) -> loc
    | ITransfer_tokens (loc, _) -> loc
    | IView (loc, _, _, _) -> loc
    | IImplicit_account (loc, _) -> loc
    | ICreate_contract {loc; _} -> loc
    | ISet_delegate (loc, _) -> loc
    | INow (loc, _) -> loc
    | IMin_block_time (loc, _) -> loc
    | IBalance (loc, _) -> loc
    | ILevel (loc, _) -> loc
    | ICheck_signature (loc, _) -> loc
    | IHash_key (loc, _) -> loc
    | IPack (loc, _, _) -> loc
    | IUnpack (loc, _, _) -> loc
    | IBlake2b (loc, _) -> loc
    | ISha256 (loc, _) -> loc
    | ISha512 (loc, _) -> loc
    | ISource (loc, _) -> loc
    | ISender (loc, _) -> loc
    | ISelf (loc, _, _, _) -> loc
    | ISelf_address (loc, _) -> loc
    | IAmount (loc, _) -> loc
    | ISapling_empty_state (loc, _, _) -> loc
    | ISapling_verify_update (loc, _) -> loc
    | ISapling_verify_update_deprecated (loc, _) -> loc
    | IDig (loc, _, _, _) -> loc
    | IDug (loc, _, _, _) -> loc
    | IDipn (loc, _, _, _, _) -> loc
    | IDropn (loc, _, _, _) -> loc
    | IChainId (loc, _) -> loc
    | INever loc -> loc
    | IVoting_power (loc, _) -> loc
    | ITotal_voting_power (loc, _) -> loc
    | IKeccak (loc, _) -> loc
    | ISha3 (loc, _) -> loc
    | IAdd_bls12_381_g1 (loc, _) -> loc
    | IAdd_bls12_381_g2 (loc, _) -> loc
    | IAdd_bls12_381_fr (loc, _) -> loc
    | IMul_bls12_381_g1 (loc, _) -> loc
    | IMul_bls12_381_g2 (loc, _) -> loc
    | IMul_bls12_381_fr (loc, _) -> loc
    | IMul_bls12_381_z_fr (loc, _) -> loc
    | IMul_bls12_381_fr_z (loc, _) -> loc
    | IInt_bls12_381_fr (loc, _) -> loc
    | INeg_bls12_381_g1 (loc, _) -> loc
    | INeg_bls12_381_g2 (loc, _) -> loc
    | INeg_bls12_381_fr (loc, _) -> loc
    | IPairing_check_bls12_381 (loc, _) -> loc
    | IComb (loc, _, _, _) -> loc
    | IUncomb (loc, _, _, _) -> loc
    | IComb_get (loc, _, _, _) -> loc
    | IComb_set (loc, _, _, _) -> loc
    | IDup_n (loc, _, _, _) -> loc
    | ITicket (loc, _, _) -> loc
    | IRead_ticket (loc, _, _) -> loc
    | ISplit_ticket (loc, _) -> loc
    | IJoin_tickets (loc, _, _) -> loc
    | IOpen_chest (loc, _) -> loc
    | IEmit {loc; _} -> loc
    | IHalt loc -> loc
    | ILog (loc, _, _, _, _) -> loc

  type 'a kinstr_traverse = {
    apply : 'b 'u 'r 'f. 'a -> ('b, 'u, 'r, 'f) kinstr -> 'a;
  }

  let kinstr_traverse i init f =
    let rec aux :
        type ret a s r f. 'accu -> (a, s, r, f) kinstr -> ('accu -> ret) -> ret
        =
     fun accu t continue ->
      let accu = f.apply accu t in
      let next k =
        (aux [@ocaml.tailcall]) accu k (fun accu ->
            (continue [@ocaml.tailcall]) accu)
      in
      let next2 k1 k2 =
        (aux [@ocaml.tailcall]) accu k1 (fun accu ->
            (aux [@ocaml.tailcall]) accu k2 (fun accu ->
                (continue [@ocaml.tailcall]) accu))
      in
      let next3 k1 k2 k3 =
        (aux [@ocaml.tailcall]) accu k1 (fun accu ->
            (aux [@ocaml.tailcall]) accu k2 (fun accu ->
                (aux [@ocaml.tailcall]) accu k3 (fun accu ->
                    (continue [@ocaml.tailcall]) accu)))
      in
      let return () = (continue [@ocaml.tailcall]) accu in
      match t with
      | IDrop (_, k) -> (next [@ocaml.tailcall]) k
      | IDup (_, k) -> (next [@ocaml.tailcall]) k
      | ISwap (_, k) -> (next [@ocaml.tailcall]) k
      | IConst (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | ICons_pair (_, k) -> (next [@ocaml.tailcall]) k
      | ICar (_, k) -> (next [@ocaml.tailcall]) k
      | ICdr (_, k) -> (next [@ocaml.tailcall]) k
      | IUnpair (_, k) -> (next [@ocaml.tailcall]) k
      | ICons_some (_, k) -> (next [@ocaml.tailcall]) k
      | ICons_none (_, _, k) -> (next [@ocaml.tailcall]) k
      | IIf_none {loc = _; branch_if_none = k1; branch_if_some = k2; k} ->
          (next3 [@ocaml.tailcall]) k1 k2 k
      | IOpt_map {loc = _; body; k} -> (next2 [@ocaml.tailcall]) body k
      | ICons_left (_, _, k) -> (next [@ocaml.tailcall]) k
      | ICons_right (_, _, k) -> (next [@ocaml.tailcall]) k
      | IIf_left {loc = _; branch_if_left = k1; branch_if_right = k2; k} ->
          (next3 [@ocaml.tailcall]) k1 k2 k
      | ICons_list (_, k) -> (next [@ocaml.tailcall]) k
      | INil (_, _, k) -> (next [@ocaml.tailcall]) k
      | IIf_cons {loc = _; branch_if_nil = k1; branch_if_cons = k2; k} ->
          (next3 [@ocaml.tailcall]) k1 k2 k
      | IList_map (_, k1, _, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IList_iter (_, _, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IList_size (_, k) -> (next [@ocaml.tailcall]) k
      | IEmpty_set (_, _, k) -> (next [@ocaml.tailcall]) k
      | ISet_iter (_, _, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | ISet_mem (_, k) -> (next [@ocaml.tailcall]) k
      | ISet_update (_, k) -> (next [@ocaml.tailcall]) k
      | ISet_size (_, k) -> (next [@ocaml.tailcall]) k
      | IEmpty_map (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IMap_map (_, _, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IMap_iter (_, _, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IMap_mem (_, k) -> (next [@ocaml.tailcall]) k
      | IMap_get (_, k) -> (next [@ocaml.tailcall]) k
      | IMap_update (_, k) -> (next [@ocaml.tailcall]) k
      | IMap_get_and_update (_, k) -> (next [@ocaml.tailcall]) k
      | IMap_size (_, k) -> (next [@ocaml.tailcall]) k
      | IEmpty_big_map (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IBig_map_mem (_, k) -> (next [@ocaml.tailcall]) k
      | IBig_map_get (_, k) -> (next [@ocaml.tailcall]) k
      | IBig_map_update (_, k) -> (next [@ocaml.tailcall]) k
      | IBig_map_get_and_update (_, k) -> (next [@ocaml.tailcall]) k
      | IConcat_string (_, k) -> (next [@ocaml.tailcall]) k
      | IConcat_string_pair (_, k) -> (next [@ocaml.tailcall]) k
      | ISlice_string (_, k) -> (next [@ocaml.tailcall]) k
      | IString_size (_, k) -> (next [@ocaml.tailcall]) k
      | IConcat_bytes (_, k) -> (next [@ocaml.tailcall]) k
      | IConcat_bytes_pair (_, k) -> (next [@ocaml.tailcall]) k
      | ISlice_bytes (_, k) -> (next [@ocaml.tailcall]) k
      | IBytes_size (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_seconds_to_timestamp (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_timestamp_to_seconds (_, k) -> (next [@ocaml.tailcall]) k
      | ISub_timestamp_seconds (_, k) -> (next [@ocaml.tailcall]) k
      | IDiff_timestamps (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_tez (_, k) -> (next [@ocaml.tailcall]) k
      | ISub_tez (_, k) -> (next [@ocaml.tailcall]) k
      | ISub_tez_legacy (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_teznat (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_nattez (_, k) -> (next [@ocaml.tailcall]) k
      | IEdiv_teznat (_, k) -> (next [@ocaml.tailcall]) k
      | IEdiv_tez (_, k) -> (next [@ocaml.tailcall]) k
      | IOr (_, k) -> (next [@ocaml.tailcall]) k
      | IAnd (_, k) -> (next [@ocaml.tailcall]) k
      | IXor (_, k) -> (next [@ocaml.tailcall]) k
      | INot (_, k) -> (next [@ocaml.tailcall]) k
      | IIs_nat (_, k) -> (next [@ocaml.tailcall]) k
      | INeg (_, k) -> (next [@ocaml.tailcall]) k
      | IAbs_int (_, k) -> (next [@ocaml.tailcall]) k
      | IInt_nat (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_int (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_nat (_, k) -> (next [@ocaml.tailcall]) k
      | ISub_int (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_int (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_nat (_, k) -> (next [@ocaml.tailcall]) k
      | IEdiv_int (_, k) -> (next [@ocaml.tailcall]) k
      | IEdiv_nat (_, k) -> (next [@ocaml.tailcall]) k
      | ILsl_nat (_, k) -> (next [@ocaml.tailcall]) k
      | ILsr_nat (_, k) -> (next [@ocaml.tailcall]) k
      | IOr_nat (_, k) -> (next [@ocaml.tailcall]) k
      | IAnd_nat (_, k) -> (next [@ocaml.tailcall]) k
      | IAnd_int_nat (_, k) -> (next [@ocaml.tailcall]) k
      | IXor_nat (_, k) -> (next [@ocaml.tailcall]) k
      | INot_int (_, k) -> (next [@ocaml.tailcall]) k
      | IIf {loc = _; branch_if_true = k1; branch_if_false = k2; k} ->
          (next3 [@ocaml.tailcall]) k1 k2 k
      | ILoop (_, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | ILoop_left (_, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IDip (_, k1, _, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IExec (_, _, k) -> (next [@ocaml.tailcall]) k
      | IApply (_, _, k) -> (next [@ocaml.tailcall]) k
      | ILambda (_, _, k) -> (next [@ocaml.tailcall]) k
      | IFailwith (_, _) -> (return [@ocaml.tailcall]) ()
      | ICompare (_, _, k) -> (next [@ocaml.tailcall]) k
      | IEq (_, k) -> (next [@ocaml.tailcall]) k
      | INeq (_, k) -> (next [@ocaml.tailcall]) k
      | ILt (_, k) -> (next [@ocaml.tailcall]) k
      | IGt (_, k) -> (next [@ocaml.tailcall]) k
      | ILe (_, k) -> (next [@ocaml.tailcall]) k
      | IGe (_, k) -> (next [@ocaml.tailcall]) k
      | IAddress (_, k) -> (next [@ocaml.tailcall]) k
      | IContract (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IView (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | ITransfer_tokens (_, k) -> (next [@ocaml.tailcall]) k
      | IImplicit_account (_, k) -> (next [@ocaml.tailcall]) k
      | ICreate_contract {k; _} -> (next [@ocaml.tailcall]) k
      | ISet_delegate (_, k) -> (next [@ocaml.tailcall]) k
      | INow (_, k) -> (next [@ocaml.tailcall]) k
      | IMin_block_time (_, k) -> (next [@ocaml.tailcall]) k
      | IBalance (_, k) -> (next [@ocaml.tailcall]) k
      | ILevel (_, k) -> (next [@ocaml.tailcall]) k
      | ICheck_signature (_, k) -> (next [@ocaml.tailcall]) k
      | IHash_key (_, k) -> (next [@ocaml.tailcall]) k
      | IPack (_, _, k) -> (next [@ocaml.tailcall]) k
      | IUnpack (_, _, k) -> (next [@ocaml.tailcall]) k
      | IBlake2b (_, k) -> (next [@ocaml.tailcall]) k
      | ISha256 (_, k) -> (next [@ocaml.tailcall]) k
      | ISha512 (_, k) -> (next [@ocaml.tailcall]) k
      | ISource (_, k) -> (next [@ocaml.tailcall]) k
      | ISender (_, k) -> (next [@ocaml.tailcall]) k
      | ISelf (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | ISelf_address (_, k) -> (next [@ocaml.tailcall]) k
      | IAmount (_, k) -> (next [@ocaml.tailcall]) k
      | ISapling_empty_state (_, _, k) -> (next [@ocaml.tailcall]) k
      | ISapling_verify_update (_, k) -> (next [@ocaml.tailcall]) k
      | ISapling_verify_update_deprecated (_, k) -> (next [@ocaml.tailcall]) k
      | IDig (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IDug (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IDipn (_, _, _, k1, k2) -> (next2 [@ocaml.tailcall]) k1 k2
      | IDropn (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IChainId (_, k) -> (next [@ocaml.tailcall]) k
      | INever _ -> (return [@ocaml.tailcall]) ()
      | IVoting_power (_, k) -> (next [@ocaml.tailcall]) k
      | ITotal_voting_power (_, k) -> (next [@ocaml.tailcall]) k
      | IKeccak (_, k) -> (next [@ocaml.tailcall]) k
      | ISha3 (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_bls12_381_g1 (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_bls12_381_g2 (_, k) -> (next [@ocaml.tailcall]) k
      | IAdd_bls12_381_fr (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_bls12_381_g1 (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_bls12_381_g2 (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_bls12_381_fr (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_bls12_381_z_fr (_, k) -> (next [@ocaml.tailcall]) k
      | IMul_bls12_381_fr_z (_, k) -> (next [@ocaml.tailcall]) k
      | IInt_bls12_381_fr (_, k) -> (next [@ocaml.tailcall]) k
      | INeg_bls12_381_g1 (_, k) -> (next [@ocaml.tailcall]) k
      | INeg_bls12_381_g2 (_, k) -> (next [@ocaml.tailcall]) k
      | INeg_bls12_381_fr (_, k) -> (next [@ocaml.tailcall]) k
      | IPairing_check_bls12_381 (_, k) -> (next [@ocaml.tailcall]) k
      | IComb (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IUncomb (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IComb_get (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IComb_set (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | IDup_n (_, _, _, k) -> (next [@ocaml.tailcall]) k
      | ITicket (_, _, k) -> (next [@ocaml.tailcall]) k
      | IRead_ticket (_, _, k) -> (next [@ocaml.tailcall]) k
      | ISplit_ticket (_, k) -> (next [@ocaml.tailcall]) k
      | IJoin_tickets (_, _, k) -> (next [@ocaml.tailcall]) k
      | IOpen_chest (_, k) -> (next [@ocaml.tailcall]) k
      | IEmit {k; _} -> (next [@ocaml.tailcall]) k
      | IHalt _ -> (return [@ocaml.tailcall]) ()
      | ILog (_, _, _, _, k) -> (next [@ocaml.tailcall]) k
    in
    aux init i (fun accu -> accu)
end

and Lambda : sig
  type ('arg, 'ret) t =
    | Lam :
        ('arg, end_of_stack, 'ret, end_of_stack) Instruction.kdescr
        * Script.node
        -> ('arg, 'ret) t
end = struct
  type ('arg, 'ret) t =
    | Lam :
        ('arg, end_of_stack, 'ret, end_of_stack) Instruction.kdescr
        * Script.node
        -> ('arg, 'ret) t
end

and Typed_contract : sig
  type 'arg t =
    | Typed_implicit : public_key_hash -> unit t
    | Typed_originated : {
        arg_ty : ('arg * _) Ty.t;
        contract_hash : Contract_hash.t;
        entrypoint : Entrypoint.t;
      }
        -> 'arg t
    | Typed_tx_rollup : {
        arg_ty : (('a ticket, tx_rollup_l2_address) pair * _) Ty.t;
        tx_rollup : Tx_rollup.t;
      }
        -> ('a ticket, tx_rollup_l2_address) pair t
    | Typed_sc_rollup : {
        arg_ty : ('arg * _) Ty.t;
        sc_rollup : Sc_rollup.t;
        entrypoint : Entrypoint.t;
      }
        -> 'arg t

  val destination : _ t -> Destination.t

  val arg_ty : 'a t -> 'a Ty.ty_ex_c

  val entrypoint : _ t -> Entrypoint.t

  module Internal_for_tests : sig
    (* This function doesn't guarantee that the contract is well-typed wrt its
       registered type at origination, it only guarantees that the type is
       plausible wrt to the destination kind. *)
    val typed_exn : ('a, _) Ty.ty -> Destination.t -> Entrypoint.t -> 'a t
  end
end = struct
  type 'arg t =
    | Typed_implicit : public_key_hash -> unit t
    | Typed_originated : {
        arg_ty : ('arg * _) Ty.t;
        contract_hash : Contract_hash.t;
        entrypoint : Entrypoint.t;
      }
        -> 'arg t
    | Typed_tx_rollup : {
        arg_ty : (('a ticket, tx_rollup_l2_address) pair * _) Ty.t;
        tx_rollup : Tx_rollup.t;
      }
        -> ('a ticket, tx_rollup_l2_address) pair t
    | Typed_sc_rollup : {
        arg_ty : ('arg * _) Ty.t;
        sc_rollup : Sc_rollup.t;
        entrypoint : Entrypoint.t;
      }
        -> 'arg t

  let destination : type a. a t -> Destination.t = function
    | Typed_implicit pkh -> Destination.Contract (Implicit pkh)
    | Typed_originated {contract_hash; _} ->
        Destination.Contract (Originated contract_hash)
    | Typed_tx_rollup {tx_rollup; _} -> Destination.Tx_rollup tx_rollup
    | Typed_sc_rollup {sc_rollup; _} -> Destination.Sc_rollup sc_rollup

  let arg_ty : type a. a t -> a Ty.ty_ex_c = function
    | Typed_implicit _ -> (Ty.Ty_ex_c Ty.unit_t : a Ty.ty_ex_c)
    | Typed_originated {arg_ty; _} -> Ty_ex_c arg_ty
    | Typed_tx_rollup {arg_ty; _} -> Ty_ex_c arg_ty
    | Typed_sc_rollup {arg_ty; _} -> Ty_ex_c arg_ty

  let entrypoint : type a. a t -> Entrypoint.t = function
    | Typed_implicit _ -> Entrypoint.default
    | Typed_tx_rollup _ -> Tx_rollup.deposit_entrypoint
    | Typed_originated {entrypoint; _} | Typed_sc_rollup {entrypoint; _} ->
        entrypoint

  module Internal_for_tests = struct
    let typed_exn :
        type a ac. (a, ac) Ty.ty -> Destination.t -> Entrypoint.t -> a t =
     fun arg_ty destination entrypoint ->
      match (destination, arg_ty.value) with
      | Contract (Implicit pkh), Ty_value.Unit_t -> Typed_implicit pkh
      | Contract (Implicit _), _ ->
          invalid_arg "Implicit contracts expect type unit"
      | Contract (Originated contract_hash), _ ->
          Typed_originated {arg_ty; contract_hash; entrypoint}
      | ( Tx_rollup tx_rollup,
          Ty_value.Pair_t
            ({value = Ticket_t _; _}, {value = Tx_rollup_l2_address_t; _}, _, _)
        ) ->
          (Typed_tx_rollup {arg_ty; tx_rollup} : a t)
      | Tx_rollup _, _ ->
          invalid_arg
            "Transaction rollups expect type (pair (ticket _) \
             tx_rollup_l2_address)"
      | Sc_rollup sc_rollup, _ ->
          Typed_sc_rollup {arg_ty; sc_rollup; entrypoint}
  end
end

and Operation : sig
  type 'kind internal_operation_contents =
    | Transaction_to_implicit : {
        destination : Signature.Public_key_hash.t;
        amount : Tez.tez;
      }
        -> Kind.transaction internal_operation_contents
    | Transaction_to_smart_contract : {
        (* The [unparsed_parameters] field may seem useless since we have
           access to a typed version of the field (with [parameters_ty] and
           [parameters]), but we keep it so that we do not have to unparse the
           typed version in order to produce the receipt
           ([Apply_internal_results.internal_operation_contents]). *)
        destination : Contract_hash.t;
        amount : Tez.tez;
        entrypoint : Entrypoint.t;
        location : Script.location;
        parameters_ty : ('a * _) Ty.t;
        parameters : 'a;
        unparsed_parameters : Script.expr;
      }
        -> Kind.transaction internal_operation_contents
    | Transaction_to_tx_rollup : {
        destination : Tx_rollup.t;
        parameters_ty : (('a ticket, tx_rollup_l2_address) pair * _) Ty.t;
        parameters : ('a ticket, tx_rollup_l2_address) pair;
        unparsed_parameters : Script.expr;
      }
        -> Kind.transaction internal_operation_contents
    | Transaction_to_sc_rollup : {
        destination : Sc_rollup.t;
        entrypoint : Entrypoint.t;
        parameters_ty : ('a * _) Ty.t;
        parameters : 'a;
        unparsed_parameters : Script.expr;
      }
        -> Kind.transaction internal_operation_contents
    | Event : {
        ty : Script.expr;
        tag : Entrypoint.t;
        unparsed_data : Script.expr;
      }
        -> Kind.event internal_operation_contents
    | Origination : {
        delegate : Signature.Public_key_hash.t option;
        code : Script.expr;
        unparsed_storage : Script.expr;
        credit : Tez.tez;
        preorigination : Contract_hash.t;
        storage_type : ('storage * _) Ty.t;
        storage : 'storage;
      }
        -> Kind.origination internal_operation_contents
    | Delegation :
        Signature.Public_key_hash.t option
        -> Kind.delegation internal_operation_contents

  and 'kind internal_operation = {
    source : Contract.t;
    operation : 'kind internal_operation_contents;
    nonce : int;
  }

  and packed_internal_operation =
    | Internal_operation : 'kind internal_operation -> packed_internal_operation
  [@@ocaml.unboxed]

  and t = {
    piop : packed_internal_operation;
    lazy_storage_diff : Lazy_storage.diffs option;
  }
end = struct
  type 'kind internal_operation_contents =
    | Transaction_to_implicit : {
        destination : Signature.Public_key_hash.t;
        amount : Tez.tez;
      }
        -> Kind.transaction internal_operation_contents
    | Transaction_to_smart_contract : {
        (* The [unparsed_parameters] field may seem useless since we have
           access to a typed version of the field (with [parameters_ty] and
           [parameters]), but we keep it so that we do not have to unparse the
           typed version in order to produce the receipt
           ([Apply_internal_results.internal_operation_contents]). *)
        destination : Contract_hash.t;
        amount : Tez.tez;
        entrypoint : Entrypoint.t;
        location : Script.location;
        parameters_ty : ('a * _) Ty.t;
        parameters : 'a;
        unparsed_parameters : Script.expr;
      }
        -> Kind.transaction internal_operation_contents
    | Transaction_to_tx_rollup : {
        destination : Tx_rollup.t;
        parameters_ty : (('a ticket, tx_rollup_l2_address) pair * _) Ty.t;
        parameters : ('a ticket, tx_rollup_l2_address) pair;
        unparsed_parameters : Script.expr;
      }
        -> Kind.transaction internal_operation_contents
    | Transaction_to_sc_rollup : {
        destination : Sc_rollup.t;
        entrypoint : Entrypoint.t;
        parameters_ty : ('a * _) Ty.t;
        parameters : 'a;
        unparsed_parameters : Script.expr;
      }
        -> Kind.transaction internal_operation_contents
    | Event : {
        ty : Script.expr;
        tag : Entrypoint.t;
        unparsed_data : Script.expr;
      }
        -> Kind.event internal_operation_contents
    | Origination : {
        delegate : Signature.Public_key_hash.t option;
        code : Script.expr;
        unparsed_storage : Script.expr;
        credit : Tez.tez;
        preorigination : Contract_hash.t;
        storage_type : ('storage * _) Ty.t;
        storage : 'storage;
      }
        -> Kind.origination internal_operation_contents
    | Delegation :
        Signature.Public_key_hash.t option
        -> Kind.delegation internal_operation_contents

  and 'kind internal_operation = {
    source : Contract.t;
    operation : 'kind internal_operation_contents;
    nonce : int;
  }

  and packed_internal_operation =
    | Internal_operation : 'kind internal_operation -> packed_internal_operation
  [@@ocaml.unboxed]

  and t = {
    piop : packed_internal_operation;
    lazy_storage_diff : Lazy_storage.diffs option;
  }
end

and Big_map : sig
  type ('key, 'value) t =
    | Big_map : {
        id : Alpha_context.Big_map.Id.t option;
        diff : ('key, 'value) big_map_overlay;
        key_type : 'key Ty.comparable_ty;
        value_type : ('value * _) Ty.t;
      }
        -> ('key, 'value) t
end = struct
  type ('key, 'value) t =
    | Big_map : {
        id : Alpha_context.Big_map.Id.t option;
        diff : ('key, 'value) big_map_overlay;
        key_type : 'key Ty.comparable_ty;
        value_type : ('value * _) Ty.t;
      }
        -> ('key, 'value) t
end

type ('arg, 'storage) script =
  | Script : {
      code :
        ( ('arg, 'storage) pair,
          (Operation.t boxed_list, 'storage) pair )
        Lambda.t;
      arg_type : ('arg, _) Ty.ty;
      storage : 'storage;
      storage_type : ('storage, _) Ty.ty;
      views : view_map;
      entrypoints : 'arg entrypoints;
      code_size : Cache_memory_helpers.sint;
    }
      -> ('arg, 'storage) script

let manager_kind :
    type kind. kind Operation.internal_operation_contents -> kind Kind.manager =
  function
  | Transaction_to_implicit _ -> Kind.Transaction_manager_kind
  | Transaction_to_smart_contract _ -> Kind.Transaction_manager_kind
  | Transaction_to_tx_rollup _ -> Kind.Transaction_manager_kind
  | Transaction_to_sc_rollup _ -> Kind.Transaction_manager_kind
  | Event _ -> Kind.Event_manager_kind
  | Origination _ -> Kind.Origination_manager_kind
  | Delegation _ -> Kind.Delegation_manager_kind

type ('before_top, 'before, 'result_top, 'result) kinstr =
  ('before_top, 'before, 'result_top, 'result) Instruction.kinstr

and ('arg, 'ret) lambda = ('arg, 'ret) Lambda.t

and 'arg typed_contract = 'arg Typed_contract.t

and ('a, 'b, 'c, 'd) continuation = ('a, 'b, 'c, 'd) Instruction.continuation

and ('a, 's, 'b, 'f, 'c, 'u) logging_function =
  ('a, 's, 'b, 'f, 'c, 'u) Instruction.logging_function

and execution_trace = Instruction.execution_trace

and logger = Instruction.logger

and ('ty, 'comparable) ty_value = ('ty * 'comparable) Ty_value.t

and 'ty comparable_ty = 'ty Ty.comparable_ty

and ('ty, 'comparable) ty = ('ty, 'comparable) Ty.ty

and ('top_ty, 'resty) stack_ty_value = ('top_ty * 'resty) Ty_value.s

and ('top_ty, 'resty) stack_ty = ('top_ty, 'resty) Ty.stack

and ('key, 'value) big_map = ('key, 'value) Big_map.t

and ('a, 's, 'r, 'f) kdescr = ('a, 's, 'r, 'f) Instruction.kdescr

and ('c, 'v, 'd, 'w, 'a, 'x, 'b, 'y) stack_prefix_preservation_witness =
  ('c, 'v, 'd, 'w, 'a, 'x, 'b, 'y) Instruction.stack_prefix_preservation_witness

and ('a, 'b, 'c, 'd, 'e, 'f) comb_gadt_witness =
  ('a, 'b, 'c, 'd, 'e, 'f) Instruction.comb_gadt_witness

and ('a, 'b, 'c, 'd, 'e, 'f) uncomb_gadt_witness =
  ('a, 'b, 'c, 'd, 'e, 'f) Instruction.uncomb_gadt_witness

and ('before, 'after) comb_get_gadt_witness =
  ('before, 'after) Instruction.comb_get_gadt_witness

and ('value, 'before, 'after) comb_set_gadt_witness =
  ('value, 'before, 'after) Instruction.comb_set_gadt_witness

and ('a, 'b, 'c, 'd) dup_n_gadt_witness =
  ('a, 'b, 'c, 'd) Instruction.dup_n_gadt_witness

and ('input, 'output) view_signature =
  ('input, 'output) Instruction.view_signature

and 'kind internal_operation_contents =
  'kind Operation.internal_operation_contents

and 'kind internal_operation = 'kind Operation.internal_operation

and packed_internal_operation = Operation.packed_internal_operation

and operation = Operation.t

let kinstr_location = Instruction.kinstr_location

let ty_size = Ty.ty_size

let is_comparable = Ty.is_comparable

type 'v ty_ex_c = 'v Ty.ty_ex_c

type ex_ty = Ex_ty : ('a, _) ty -> ex_ty

let unit_t = Ty.unit_t

let int_t = Ty.int_t

let nat_t = Ty.nat_t

let signature_t = Ty.signature_t

let string_t = Ty.string_t

let bytes_t = Ty.bytes_t

let mutez_t = Ty.mutez_t

let key_hash_t = Ty.key_hash_t

let key_t = Ty.key_t

let timestamp_t = Ty.timestamp_t

let address_t = Ty.address_t

let tx_rollup_l2_address_t = Ty.tx_rollup_l2_address_t

let bool_t = Ty.bool_t

let pair_t = Ty.pair_t

let pair_3_t = Ty.pair_3_t

let comparable_pair_t = Ty.comparable_pair_t

let comparable_pair_3_t = Ty.comparable_pair_3_t

let union_t = Ty.union_t

let comparable_union_t = Ty.comparable_union_t

let union_bytes_bool_t = Ty.union_bytes_bool_t

let lambda_t = Ty.lambda_t

let option_t = Ty.option_t

let comparable_option_t = Ty.comparable_option_t

let option_mutez_t = Ty.option_mutez_t

let option_string_t = Ty.option_string_t

let option_bytes_t = Ty.option_bytes_t

let option_nat_t = Ty.option_nat_t

let option_pair_nat_nat_t = Ty.option_pair_nat_nat_t

let option_pair_nat_mutez_t = Ty.option_pair_nat_mutez_t

let option_pair_mutez_mutez_t = Ty.option_pair_mutez_mutez_t

let option_pair_int_nat_t = Ty.option_pair_int_nat_t

let list_t = Ty.list_t

let list_operation_t = Ty.list_operation_t

let set_t = Ty.set_t

let map_t = Ty.map_t

let big_map_t = Ty.big_map_t

let contract_t = Ty.contract_t

let contract_unit_t = Ty.contract_unit_t

let sapling_transaction_t = Ty.sapling_transaction_t

let sapling_transaction_deprecated_t = Ty.sapling_transaction_deprecated_t

let sapling_state_t = Ty.sapling_state_t

let operation_t = Ty.operation_t

let chain_id_t = Ty.chain_id_t

let never_t = Ty.never_t

let bls12_381_g1_t = Ty.bls12_381_g1_t

let bls12_381_g2_t = Ty.bls12_381_g2_t

let bls12_381_fr_t = Ty.bls12_381_fr_t

let ticket_t = Ty.ticket_t

let chest_key_t = Ty.chest_key_t

let chest_t = Ty.chest_t

type 'a kinstr_traverse = 'a Instruction.kinstr_traverse

let kinstr_traverse = Instruction.kinstr_traverse

type 'a ty_traverse = 'a Ty.ty_traverse

let ty_traverse = Ty.ty_traverse

type 'accu stack_ty_traverse = 'accu Ty.stack_traverse

let stack_ty_traverse = Ty.stack_traverse

type 'a value_traverse = 'a Ty.ty_value_traverse

let value_traverse = Ty.ty_value_traverse

let stack_top_ty = Ty.stack_top