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

(** Ticket generators to be used in property based tests. *)

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
  | Error _ -> Stdlib.failwith "Cannot generate Pair"

let union_t ?(location = Micheline.dummy_location) ty1 ty2 =
  match Script_typed_ir.union_t location ty1 ty2 with
  | Ok union_ty -> union_ty
  | Error _ -> Stdlib.failwith "Cannot generate Union"

let option_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.option_t location ty with
  | Ok option_ty -> option_ty
  | Error _ -> Stdlib.failwith "Cannot generate Option"

let list_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.list_t location ty with
  | Ok list_ty -> list_ty
  | Error _ -> Stdlib.failwith "Cannot generate List"

let set_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.set_t location ty with
  | Ok set_ty -> set_ty
  | Error _ -> Stdlib.failwith "Cannot generate Set"

let map_t ?(location = Micheline.dummy_location) cty ty =
  match Script_typed_ir.map_t location cty ty with
  | Ok map_ty -> map_ty
  | Error _ -> Stdlib.failwith "Cannot generate Map"

let ticket_t ?(location = Micheline.dummy_location) ty =
  match Script_typed_ir.ticket_t location ty with
  | Ok ticket_ty -> ticket_ty
  | Error _ -> Stdlib.failwith "Cannot generate Ticket"

let big_map_t ?(location = Micheline.dummy_location) cty ty =
  match Script_typed_ir.big_map_t location cty ty with
  | Ok map_ty -> map_ty
  | Error _ -> Stdlib.failwith "Cannot generate Bigmap"

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
      | Pair_t (ty1, ty2, _, _) ->
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
      | _ -> "Not supported")

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
          return_ex @@ Script_typed_ir.address_t;
          return_ex @@ Script_typed_ir.key_hash_t;
          return_ex @@ Script_typed_ir.key_t;
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
          return_ex Address_t;
          return_ex Key_hash_t;
          return_ex Key_t;
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
    | Never_t ->
        (* we never generate type Never_t *)
        Stdlib.failwith "Generating value of type never"
    | _ ->
        (* we do not generate any other type *)
        Stdlib.failwith "Generating unsupported type"
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

(** Generate a random type, along with a random value of that type. *)
let ex_val_generator :
    allow_bigmap:bool -> max_depth:int -> ex_val Context_gen.t =
 fun ~allow_bigmap ~max_depth ->
  let open Monad.Syntax (Context_gen) in
  let* (Ex_ty ty) = ex_ty_generator ~allow_bigmap ~max_depth in
  let+ x = ty_generator @@ Script_typed_ir.Ty_ex_c ty in
  Ex_val (ty, x)
