(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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
let rename constant_name = Namespace.of_string @@ constant_name ^ "__model"

type (_, _, _) arity =
  | Zero_arity : ('elt, 'elt, unit) arity
  | Succ_arity : ('elt, 'b, 'a) arity -> ('elt, 'elt -> 'b, int * 'a) arity

let arity_0 = Zero_arity

let arity_1 = Succ_arity arity_0

let arity_2 = Succ_arity arity_1

let arity_3 = Succ_arity arity_2

module type Model_impl = sig
  type arg_type

  val name : Namespace.t

  module Def (X : Costlang.S) : sig
    type model_type

    val arity : (X.size, model_type, arg_type) arity

    val model : model_type X.repr
  end
end

module type Instantiated = sig
  type 'a repr

  type size

  type arg_type

  type model_type

  val arity : (size, model_type, arg_type) arity

  val model : arg_type -> size repr
end

type 'arg model = (module Model_impl with type arg_type = 'arg)

module type App = sig
  type t

  val applied : t
end

module type Applied = functor (X : Costlang.S) ->
  App with type t = X.size X.repr

type applied = (module Applied)

type packed_model = Model : _ model -> packed_model

type _ t =
  | Abstract : {conv : 'workload -> 'arg; model : 'arg model} -> 'workload t
  | Aggregate : {
      model : 'workload -> applied;
      sub_models : packed_model list;
    }
      -> 'workload t

let pp_packed_model ppf (Model model) =
  let module Model = (val model) in
  let module Pp = Model.Def (Costlang.Pp) in
  Format.fprintf ppf "@[<v2>%a:@ %s@]" Namespace.pp Model.name Pp.model

let pp ppf = function
  | Abstract {model; _} ->
      Format.fprintf ppf "@[<v2>Abstract@ %a@]" pp_packed_model (Model model)
  | Aggregate {sub_models; _} ->
      Format.fprintf
        ppf
        "@[<v2>Aggregate with submodels:@ @[%a@]@]"
        (Format.pp_print_list pp_packed_model)
        sub_models

let apply_model : 'arg -> 'arg model -> applied =
  fun (type e) (elim : e) ((module Impl) : e model) ->
   let module Applied (X : Costlang.S) = struct
     include Impl.Def (X)

     type t = X.size X.repr

     let rec apply :
         type a b c.
         (int -> c X.repr) -> (c, a, b) arity -> a X.repr -> b -> c X.repr =
      fun conv arity f arg ->
       match arity with
       | Zero_arity -> f
       | Succ_arity ar ->
           let arg, rest = arg in
           apply conv ar (X.app f (conv arg)) rest

     let applied = apply X.int arity model elim
   end in
   ((module Applied) : applied)

module Instantiate (X : Costlang.S) (M : Model_impl) :
  Instantiated
    with type 'a repr = 'a X.repr
     and type size = X.size
     and type arg_type = M.arg_type = struct
  type 'a repr = 'a X.repr

  type size = X.size

  include M
  include Def (X)

  let rec apply :
      type a b c.
      (int -> c X.repr) -> (c, a, b) arity -> a X.repr -> b -> c X.repr =
   fun conv arity f arg ->
    match arity with
    | Zero_arity -> f
    | Succ_arity ar ->
        let arg, rest = arg in
        apply conv ar (X.app f (conv arg)) rest

  let model elim = apply X.int arity model elim
end

let make ~conv ~model = Abstract {conv; model}

let make_aggregated ~model ~sub_models = Aggregate {model; sub_models}

let apply model workload =
  match model with
  | Abstract {conv; model} -> apply_model (conv workload) model
  | Aggregate {model; _} -> model workload

let force_aggregated ~model =
  match model with
  | Aggregate _ -> model
  | Abstract {conv = _; model = model2} ->
      Aggregate {model = apply model; sub_models = [Model model2]}

let add_aggregated_models :
    ('w1 -> applied) -> ('w2 -> applied) -> 'w1 * 'w2 -> applied =
 fun m1 m2 (w1, w2) ->
  let (module M1) = m1 w1 in
  let (module M2) = m2 w2 in
  let module M (X : Costlang.S) = struct
    type t = X.size X.repr

    let applied =
      let (module M1 : App with type t = X.size X.repr) = (module M1 (X)) in
      let (module M2 : App with type t = X.size X.repr) = (module M2 (X)) in
      X.(M1.applied + M2.applied)
  end in
  (module M : Applied)

let add_model m1 m2 =
  let m1 = force_aggregated ~model:m1 in
  let m2 = force_aggregated ~model:m2 in
  match (m1, m2) with
  | ( Aggregate {model = m1; sub_models = l1},
      Aggregate {model = m2; sub_models = l2} ) ->
      Aggregate {model = add_aggregated_models m1 m2; sub_models = l1 @ l2}
  | _ -> assert false (* impossible *)

let precompose : type a b. (a -> b) -> b t -> a t =
 fun f model ->
  match model with
  | Abstract {conv; model} ->
      let conv x = conv (f x) in
      Abstract {conv; model}
  | Aggregate {model; sub_models} ->
      Aggregate {model = (fun x -> model (f x)); sub_models}

let get_free_variable_set (type a) (model : a model) =
  let module M = (val model) in
  let module T0 = Costlang.Fold_constants (Costlang.Free_variables) in
  let module T1 = Costlang.Beta_normalize (T0) in
  let module R = M.Def (T1) in
  T0.prj @@ T1.prj R.model

let adjust_name bench_name model_name =
  let ns =
    match Namespace.to_list bench_name |> List.rev with
    | "intercept" :: xs -> xs
    | x -> x
  in
  let name =
    String.concat "/" (List.rev ns |> List.drop_n 1) |> Namespace.of_string
  in
  Namespace.cons name (Namespace.basename model_name)

(* No workload application.  For [Aggregate _], only extract
   the free variables of the [sub_models].
*)
let get_free_variable_set_of_t =
  let get_free_variables_of_packed_model (Model (module Model) : packed_model) =
    let module M = Model.Def (Costlang.Free_variables) in
    M.model
  in
  function
  | Abstract {model; _} -> get_free_variables_of_packed_model (Model model)
  | Aggregate {sub_models; _} ->
      List.fold_left
        (fun acc packed_model ->
          Free_variable.Set.union acc
          @@ get_free_variables_of_packed_model packed_model)
        Free_variable.Set.empty
        sub_models

let get_free_variable_set_applied (type workload) (model : workload t)
    (workload : workload) =
  (* If a parameter is fixed to 0 in the workload data, the application
      of the workload can eliminate free variables multiplied
      by the parameter.

      The typical example is the intercept case where some parameters
      tend to be fixed to 0.  This may not work when the intercept point
      is not at "zero"s.

      It is unfortunate that we need to apply workload data to a model to
      know which variables can be optimized out.  We may be able to do it
      without workload, but it seems not an easy task.
  *)
  let applied = apply model workload in
  let module M = (val applied) in
  let module T0 = Costlang.Fold_constants (Costlang.Free_variables) in
  let module T1 = Costlang.Beta_normalize (T0) in
  let module R = M (T1) in
  T0.prj @@ T1.prj R.applied

module Utils = struct
  let fv = Free_variable.For_open.fv

  let make ~f ?(num = 0) ~name param =
    let name = match num with 0 -> name | _ -> name ^ string_of_int num in
    f param name

  let id param name = fv @@ Format.sprintf "%s_%s" param name

  let option param name =
    Option.fold
      ~none:(fv name)
      ~some:(fun x ->
        let x = fv x in
        Free_variable.cons x name)
      param

  let mk_const ?num = make ?num ~f:id ~name:"const"

  let mk_const_opt ?num = make ?num ~f:option ~name:"const"

  let mk_coeff ?num = make ?num ~f:id ~name:"coeff"

  let mk_coeff_opt ?num = make ?num ~f:option ~name:"coeff"

  let mk_log_coeff ?num = make ?num ~f:id ~name:"log_coeff"

  let mk_log_coeff_opt ?num = make ?num ~f:option ~name:"log_coeff"

  let mk_linear_coeff ?num = make ?num ~f:id ~name:"linear_coeff"

  let mk_linear_coeff_opt ?num = make ?num ~f:option ~name:"linear_coeff"

  let mk_intercept ?num = make ?num ~f:id ~name:"intercept"

  let mk_intercept_opt ?num = make ?num ~f:option ~name:"intercept"
end

(* -------------------------------------------------------------------------- *)
(* Commonly used models *)

open Utils

let zero =
  let module M = struct
    type arg_type = unit

    let name = Namespace.root "zero"

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size

      let arity = arity_0

      let model = int 0
    end
  end in
  (module M : Model_impl with type arg_type = unit)

let unknown_const1 ?const () =
  let module M = struct
    type arg_type = unit

    let const = mk_const_opt const

    let name = rename "unknown_const1"

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size

      let arity = arity_0

      let model = free ~name:const
    end
  end in
  (module M : Model_impl with type arg_type = unit)

let linear ?coeff () =
  let module M = struct
    type arg_type = int * unit

    let name = rename "linear"

    let coeff = mk_coeff_opt coeff

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model = lam ~name:"size" @@ fun size -> free ~name:coeff * size
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let affine ?intercept ?coeff () : (int * unit) model =
  let module M = struct
    type arg_type = int * unit

    let name = rename "affine"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        free ~name:intercept + (free ~name:coeff * size)
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let affine_offset ?intercept ?coeff ~offset () =
  let module M = struct
    type arg_type = int * unit

    let name = rename "affine_offset"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        free ~name:intercept + (free ~name:coeff * sat_sub size (int offset))
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let quadratic ?coeff () =
  let module M = struct
    type arg_type = int * unit

    let name = rename "quadratic"

    let coeff = mk_coeff_opt coeff

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size -> free ~name:coeff * (size * size)
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let nlogn ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * unit

    let name = rename "nlogn"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        free ~name:intercept + (free ~name:coeff * (size * log2 (int 1 + size)))
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let nsqrtn_const ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * unit

    let name = rename "nsqrtn_const"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        free ~name:intercept + (free ~name:coeff * (size * sqrt size))
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let logn ?coeff () =
  let module M = struct
    type arg_type = int * unit

    let name = rename "logn"

    let coeff = mk_coeff_opt coeff

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size -> free ~name:coeff * log2 (int 1 + size)
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let linear_sum ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "linear_sum"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept + (free ~name:coeff * (size1 + size2))
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let linear_max ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "linear_max"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept + (free ~name:coeff * max size1 size2)
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let linear_min ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "linear_min"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept + (free ~name:coeff * min size1 size2)
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let linear_min_offset ?intercept ?coeff ~offset () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "linear_min_offset"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept
        + (free ~name:coeff * sat_sub (min size1 size2) (int offset))
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let linear_mul ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "linear_mul"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept + (free ~name:coeff * (size1 * size2))
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let bilinear ?coeff1 ?coeff2 () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "bilinear"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        (free ~name:coeff1 * size1) + (free ~name:coeff2 * size2)
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let bilinear_affine ?intercept ?coeff1 ?coeff2 () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "bilinear_affine"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept
        + (free ~name:coeff1 * size1)
        + (free ~name:coeff2 * size2)
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let nlogm ?intercept ?coeff () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "nlogm"

    let coeff = mk_coeff_opt coeff

    let intercept = mk_intercept_opt intercept

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept
        + (free ~name:coeff * (size1 * log2 (int 1 + size2)))
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let n_plus_logm ?intercept ?linear_coeff ?log_coeff () =
  let module M = struct
    type arg_type = int * (int * unit)

    let name = rename "n_plus_logm"

    let intercept = mk_intercept_opt intercept

    let log_coeff = mk_log_coeff_opt log_coeff

    let linear_coeff = mk_linear_coeff_opt linear_coeff

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size

      let arity = arity_2

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        free ~name:intercept
        + (free ~name:linear_coeff * size1)
        + (free ~name:log_coeff * log2 (int 1 + size2))
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * unit))

let trilinear ?coeff1 ?coeff2 ?coeff3 () =
  let module M = struct
    type arg_type = int * (int * (int * unit))

    let name = rename "trilinear"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    let coeff3 = mk_coeff_opt ~num:3 coeff3

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size -> size -> size

      let arity = arity_3

      let model =
        lam ~name:"size1" @@ fun size1 ->
        lam ~name:"size2" @@ fun size2 ->
        lam ~name:"size3" @@ fun size3 ->
        (free ~name:coeff1 * size1)
        + (free ~name:coeff2 * size2)
        + (free ~name:coeff3 * size3)
    end
  end in
  (module M : Model_impl with type arg_type = int * (int * (int * unit)))

let breakdown ?coeff1 ?coeff2 ~break () =
  assert (0 <= break) ;

  let module M = struct
    type arg_type = int * unit

    let name = rename "breakdown"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        (free ~name:coeff1 * min (int break) size)
        + (free ~name:coeff2 * sat_sub size (int break))
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let breakdown2 ?coeff1 ?coeff2 ?coeff3 ~break1 ~break2 () =
  assert (0 <= break1 && break1 <= break2) ;
  let module M = struct
    type arg_type = int * unit

    let name = rename "breakdown2"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    let coeff3 = mk_coeff_opt ~num:3 coeff3

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        (free ~name:coeff1 * min (int break1) size)
        + (free ~name:coeff2 * sat_sub (min (int break2) size) (int break1))
        + (free ~name:coeff3 * sat_sub size (int break2))
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let breakdown2_const ?coeff1 ?coeff2 ?coeff3 ?const ~break1 ~break2 () =
  assert (0 <= break1 && break1 <= break2) ;
  let module M = struct
    type arg_type = int * unit

    let name = rename "breakdown2_const"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    let coeff3 = mk_coeff_opt ~num:3 coeff3

    let const = mk_const_opt const

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        (free ~name:coeff1 * min (int break1) size)
        + (free ~name:coeff2 * sat_sub (min (int break2) size) (int break1))
        + (free ~name:coeff3 * sat_sub size (int break2))
        + free ~name:const
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

let breakdown2_const_offset ?coeff1 ?coeff2 ?coeff3 ?const ~break1 ~break2
    ~offset () =
  assert (0 <= break1 && break1 <= break2) ;
  let module M = struct
    type arg_type = int * unit

    let name = rename "breakdown2_const_offset"

    let coeff1 = mk_coeff_opt ~num:1 coeff1

    let coeff2 = mk_coeff_opt ~num:2 coeff2

    let coeff3 = mk_coeff_opt ~num:3 coeff3

    let const = mk_const_opt const

    module Def (X : Costlang.S) = struct
      open X

      type model_type = size -> size

      let arity = arity_1

      let model =
        lam ~name:"size" @@ fun size ->
        let_ ~name:"size" (sat_sub size (int offset)) @@ fun size ->
        (free ~name:coeff1 * min (int break1) size)
        + (free ~name:coeff2 * sat_sub (min (int break2) size) (int break1))
        + (free ~name:coeff3 * sat_sub size (int break2))
        + free ~name:const
    end
  end in
  (module M : Model_impl with type arg_type = int * unit)

module type Binary_operation = sig
  module Def (X : Costlang.S) : sig
    val op : X.size X.repr -> X.size X.repr -> X.size X.repr
  end
end

module Synthesize
    (B : Binary_operation)
    (X : Model_impl)
    (Y : Model_impl with type arg_type = X.arg_type) (Names : sig
      val name : Namespace.t

      val x_label : string

      val y_label : string
    end) : Model_impl with type arg_type = X.arg_type = struct
  type arg_type = X.arg_type

  let name = Names.name

  module Def (C : Costlang.S) = struct
    module Args = X.Def (Costlang.Arg_names)
    module BinOp = B.Def (C)
    module X = X.Def (C)
    module Y = Y.Def (C)

    type model_type = X.model_type

    let arity = X.arity

    let rec synthesize :
        type a args_model x_model y_model.
        (Costlang.Arg_names.size, args_model, a) arity ->
        args_model Costlang.Arg_names.repr ->
        (C.size, x_model, a) arity ->
        x_model C.repr ->
        (C.size, y_model, a) arity ->
        y_model C.repr ->
        x_model C.repr =
     fun arg_arity args arity1 term1 arity2 term2 ->
      match arg_arity with
      | Zero_arity ->
          (* These bindings of Zero_arity are necessary for type checking *)
          let Zero_arity = arity1 in
          let Zero_arity = arity2 in
          let open C in
          let_ ~name:Names.x_label term1 @@ fun term1 ->
          let_ ~name:Names.y_label term2 @@ fun term2 -> BinOp.op term1 term2
      | Succ_arity arg_arity ->
          let (Succ_arity arity1) = arity1 in
          let (Succ_arity arity2) = arity2 in
          let open C in
          lam ~name:(Costlang.Arg_names.arg_name args) @@ fun arg ->
          synthesize
            arg_arity
            (Costlang.Arg_names.unwrap_size args)
            arity1
            (app term1 arg)
            arity2
            (app term2 arg)

    let model = synthesize Args.arity Args.model X.arity X.model Y.arity Y.model
  end
end

let synthesize (type a) ~name ~binop ~x_label ~x_model ~y_label ~y_model =
  let (module B : Binary_operation) = binop in
  let ((module X) : a model) = x_model in
  let ((module Y) : a model) = y_model in
  let module M =
    Synthesize (B) (X) (Y)
      (struct
        let x_label = x_label

        let y_label = y_label

        let name = name
      end)
  in
  ((module M) : a model)
