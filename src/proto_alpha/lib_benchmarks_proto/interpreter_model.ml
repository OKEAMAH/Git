(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

let ns = Namespace.make Registration_helpers.ns "interpreter"

let fv s = Free_variable.of_namespace (ns s)

(* ------------------------------------------------------------------------- *)

let trace_error expected given =
  let open Interpreter_workload in
  let exp = string_of_instr_or_cont expected in
  let given = string_of_instr_or_cont given in
  let msg =
    Format.asprintf
      "Interpreter_model: trace error, expected %s, given %s"
      exp
      given
  in
  Stdlib.failwith msg

let arity_error instr expected given =
  let open Interpreter_workload in
  let s = string_of_instr_or_cont instr in
  let msg =
    Format.asprintf
      "Interpreter_model: arity error (%s), expected %d, given %a"
      s
      expected
      Interpreter_workload.pp_args
      given
  in
  Stdlib.failwith msg

(* ------------------------------------------------------------------------- *)

let arity_to_int : type a b c. (a, b, c) Model.arity -> int =
 fun arity ->
  let rec aux : type x y z. int -> (x, y, z) Model.arity -> int =
   fun i -> function
    | Model.Zero_arity -> i
    | Succ_arity arity -> aux (i + 1) arity
  in
  aux 0 arity

let model_with_conv :
    type a.
    Interpreter_workload.instr_or_cont_name ->
    a Model.model ->
    Interpreter_workload.ir_sized_step Model.t =
 fun instr model ->
  let open Interpreter_workload in
  let module M = (val model) in
  let module I = Model.Instantiate (Costlang.Void) (M) in
  let arity_init = I.arity in
  let rec make_args :
      type x y z. arg list -> arg list -> (x, y, z) Model.arity -> z =
   fun args_init args arity ->
    match (args, arity) with
    | [], Zero_arity -> ()
    | {arg; _} :: l, Succ_arity arity -> (arg, make_args args_init l arity)
    | _ -> arity_error instr (arity_to_int arity_init) args_init
  in
  let conv {name; args} =
    if name = instr then make_args args args arity_init
    else trace_error instr name
  in
  Model.make ~conv ~model

let sf = Format.asprintf

let division_cost name =
  let open Model.Utils in
  let const = mk_const_opt None in
  let size1_coeff = fv "size1_coeff" in
  let q_coeff = fv "q_coeff" in
  let q_size2_coeff = fv "q_size2_coeff" in
  let module M = struct
    type arg_type = int * (int * unit)

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = Model.arity_2

      (* Actual [ediv] implementation uses different algorithms
         depending on the size of the arguments.
         Ideally, the cost function should be the combination of
         multiple affine functions branching on the arguments,
         but the current model fits with only one affine function for simplicity.
         For more discussion, see https://gitlab.com/tezos/tezos/-/issues/5480 *)
      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        (* Note that [q] is guaranteed to be non-negative because we use
           saturated subtraction. When [size1 < size2], the model evaluates to
           [const] as expected. *)
        let_ ~name:"q" (sat_sub size1 size2) @@ fun q ->
        (free ~name:q_size2_coeff * q * size2)
        + (free ~name:size1_coeff * size1)
        + (free ~name:q_coeff * q)
        + free ~name:const
    end

    let name = ns name
  end in
  (module M : Model.Model_impl with type arg_type = int * (int * unit))

let addlogadd name =
  let open Model.Utils in
  let const = mk_const_opt None in
  let coeff = mk_coeff_opt None in
  let module M = struct
    type arg_type = int * (int * unit)

    let name = ns name

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = Model.arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        let_ ~name:"a" (size1 + size2) @@ fun a ->
        (free ~name:coeff * (a * log2 (int 1 + a))) + free ~name:const
    end
  end in
  (module M : Model.Model_impl with type arg_type = int * (int * unit))

let name_of_instr_or_cont instr_or_cont =
  Interpreter_workload.string_of_instr_or_cont instr_or_cont

module Models = struct
  open Model.Utils

  let const1_model () =
    (* For constant-time instructions *)
    Model.unknown_const1 ()

  let affine_model =
    (* For instructions with cost function
       [\lambda size. const + coeff * size] *)
    Model.affine

  let affine_offset_model ~offset =
    (* For instructions with cost function
       [\lambda size. const + coeff * (size - offset)] *)
    Model.affine_offset ~offset

  let break_model break = Model.breakdown ~break

  let break_model_2 break1 break2 = Model.breakdown2 ~break1 ~break2

  let break_model_2_const break1 break2 = Model.breakdown2_const ~break1 ~break2

  let break_model_2_const_offset break1 break2 ~offset =
    Model.breakdown2_const_offset ~break1 ~break2 ~offset

  let nlogm_model =
    (* For instructions with cost function
       [\lambda size1. \lambda size2. const + coeff * size1 log2(size2)] *)
    Model.nlogm

  let concat_model =
    Model.bilinear_affine ~coeff1:"total_bytes" ~coeff2:"list_length"

  let concat_pair_model = Model.linear_sum

  let linear_max_model =
    (* For instructions with cost function
       [\lambda size1. \lambda size2. const + coeff * max(size1,size2)] *)
    Model.linear_max

  let linear_min_model =
    (* For instructions with cost function
       [\lambda size1. \lambda size2. const + coeff * min(size1,size2)] *)
    Model.linear_min

  let linear_min_offset_model ~offset =
    (* For instructions with cost function
       [\lambda size1. \lambda size2. const + coeff * (min(size1,size2) - offset)] *)
    Model.linear_min_offset ~offset

  let pack_model =
    Model.trilinear
      ~coeff1:"micheline_nodes"
      ~coeff2:"micheline_int_bytes"
      ~coeff3:"micheline_string_bytes"

  let open_chest_model name =
    let module M = struct
      type arg_type = int * (int * unit)

      let const = mk_const_opt None

      let coeff1 = mk_coeff ~num:1 "log_time"

      let coeff2 = mk_coeff ~num:2 "plaintext"

      module Def (X : Costlang.S) = struct
        open X

        type model_type = size -> size -> size

        let arity = Model.arity_2

        let model =
          lam ~name:"size1" @@ fun size1 ->
          lam ~name:"size2" @@ fun size2 ->
          free ~name:const
          + (free ~name:coeff1 * sat_sub size1 (int 1))
          + (free ~name:coeff2 * size2)
      end

      let name = ns name
    end in
    (module M : Model.Model_impl with type arg_type = int * (int * unit))

  let verify_update_model =
    Model.bilinear_affine ~coeff1:"inputs" ~coeff2:"outputs"

  let list_enter_body_model name =
    let module M = struct
      type arg_type = int * (int * unit)

      let const = mk_const_opt None

      let coeff1 = mk_coeff_opt ~num:1 None

      let coeff2 = mk_coeff ~num:2 "iter"

      module Def (X : Costlang.S) = struct
        open X

        type model_type = size -> size -> size

        let arity = Model.arity_2

        let model =
          lam ~name:"size_xs" @@ fun size_xs ->
          lam ~name:"size_ys" @@ fun size_ys ->
          if_
            (eq size_xs (int 0))
            (free ~name:const + (free ~name:coeff1 * size_ys))
            (free ~name:coeff2)
      end

      let name = ns name
    end in
    (module M : Model.Model_impl with type arg_type = int * (int * unit))

  let branching_model ~case_0 ~case_1 name =
    let module M = struct
      type arg_type = int * unit

      module Def (X : Costlang.S) = struct
        open X

        type model_type = size -> size

        let arity = Model.arity_1

        let model =
          lam ~name:"size" @@ fun size ->
          if_
            (eq size (int 0))
            (free ~name:(fv (sf "%s_%s" name case_0)))
            (free ~name:(fv (sf "%s_%s" name case_1)))
      end

      let name = ns name
    end in
    (module M : Model.Model_impl with type arg_type = int * unit)

  let empty_branch_model name =
    branching_model ~case_0:"empty" ~case_1:"nonempty" name

  let option_branch_model name =
    (* This model takes a boolean argument representing whether it is some or none *)
    branching_model ~case_0:"none" ~case_1:"some" name

  let lambda_model name =
    (* branch whether lambda is rec or nonrec *)
    branching_model ~case_0:"lam" ~case_1:"lamrec" name

  let join_tickets_model name =
    let module M = struct
      type arg_type = int * (int * (int * (int * unit)))

      let const = mk_const_opt None

      let coeff1 = mk_coeff ~num:1 "compare_coeff"

      let coeff2 = mk_coeff ~num:2 "add"

      module Def (X : Costlang.S) = struct
        open X

        type model_type = size -> size -> size -> size -> size

        let arity = Model.Succ_arity Model.arity_3

        let model =
          lam ~name:"content_size_x" @@ fun content_size_x ->
          lam ~name:"content_size_y" @@ fun content_size_y ->
          lam ~name:"amount_size_x" @@ fun amount_size_x ->
          lam ~name:"amount_size_y" @@ fun amount_size_y ->
          free ~name:const
          + (free ~name:coeff1 * min content_size_x content_size_y)
          + (free ~name:coeff2 * max amount_size_x amount_size_y)
      end

      let name = ns name
    end in
    (module M : Model.Model_impl
      with type arg_type = int * (int * (int * (int * unit))))

  (* Almost [Model.bilinear_affine] but the intercept is not at 0s
     but size1=0 and size2=1 *)
  let lsl_bytes_model name =
    let intercept = mk_const_opt None in
    let coeff1 = mk_coeff ~num:1 "bytes" in
    let coeff2 = mk_coeff ~num:2 "shift" in
    let module M = struct
      type arg_type = int * (int * unit)

      let name = ns name

      module Def (X : Costlang.S) = struct
        open X

        type model_type = size -> size -> size

        let arity = Model.arity_2

        let model =
          lam ~name:"size1" @@ fun size1 ->
          lam ~name:"size2" @@ fun size2 ->
          free ~name:intercept
          + (free ~name:coeff1 * size1)
          + (free ~name:coeff2 * sat_sub size2 (int 1))
      end
    end in
    (module M : Model.Model_impl with type arg_type = int * (int * unit))

  (* The intercept is not at 0s but size1=0 and size2=1 *)
  let lsr_bytes_model name =
    let const = mk_const_opt None in
    let coeff = mk_coeff_opt None in
    let module M = struct
      type arg_type = int * (int * unit)

      module Def (X : Costlang.S) = struct
        open X

        type model_type = size -> size -> size

        let arity = Model.arity_2

        let model =
          lam ~name:"size1" @@ fun size1 ->
          lam ~name:"size2" @@ fun size2 ->
          (* Note that [q] is guaranteed to be non-negative because we use
             saturated subtraction. When [size1 < size2], the model evaluates to
             [const] as expected. *)
          let_ ~name:"q" (sat_sub size1 (size2 * float 0.125)) @@ fun q ->
          free ~name:const + (free ~name:coeff * q)
      end

      let name = ns name
    end in
    (module M : Model.Model_impl with type arg_type = int * (int * unit))
end

type ir_model =
  | TimeModel : 'a Model.model -> ir_model
  | TimeAllocModel : {
      name : Namespace.t; (* name for synthesized model *)
      time : 'a Model.model;
      alloc : 'a Model.model;
    }
      -> ir_model

let ir_model instr_or_cont =
  let open Interpreter_workload in
  let open Models in
  let name = name_of_instr_or_cont instr_or_cont in
  let m s = TimeModel s in
  match instr_or_cont with
  | Instr_name instr -> (
      match instr with
      | N_IDrop | N_IDup | N_ISwap | N_IPush | N_IUnit | N_ICons_pair | N_ICar
      | N_ICdr | N_ICons_some | N_ICons_none | N_IIf_none | N_ILeft | N_IRight
      | N_IIf_left | N_ICons_list | N_INil | N_IIf_cons | N_IEmpty_set
      | N_IEmpty_map | N_IEmpty_big_map | N_IOr | N_IAnd | N_IXor | N_INot
      | N_IIf | N_ILoop | N_ILoop_left | N_IDip | N_IExec | N_IView
      | N_IFailwith | N_IAddress | N_ICreate_contract | N_ISet_delegate | N_INow
      | N_IMin_block_time | N_IBalance | N_IHash_key | N_IUnpack | N_ISource
      | N_ISender | N_ISelf | N_IAmount | N_IChainId | N_ILevel
      | N_ISelf_address | N_INever | N_IUnpair | N_IVoting_power
      | N_ITotal_voting_power | N_IList_size | N_ISet_size | N_IMap_size
      | N_ISapling_empty_state ->
          const1_model () |> m
      | N_ISet_mem | N_ISet_update | N_IMap_mem | N_IMap_get | N_IMap_update
      | N_IBig_map_mem | N_IBig_map_get | N_IBig_map_update
      | N_IMap_get_and_update | N_IBig_map_get_and_update ->
          nlogm_model () |> m
      | N_IConcat_string -> concat_model () |> m
      | N_IConcat_string_pair -> concat_pair_model () |> m
      | N_ISlice_string -> affine_model () |> m
      | N_IString_size -> const1_model () |> m
      | N_IConcat_bytes -> concat_model () |> m
      | N_IConcat_bytes_pair -> concat_pair_model () |> m
      | N_ISlice_bytes -> affine_model () |> m
      | N_IBytes_size -> const1_model () |> m
      | N_IOr_bytes -> linear_max_model () |> m
      | N_IAnd_bytes -> linear_min_model () |> m
      | N_IXor_bytes -> linear_max_model () |> m
      | N_INot_bytes -> affine_model () |> m
      | N_ILsl_bytes -> lsl_bytes_model name |> m
      | N_ILsr_bytes -> lsr_bytes_model name |> m
      | N_IBytes_nat -> affine_model () |> m
      | N_INat_bytes -> affine_model () |> m
      | N_IBytes_int -> affine_model () |> m
      | N_IInt_bytes -> affine_model () |> m
      | N_IAdd_seconds_to_timestamp | N_IAdd_timestamp_to_seconds
      | N_ISub_timestamp_seconds | N_IDiff_timestamps ->
          linear_max_model () |> m
      | N_IAdd_tez | N_ISub_tez | N_ISub_tez_legacy | N_IEdiv_tez
      | N_IMul_teznat | N_IMul_nattez | N_IEdiv_teznat ->
          const1_model () |> m
      | N_IIs_nat -> const1_model () |> m
      | N_INeg -> affine_model () |> m
      | N_IAbs_int -> affine_model () |> m
      | N_IInt_nat -> const1_model () |> m
      | N_IAdd_int -> linear_max_model () |> m
      | N_IAdd_nat -> linear_max_model () |> m
      | N_ISub_int -> linear_max_model () |> m
      | N_IMul_int -> addlogadd name |> m
      | N_IMul_nat -> addlogadd name |> m
      | N_IEdiv_int -> division_cost name |> m
      | N_IEdiv_nat -> division_cost name |> m
      | N_ILsl_nat -> affine_model () |> m
      | N_ILsr_nat -> affine_model () |> m
      | N_IOr_nat -> linear_max_model () |> m
      | N_IAnd_nat -> linear_min_model () |> m
      | N_IAnd_int_nat -> linear_min_model () |> m
      | N_IXor_nat -> linear_max_model () |> m
      | N_INot_int -> affine_model () |> m
      | N_ICompare -> linear_min_offset_model () ~offset:1 |> m
      | N_IEq | N_INeq | N_ILt | N_IGt | N_ILe | N_IGe -> const1_model () |> m
      | N_IPack -> pack_model () |> m
      | N_IBlake2b | N_ISha256 | N_ISha512 | N_IKeccak | N_ISha3 ->
          affine_model () |> m
      | N_ICheck_signature_ed25519 | N_ICheck_signature_secp256k1
      | N_ICheck_signature_p256 | N_ICheck_signature_bls ->
          affine_model () |> m
      | N_IContract | N_ITransfer_tokens | N_IImplicit_account ->
          const1_model () |> m
      (* The following two instructions are expected to have an affine model. However,
         we observe 3 affine parts, on [0;300], [300;400] and [400;\inf[. *)
      | N_IDupN -> break_model_2_const_offset 300 400 ~offset:1 () |> m
      | N_IDropN -> break_model_2_const 300 400 () |> m
      | N_IDig | N_IDug | N_IDipN -> affine_model () |> m
      | N_IAdd_bls12_381_g1 | N_IAdd_bls12_381_g2 | N_IAdd_bls12_381_fr
      | N_IMul_bls12_381_g1 | N_IMul_bls12_381_g2 | N_IMul_bls12_381_fr
      | N_INeg_bls12_381_g1 | N_INeg_bls12_381_g2 | N_INeg_bls12_381_fr
      | N_IInt_bls12_381_z_fr ->
          const1_model () |> m
      | N_IMul_bls12_381_fr_z | N_IMul_bls12_381_z_fr
      | N_IPairing_check_bls12_381 ->
          affine_model () |> m
      | N_IComb | N_IUncomb -> affine_offset_model () ~offset:2 |> m
      | N_IComb_get | N_IComb_set -> affine_model () |> m
      | N_ITicket | N_IRead_ticket -> const1_model () |> m
      | N_ISplit_ticket -> linear_max_model () |> m
      | N_IJoin_tickets -> join_tickets_model name |> m
      | N_ISapling_verify_update -> verify_update_model () |> m
      | N_IList_map -> const1_model () |> m
      | N_IList_iter -> const1_model () |> m
      | N_IIter -> const1_model () |> m
      | N_IMap_map -> affine_model () |> m
      | N_IMap_iter -> affine_model () |> m
      | N_ISet_iter -> affine_model () |> m
      | N_IHalt -> const1_model () |> m
      | N_IApply -> lambda_model name |> m
      | N_ILambda -> lambda_model name |> m
      | N_ILog -> const1_model () |> m
      | N_IOpen_chest -> open_chest_model name |> m
      | N_IEmit -> const1_model () |> m
      | N_IOpt_map -> option_branch_model name |> m)
  | Cont_name cont -> (
      match cont with
      | N_KNil -> const1_model () |> m
      | N_KCons -> const1_model () |> m
      | N_KReturn -> const1_model () |> m
      | N_KView_exit -> const1_model () |> m
      | N_KMap_head -> const1_model () |> m
      | N_KUndip -> const1_model () |> m
      | N_KLoop_in -> const1_model () |> m
      | N_KLoop_in_left -> const1_model () |> m
      | N_KIter -> empty_branch_model name |> m
      | N_KList_enter_body -> list_enter_body_model name |> m
      | N_KList_exit_body -> const1_model () |> m
      | N_KMap_enter_body -> empty_branch_model name |> m
      | N_KMap_exit_body -> nlogm_model () |> m
      | N_KLog -> const1_model () |> m)

let gas_unit_per_allocation_word = 4

module SynthesizeTimeAlloc : Model.Binary_operation = struct
  module Def (X : Costlang.S) = struct
    let op time alloc = X.(max time (alloc * int gas_unit_per_allocation_word))
  end
end

let pack_ir_model = function
  | TimeModel m -> Model.Model m
  | TimeAllocModel {name; time; alloc} ->
      Model.Model
        (Model.synthesize
           ~binop:(module SynthesizeTimeAlloc)
           ~name
           ~x_label:"time"
           ~x_model:time
           ~y_label:"alloc"
           ~y_model:alloc)

let amplification_loop_iteration = "amplification_loop_iteration"

let amplification_loop_model =
  let module Mod = (val Model.linear ~coeff:amplification_loop_iteration ()) in
  let module M = struct
    include Mod

    let name = ns "amplification_loop_model"

    module Rename = (val Costlang.rename_free_vars ~name)

    module Def (X : Costlang.S) = Def (Rename (X))
  end in
  Model.make ~conv:(fun iterations -> (iterations, ())) ~model:(module M)

let conv (type a) (module M : Model.Model_impl with type arg_type = a)
    bench_name =
  (module struct
    include M

    let name = Model.adjust_name bench_name M.name

    module Renamed = (val Costlang.rename_free_vars ~name)

    module Def (S : Costlang.S) = Def (Renamed (S))
  end : Model.Model_impl
    with type arg_type = a)

let conv_model (m : ir_model) bench_name =
  match m with TimeModel m -> TimeModel (conv m bench_name) | x -> x

let conv_model_made (m : 'a Model.t) bench_name =
  match m with
  | Model.Abstract {conv = c; model} ->
      Model.Abstract {conv = c; model = conv model bench_name}
  | _ -> m

(* The following model stitches together the per-instruction models and
   adds a term corresponding to the amplification (if needed). *)
let interpreter_model ?amplification sub_model =
  Model.make_aggregated
    ~model:(fun trace ->
      let module Def (X : Costlang.S) = struct
        type t = X.size X.repr

        let applied =
          let initial =
            match amplification with
            | None -> X.int 0
            | Some amplification_factor ->
                let (module Amplification_applied) =
                  Model.apply
                    (conv_model_made
                       amplification_loop_model
                       (ns "amplification_loop"))
                    amplification_factor
                in
                let module Amplification_result = Amplification_applied (X) in
                Amplification_result.applied
          in
          List.fold_left
            (fun (acc : X.size X.repr) instr_trace ->
              let name = instr_trace.Interpreter_workload.name in
              let (Model.Model model) =
                pack_ir_model
                  (conv_model
                     (ir_model name)
                     (ns @@ name_of_instr_or_cont name))
              in
              let (module Applied_instr) =
                Model.apply (model_with_conv name model) instr_trace
              in
              let module R = Applied_instr (X) in
              X.(acc + R.applied))
            initial
            trace
      end in
      ((module Def) : Model.applied))
    ~sub_models:[sub_model]

let make_model ?amplification instr_name =
  let ir_model = ir_model instr_name in
  [("interpreter", interpreter_model ?amplification (pack_ir_model ir_model))]
