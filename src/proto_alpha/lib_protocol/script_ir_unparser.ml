(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

open Alpha_context
open Micheline
open Script_typed_ir
open Michelson_v1_primitives
module Unparse_costs = Michelson_v1_gas.Cost_of.Unparsing

type unparsing_mode = Optimized | Readable | Optimized_legacy

(* This part contains the unparsing that does not depend on parsing
   (everything that cannot contain a lambda). The rest is located at
   the end of the file. *)

let unparse_memo_size ~loc memo_size =
  let z = Sapling.Memo_size.unparse_to_z memo_size in
  Int (loc, z)

let rec unparse_ty_and_entrypoints_uncarbonated :
    type a ac loc.
    loc:loc -> (a, ac) ty -> a entrypoints_node -> loc Script.michelson_node =
 fun ~loc ty {nested = nested_entrypoints; at_node} ->
  let name, args =
    match ty with
    | Unit_t -> (T_unit, [])
    | Int_t -> (T_int, [])
    | Nat_t -> (T_nat, [])
    | Signature_t -> (T_signature, [])
    | String_t -> (T_string, [])
    | Bytes_t -> (T_bytes, [])
    | Mutez_t -> (T_mutez, [])
    | Bool_t -> (T_bool, [])
    | Key_hash_t -> (T_key_hash, [])
    | Key_t -> (T_key, [])
    | Timestamp_t -> (T_timestamp, [])
    | Address_t -> (T_address, [])
    | Tx_rollup_l2_address_t -> (T_tx_rollup_l2_address, [])
    | Operation_t -> (T_operation, [])
    | Chain_id_t -> (T_chain_id, [])
    | Never_t -> (T_never, [])
    | Bls12_381_g1_t -> (T_bls12_381_g1, [])
    | Bls12_381_g2_t -> (T_bls12_381_g2, [])
    | Bls12_381_fr_t -> (T_bls12_381_fr, [])
    | Contract_t (ut, _meta) ->
        let t =
          unparse_ty_and_entrypoints_uncarbonated ~loc ut no_entrypoints
        in
        (T_contract, [t])
    | Pair_t (utl, utr, _meta, _) -> (
        let tl =
          unparse_ty_and_entrypoints_uncarbonated ~loc utl no_entrypoints
        in
        let tr =
          unparse_ty_and_entrypoints_uncarbonated ~loc utr no_entrypoints
        in
        (* Fold [pair a1 (pair ... (pair an-1 an))] into [pair a1 ... an] *)
        (* Note that the folding does not happen if the pair on the right has an
           annotation because this annotation would be lost *)
        match tr with
        | Prim (_, T_pair, ts, []) -> (T_pair, tl :: ts)
        | _ -> (T_pair, [tl; tr]))
    | Or_t (utl, utr, _meta, _) ->
        let entrypoints_l, entrypoints_r =
          match nested_entrypoints with
          | Entrypoints_None -> (no_entrypoints, no_entrypoints)
          | Entrypoints_Or {left; right} -> (left, right)
        in
        let tl =
          unparse_ty_and_entrypoints_uncarbonated ~loc utl entrypoints_l
        in
        let tr =
          unparse_ty_and_entrypoints_uncarbonated ~loc utr entrypoints_r
        in
        (T_or, [tl; tr])
    | Lambda_t (uta, utr, _meta) ->
        let ta =
          unparse_ty_and_entrypoints_uncarbonated ~loc uta no_entrypoints
        in
        let tr =
          unparse_ty_and_entrypoints_uncarbonated ~loc utr no_entrypoints
        in
        (T_lambda, [ta; tr])
    | Option_t (ut, _meta, _) ->
        let ut =
          unparse_ty_and_entrypoints_uncarbonated ~loc ut no_entrypoints
        in
        (T_option, [ut])
    | List_t (ut, _meta) ->
        let t =
          unparse_ty_and_entrypoints_uncarbonated ~loc ut no_entrypoints
        in
        (T_list, [t])
    | Ticket_t (ut, _meta) ->
        let t = unparse_comparable_ty_uncarbonated ~loc ut in
        (T_ticket, [t])
    | Set_t (ut, _meta) ->
        let t = unparse_comparable_ty_uncarbonated ~loc ut in
        (T_set, [t])
    | Map_t (uta, utr, _meta) ->
        let ta = unparse_comparable_ty_uncarbonated ~loc uta in
        let tr =
          unparse_ty_and_entrypoints_uncarbonated ~loc utr no_entrypoints
        in
        (T_map, [ta; tr])
    | Big_map_t (uta, utr, _meta) ->
        let ta = unparse_comparable_ty_uncarbonated ~loc uta in
        let tr =
          unparse_ty_and_entrypoints_uncarbonated ~loc utr no_entrypoints
        in
        (T_big_map, [ta; tr])
    | Sapling_transaction_t memo_size ->
        (T_sapling_transaction, [unparse_memo_size ~loc memo_size])
    | Sapling_transaction_deprecated_t memo_size ->
        (T_sapling_transaction_deprecated, [unparse_memo_size ~loc memo_size])
    | Sapling_state_t memo_size ->
        (T_sapling_state, [unparse_memo_size ~loc memo_size])
    | Chest_key_t -> (T_chest_key, [])
    | Chest_t -> (T_chest, [])
  in
  let annot =
    match at_node with
    | None -> []
    | Some {name; original_type_expr = _} ->
        [Entrypoint.unparse_as_field_annot name]
  in
  Prim (loc, name, args, annot)

and unparse_comparable_ty_uncarbonated :
    type a loc. loc:loc -> a comparable_ty -> loc Script.michelson_node =
 fun ~loc ty -> unparse_ty_and_entrypoints_uncarbonated ~loc ty no_entrypoints

let unparse_ty_uncarbonated ~loc ty =
  unparse_ty_and_entrypoints_uncarbonated ~loc ty no_entrypoints

let unparse_ty ~loc ty =
  let open Gas_monad.Syntax in
  let+ () = Gas_monad.consume_gas (Unparse_costs.unparse_type ty) in
  unparse_ty_uncarbonated ~loc ty

let unparse_parameter_ty ~loc ty ~entrypoints =
  let open Gas_monad.Syntax in
  let+ () = Gas_monad.consume_gas (Unparse_costs.unparse_type ty) in
  unparse_ty_and_entrypoints_uncarbonated ~loc ty entrypoints.root

let serialize_ty_for_error ty =
  (*
    Types are bounded by [Constants.michelson_maximum_type_size], so
    [unparse_ty_uncarbonated] and [strip_locations] are bounded in time.

    It is hence OK to use them in errors that are not caught in the validation
    (only once in apply).
  *)
  unparse_ty_uncarbonated ~loc:() ty |> Micheline.strip_locations

let rec unparse_stack_uncarbonated :
    type a s. (a, s) stack_ty -> Script.expr list = function
  | Bot_t -> []
  | Item_t (ty, rest) ->
      let uty = unparse_ty_uncarbonated ~loc:() ty in
      let urest = unparse_stack_uncarbonated rest in
      strip_locations uty :: urest

let serialize_stack_for_error ctxt stack_ty =
  match Gas.level ctxt with
  | Unaccounted -> unparse_stack_uncarbonated stack_ty
  | Limited _ -> []

let unparse_unit ~loc () = Gas_monad.return (Prim (loc, D_Unit, [], []))

let unparse_int ~loc v = Gas_monad.return (Int (loc, Script_int.to_zint v))

let unparse_nat ~loc v = Gas_monad.return (Int (loc, Script_int.to_zint v))

let unparse_string ~loc s =
  Gas_monad.return (String (loc, Script_string.to_string s))

let unparse_bytes ~loc s = Gas_monad.return (Bytes (loc, s))

let unparse_bool ~loc b =
  Gas_monad.return (Prim (loc, (if b then D_True else D_False), [], []))

let unparse_timestamp ~loc mode t =
  let open Gas_monad.Syntax in
  match mode with
  | Optimized | Optimized_legacy ->
      return (Int (loc, Script_timestamp.to_zint t))
  | Readable -> (
      let+ () = Gas_monad.consume_gas Unparse_costs.timestamp_readable in
      match Script_timestamp.to_notation t with
      | None -> Int (loc, Script_timestamp.to_zint t)
      | Some s -> String (loc, s))

let unparse_address ~loc mode {destination; entrypoint} =
  let open Gas_monad.Syntax in
  match mode with
  | Optimized | Optimized_legacy ->
      let+ () = Gas_monad.consume_gas Unparse_costs.contract_optimized in
      let bytes =
        Data_encoding.Binary.to_bytes_exn
          Data_encoding.(tup2 Destination.encoding Entrypoint.value_encoding)
          (destination, entrypoint)
      in
      Bytes (loc, bytes)
  | Readable ->
      let+ () = Gas_monad.consume_gas Unparse_costs.contract_readable in
      let notation =
        Destination.to_b58check destination
        ^ Entrypoint.to_address_suffix entrypoint
      in
      String (loc, notation)

let unparse_tx_rollup_l2_address ~loc mode (tx_address : tx_rollup_l2_address) =
  let open Gas_monad.Syntax in
  let tx_address = Indexable.to_value tx_address in
  match mode with
  | Optimized | Optimized_legacy ->
      let+ () = Gas_monad.consume_gas Unparse_costs.contract_optimized in
      let bytes =
        Data_encoding.Binary.to_bytes_exn
          Tx_rollup_l2_address.encoding
          tx_address
      in
      Bytes (loc, bytes)
  | Readable ->
      let+ () = Gas_monad.consume_gas Unparse_costs.contract_readable in
      let b58check = Tx_rollup_l2_address.to_b58check tx_address in
      String (loc, b58check)

let unparse_contract ~loc mode typed_contract =
  let destination = Typed_contract.destination typed_contract in
  let entrypoint = Typed_contract.entrypoint typed_contract in
  let address = {destination; entrypoint} in
  unparse_address ~loc mode address

let unparse_signature ~loc mode s =
  let open Gas_monad.Syntax in
  let s = Script_signature.get s in
  match mode with
  | Optimized | Optimized_legacy ->
      let+ () = Gas_monad.consume_gas Unparse_costs.signature_optimized in
      let bytes = Data_encoding.Binary.to_bytes_exn Signature.encoding s in
      Bytes (loc, bytes)
  | Readable ->
      let+ () = Gas_monad.consume_gas Unparse_costs.signature_readable in
      String (loc, Signature.to_b58check s)

let unparse_mutez ~loc v =
  Gas_monad.return (Int (loc, Z.of_int64 (Tez.to_mutez v)))

let unparse_key ~loc mode k =
  let open Gas_monad.Syntax in
  match mode with
  | Optimized | Optimized_legacy ->
      let+ () = Gas_monad.consume_gas Unparse_costs.public_key_optimized in
      let bytes =
        Data_encoding.Binary.to_bytes_exn Signature.Public_key.encoding k
      in
      Bytes (loc, bytes)
  | Readable ->
      let+ () = Gas_monad.consume_gas Unparse_costs.public_key_readable in
      String (loc, Signature.Public_key.to_b58check k)

let unparse_key_hash ~loc mode k =
  let open Gas_monad.Syntax in
  match mode with
  | Optimized | Optimized_legacy ->
      let+ () = Gas_monad.consume_gas Unparse_costs.key_hash_optimized in
      let bytes =
        Data_encoding.Binary.to_bytes_exn Signature.Public_key_hash.encoding k
      in
      Bytes (loc, bytes)
  | Readable ->
      let+ () = Gas_monad.consume_gas Unparse_costs.key_hash_readable in
      String (loc, Signature.Public_key_hash.to_b58check k)

(* Operations are only unparsed during the production of execution traces of
   the interpreter. *)
let unparse_operation ~loc {piop; lazy_storage_diff = _} =
  let open Gas_monad.Syntax in
  let iop = Apply_internal_results.packed_internal_operation piop in
  let bytes =
    Data_encoding.Binary.to_bytes_exn
      Apply_internal_results.internal_operation_encoding
      iop
  in
  let+ () = Gas_monad.consume_gas (Unparse_costs.operation bytes) in
  Bytes (loc, bytes)

let unparse_chain_id ~loc mode chain_id =
  let open Gas_monad.Syntax in
  match mode with
  | Optimized | Optimized_legacy ->
      let+ () = Gas_monad.consume_gas Unparse_costs.chain_id_optimized in
      let bytes =
        Data_encoding.Binary.to_bytes_exn Script_chain_id.encoding chain_id
      in
      Bytes (loc, bytes)
  | Readable ->
      let+ () = Gas_monad.consume_gas Unparse_costs.chain_id_readable in
      String (loc, Script_chain_id.to_b58check chain_id)

let unparse_bls12_381_g1 ~loc x =
  let open Gas_monad.Syntax in
  let+ () = Gas_monad.consume_gas Unparse_costs.bls12_381_g1 in
  let bytes = Script_bls.G1.to_bytes x in
  Bytes (loc, bytes)

let unparse_bls12_381_g2 ~loc x =
  let open Gas_monad.Syntax in
  let+ () = Gas_monad.consume_gas Unparse_costs.bls12_381_g2 in
  let bytes = Script_bls.G2.to_bytes x in
  Bytes (loc, bytes)

let unparse_bls12_381_fr ~loc x =
  let open Gas_monad.Syntax in
  let+ () = Gas_monad.consume_gas Unparse_costs.bls12_381_fr in
  let bytes = Script_bls.Fr.to_bytes x in
  Bytes (loc, bytes)

let unparse_with_data_encoding ~loc ctxt s unparse_cost encoding =
  Lwt.return
    ( Gas.consume ctxt unparse_cost >|? fun ctxt ->
      let bytes = Data_encoding.Binary.to_bytes_exn encoding s in
      (Bytes (loc, bytes), ctxt) )

(* -- Unparsing data of complex types -- *)

type ('ty, 'depth) comb_witness =
  | Comb_Pair : ('t, 'd) comb_witness -> (_ * 't, unit -> 'd) comb_witness
  | Comb_Any : (_, _) comb_witness

module type UNPARSING_MONAD = sig
  type 'a m

  val return : 'a -> 'a m

  val ( let* ) : 'a m -> ('a -> 'b m) -> 'b m

  val ( let+ ) : 'a m -> ('a -> 'b) -> 'b m
end

module Pure_unparsing_monad :
  UNPARSING_MONAD with type 'a m = 'a Gas_monad.pure_gas_monad = struct
  type 'a m = 'a Gas_monad.pure_gas_monad

  let return = Gas_monad.return

  let ( let* ) = Gas_monad.Syntax.( let* )

  let ( let+ ) = Gas_monad.Syntax.( let+ )
end

module Lwt_unparsing_monad :
  UNPARSING_MONAD with type 'a m = context -> ('a * context) tzresult Lwt.t =
struct
  open Lwt_result_syntax

  type 'a m = context -> ('a * context) tzresult Lwt.t

  let return x ctxt = return (x, ctxt)

  let ( let* ) m f ctxt =
    let* x, ctxt = m ctxt in
    f x ctxt

  let ( let+ ) m f =
    let* x = m in
    return (f x)
end

module Unparsing_coumpoud (M : UNPARSING_MONAD) = struct
  let unparse_pair (type r) ~loc unparse_l unparse_r mode
      (r_comb_witness : (r, unit -> unit -> _) comb_witness) (l, (r : r)) =
    let open M in
    let* l = unparse_l l in
    let+ r = unparse_r r in
    (* Fold combs.
       For combs, three notations are supported:
       - a) [Pair x1 (Pair x2 ... (Pair xn-1 xn) ...)],
       - b) [Pair x1 x2 ... xn-1 xn], and
       - c) [{x1; x2; ...; xn-1; xn}].
       In readable mode, we always use b),
       in optimized mode we use the shortest to serialize:
       - for n=2, [Pair x1 x2],
       - for n=3, [Pair x1 (Pair x2 x3)],
       - for n>=4, [{x1; x2; ...; xn}].
    *)
    match (mode, r_comb_witness, r) with
    | Optimized, Comb_Pair _, Micheline.Seq (_, r) ->
        (* Optimized case n > 4 *)
        Micheline.Seq (loc, l :: r)
    | ( Optimized,
        Comb_Pair (Comb_Pair _),
        Prim (_, D_Pair, [x2; Prim (_, D_Pair, [x3; x4], [])], []) ) ->
        (* Optimized case n = 4 *)
        Micheline.Seq (loc, [l; x2; x3; x4])
    | Readable, Comb_Pair _, Prim (_, D_Pair, xs, []) ->
        (* Readable case n > 2 *)
        Prim (loc, D_Pair, l :: xs, [])
    | _ ->
        (* The remaining cases are:
            - Optimized n = 2,
            - Optimized n = 3, and
            - Readable n = 2,
            - Optimized_legacy, any n *)
        Prim (loc, D_Pair, [l; r], [])

  let unparse_or ~loc unparse_l unparse_r =
    let open M in
    function
    | L l ->
        let+ l = unparse_l l in
        Prim (loc, D_Left, [l], [])
    | R r ->
        let+ r = unparse_r r in
        Prim (loc, D_Right, [r], [])

  let unparse_option ~loc unparse_v =
    let open M in
    function
    | Some v ->
        let+ v = unparse_v v in
        Prim (loc, D_Some, [v], [])
    | None -> return (Prim (loc, D_None, [], []))
end

module Unparsing_compound_pure_gas = Unparsing_coumpoud (Pure_unparsing_monad)
module Unparsing_compound_lwt = Unparsing_coumpoud (Lwt_unparsing_monad)

(* -- Unparsing data of comparable types -- *)

let comb_witness2 :
    type t tc. (t, tc) ty -> (t, unit -> unit -> unit) comb_witness = function
  | Pair_t (_, Pair_t _, _, _) -> Comb_Pair (Comb_Pair Comb_Any)
  | Pair_t _ -> Comb_Pair Comb_Any
  | _ -> Comb_Any

let rec unparse_comparable_data_rec :
    type a loc.
    loc:loc ->
    unparsing_mode ->
    a comparable_ty ->
    a ->
    loc Script.michelson_node Gas_monad.pure_gas_monad =
 fun ~loc mode ty a ->
  (* No need for stack_depth here. Unlike [unparse_data],
     [unparse_comparable_data] doesn't call [unparse_code].
     The stack depth is bounded by the type depth, currently bounded
     by 1000 (michelson_maximum_type_size). *)
  let open Gas_monad.Syntax in
  let* () = Gas_monad.consume_gas Unparse_costs.unparse_data_cycle in
  (* We could have a smaller cost but let's keep it consistent with
     [unparse_data] for now. *)
  match (ty, a) with
  | Unit_t, v -> unparse_unit ~loc v
  | Int_t, v -> unparse_int ~loc v
  | Nat_t, v -> unparse_nat ~loc v
  | String_t, s -> unparse_string ~loc s
  | Bytes_t, s -> unparse_bytes ~loc s
  | Bool_t, b -> unparse_bool ~loc b
  | Timestamp_t, t -> unparse_timestamp ~loc mode t
  | Address_t, address -> unparse_address ~loc mode address
  | Tx_rollup_l2_address_t, address ->
      unparse_tx_rollup_l2_address ~loc mode address
  | Signature_t, s -> unparse_signature ~loc mode s
  | Mutez_t, v -> unparse_mutez ~loc v
  | Key_t, k -> unparse_key ~loc mode k
  | Key_hash_t, k -> unparse_key_hash ~loc mode k
  | Chain_id_t, chain_id -> unparse_chain_id ~loc mode chain_id
  | Pair_t (tl, tr, _, YesYes), pair ->
      let r_witness = comb_witness2 tr in
      let unparse_l v = unparse_comparable_data_rec ~loc mode tl v in
      let unparse_r v = unparse_comparable_data_rec ~loc mode tr v in
      Unparsing_compound_pure_gas.unparse_pair
        ~loc
        unparse_l
        unparse_r
        mode
        r_witness
        pair
  | Or_t (tl, tr, _, YesYes), v ->
      let unparse_l v = unparse_comparable_data_rec ~loc mode tl v in
      let unparse_r v = unparse_comparable_data_rec ~loc mode tr v in
      Unparsing_compound_pure_gas.unparse_or ~loc unparse_l unparse_r v
  | Option_t (t, _, Yes), v ->
      let unparse_v v = unparse_comparable_data_rec ~loc mode t v in
      Unparsing_compound_pure_gas.unparse_option ~loc unparse_v v
  | Never_t, _ -> .

let account_for_future_serialization_cost unparsed_data ctxt =
  Gas.consume ctxt (Script.strip_locations_cost unparsed_data) >>? fun ctxt ->
  let unparsed_data = Micheline.strip_locations unparsed_data in
  Gas.consume ctxt (Script.micheline_serialization_cost unparsed_data)
  >|? fun ctxt -> (unparsed_data, ctxt)

type unparse_code_rec =
  t ->
  stack_depth:int ->
  unparsing_mode ->
  Script.node ->
  ((canonical_location, prim) node * t, error trace) result Lwt.t

module type MICHELSON_PARSER = sig
  val opened_ticket_type :
    Script.location ->
    'a comparable_ty ->
    (address, ('a, Script_int.n Script_int.num) pair) pair comparable_ty
    tzresult

  val parse_packable_ty :
    context ->
    stack_depth:int ->
    legacy:bool ->
    Script.node ->
    (ex_ty * context) tzresult

  val parse_data :
    unparse_code_rec:unparse_code_rec ->
    elab_conf:Script_ir_translator_config.elab_config ->
    stack_depth:int ->
    context ->
    allow_forged:bool ->
    ('a, 'ac) ty ->
    Script.node ->
    ('a * t) tzresult Lwt.t
end

module Data_unparser (P : MICHELSON_PARSER) = struct
  open Script_tc_errors

  (* -- Unparsing data of any type -- *)
  let rec unparse_data_rec :
      type a ac.
      context ->
      stack_depth:int ->
      unparsing_mode ->
      (a, ac) ty ->
      a ->
      (Script.node * context) tzresult Lwt.t =
   fun ctxt ~stack_depth mode ty a ->
    Gas.consume ctxt Unparse_costs.unparse_data_cycle >>?= fun ctxt ->
    let non_terminal_recursion ctxt mode ty a =
      if Compare.Int.(stack_depth > 10_000) then
        tzfail Script_tc_errors.Unparsing_too_many_recursive_calls
      else unparse_data_rec ctxt ~stack_depth:(stack_depth + 1) mode ty a
    in
    let loc = Micheline.dummy_location in
    let return x = Lwt.return @@ Gas_monad.run_pure_gas ctxt x in
    match (ty, a) with
    | Unit_t, v -> return @@ unparse_unit ~loc v
    | Int_t, v -> return @@ unparse_int ~loc v
    | Nat_t, v -> return @@ unparse_nat ~loc v
    | String_t, s -> return @@ unparse_string ~loc s
    | Bytes_t, s -> return @@ unparse_bytes ~loc s
    | Bool_t, b -> return @@ unparse_bool ~loc b
    | Timestamp_t, t -> return @@ unparse_timestamp ~loc mode t
    | Address_t, address -> return @@ unparse_address ~loc mode address
    | Tx_rollup_l2_address_t, address ->
        return @@ unparse_tx_rollup_l2_address ~loc mode address
    | Contract_t _, contract -> return @@ unparse_contract ~loc mode contract
    | Signature_t, s -> return @@ unparse_signature ~loc mode s
    | Mutez_t, v -> return @@ unparse_mutez ~loc v
    | Key_t, k -> return @@ unparse_key ~loc mode k
    | Key_hash_t, k -> return @@ unparse_key_hash ~loc mode k
    | Operation_t, operation -> return @@ unparse_operation ~loc operation
    | Chain_id_t, chain_id -> return @@ unparse_chain_id ~loc mode chain_id
    | Bls12_381_g1_t, x -> return @@ unparse_bls12_381_g1 ~loc x
    | Bls12_381_g2_t, x -> return @@ unparse_bls12_381_g2 ~loc x
    | Bls12_381_fr_t, x -> return @@ unparse_bls12_381_fr ~loc x
    | Pair_t (tl, tr, _, _), pair ->
        let r_witness = comb_witness2 tr in
        let unparse_l v ctxt = non_terminal_recursion ctxt mode tl v in
        let unparse_r v ctxt = non_terminal_recursion ctxt mode tr v in
        Unparsing_compound_lwt.unparse_pair
          ~loc
          unparse_l
          unparse_r
          mode
          r_witness
          pair
          ctxt
    | Or_t (tl, tr, _, _), v ->
        let unparse_l v ctxt = non_terminal_recursion ctxt mode tl v in
        let unparse_r v ctxt = non_terminal_recursion ctxt mode tr v in
        Unparsing_compound_lwt.unparse_or ~loc unparse_l unparse_r v ctxt
    | Option_t (t, _, _), v ->
        let unparse_v v ctxt = non_terminal_recursion ctxt mode t v in
        Unparsing_compound_lwt.unparse_option ~loc unparse_v v ctxt
    | List_t (t, _), items ->
        List.fold_left_es
          (fun (l, ctxt) element ->
            non_terminal_recursion ctxt mode t element
            >|=? fun (unparsed, ctxt) -> (unparsed :: l, ctxt))
          ([], ctxt)
          items.elements
        >|=? fun (items, ctxt) -> (Micheline.Seq (loc, List.rev items), ctxt)
    | Ticket_t (t, _), {ticketer; contents; amount} ->
        (* ideally we would like to allow a little overhead here because it is only used for unparsing *)
        P.opened_ticket_type loc t >>?= fun t ->
        let destination : Destination.t = Contract ticketer in
        let addr = {destination; entrypoint = Entrypoint.default} in
        (unparse_data_rec [@tailcall])
          ctxt
          ~stack_depth
          mode
          t
          (addr, (contents, (amount :> Script_int.n Script_int.num)))
    | Set_t (t, _), set ->
        Lwt.return
        @@ ( List.fold_left_e
               (fun (l, ctxt) item ->
                 Gas_monad.run_pure_gas ctxt
                 @@ unparse_comparable_data_rec ~loc mode t item
                 >|? fun (item, ctxt) -> (item :: l, ctxt))
               ([], ctxt)
               (Script_set.fold (fun e acc -> e :: acc) set [])
           >|? fun (items, ctxt) -> (Micheline.Seq (loc, items), ctxt) )
    | Map_t (kt, vt, _), map ->
        let items = Script_map.fold (fun k v acc -> (k, v) :: acc) map [] in
        unparse_items_rec ctxt ~stack_depth:(stack_depth + 1) mode kt vt items
        >|=? fun (items, ctxt) -> (Micheline.Seq (loc, items), ctxt)
    | Big_map_t (_kt, _vt, _), Big_map {id = Some id; diff = {size; _}; _}
      when Compare.Int.( = ) size 0 ->
        Lwt_result_syntax.return
          (Micheline.Int (loc, Big_map.Id.unparse_to_z id), ctxt)
    | Big_map_t (kt, vt, _), Big_map {id = Some id; diff = {map; _}; _} ->
        let items =
          Big_map_overlay.fold (fun _ (k, v) acc -> (k, v) :: acc) map []
        in
        let items =
          (* Sort the items in Michelson comparison order and not in key
             hash order. This code path is only exercised for tracing,
             so we don't bother carbonating this sort operation
             precisely. Also, the sort uses a reverse compare because
             [unparse_items] will reverse the result. *)
          List.sort
            (fun (a, _) (b, _) -> Script_comparable.compare_comparable kt b a)
            items
        in
        (* this can't fail if the original type is well-formed
           because [option vt] is always strictly smaller than [big_map kt vt] *)
        option_t loc vt >>?= fun vt ->
        unparse_items_rec ctxt ~stack_depth:(stack_depth + 1) mode kt vt items
        >|=? fun (items, ctxt) ->
        ( Micheline.Prim
            ( loc,
              D_Pair,
              [Int (loc, Big_map.Id.unparse_to_z id); Seq (loc, items)],
              [] ),
          ctxt )
    | Big_map_t (kt, vt, _), Big_map {id = None; diff = {map; _}; _} ->
        let items =
          Big_map_overlay.fold
            (fun _ (k, v) acc ->
              match v with None -> acc | Some v -> (k, v) :: acc)
            map
            []
        in
        let items =
          (* See note above. *)
          List.sort
            (fun (a, _) (b, _) -> Script_comparable.compare_comparable kt b a)
            items
        in
        unparse_items_rec ctxt ~stack_depth:(stack_depth + 1) mode kt vt items
        >|=? fun (items, ctxt) -> (Micheline.Seq (loc, items), ctxt)
    | Lambda_t _, Lam (_, original_code) ->
        unparse_code_rec ctxt ~stack_depth:(stack_depth + 1) mode original_code
    | Lambda_t _, LamRec (_, original_code) ->
        unparse_code_rec ctxt ~stack_depth:(stack_depth + 1) mode original_code
        >|=? fun (body, ctxt) ->
        (Micheline.Prim (loc, D_Lambda_rec, [body], []), ctxt)
    | Never_t, _ -> .
    | Sapling_transaction_t _, s ->
        Lwt.return
          ( Gas.consume ctxt (Unparse_costs.sapling_transaction s)
          >|? fun ctxt ->
            let bytes =
              Data_encoding.Binary.to_bytes_exn Sapling.transaction_encoding s
            in
            (Bytes (loc, bytes), ctxt) )
    | Sapling_transaction_deprecated_t _, s ->
        Lwt.return
          ( Gas.consume ctxt (Unparse_costs.sapling_transaction_deprecated s)
          >|? fun ctxt ->
            let bytes =
              Data_encoding.Binary.to_bytes_exn
                Sapling.Legacy.transaction_encoding
                s
            in
            (Bytes (loc, bytes), ctxt) )
    | Sapling_state_t _, {id; diff; _} ->
        Lwt.return
          ( Gas.consume ctxt (Unparse_costs.sapling_diff diff) >|? fun ctxt ->
            ( (match diff with
              | {commitments_and_ciphertexts = []; nullifiers = []} -> (
                  match id with
                  | None -> Micheline.Seq (loc, [])
                  | Some id ->
                      let id = Sapling.Id.unparse_to_z id in
                      Micheline.Int (loc, id))
              | diff -> (
                  let diff_bytes =
                    Data_encoding.Binary.to_bytes_exn Sapling.diff_encoding diff
                  in
                  let unparsed_diff = Bytes (loc, diff_bytes) in
                  match id with
                  | None -> unparsed_diff
                  | Some id ->
                      let id = Sapling.Id.unparse_to_z id in
                      Micheline.Prim
                        (loc, D_Pair, [Int (loc, id); unparsed_diff], []))),
              ctxt ) )
    | Chest_key_t, s ->
        unparse_with_data_encoding
          ~loc
          ctxt
          s
          Unparse_costs.chest_key
          Script_timelock.chest_key_encoding
    | Chest_t, s ->
        unparse_with_data_encoding
          ~loc
          ctxt
          s
          (Unparse_costs.chest
             ~plaintext_size:(Script_timelock.get_plaintext_size s))
          Script_timelock.chest_encoding

  and unparse_items_rec :
      type k v vc.
      context ->
      stack_depth:int ->
      unparsing_mode ->
      k comparable_ty ->
      (v, vc) ty ->
      (k * v) list ->
      (Script.node list * context) tzresult Lwt.t =
   fun ctxt ~stack_depth mode kt vt items ->
    List.fold_left_es
      (fun (l, ctxt) (k, v) ->
        let loc = Micheline.dummy_location in
        Gas_monad.run_pure_gas ctxt
        @@ unparse_comparable_data_rec ~loc mode kt k
        >>?= fun (key, ctxt) ->
        unparse_data_rec ctxt ~stack_depth:(stack_depth + 1) mode vt v
        >|=? fun (value, ctxt) ->
        (Prim (loc, D_Elt, [key; value], []) :: l, ctxt))
      ([], ctxt)
      items

  and unparse_code_rec ctxt ~stack_depth mode code =
    let elab_conf = Script_ir_translator_config.make ~legacy:true () in
    Gas.consume ctxt Unparse_costs.unparse_instr_cycle >>?= fun ctxt ->
    let non_terminal_recursion ctxt mode code =
      if Compare.Int.(stack_depth > 10_000) then
        tzfail Unparsing_too_many_recursive_calls
      else unparse_code_rec ctxt ~stack_depth:(stack_depth + 1) mode code
    in
    match code with
    | Prim (loc, I_PUSH, [ty; data], annot) ->
        P.parse_packable_ty
          ctxt
          ~stack_depth:(stack_depth + 1)
          ~legacy:elab_conf.legacy
          ty
        >>?= fun (Ex_ty t, ctxt) ->
        let allow_forged =
          false
          (* Forgeable in PUSH data are already forbidden at parsing,
             the only case for which this matters is storing a lambda resulting
             from APPLYing a non-forgeable but this cannot happen either as long
             as all packable values are also forgeable. *)
        in
        P.parse_data
          ~unparse_code_rec
          ~elab_conf
          ctxt
          ~stack_depth:(stack_depth + 1)
          ~allow_forged
          t
          data
        >>=? fun (data, ctxt) ->
        unparse_data_rec ctxt ~stack_depth:(stack_depth + 1) mode t data
        >>=? fun (data, ctxt) ->
        return (Prim (loc, I_PUSH, [ty; data], annot), ctxt)
    | Seq (loc, items) ->
        List.fold_left_es
          (fun (l, ctxt) item ->
            non_terminal_recursion ctxt mode item >|=? fun (item, ctxt) ->
            (item :: l, ctxt))
          ([], ctxt)
          items
        >>=? fun (items, ctxt) ->
        return (Micheline.Seq (loc, List.rev items), ctxt)
    | Prim (loc, prim, items, annot) ->
        List.fold_left_es
          (fun (l, ctxt) item ->
            non_terminal_recursion ctxt mode item >|=? fun (item, ctxt) ->
            (item :: l, ctxt))
          ([], ctxt)
          items
        >>=? fun (items, ctxt) ->
        return (Prim (loc, prim, List.rev items, annot), ctxt)
    | (Int _ | String _ | Bytes _) as atom -> return (atom, ctxt)

  let unparse_data ctxt ~stack_depth mode ty v =
    unparse_data_rec ctxt ~stack_depth mode ty v
    >>=? fun (unparsed_data, ctxt) ->
    Lwt.return (account_for_future_serialization_cost unparsed_data ctxt)

  let unparse_code ctxt ~stack_depth mode v =
    unparse_code_rec ctxt ~stack_depth mode v >>=? fun (unparsed_data, ctxt) ->
    Lwt.return (account_for_future_serialization_cost unparsed_data ctxt)

  let unparse_items ctxt ~stack_depth mode ty vty vs =
    unparse_items_rec ctxt ~stack_depth mode ty vty vs
    >>=? fun (unparsed_datas, ctxt) ->
    List.fold_left_e
      (fun (acc, ctxt) unparsed_data ->
        account_for_future_serialization_cost unparsed_data ctxt
        >|? fun (unparsed_data, ctxt) -> (unparsed_data :: acc, ctxt))
      ([], ctxt)
      unparsed_datas
    >>?= fun (unparsed_datas, ctxt) -> return (List.rev unparsed_datas, ctxt)

  module Internal_for_benchmarking = struct
    let unparse_data = unparse_data_rec

    let unparse_code = unparse_code_rec
  end
end

let unparse_comparable_data ctxt mode ty v =
  Gas_monad.run_pure_gas ctxt @@ unparse_comparable_data_rec ~loc:() mode ty v
  >>? fun (unparsed_data, ctxt) ->
  account_for_future_serialization_cost unparsed_data ctxt
