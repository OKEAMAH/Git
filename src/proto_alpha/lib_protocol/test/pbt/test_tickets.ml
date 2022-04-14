(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

(** Testing
    -------
    Component:    Protocol Library
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/test_tickets.exe
    Subject:      Property-Based Tests for Tickets
*)

module Test_helpers = Lib_test.Qcheck_helpers
module Qcheck_extra = Lib_test.Qcheck_extra
module Non_empty = Lib_test.Qcheck_extra.Non_empty
module Monad = Qcheck_extra.Monad
module Identity = Qcheck_extra.Identity
module Script_typed_ir = Protocol.Script_typed_ir
module Script_ir_translator = Protocol.Script_ir_translator
module Script_comparable = Protocol.Script_comparable
module Env = Protocol.Environment
module Gen = Qcheck_extra.Stateful_gen.Default
open Protocol.Alpha_context

(** [Context_monad] abstracts over the pattern
    [Context.t -> (Context.t * 'a) tzresult Lwt.t].

    [Context_monad] is a [Monad.S] providing the following effects:

    - State manipulation of an [Context].
    - Error handling as per [Error_monad].
    - External effects in [Lwt]
 *)
module Context_monad : sig
  type err = Protocol.Environment.Error_monad.error

  type 'a trace = 'a Protocol.Environment.Error_monad.trace

  type ('a, 'e) result = ('a, 'e) Protocol.Environment.Pervasives.result

  include
    Monad.S with type 'a t = context -> (context * 'a, err trace) result Lwt.t

  exception Err of err trace

  (** Lift a computation that updates the context but does not return a value. *)
  val lift_unit : (context -> (context, err trace) result Lwt.t) -> unit t

  (** Lift a computation passing the context in the left pair component. *)
  val lift_left : (context -> (context * 'a, err trace) result Lwt.t) -> 'a t

  (** Lift a computation reading from, but not modifying the context. *)
  val lift_read : (context -> ('a, err trace) result Lwt.t) -> 'a t

  (** Lift a computation passing the context in the right pair component. *)
  val lift_right : (context -> ('a * context, err trace) result Lwt.t) -> 'a t

  (** Run in and ignore raise any errors as an exception. For testing only.
      *)
  val run_lwt_exn : context -> 'a t -> (context * 'a) Lwt.t

  (** Return the current state value. *)
end = struct
  type err = Protocol.Environment.Error_monad.error

  type 'a trace = 'a Protocol.Environment.Error_monad.trace

  type ('a, 'e) result = ('a, 'e) Protocol.Environment.Pervasives.result

  type 'a t = context -> (context * 'a, err trace) result Lwt.t

  exception Err of err trace

  let lift_unit k ctxt = k ctxt >>=? fun ctxt -> return (ctxt, ())

  let lift_left x = x

  let lift_read k ctxt = k ctxt >>=? fun x -> return (ctxt, x)

  let lift_right k ctxt = k ctxt >>=? fun (x, ctxt) -> return (ctxt, x)

  let run_lwt_exn ctxt k =
    let open Lwt_syntax in
    let* res = k ctxt in
    match res with
    | Error e -> raise @@ Err e
    | Ok (ctxt, x) -> Lwt.return (ctxt, x)

  let return x s = Lwt.return (Ok (s, x))

  let ( let* ) x f s = x s >>=? fun (s2, x2) -> f x2 s2

  let map f x =
    let* y = x in
    return (f y)

  let map2 f x y =
    let* a = x in
    let* b = y in
    return (f a b)

  let join x =
    let* y = x in
    y

  let bind xt f =
    let xtt = map f xt in
    join xtt

  let product xt yt = map2 (fun x y -> (x, y)) xt yt

  (*
  let ( and+ ) x y = map2 (fun x y -> (x, y)) x y

  let ( let+ ) x f = map f x
  *)
end

module Context_gen = Qcheck_extra.Stateful_gen.Make (Context_monad)

type z = Protocol.Script_int.z

type n = Protocol.Script_int.n

type 'a num = 'a Protocol.Script_int.num

(* [Note partial_generators]

   QCheck does not support partial generators, so we handle empty by producing
   generators that raise Error_partial generator.

   Alternatively we could leave [never] out of Test_ty, but that would make
   integration with [ty] and [comparable_ty] awkward.
*)

(** Like [Script_ir_translator.ty], without annotations, and not including:
    types:

    - [lambda]
    - [contract]
    - [address]
    - [sapling_transaction]
    - [sapling_state]
    - [operation]
    - [ticket]
    - BLS signatures

    Like [Script_ir_translator.comparable_ty] without annotations, and including:

    - [list]
    - [set]
    - [map]
    - [big_map]

  *)

(** Existential wrapper over some comparable type. *)
type ex_comparable_ty =
  | Ex_comparable_ty : 'a Script_typed_ir.comparable_ty -> ex_comparable_ty

type ex_ty = Ex_ty : ('a, 'b) Script_typed_ir.ty -> ex_ty

let from_ty_ex_c : 'v Script_typed_ir.ty_ex_c -> ex_ty = function
  | Script_typed_ir.Ty_ex_c x -> Ex_ty x

(* TODO: Factor out common code. Most of the functions below are very similar. *)

let pair_t ?(location = Micheline.dummy_location) ty1 ty2 =
  match Script_typed_ir.pair_t location ty1 ty2 with
  | Ok pair_ty -> pair_ty
  | Error _ -> assert false

let union_t ?(location = Micheline.dummy_location) ty1 ty2 =
  match Script_typed_ir.union_t location ty1 ty2 with
  | Ok union_ty -> union_ty
  | Error _ -> assert false

let option_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.option_t location ty with
  | Ok option_ty -> option_ty
  | Error _ -> assert false

let list_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.list_t location ty with
  | Ok list_ty -> list_ty
  | Error _ -> assert false

let set_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.set_t location ty with
  | Ok set_ty -> set_ty
  | Error _ -> assert false

let map_t ?(location = Micheline.dummy_location) cty ty =
  match Script_typed_ir.map_t location cty ty with
  | Ok map_ty -> map_ty
  | Error _ -> assert false

let ticket_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.ticket_t location ty with
  | Ok ticket_ty -> ticket_ty
  | Error _ -> assert false

let big_map_t ?(location = Micheline.dummy_location) cty ty =
  match Script_typed_ir.big_map_t location cty ty with
  | Ok map_ty -> map_ty
  | Error _ -> assert false

let rec to_string : ex_ty -> string = function
  | Ex_ty ty -> (
      match ty with
      | Never_t -> "never"
      | Unit_t -> "unit"
      | Bool_t -> "bool"
      | Int_t -> "int"
      | Nat_t -> "nat"
      | Mutez_t -> "mutez"
      | Timestamp_t -> "timestamp"
      | String_t -> "string"
      | Bytes_t -> "bytes"
      | Signature_t -> "signature"
      | Address_t -> "address"
      | Chain_id_t -> "chain_id"
      | Key_hash_t -> "key_hash"
      | Key_t -> "key"
      | Tx_rollup_l2_address_t -> "tx_rollup_l2_address"
      | Pair_t (ty1, ty2, _, YesYes) ->
          "(pair " ^ to_string (Ex_ty ty1) ^ " " ^ to_string (Ex_ty ty2) ^ ")"
      | Union_t (ty1, ty2, _, _) ->
          "(union " ^ to_string (Ex_ty ty1) ^ " " ^ to_string (Ex_ty ty2) ^ ")"
      | Option_t (ty1, _, _) -> "(option " ^ to_string (Ex_ty ty1) ^ ")"
      | List_t (ty1, _) -> "(list " ^ to_string (Ex_ty ty1) ^ ")"
      | Set_t (ty1, _) -> "(set " ^ to_string (Ex_ty ty1) ^ ")"
      | Ticket_t (ty1, _) -> "(ticket " ^ to_string (Ex_ty ty1) ^ ")"
      | Map_t (ty1, ty2, _) ->
          "(map " ^ to_string (Ex_ty ty1) ^ " " ^ to_string (Ex_ty ty2) ^ ")"
      | Big_map_t (ty1, ty2, _) ->
          "(big_map " ^ to_string (Ex_ty ty1) ^ " " ^ to_string (Ex_ty ty2)
          ^ ")"
      | _ -> (* TODO : raise error here ? *) "Not supported")

(** Existential wrapper over some test type and a whitness. *)
type ex_val = Ex_val : ('a, 'b) Script_typed_ir.ty * 'a -> ex_val

let return_ex x = Context_gen.return (Ex_comparable_ty x)

(* TODO: check what to do with location in compound types*)

(** Generate a random comparable type. *)
let rec ex_comparable_ty_generator :
    max_depth:int -> ex_comparable_ty Context_gen.t =
 fun ~max_depth ->
  let handle_size x =
    match x with
    (* If [ty] construction fails due to size limits, return a smaller
       type. Given a suitably small ~max_depth this does not affect
       the distribution. *)
    | Ok x -> return_ex x
    | Error _ -> ex_comparable_ty_generator ~max_depth:0
  in
  let open Monad.Syntax (Context_gen) in
  Context_gen.oneof
  @@ Non_empty.of_list_exn
       ([
          (* Note: we avoid never. See [Note partial_generators]. *)
          return_ex @@ Script_typed_ir.unit_t;
          return_ex @@ Script_typed_ir.bool_t;
          return_ex @@ Script_typed_ir.int_t;
          return_ex @@ Script_typed_ir.nat_t;
          return_ex @@ Script_typed_ir.mutez_t;
          return_ex @@ Script_typed_ir.timestamp_t;
          return_ex @@ Script_typed_ir.string_t;
          return_ex @@ Script_typed_ir.bytes_t;
          return_ex @@ Script_typed_ir.signature_t;
          return_ex @@ Script_typed_ir.chain_id_t;
          (* TODO
             return_ex @@ Script_typed_ir.address_key;
             return_ex @@ Script_typed_ir.key_hash_key;
             return_ex @@ Script_typed_ir.key_key;
          *)
        ]
       @
       if max_depth > 0 then
         [
           (let* (Ex_comparable_ty ty1) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            let* (Ex_comparable_ty ty2) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            handle_size @@ Script_typed_ir.comparable_pair_t 0 ty1 ty2);
           (let* (Ex_comparable_ty ty1) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            let* (Ex_comparable_ty ty2) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            handle_size (Script_typed_ir.comparable_union_t 0 ty1 ty2));
           (let* (Ex_comparable_ty ty) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            handle_size (Script_typed_ir.comparable_option_t 0 ty));
         ]
       else [])

(** Generate a random test type. *)
let rec ex_ty_generator :
    allow_bigmap:bool -> max_depth:int -> ex_ty Context_gen.t =
 fun ~allow_bigmap ~max_depth ->
  let return_ex x = Context_gen.return (Ex_ty x) in
  let return_ex_from_ty_ex_c x = Context_gen.return (from_ty_ex_c x) in

  let open Monad.Syntax (Context_gen) in
  Context_gen.oneof
  @@ Non_empty.of_list_exn
       ([
          (* Note: we avoid never. See [Note partial_generators]. *)
          return_ex Unit_t;
          return_ex Bool_t;
          return_ex Int_t;
          return_ex Nat_t;
          return_ex Mutez_t;
          return_ex Timestamp_t;
          return_ex String_t;
          return_ex Bytes_t;
          return_ex Signature_t;
          return_ex Chain_id_t;
          return_ex Tx_rollup_l2_address_t;
          (* TODO
             return_ex Address_t;
             return_ex Key_hash_t;
             return_ex Key_t;
          *)
        ]
       @
       if max_depth > 0 then
         [
           (let* (Ex_ty ty1) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            let* (Ex_ty ty2) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            return_ex_from_ty_ex_c @@ pair_t ty1 ty2);
           (let* (Ex_ty ty1) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            let* (Ex_ty ty2) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            return_ex_from_ty_ex_c @@ union_t ty1 ty2);
           (let* (Ex_ty ty) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            return_ex @@ option_t ty);
           (let* (Ex_ty ty) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            return_ex @@ list_t ty);
           (let* (Ex_comparable_ty ty) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            return_ex @@ set_t ty);
           (let* (Ex_comparable_ty ty) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            return_ex @@ ticket_t ty);
           (let* (Ex_comparable_ty ty1) =
              ex_comparable_ty_generator ~max_depth:(max_depth - 1)
            in
            let* (Ex_ty ty2) =
              ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
            in
            return_ex @@ map_t ty1 ty2);
         ]
         @
         if allow_bigmap then
           [
             (let* (Ex_comparable_ty ty1) =
                ex_comparable_ty_generator ~max_depth:(max_depth - 1)
              in
              let* (Ex_ty ty2) =
                ex_ty_generator ~allow_bigmap ~max_depth:(max_depth - 1)
              in
              return_ex @@ big_map_t ty1 ty2);
           ]
         else []
       else [])

let big_map_of_list_gen_t key_ty ty x =
  Context_gen.lift @@ Context_monad.lift_right
  @@ fun ctxt -> Script_big_map.of_list key_ty ty x ctxt

(* TODO consolidate default_step_constants, get_balance, set_balance, assert_token_balance with similar wrappers in Test_tickets *)

let default_step_constants =
  let open Protocol.Script_interpreter in
  let default_source =
    Contract.implicit_contract Signature.Public_key_hash.zero
  in
  {
    source = default_source;
    payer = default_source;
    self = default_source;
    amount = Tez.zero;
    chain_id = Chain_id.zero;
    balance = Tez.zero;
    level = Protocol.Script_int.zero_n;
    now = Protocol.Script_timestamp.of_zint Z.zero;
  }

(*let pp_token fmt (token: Protocol.Ticket_token.ex_token) pp_contents =
    let open Protocol.Ticket_token in
      match token with
      | Ex_token {ticketer; contents; contents_type} ->
  Format.fprintf
      fmt
      "@[ticketer: %a contents: %a@]"
      AC.Contract.pp ticketer
      pp_contents contents

let show_token (token : Protocol.Ticket_token.ex_token) : string =
  String.escaped
  @@ Format.kasprintf
       Fun.id
       "%a"
       pp_token token *)

(* Build a generator that returns one of a list of values: 
   No shrinking is involved here, it would be interesting to 
   see how to generalise this function to pass explicitly 
   a shrinker.
*)

(* TODO: move to Context_gen interface? *)
let list_lift : 'a list -> 'a Context_gen.t =
 fun choices ->
  let generators = List.map (fun choice -> Context_gen.return choice) choices in
  Context_gen.oneof @@ Non_empty.of_list_exn generators

(* [key_triple algo seed_length] Generates a triple [(public key hash, public key, secret key)] 
using [algo] and a seed of [seed_length] random bytes. Both arguments are optional. *)
let key_triple ?(algo = Tezos_crypto.Signature.Ed25519) ?(seed_length = 32) () =
  let open Monad.Syntax (Context_gen) in
  let+ seed = Context_gen.bytes_sequence seed_length in
  Tezos_crypto.Signature.generate_key ~algo ~seed ()

(* generate one public key hash *)
let public_key_hash ?(algo = Tezos_crypto.Signature.Ed25519) ?(seed_length = 32)
    () =
  let open Monad.Syntax (Context_gen) in
  let+ (pkh, _, _) = key_triple ~algo ~seed_length () in
  pkh

let public_key ?(algo = Tezos_crypto.Signature.Ed25519) ?(seed_length = 32) () =
  let open Monad.Syntax (Context_gen) in
  let+ (_, pk, _) = key_triple ~algo ~seed_length () in
  pk

let secret_key ?(algo = Tezos_crypto.Signature.Ed25519) ?(seed_length = 32) () =
  let open Monad.Syntax (Context_gen) in
  let+ (_, _, sk) = key_triple ~algo ~seed_length () in
  sk

let bls_keys_with_tx_rollup_address ?(seed_length = 32) () =
  let open Monad.Syntax (Context_gen) in
  let+ seed = Context_gen.bytes_sequence seed_length in
  let secret_key = Bls12_381.Signature.generate_sk seed in
  let public_key = Bls12_381.Signature.MinPk.derive_pk secret_key in
  let tx_rollup_address =
    Protocol.Indexable.value
    @@ Protocol.Tx_rollup_l2_address.of_bls_pk public_key
  in
  (secret_key, public_key, tx_rollup_address)

let tx_rollup_l2_address ?(seed_length = 32) () =
  let open Monad.Syntax (Context_gen) in
  let+ (_, _, tx_rollup_address) =
    bls_keys_with_tx_rollup_address ~seed_length ()
  in
  tx_rollup_address

(* Use sensible names for entrypoints - taken from the interface of FA1.2.*)
let entrypoint () =
  let entrypoints =
    ["transfer"; "approve"; "getAllowance"; "getBalance"; "getTotalSupply"]
  in
  list_lift
  @@ List.map Protocol.Entrypoint_repr.of_string_strict_exn entrypoints

let destination ?(max_origination_index = 64) () =
  (* Ugly as we do not expose a method to set the origination nonce directly in the protocol. *)
  let rec build_origination_nonce current_nonce index =
    if Int32.(index <= zero) then current_nonce
    else
      let new_nonce = Origination_nonce.Internal_for_tests.incr current_nonce in
      build_origination_nonce new_nonce (Int32.sub index Int32.one)
  in

  let open Monad.Syntax (Context_gen) in
  (* We can use a zero hash, and then randomise the origination_index to
     randomise the generated contract address
  *)
  let operation_hash = Env.Operation_hash.zero in
  let+ origination_index = Context_gen.nat_less_than max_origination_index in
  let origination_index = Int32.of_int origination_index in
  let origination_nonce =
    build_origination_nonce
      (Origination_nonce.Internal_for_tests.initial operation_hash)
      origination_index
  in
  Destination.Contract
    (Contract.Internal_for_tests.originated_contract origination_nonce)

let address ?(max_origination_index = 64) () =
  let open Monad.Syntax (Context_gen) in
  let* destination = destination ~max_origination_index () in
  let+ entrypoint = entrypoint () in
  ({destination; entrypoint} : Protocol.Script_typed_ir.address)

(* Generate one random signed message *)
let signature ?(algo = Tezos_crypto.Signature.Ed25519) ?(seed_length = 32) () =
  let open Monad.Syntax (Context_gen) in
  let* sk = secret_key ~algo ~seed_length () in
  let+ msg = Context_gen.bytes_sequence 32 in
  Tezos_crypto.Signature.sign sk msg

let to_token ~contents_type ~contents ~ticketer =
  Context_gen.lift
  @@ Context_monad.return
       (Protocol.Ticket_token.Ex_token {contents_type; contents; ticketer})

let make_ticket_hash ?(loc = Micheline.dummy_location) ctxt ~ticketer
    ~(ty : ('a, _) Script_typed_ir.ty) ~contents ~owner =
  let open Lwt_result_syntax in
  let*? (ty_unparsed, ctxt) = Script_ir_translator.unparse_ty ~loc ctxt ty in
  let ty_unparsed = Script.strip_annotations ty_unparsed in
  let* (contents, ctxt) =
    Script_ir_translator.unparse_comparable_data
      ~loc
      ctxt
      Script_ir_translator.Optimized_legacy
      ty
      contents
  in
  let ticketer_address =
    Script_typed_ir.
      {destination = Contract ticketer; entrypoint = Entrypoint.default}
  in
  let owner_address =
    Script_typed_ir.{destination = owner; entrypoint = Entrypoint.default}
  in
  let* (ticketer, ctxt) =
    Script_ir_translator.unparse_data
      ctxt
      Script_ir_translator.Optimized_legacy
      Script_typed_ir.address_t
      ticketer_address
  in
  let* (owner, ctxt) =
    Script_ir_translator.unparse_data
      ctxt
      Script_ir_translator.Optimized_legacy
      Script_typed_ir.address_t
      owner_address
  in
  let*? x = Ticket_hash.make ctxt ~ticketer ~ty:ty_unparsed ~contents ~owner in
  return x

let adjust_balance ~(ty : ('a, _) Script_typed_ir.ty) ~ticketer ~owner ~contents
    =
  Context_gen.lift @@ Context_monad.lift_right
  @@ fun ctxt ->
  let open Lwt_result_syntax in
  (*let* () = Lwt_io.printl ("TODO DEBUG added ticket " ^ show_token token))  in *)
  let* (hash, ctxt) = make_ticket_hash ctxt ~ticketer ~ty ~contents ~owner in
  Ticket_balance.adjust_balance ctxt hash ~delta:Z.one

let ty_generator :
    type a.
    ?ticket_owner:Contract.t -> a Script_typed_ir.ty_ex_c -> a Context_gen.t =
 fun ?ticket_owner (Script_typed_ir.Ty_ex_c ty) ->
  let open Monad.Syntax (Context_gen) in
  let rec loop : type a. a Script_typed_ir.ty_ex_c -> a Context_gen.t =
   fun (Script_typed_ir.Ty_ex_c ty) ->
    let ticket_owner =
      match ticket_owner with
      | None -> default_step_constants.source
      | Some x -> x
    in
    match ty with
    | Unit_t -> Context_gen.return ()
    | Bool_t -> Context_gen.bool
    | Nat_t ->
        let+ g = Context_gen.small_int in
        Protocol.Script_int.abs @@ Protocol.Script_int.of_int g
    | Int_t ->
        let+ g = Context_gen.small_int in
        Protocol.Script_int.of_int g
    | Mutez_t ->
        let+ g = Context_gen.small_int in
        Tez.of_mutez_exn @@ Int64.of_int g
    | Timestamp_t ->
        let+ g = Context_gen.small_int in
        Protocol.Script_timestamp.of_zint @@ Env.Z.of_int g
    | Signature_t ->
        Context_gen.map
          (fun signature -> Script_typed_ir.Script_signature.make signature)
          (signature ())
    | String_t -> (
        let+ y = Context_gen.string_readable in
        match Protocol.Script_string.of_string y with
        | Ok x -> x
        | Error _ -> Protocol.Script_string.empty)
    | Bytes_t ->
        let+ x = Context_gen.string_readable in
        Bytes.of_string x
    | Key_hash_t -> public_key_hash ()
    | Key_t -> public_key ()
    | Chain_id_t ->
        (* TODO demonstrate this won't raise exn *)
        Context_gen.return
          (Script_typed_ir.Script_chain_id.make
             (Env.Chain_id.of_b58check_exn "NetXdQprcVkpaWU"))
    | Tx_rollup_l2_address_t -> tx_rollup_l2_address ()
    | Pair_t (ty1, ty2, _metadata, _comparable) ->
        let ty1 = Script_typed_ir.Ty_ex_c ty1 in
        let ty2 = Script_typed_ir.Ty_ex_c ty2 in
        let+ g1 = loop ty1 and+ g2 = loop ty2 in
        (g1, g2)
    | Union_t (ty1, ty2, _metadata, _comparable) ->
        let ty1 = Script_typed_ir.Ty_ex_c ty1 in
        let ty2 = Script_typed_ir.Ty_ex_c ty2 in
        Context_gen.oneof
        @@ Non_empty.of_pair
             ( (let+ x = loop ty1 in
                Script_typed_ir.L x),
               let+ x = loop ty2 in
               Script_typed_ir.R x )
    | Option_t (ty1, _metadata, _comparable) ->
        let ty1 = Script_typed_ir.Ty_ex_c ty1 in
        Context_gen.opt (loop ty1)
    | List_t (ty1, _metadata) ->
        let ty1 = Script_typed_ir.Ty_ex_c ty1 in
        let+ x = Context_gen.small_list (loop ty1) in
        Script_list.of_list x
    | Set_t (ty1, _metadata) ->
        let+ x = small_unique_list ty1 in
        Script_set.of_list ty1 x
    | Ticket_t (ty1, _metadata) ->
        let ty1_ex = Script_typed_ir.Ty_ex_c ty1 in
        let* contents = loop ty1_ex in
        let* destination = destination () in
        let open Script_typed_ir in
        let* _ =
          adjust_balance
            ~contents
            ~ty:ty1
            ~ticketer:ticket_owner
            ~owner:destination
        in
        (* TODO can you always use "default"? a la ITicket in
           Script_interpreter?
        *)
        Context_gen.return
        @@ {
             ticketer = ticket_owner;
             contents;
             amount = Protocol.Script_int.one_n;
           }
    | Map_t (ty1, ty2, _metadata) ->
        let ty2 = Script_typed_ir.Ty_ex_c ty2 in
        let+ assoc_list = small_assoc_list ty1 ty2 in
        Script_map.of_list ty1 assoc_list
    | Big_map_t (ty1, ty2, _metadata) ->
        let ty2' = Script_typed_ir.Ty_ex_c ty2 in
        let* assoc_list = small_assoc_list ty1 ty2' in
        big_map_of_list_gen_t ty1 ty2 assoc_list
    | Address_t -> address ()
    | Never_t -> (* we never generate type Never_t *) assert false
    | _ -> (* we do not generate any other type *) assert false
  (* Generate a list with all unique elements. *)
  and small_unique_list :
      type k. k Script_typed_ir.comparable_ty -> k list Context_gen.t =
   fun ty1 ->
    let+ xs = Context_gen.small_list @@ loop (Script_typed_ir.Ty_ex_c ty1) in
    List.sort_uniq (Script_comparable.compare_comparable ty1) xs
  (* Generate an assoc list, e.g. a list with unique keys. *)
  and small_assoc_list :
      type k v.
      k Script_typed_ir.comparable_ty ->
      v Script_typed_ir.ty_ex_c ->
      (k * v) list Context_gen.t =
   fun ty1 ty2 ->
    let* ks = small_unique_list ty1 in
    (* It is tempting to use small_list to generate keys
       and combine the results with a "short-cutting zip",
       but that would lead to tickets being created and
       counted without actually ending up in the resulting
       structure.

       Instead, we use replicate_for_each, which takes care
       to run the ty2 generator only once for each
       unique key.
    *)
    Context_gen.replicate_for_each ks (loop ty2)
  in
  loop @@ Script_typed_ir.Ty_ex_c ty

module Tmp = struct
  (* TODO move to AC.Ticket_balance.Internal_for_tests ? *)
  type key = Ticket_hash.t
end

let balance_table_keys : Tmp.key list Context_monad.t =
  Context_monad.lift_read @@ fun _ctxt -> Stdlib.failwith "TODO MERGE"
(* Ticket.all_keys ctxt *)

let rec traverse xs f =
  match xs with
  | [] -> Context_monad.return []
  | x :: xs -> Context_monad.map2 (fun x xs -> x :: xs) (f x) (traverse xs f)

let balance_table : (Tmp.key * Z.t) list Context_monad.t =
  let open Monad.Syntax (Context_monad) in
  let* keys = balance_table_keys in
  let* kvs =
    traverse keys (fun key ->
        let* balance =
          Context_monad.lift_right @@ fun ctxt ->
          Ticket_balance.get_balance ctxt key
        in
        Context_monad.return
        @@ Option.fold ~none:[] ~some:(fun b -> [(key, b)]) balance)
  in
  Context_monad.return @@ List.concat kvs

let show_key_balance (_key : Tmp.key) balance : string * string =
  let key =
    Stdlib.failwith "TODO MERGE"
    (*
    String.escaped @@ Format.kasprintf Fun.id "%a" AC.Ticket.pp_key key
    *)
  in
  let regexp = Str.regexp "\\\\00[0-9]" in
  let key = Str.global_replace regexp "" key in
  let balance = Z.to_string balance in
  (key, balance)

let compare_key_balance (k1, b1) (k2, b2) =
  match String.compare k1 k2 with
  | n when n <> 0 -> n
  | _ -> String.compare b1 b2

let normalize_balances (key_balances : (Tmp.key * counter) list) :
    (string * string) list =
  List.filter_map
    (fun (key, balance) ->
      if Z.equal balance Z.zero then None
      else Some (show_key_balance key balance))
    key_balances
  |> List.sort compare_key_balance

(* TODO consolidate show_balance_table with similar code in Test_ticket_balance *)
let show_balance_table : (string * string) list -> string =
 fun kvs ->
  let show_rows kvs =
    let key_col_length =
      List.fold_left (fun mx (s, _) -> max mx (String.length s)) 0 kvs
    in
    let column align col_length s =
      let space =
        Stdlib.List.init (col_length - String.length s) (fun _ -> " ")
        |> String.concat ""
      in
      match align with
      | `Left -> Printf.sprintf "%s%s" s space
      | `Right -> Printf.sprintf "%s%s" space s
    in
    List.map
      (fun (k, v) ->
        Printf.sprintf
          "| %s  | %s |"
          (column `Left key_col_length k)
          (column `Right 8 v))
      kvs
    |> String.concat "\n"
  in
  show_rows (("Token x Content x Owner", "Balance") :: kvs)

(** Generate a random type, along with a random value of that type. *)
let ex_val_generator :
    allow_bigmap:bool -> max_depth:int -> ex_val Context_gen.t =
 fun ~allow_bigmap ~max_depth ->
  let open Monad.Syntax (Context_gen) in
  let* (Ex_ty ty) = ex_ty_generator ~allow_bigmap ~max_depth in
  let+ x = ty_generator @@ Script_typed_ir.Ty_ex_c ty in
  Ex_val (ty, x)

(** Unparse interpreter representation to Michelson AST. *)
let unparse_data_readable :
    ('a, 'b) Script_typed_ir.ty -> 'a -> Script.node Context_monad.t =
 fun ty x ->
  Context_monad.lift_right (fun ctxt ->
      Script_ir_translator.unparse_data ctxt Script_ir_translator.Readable ty x)

(** Unparse interpreter representation to a string. *)
let unparse_data_to_string :
    ('a, 'b) Script_typed_ir.ty -> 'a -> string Context_monad.t =
 fun ty x ->
  let string_of_node (n : Script.node) : string =
    let c = Micheline.strip_locations n in
    Format.kasprintf
      Fun.id
      "%a"
      Micheline_printer.print_expr
      (Micheline_printer.printable
         Protocol.Michelson_v1_primitives.string_of_prim
         c)
  in
  let open Monad.Syntax (Context_monad) in
  let* node = unparse_data_readable ty x in
  Context_monad.return @@ string_of_node node

(** A fixed seed used to test the generator framework itself. *)
let test_seed = 5471827389070247L

(** Test that a stateless generator produces some predetermined output.
    Equality is checked as per the given testable.
    *)
let test_stateless :
    type a.
    string -> a Alcotest.testable -> a Gen.t -> a -> unit Alcotest_lwt.test_case
    =
 fun msg testable gen expected ->
  Tztest.tztest msg `Quick @@ fun () ->
  return
  @@ Alcotest.check
       testable
       "generated value"
       expected
       (Identity.run (gen @@ Lib_test.Random_pure.of_seed test_seed))

(** Test that a stateful generator produces some predetermined output in a fresh context.
    Equality is checked as per the given testable.
    *)
let test_stateful :
    type a.
    string ->
    a Alcotest.testable ->
    a Context_gen.t ->
    a ->
    unit Alcotest_lwt.test_case =
  let test_context () =
    let ( let* ) m f = m >>=? f in
    let* (b, _) = Context.init 3 in
    let* v = Incremental.begin_construction b in
    return (Incremental.alpha_ctxt v)
  in
  fun msg testable gen expected ->
    Tztest.tztest msg `Quick @@ fun () ->
    let ( let* ) = Lwt.( >>= ) in
    let* ctxt_res = test_context () in
    match ctxt_res with
    | Error _ -> Stdlib.failwith "Could not create context"
    | Ok ctxt ->
        let* (_ctxt, actual) =
          Context_monad.run_lwt_exn ctxt
          @@ (fun f -> f @@ Lib_test.Random_pure.of_seed test_seed)
          @@ gen
        in
        return @@ Alcotest.check testable "generated value" expected actual

(** Test that a stateful generator produces some predetermined output in a fresh context.
    The result is converted to a Michelson literal and cheked against the given string.
  *)
let test_stateful_ty :
    type a. (a, _) Script_typed_ir.ty -> string -> unit Alcotest_lwt.test_case =
 fun ty expected ->
  let open Monad.Syntax (Context_gen) in
  test_stateful
    (to_string (Ex_ty ty))
    Alcotest.string
    (let* big_map = ty_generator @@ Script_typed_ir.Ty_ex_c ty in
     Context_gen.lift @@ unparse_data_to_string ty big_map)
    expected

let test_context () =
  let ( let* ) m f = m >>=? f in
  let* (b, _) = Context.init 5 in
  let* v = Incremental.begin_construction b in
  return @@ Incremental.alpha_ctxt v

module Alpha_test = struct
  exception Could_not_create_context

  (** Run an [Context_monad] computation in a default (empty) context, and return
        the final context. Fails on errors.

        Useful for testing.
     *)
  let run_in_default_context_exn :
      type a. a Context_monad.t -> (context * a) Lwt.t =
   fun h ->
    let ( let* ) = Lwt.( >>= ) in
    let* ctxt_res = test_context () in
    match ctxt_res with
    | Error _e -> raise Could_not_create_context
    | Ok ctxt -> Context_monad.run_lwt_exn ctxt h
end

(* TODO make this private, should only be used from qcheck_make_stateful, as
    it calls into expensive context setup, and therefore neeeds smaller count/max_gen
    parameters than QCheck.Test.make defaults.
   *)

(** Convert a an [Context_gen] to a [QCheck.arbitrary], for passing to [QCheck.make].

    {i Warning:} Uses [Lwt_main.run] internally. Running this inside another [Lwt]
    computation will fail.
 *)
let to_arb_exn (gen : 'a Context_gen.t) : (context * 'a) QCheck.arbitrary =
  QCheck.make (fun g ->
      Lwt_main.run @@ Alpha_test.run_in_default_context_exn
      @@ (Context_gen.to_qcheck_gen gen) g)

(* TODO make sure all uses of qcheck_eq should pass a comparator, or else we
   fall back on Stdlib. *)
let qcheck_make_stateful :
    name:string ->
    generator:'a Context_gen.t ->
    property:('a -> bool Context_monad.t) ->
    QCheck.Test.t =
 fun ~name ~generator ~property ->
  QCheck.Test.make
  (* Note: QCheck defaults as of 0.17:
       count=100
       max_gen=count+200
       max_fail=1
  *)
    ~count:(15 + 100)
    ~max_gen:(20 + 100)
    ~name
    (to_arb_exn generator)
    (*
                  Ugly solution: use Lwt_main.run.

                  Nice solution: make a version of QCheck.Test
                  parameterized on the effect type.
               *)
    (fun (ctxt, ex) ->
      Lwt_main.run
      @@ Lwt.map (fun x -> snd x)
      @@ Context_monad.run_lwt_exn ctxt (property ex))

let pp_bal f kvs_balance =
  Format.pp_print_string f (show_balance_table @@ normalize_balances kvs_balance)

let eq_bal a b =
  0
  = Stdlib.compare
      (show_balance_table @@ normalize_balances a)
      (show_balance_table @@ normalize_balances b)

let qcheck_wrap xs =
  List.map (fun (x, y, z) -> (x, y, fun a -> Lwt.return @@ z a))
  @@ Test_helpers.qcheck_wrap xs

let test_stateless =
  [
    test_stateless "()" Alcotest.unit (Gen.return ()) ();
    test_stateless
      "string"
      Alcotest.string
      Gen.string_readable
      "GSCFNIXYOJUJWXPBSA";
    test_stateless
      "list bool"
      (Alcotest.list Alcotest.bool)
      (Gen.small_list Gen.bool)
      [true; true; false; false; false; true; false];
  ]

let test_return_generators =
  qcheck_wrap
    [
      QCheck.Test.make
        ~name:"return generator works"
        (QCheck.make (Gen.to_qcheck_gen (Gen.return "hiha")))
        (fun x -> Test_helpers.qcheck_eq (Identity.run x) "hiha");
    ]

let test_stateful =
  [
    test_stateful_ty Unit_t "Unit";
    test_stateful_ty (map_t Unit_t Unit_t) "{ Elt Unit Unit }";
    test_stateful_ty (map_t Bool_t Bool_t) "{ Elt False True ; Elt True True }";
    test_stateful_ty (big_map_t Unit_t Unit_t) "{ Elt Unit Unit }";
    test_stateful_ty
      (big_map_t Bool_t Unit_t)
      "{ Elt False Unit ; Elt True Unit }";
    test_stateful_ty
      (big_map_t Unit_t @@ big_map_t Unit_t Unit_t)
      "{ Elt Unit { Elt Unit Unit } }";
  ]

let test_sanity =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"trivial generator works"
        ~generator:(Context_gen.return @@ Ex_val (Unit_t, ()))
        ~property:(fun ex ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (ty, x)) = ex in
          let* str = unparse_data_to_string ty x in
          Context_monad.return
          @@ Test_helpers.qcheck_eq ~pp:Format.pp_print_string str str);
      qcheck_make_stateful
        ~name:"ex_val_generator works"
        ~generator:(ex_val_generator ~allow_bigmap:true ~max_depth:5)
        ~property:(fun ex ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (ty, x)) = ex in
          let* str = unparse_data_to_string ty x in
          Context_monad.return
          @@ Test_helpers.qcheck_eq ~pp:Format.pp_print_string str str);
    ]

let test_storage_unchanged =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"storage unchanged"
        ~generator:
          (let open Monad.Syntax (Context_gen) in
          let+ storage =
            (*
               ex_val_generator ~allow_bigmap:false ~max_depth:5
               *)
            ex_val_generator ~allow_bigmap:false ~max_depth:3
          and+ param = Context_gen.return (Ex_val (Unit_t, ())) in
          (storage, param))
        ~property:(fun (ex_storage, ex_param) ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (storage_type, storage)) = ex_storage in
          let (Ex_val (arg_type, arg)) = ex_param in
          let alice = default_step_constants.source in
          let* old_balances = balance_table in
          let* () =
            Context_monad.lift_unit @@ fun ctxt ->
            Protocol.Ticket_scanner.type_has_tickets ctxt arg_type
            >>?= fun (arg_type_tickets, ctxt) ->
            Protocol.Ticket_scanner.type_has_tickets ctxt storage_type
            >>?= fun (storage_type_has_tickets, ctxt) ->
            Protocol.Ticket_accounting.ticket_diffs
              ctxt
              ~arg_type_has_tickets:arg_type_tickets
              ~arg
              ~storage_type_has_tickets
              ~old_storage:storage
              ~new_storage:storage
              ~lazy_storage_diff:[]
            >>=? fun (ticket_map, ctxt) ->
            Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~ticket_diffs:ticket_map
              []
            >|=? fun (_, ctxt) -> ctxt
          in
          let* new_balances = balance_table in
          (* No tickets were passed and storage is unchanged, so
             the balance table should be unchanged.
          *)
          Context_monad.return
          @@ Test_helpers.qcheck_eq
               ~eq:eq_bal
               ~pp:pp_bal
               old_balances
               new_balances);
    ]

let test_drop_from_strict =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"drop from strict storage"
        ~generator:
          (let open Monad.Syntax (Context_gen) in
          let* _ =
            Context_gen.lift @@ Context_monad.lift_unit
            @@ fun ctxt ->
            Lwt.( >>= ) (Lwt_io.printl "TODO DEBUG new gen") (fun () ->
                return ctxt)
          in
          let* param = ex_val_generator ~allow_bigmap:false ~max_depth:2 in
          let* storage = ex_val_generator ~allow_bigmap:false ~max_depth:2 in
          Context_gen.return (storage, param))
        ~property:(fun (ex_storage, ex_param) ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (storage_type, storage)) = ex_storage in
          let (Ex_val (arg_type, arg)) = ex_param in
          let alice = default_step_constants.source in
          let* () =
            Context_monad.lift_unit @@ fun ctxt ->
            Protocol.Ticket_scanner.type_has_tickets ctxt arg_type
            >>?= fun (arg_type_tickets, ctxt) ->
            Protocol.Ticket_scanner.type_has_tickets
              ctxt
              (option_t storage_type)
            >>?= fun (storage_type_has_tickets, ctxt) ->
            Protocol.Ticket_accounting.ticket_diffs
              ctxt (*~update_storage:return*)
              ~arg_type_has_tickets:arg_type_tickets
              ~arg
              ~storage_type_has_tickets
              ~old_storage:(Some storage)
              ~new_storage:None
              ~lazy_storage_diff:[]
            >>=? fun (ticket_map, ctxt) ->
            Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~ticket_diffs:ticket_map
              []
            >|=? fun (_, ctxt) -> ctxt
          in
          let* new_balances = balance_table in
          (* Nothing is transferred or stored, so the balance
             table should be empty *)
          Context_monad.return
          @@ Test_helpers.qcheck_eq (* TODO factor/outmove up: *)
               ~eq:eq_bal
               ~pp:pp_bal
               []
               new_balances);
    ]

let test_drop_lazy =
  qcheck_wrap
    [
      qcheck_make_stateful
        ~name:"drop all tickets from lazy storage"
        ~generator:
          (let open Monad.Syntax (Context_gen) in
          let+ storage = ex_val_generator ~allow_bigmap:true ~max_depth:2
          and+ param = ex_val_generator ~allow_bigmap:true ~max_depth:2 in
          (storage, param))
        ~property:(fun (ex_storage, ex_param) ->
          let open Monad.Syntax (Context_monad) in
          let (Ex_val (storage_type, storage)) = ex_storage in
          let (Ex_val (arg_type, arg)) = ex_param in
          let alice = default_step_constants.source in
          let arg_type = arg_type in
          let storage_type = option_t storage_type in
          let old_storage = Some storage in
          let* (new_storage, lazy_storage_diff, operations) =
            Context_monad.lift_left @@ fun ctxt ->
            Script_ir_translator.collect_lazy_storage ctxt arg_type arg
            >>?= fun (to_duplicate, ctxt) ->
            Script_ir_translator.collect_lazy_storage
              ctxt
              storage_type
              old_storage
            >>?= fun (to_update, ctxt) ->
            (*
                trace
                  (Runtime_contract_error (step_constants.self, script_code))
                  (interp logger (ctxt, step_constants) code (arg, old_storage))
                >>=? fun ((operations, new_storage), ctxt) ->
                *)
            let operations = Protocol.Script_list.empty in
            let new_storage = None in
            Script_ir_translator.extract_lazy_storage_diff
              ctxt
              Script_ir_translator.Readable
              ~temporary:false
              ~to_duplicate
              ~to_update
              storage_type
              new_storage
            >>=? fun (_storage, lazy_storage_diff, ctxt) ->
            let (_ops, op_diffs) = List.split operations.elements in
            let lazy_storage_diff =
              match
                List.flatten
                  (List.map
                     (Option.value ~default:[])
                     (op_diffs @ [lazy_storage_diff]))
              with
              | [] -> None
              | diff -> Some diff
            in
            return
              ( ctxt,
                ( new_storage,
                  List.concat @@ Option.to_list lazy_storage_diff,
                  operations ) )
          in
          let* () =
            Context_monad.lift_unit @@ fun ctxt ->
            Protocol.Ticket_scanner.type_has_tickets ctxt arg_type
            >>?= fun (arg_type_tickets, ctxt) ->
            Protocol.Ticket_scanner.type_has_tickets ctxt storage_type
            >>?= fun (storage_type_has_tickets, ctxt) ->
            Protocol.Ticket_accounting.ticket_diffs
              ctxt (*~update_storage:return*)
              ~arg_type_has_tickets:arg_type_tickets
              ~arg
              ~storage_type_has_tickets
              ~old_storage
              ~new_storage
              ~lazy_storage_diff
            >>=? fun (ticket_map, ctxt) ->
            Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~ticket_diffs:ticket_map
              operations.elements
            >|=? fun (_, ctxt) -> ctxt
            (*Protocol.Ticket_accounting.update_ticket_balances
              ctxt
              ~self:alice
              ~update_storage:return
              ~arg_type
              ~arg
              ~storage_type
              ~old_storage
              ~new_storage
              ~lazy_storage_diff
              ~operations*)
          in
          let* new_balances = balance_table in
          (* Nothing is transferred or stored, so the balance
             table should be empty *)
          Context_monad.return
          @@ Test_helpers.qcheck_eq (* TODO factor/outmove up: *)
               ~eq:eq_bal
               ~pp:pp_bal
               []
               new_balances);
    ]

let () = print_endline "Hello world"

let tests =
  List.concat
    [
      test_stateless;
      test_return_generators;
      test_stateful;
      test_sanity;
      test_storage_unchanged;
      test_drop_from_strict;
      test_drop_lazy;
    ]

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run "protocol > pbt > test_tickets" [("Tez_repr", tests)]
