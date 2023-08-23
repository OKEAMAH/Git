(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs. <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022, 2023 DaiLambda, Incs. <contact@dailambad.jp>          *)
(* Copyright (c) 2023  Marigold <contact@marigold.dev>                       *)
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

(* ------------------------------------------------------------------------- *)
(* OCaml codegen *)

(* Handling codegen errors. *)
type codegen_error = Variable_not_found of Free_variable.t

exception Codegen_error of codegen_error

let pp_codegen_error fmtr = function
  | Variable_not_found s ->
      Format.fprintf fmtr "Codegen: Variable not found: %a" Free_variable.pp s

let () =
  Printexc.register_printer (fun exn ->
      match exn with
      | Codegen_error err ->
          let s = Format.asprintf "%a" pp_codegen_error err in
          Some s
      | _ -> None)

module Codegen_helpers = struct
  open Ast_helper

  let loc txt = {Asttypes.txt; loc = Location.none}

  let loc_ident x = {Asttypes.txt = Longident.Lident x; loc = Location.none}

  let loc_str (x : string) = {Asttypes.txt = x; loc = Location.none}

  let ident x = Exp.ident (loc_ident x)

  let pvar x = Pat.var (loc_str x)

  let saturated name = ["S"; name]

  let call f args =
    let f = WithExceptions.Option.get ~loc:__LOC__ @@ Longident.unflatten f in
    let args = List.map (fun x -> (Asttypes.Nolabel, x)) args in
    Exp.(apply (ident (loc f)) args)

  let string_of_fv fv = Format.asprintf "%a" Free_variable.pp fv
end

module Codegen : Costlang.S with type 'a repr = Parsetree.expression = struct
  type 'a repr = Parsetree.expression

  type size = int

  let size_ty = Costlang.Ty.int

  open Codegen_helpers
  open Ast_helper

  let true_ = Exp.construct (loc_ident "true") None

  let false_ = Exp.construct (loc_ident "false") None

  let int i = call (saturated "safe_int") [Exp.constant (Const.int i)]

  let float f =
    call
      (saturated "safe_int")
      [call ["int_of_float"] [Exp.constant @@ Const.float (string_of_float f)]]

  let ( + ) x y = call ["+"] [x; y]

  let sat_sub x y = call (saturated "sub") [x; y]

  let ( * ) x y = call ["*"] [x; y]

  let ( / ) x y = call ["/"] [x; y]

  let max x y = call (saturated "max") [x; y]

  let min x y = call (saturated "min") [x; y]

  let log2 x = call ["log2"] [x]

  let sqrt x = call ["sqrt"] [x]

  let free ~name = Exp.ident (loc_ident (string_of_fv name))

  let lt x y = call ["<"] [x; y]

  let eq x y = call ["="] [x; y]

  let shift_left i bits = call ["lsl"] [i; Exp.constant (Const.int bits)]

  let shift_right i bits = call ["lsr"] [i; Exp.constant (Const.int bits)]

  let lam ~name _ty f =
    let patt = pvar name in
    let var = ident name in
    Exp.fun_ Nolabel None patt (f var)

  let app x y = Exp.apply x [(Nolabel, y)]

  let let_ ~name m f =
    let id = ident name in
    let var = pvar name in
    Exp.let_ Nonrecursive [Vb.mk var m] (f id)

  let if_ cond ift iff = Exp.ifthenelse cond ift (Some iff)
end

let detach_funcs =
  let open Parsetree in
  let rec aux acc expr =
    match expr with
    | {
     pexp_desc = Pexp_fun (_, _, {ppat_desc = Ppat_var {txt = arg; _}; _}, expr');
     _;
    } ->
        aux (arg :: acc) expr'
    | _ -> (acc, expr)
  in
  aux []

let rec restore_funcs ~used_vars (acc, expr) =
  let open Ast_helper in
  match acc with
  | arg :: acc ->
      let arg =
        if List.mem ~equal:String.equal arg used_vars then arg else "_" ^ arg
      in
      let expr = Exp.fun_ Nolabel None (Codegen_helpers.pvar arg) expr in
      restore_funcs ~used_vars (acc, expr)
  | [] -> expr

let open_m =
  let open Ast_helper in
  let open Codegen_helpers in
  Str.open_ (Opn.mk (Mod.ident (loc_ident "S.Syntax")))

(* [let name size1 size2 ... =
      let open S.Syntax in
      let size1 = S.safe_int size1 in
      let size2 = S.safe_int size2 in
      ...
      expr
   ]

   If [takes_saturation_reprs=true], skips [let sizeN = S.safe_int sizeN in]
*)
let generate_let_binding =
  let open Ast_helper in
  let open Codegen_helpers in
  fun ~takes_saturation_reprs name expr ->
    let args, expr = detach_funcs expr in
    let used_vars =
      let vs = ref [] in
      let super = Ast_iterator.default_iterator in
      let f_expr (i : Ast_iterator.iterator) e =
        match e.Parsetree.pexp_desc with
        | Pexp_ident {txt = Longident.Lident v; _} -> vs := v :: !vs
        | _ -> super.expr i e
      in
      let i = {super with expr = f_expr} in
      i.expr i expr ;
      !vs
    in
    let expr =
      if takes_saturation_reprs then expr
      else
        List.fold_left
          (fun e arg ->
            if List.mem ~equal:String.equal arg used_vars then
              let var = ident arg in
              let patt = pvar arg in
              Exp.let_
                Nonrecursive
                [Vb.mk patt (call (saturated "safe_int") [var])]
                e
            else e)
          expr
          args
    in
    let expr = restore_funcs ~used_vars (args, expr) in
    Str.value Asttypes.Nonrecursive [Vb.mk (pvar name) expr]

(* ------------------------------------------------------------------------- *)

(* Precompose pretty-printing by let-lifting *)
module Lift_then_print = Costlang.Let_lift (Codegen)

(* ------------------------------------------------------------------------- *)
type solution = {
  (* The data required to perform code generation is a map from variables to
     (floating point) coefficients. *)
  map : float Free_variable.Map.t;
  (* The scores of the models with the estimated coefficients. *)
  scores_list : ((string * Namespace.t) * Inference.scores) list;
}

let solution_encoding =
  let open Data_encoding in
  conv
    (fun {map; scores_list} -> (map, scores_list))
    (fun (map, scores_list) -> {map; scores_list})
  @@ obj2
       (req "map" (Free_variable.Map.encoding float))
       (req
          "scores_list"
          (list
             (tup2 (tup2 string Namespace.encoding) Inference.scores_encoding)))

let pp_solution ppf solution =
  let open Format in
  let alist =
    List.sort (fun (fv1, _) (fv2, _) -> Free_variable.compare fv1 fv2)
    @@ List.of_seq
    @@ Free_variable.Map.to_seq solution.map
  in
  fprintf ppf "@[" ;
  fprintf
    ppf
    "@[<2>free_variables:@ @[<v>%a@]@]@;"
    (pp_print_list (fun ppf (fv, float) ->
         fprintf ppf "%a = %.12g" Free_variable.pp fv float))
    alist ;
  fprintf
    ppf
    "@[<2>scores:@ @[<v>%a@]@]"
    (pp_print_list (fun ppf ((_s, ns), scores) ->
         fprintf ppf "%a : %a" Namespace.pp ns Inference.pp_scores scores))
    (List.sort (fun (k1, _) (k2, _) -> compare k1 k2) solution.scores_list) ;
  fprintf ppf "@]"

let load_solution_in_binary (fn : string) : solution =
  In_channel.with_open_bin fn Marshal.from_channel

let save_solution_in_binary (s : solution) (fn : string) =
  Out_channel.with_open_bin fn @@ fun outfile -> Marshal.to_channel outfile s []

let solution_to_csv {map; scores_list} =
  let csv_mapping =
    Inference.mapping_to_csv (map |> Free_variable.Map.to_seq |> List.of_seq)
  in
  let csv_scores_list =
    List.fold_left
      (fun csv (name, score) ->
        Csv.concat csv (Inference.scores_to_csv_column name score))
      [[]; []]
      scores_list
  in
  Csv.concat csv_mapping csv_scores_list

let load_solution_in_json (fn : string) : solution =
  In_channel.with_open_text fn @@ fun ic ->
  let s = In_channel.input_all ic in
  let open Data_encoding.Json in
  Result.fold
    ~error:Stdlib.failwith
    ~ok:(destruct solution_encoding)
    (from_string s)

let save_solution_in_json (s : solution) (fn : string) =
  let open Data_encoding.Json in
  let json = construct solution_encoding s in
  Out_channel.with_open_text fn @@ fun oc ->
  (* We cannot use [Data_encoding.Json.to_string] since it prints out
     floats in less precision *)
  let json : Ezjsonm.t =
    match json with `O kvs -> `O kvs | _ -> assert false
  in
  Ezjsonm.(to_channel ~minify:false oc json)

let load_solution (fn : string) : solution =
  try load_solution_in_json fn with _ -> load_solution_in_binary fn

let save_solution s fn =
  save_solution_in_binary s fn ;
  save_solution_in_json s (fn ^ ".json")

let load_exclusions exclude_fn =
  (* one model name like N_IXxx_yyy__alpha per line *)
  let open In_channel in
  with_open_text exclude_fn (fun ic ->
      let rec loop acc =
        match input_line ic with
        | None -> acc
        | Some l -> loop (String.Set.add l acc)
      in
      loop String.Set.empty)

(* ------------------------------------------------------------------------- *)

(* [Parsetree.structure_item] has no construction for comment *)
type code =
  | Comment of string list (* comment not attached to a binding *)
  | Item of {comments : string list; code : Parsetree.structure_item}

type module_ = code list

let pp_code fmtr =
  let open Format in
  function
  | Comment lines ->
      fprintf
        fmtr
        "(* @[<v>%a@] *)"
        (pp_print_list
           ~pp_sep:(fun fmtr () -> fprintf fmtr "@;")
           pp_print_string)
        lines
  | Item {comments; code} ->
      List.iter (fprintf fmtr "(* %s *)@;") comments ;
      Pprintast.structure_item fmtr code

let pp_module fmtr items =
  let open Format in
  fprintf fmtr "@[<hv 0>" ;
  pp_print_list ~pp_sep:(fun fmtr () -> fprintf fmtr "@;@;") pp_code fmtr items ;
  fprintf fmtr "@]@;"

let pp_module fmtr items =
  let s = Format.asprintf "%a" pp_module items in
  let s =
    match Ocamlformat.impl s with
    | Ok s -> s
    | Error e ->
        Format.eprintf "ocamlformat failed: %s@." (Printexc.to_string e) ;
        s
  in
  Format.pp_print_string fmtr s

let make_toplevel_module structure_items =
  let open Ast_helper in
  let open Codegen_helpers in
  let this_file_was_autogenerated =
    Comment
      [
        "Do not edit this file manually.";
        "This file was automatically generated from benchmark models";
        "If you wish to update a function in this file,";
        "a. update the corresponding model, or";
        "b. move the function to another module and edit it there.";
      ]
  in
  let suppress_unused_open_warning =
    Item
      {
        comments = [];
        code =
          Str.attribute
            (Attr.mk
               (loc_str "warning")
               (PStr [Str.eval (Exp.constant (Const.string "-33"))]));
      }
  in
  let rename_saturation_repr =
    Item
      {
        comments = [];
        code =
          Str.module_
            (Mb.mk (loc (Some "S")) (Mod.ident (loc_ident "Saturation_repr")));
      }
  in
  let open_syntax = Item {comments = []; code = open_m} in
  [
    this_file_was_autogenerated;
    suppress_unused_open_warning;
    rename_saturation_repr;
    open_syntax;
  ]
  @ structure_items

let comment ss = Comment ss

let function_name model_name =
  "cost_"
  ^ String.map (function '.' -> '_' | c -> c) (Namespace.basename model_name)

let codegen (Model.Model model) (sol : solution)
    (transform : Costlang.transform) model_name =
  let subst fv =
    match Free_variable.Map.find fv sol.map with
    | None -> raise (Codegen_error (Variable_not_found fv))
    | Some f -> f
  in
  let module T = (val transform) in
  let module Impl = T (Lift_then_print) in
  let module Subst_impl =
    Costlang.Subst
      (struct
        let subst = subst
      end)
      (Impl)
  in
  let module M = (val model) in
  let takes_saturation_reprs = M.takes_saturation_reprs in
  let comments =
    let module Sub =
      Costlang.Subst
        (struct
          let subst = subst
        end)
        (Costlang.Pp)
    in
    let module M = M.Def (Sub) in
    let expr = Sub.prj M.model in
    ["model " ^ Namespace.to_string model_name; expr]
  in
  let module M = M.Def (Subst_impl) in
  let expr = Lift_then_print.prj @@ Impl.prj @@ Subst_impl.prj M.model in
  let fun_name = function_name model_name in
  Item
    {
      comments;
      code = generate_let_binding ~takes_saturation_reprs fun_name expr;
    }

let get_codegen_destinations
    Registration.{model = Model.Model (module M); from = local_models_info} =
  if Namespace.equal M.name @@ Builtin_models.ns "timer_model" then []
  else
    List.filter_map
      (fun Registration.{bench_name; _} ->
        let open Option_syntax in
        let* (module B : Benchmark.S) =
          Registration.find_benchmark bench_name
        in
        let destination =
          match B.purpose with Generate_code d -> Some d | _ -> None
        in
        destination)
      local_models_info
    |> List.sort_uniq String.compare

let codegen_models models sol transform ~exclusions =
  let generate_with_exclusions model_name info =
    let benchmark_destinations = get_codegen_destinations info in
    if
      String.Set.mem (Namespace.to_string model_name) exclusions
      || List.is_empty benchmark_destinations
    then []
    else
      let code = codegen info.model sol transform model_name in
      List.map (fun destination -> (destination, code)) benchmark_destinations
  in
  if String.Set.is_empty exclusions then
    List.map
      (fun (model_name, info) ->
        ("auto_build", codegen info.Registration.model sol transform model_name))
      models
  else
    List.concat_map
      (fun (model_name, info) -> generate_with_exclusions model_name info)
      models

let%expect_test "basic_printing" =
  let open Codegen in
  let term =
    lam ~name:"x" size_ty @@ fun x ->
    lam ~name:"y" size_ty @@ fun y ->
    let_ ~name:"tmp1" (int 42) @@ fun tmp1 ->
    let_ ~name:"tmp2" (int 43) @@ fun tmp2 -> x + y + tmp1 + tmp2
  in
  let item = generate_let_binding ~takes_saturation_reprs:false "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let x = S.safe_int x in
      let y = S.safe_int y in
      let tmp1 = S.safe_int 42 in
      let tmp2 = S.safe_int 43 in ((x + y) + tmp1) + tmp2 |}]

let%expect_test "anonymous_int_literals" =
  let open Codegen in
  let term =
    lam ~name:"x" size_ty @@ fun x ->
    lam ~name:"y" size_ty @@ fun y -> x + y + int 42 + int 43
  in
  let item = generate_let_binding ~takes_saturation_reprs:false "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let x = S.safe_int x in
      let y = S.safe_int y in ((x + y) + (S.safe_int 42)) + (S.safe_int 43) |}]

let%expect_test "let_bound_lambda" =
  let open Codegen in
  let term =
    lam ~name:"x" size_ty @@ fun x ->
    lam ~name:"y" size_ty @@ fun y ->
    let_ ~name:"incr" (lam ~name:"x" size_ty (fun x -> x + int 1))
    @@ fun incr -> app incr x + app incr y
  in
  let item = generate_let_binding ~takes_saturation_reprs:false "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let x = S.safe_int x in
      let y = S.safe_int y in
      let incr x = x + (S.safe_int 1) in (incr x) + (incr y) |}]

let%expect_test "ill_typed_higher_order" =
  let open Codegen in
  let term =
    lam ~name:"incr" size_ty @@ fun incr ->
    lam ~name:"x" size_ty @@ fun x ->
    lam ~name:"y" size_ty @@ fun y -> app incr x + app incr y
  in
  let item = generate_let_binding ~takes_saturation_reprs:false "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name incr x y =
      let incr = S.safe_int incr in
      let x = S.safe_int x in let y = S.safe_int y in (incr x) + (incr y) |}]

let%expect_test "if_conditional_operator" =
  let open Codegen in
  let term =
    lam ~name:"x" size_ty @@ fun x ->
    lam ~name:"y" size_ty @@ fun y -> if_ (lt x y) y x
  in
  let item = generate_let_binding ~takes_saturation_reprs:false "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let x = S.safe_int x in let y = S.safe_int y in if x < y then y else x |}]

let%expect_test "module_generation" =
  let open Codegen in
  let term = lam ~name:"x" size_ty @@ fun x -> x in
  let module_ =
    make_toplevel_module
      [
        Item
          {
            comments = ["comment"];
            code =
              generate_let_binding
                ~takes_saturation_reprs:false
                "func_name"
                term;
          };
      ]
  in
  Format.printf "%a" pp_module module_ ;
  [%expect
    {|
    (* Do not edit this file manually.
       This file was automatically generated from benchmark models
       If you wish to update a function in this file,
       a. update the corresponding model, or
       b. move the function to another module and edit it there. *)

    [@@@warning "-33"]

    module S = Saturation_repr
    open S.Syntax

    (* comment *)
    let func_name x =
      let x = S.safe_int x in
      x |}]

(* Same as "basic_printing", but no [S.safe_int] conversions for [x] and [y] *)
let%expect_test "takes_saturation_reprs" =
  let open Codegen in
  let term =
    lam ~name:"x" Costlang.Ty.num @@ fun x ->
    lam ~name:"y" Costlang.Ty.num @@ fun y ->
    let_ ~name:"tmp1" (int 42) @@ fun tmp1 ->
    let_ ~name:"tmp2" (int 43) @@ fun tmp2 -> x + y + tmp1 + tmp2
  in
  let item = generate_let_binding ~takes_saturation_reprs:true "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let tmp1 = S.safe_int 42 in
      let tmp2 = S.safe_int 43 in ((x + y) + tmp1) + tmp2 |}]

(* Module to get the name of cost functions manually/automatically defined
   in a source file *)
module Parser = struct
  let with_ic fn f =
    let ic = open_in fn in
    Fun.protect (fun () -> f ic) ~finally:(fun () -> close_in ic)

  let parse ic =
    let lexbuf = Lexing.from_channel ic in
    Lexer.init () ;
    Parser.implementation Lexer.token lexbuf

  let get_pattern_vars pattern =
    let open Parsetree in
    let vars = ref [] in
    let super = Ast_iterator.default_iterator in
    let pat self p =
      (match p.ppat_desc with
      | Ppat_var {txt; _} | Ppat_alias (_, {txt; _}) -> vars := txt :: !vars
      | _ -> ()) ;
      super.pat self p
    in
    let self = {super with pat} in
    self.pat self pattern ;
    !vars

  let scrape_defined_vars str =
    let open Parsetree in
    let defs = ref [] in
    let super = Ast_iterator.default_iterator in
    let value_binding _self vb =
      defs := get_pattern_vars vb.Parsetree.pvb_pat @ !defs ;
      (* Skip traversals to ignore the internal defs *)
      ()
    in
    let structure_item self si =
      match si.pstr_desc with
      | Pstr_value _ | Pstr_module _ -> super.structure_item self si
      | _ -> ()
    in
    let self = {super with value_binding; structure_item} in
    self.structure self str ;
    !defs

  let is_cost_function n =
    let prefix = "cost_" in
    TzString.has_prefix ~prefix n

  let get_cost_functions fn =
    try
      with_ic fn @@ fun ic ->
      Ok (List.filter is_cost_function @@ scrape_defined_vars @@ parse ic)
    with exn -> Error exn
end
