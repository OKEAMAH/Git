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
open Script_typed_ir

(** Flag that drives unparsing of typed values to nodes.
    - [Optimized_legacy] must be kept backward-compatible in order to compute
      valid hashes (of big map keys).
    - [Optimized] may be used as long as the result can be read by
      {!Script_ir_translator.parse_data}.
    - [Readable] produces with [string] values instead of [bytes] when feasible.
*)
type unparsing_mode = Optimized | Readable | Optimized_legacy

(** [('t, 'd) comb_witness] describes types of values belonging to a [comb]
    of type ['t] and size ['d]. *)
type ('ty, 'depth) comb_witness =
  | Comb_Pair : ('t, 'd) comb_witness -> (_ * 't, unit -> 'd) comb_witness
  | Comb_Any : (_, _) comb_witness

(** [serialize_ty_for_error ty] returns the Micheline representation of [ty]
    suitable for rendering in an error message. Does not consume gas, since
    when this function is called, the operation must have already failed. *)
val serialize_ty_for_error : ('a, 'b) ty -> Script.expr

(** [serialize_stack_for_error stack_ty] returns a Micheline representation of
    [stack_ty] as a list of Micheline expressions. *)
val serialize_stack_for_error : ('a, 'b) stack_ty -> Script.expr list

(** [unparse_ty ~loc ty] returns the Micheline representation of a given
    type. *)
val unparse_ty :
  loc:'loc -> ('b, 'c) ty -> ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_comparable_ty_uncarbonated ~loc ty] returns the Michelson
    representation of comparable type [ty] without consuming gas. *)
val unparse_comparable_ty_uncarbonated :
  loc:'loc -> 'a comparable_ty -> 'loc Script.michelson_node

(** [unparse_stack_uncarbonated stack_ty] returns the Micheline representation
    of [stack_ty]. Does not consume gas. *)
val unparse_stack_uncarbonated : ('a, 's) stack_ty -> Script.expr list

(** [unparse_parameter_ty ~loc ty ~entrypoints] is a specialised version of
    [unparse_ty], which also analyses [entrypoints] in order to annotate
    the returned type with adequate annotations. *)
val unparse_parameter_ty :
  loc:'loc ->
  ('a, 'c) ty ->
  entrypoints:'a entrypoints ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_bls12_381_g1 ~loc bls] returns the Micheline representation
    of [bls] and consumes gas. *)
val unparse_bls12_381_g1 :
  loc:'loc ->
  Script_bls.G1.t ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_bls12_381_g1 ~loc bls] returns the Micheline representation
    of [bls] and consumes gas. *)
val unparse_bls12_381_g2 :
  loc:'loc ->
  Script_bls.G2.t ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_bls12_381_g1 ~loc bls] returns the Micheline representation
    of [bls] and consumes gas. *)
val unparse_bls12_381_fr :
  loc:'loc ->
  Script_bls.Fr.t ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_operation ~loc op] returns the Micheline representation of
    [op] and consumes gas. Useful only for producing execution
    traces in the interpreter. *)
val unparse_operation :
  loc:'loc ->
  Script_typed_ir.operation ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_with_data_encoding ~loc v gas_cost enc] returns the bytes
    representation of [v] wrapped in [Micheline.Bytes], consuming [gas_cost]. *)
val unparse_with_data_encoding :
  loc:'loc ->
  'a ->
  Gas.cost ->
  'a Data_encoding.t ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** [unparse_comparable_data ctxt unparsing_mode ty v] returns the
    Micheline representation of [v] of type [ty], consuming gas. *)
val unparse_comparable_data :
  unparsing_mode ->
  'a comparable_ty ->
  'a ->
  (Script.expr, error trace) Gas_monad.t

(** [unparse_contract ~loc unparsin_mode contract] returns a Micheline
    representation of a given contract in a given [unparsing_mode], and consumes
    gas. *)
val unparse_contract :
  loc:'loc ->
  unparsing_mode ->
  'b typed_contract ->
  ('loc Script.michelson_node, 'trace) Gas_monad.t

(** Lambdas are normalized at parsing and also at unparsing. These
    normalizations require to parse and unparse data appearing inside
    PUSH and introduces a mutual dependency between this module and
    [Script_ir_translator] which is resolved as follows:
    - [Script_ir_translator.parse_data] takes the normalization function
      [unparse_code_rec] as argument,
    - the unparsing function [unparse_data_rec] and the normalization
      function [unparse_code_rec] are mutually defined in a functor
      parameterized by the missing bits from [Script_ir_translator]; see the
      module signature [MICHELSON_PARSER] below.
 *)

(** The [unparse_code_rec] function is not exported (except through
    the [Internal_for_benchmarking] module), but needs to be called by
    [parse_data] to normalize lambdas so it is passed as argument to
    the [parse_data] of the [MICHELSON_PARSER] signature below and to
    several functions of [Script_ir_translator]. To avoid repeating the
    signature of this function we define a type alias for it. *)
type unparse_code_rec =
  stack_depth:int ->
  elab_conf:Script_ir_translator_config.elab_config ->
  unparsing_mode ->
  Script.node ->
  (Script.node, error trace) Gas_monad.t

(** [MICHELSON_PARSER] signature describes a set of dependencies required to
    unparse arbitrary values in the IR. Because some of those values contain
    just a Michelson code that does not need to be parsed immediately,
    unparsing them requires extracting information from that code – that's
    why we depend on the parser here. *)

module type MICHELSON_PARSER = sig
  val opened_ticket_type :
    Script.location ->
    'a comparable_ty ->
    (address, ('a, Script_int.n Script_int.num) pair) pair comparable_ty
    tzresult

  val parse_packable_ty :
    stack_depth:int ->
    legacy:bool ->
    Script.node ->
    (ex_ty, error trace) Gas_monad.t

  val parse_data :
    unparse_code_rec:unparse_code_rec ->
    elab_conf:Script_ir_translator_config.elab_config ->
    stack_depth:int ->
    allow_forged:bool ->
    ('a, 'ac) ty ->
    Script.node ->
    ('a, error trace) Gas_monad.t
end

module Data_unparser : functor (P : MICHELSON_PARSER) -> sig
  (** [unparse_data ~stack_depth unparsing_mode ty data] returns the
      Micheline representation of [data] of type [ty], consuming an appropriate
      amount of gas. *)
  val unparse_data :
    stack_depth:int ->
    elab_conf:Script_ir_translator_config.elab_config ->
    unparsing_mode ->
    ('a, 'ac) ty ->
    'a ->
    (Script.expr, error trace) Gas_monad.t

  (** [unparse_code ~stack_depth ~elab_conf unparsing_mode code] returns [code]
      with [I_PUSH] instructions parsed and unparsed back to make sure that
      only forgeable values are being pushed. Gas is being consumed. *)
  val unparse_code :
    stack_depth:int ->
    elab_conf:Script_ir_translator_config.elab_config ->
    unparsing_mode ->
    Script.node ->
    (Script.expr, error trace) Gas_monad.t

  (** For benchmarking purpose, we also export versions of the unparsing
      functions which don't call location stripping. These functions are
      not carbonated and should not be called directly from the protocol. *)
  module Internal_for_benchmarking : sig
    val unparse_data :
      stack_depth:int ->
      elab_conf:Script_ir_translator_config.elab_config ->
      unparsing_mode ->
      ('a, 'ac) ty ->
      'a ->
      (Script.node, error trace) Gas_monad.t

    val unparse_code :
      stack_depth:int ->
      elab_conf:Script_ir_translator_config.elab_config ->
      unparsing_mode ->
      Script.node ->
      (Script.node, error trace) Gas_monad.t
  end
end
