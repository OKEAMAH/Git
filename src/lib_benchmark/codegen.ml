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

  let extract (f : Parsetree.expression) =
    match f.pexp_desc with
    | Parsetree.Pexp_let (_, bindings, expr) -> Some (bindings, expr)
    | _ -> None

  let call f args =
    let f = WithExceptions.Option.get ~loc:__LOC__ @@ Longident.unflatten f in
    let args = List.map (fun x -> (Asttypes.Nolabel, x)) args in
    Exp.(apply (ident (loc f)) args)

  let string_of_fv fv = Format.asprintf "%a" Free_variable.pp fv
end

type code_repr = {
  expr : Parsetree.expression;
  lifted : Parsetree.expression option;
}

let gen_var, reset_id =
  let id = ref 0 in
  let gen_var () =
    let r = "const_" ^ string_of_int !id in
    incr id ;
    r
  in
  (gen_var, fun () -> id := 0)

module Codegen : Costlang.S with type 'a repr = code_repr = struct
  type 'a repr = code_repr

  type size = int

  open Codegen_helpers
  open Ast_helper

  let mk expr = {expr; lifted = None}

  let lift t = (t.expr, t.lifted)

  let merge (a : Parsetree.expression) (b : Parsetree.expression) =
    let open Option_syntax in
    let* a, _ = extract a in
    let* b, _ = extract b in
    Option.some @@ Exp.let_ Nonrecursive (a @ b) (ident "shouldn't appear")

  let mk_lifted expr =
    let name = gen_var () in
    let var = pvar name in
    let expr =
      Exp.let_ Nonrecursive [Vb.mk var expr] (ident "shouldn't appear")
    in
    {expr = ident name; lifted = Some expr}

  type on_zero = Remove | Zero | Nothing

  let mk_call ?(on_zero = Nothing) f args =
    let rec go ?acc x =
      let open Option_syntax in
      match x with
      | [] -> acc
      | x :: rest -> (
          match acc with
          | None -> go ~acc:x rest
          | Some acc ->
              let* res = merge acc x in
              go ~acc:res rest)
    in
    let args, lifted = List.map (fun x -> lift x) args |> List.split in
    let is_all_idents =
      List.for_all
        (fun (x : Parsetree.expression) ->
          match x.pexp_desc with Parsetree.Pexp_ident _ -> true | _ -> false)
        args
    in
    if
      is_all_idents
      && List.for_all
           (fun (x : Parsetree.expression) ->
             match x.pexp_desc with
             | Parsetree.Pexp_ident {txt = Lident id; _} ->
                 let res =
                   List.find_map
                     (fun (x : Parsetree.expression) ->
                       let open Option_syntax in
                       let* bindings, _ = extract x in
                       if
                         List.exists
                           (fun (x : Parsetree.value_binding) ->
                             x.pvb_pat = pvar id)
                           bindings
                       then Some true
                       else None)
                     (List.concat_map Option.to_list lifted)
                 in
                 Option.value res ~default:false
             | _ -> false)
           args
    then
      let lifted =
        List.filter_map
          (fun (x : Parsetree.expression) ->
            let open Option_syntax in
            let* expr, _ = extract x in
            let* head = List.hd expr in
            Some head.pvb_expr)
          (List.concat_map Option.to_list lifted)
      in
      let repr = mk_lifted (call f lifted) in
      repr
    else
      let new_args =
        List.filter_map
          (fun (x : Parsetree.expression) ->
            match x.pexp_desc with
            | Parsetree.Pexp_constant (Pconst_integer ("0", _)) -> None
            | _ -> Some x)
          args
      in
      let not_var (f : Parsetree.expression) =
        match f.pexp_desc with Parsetree.Pexp_ident _ -> false | _ -> true
      in
      let result =
        match (on_zero, new_args) with
        | Remove, x :: [] when not_var x -> mk @@ x
        | Zero, x :: [] when not_var x -> mk @@ Exp.constant (Const.int 0)
        | Remove, _ | Zero, _ | Nothing, _ -> mk (call f args)
      in
      {
        result with
        lifted =
          go
            (List.concat_map
               (fun x -> Option.to_list x)
               (lifted @ [result.lifted]));
      }

  let true_ = mk @@ Exp.construct (loc_ident "true") None

  let false_ = mk @@ Exp.construct (loc_ident "false") None

  let int i =
    if i = 0 then mk @@ Exp.constant (Const.int 0)
    else mk_lifted @@ call (saturated "safe_int") [Exp.constant (Const.int i)]

  let float f =
    if f = 0. then mk @@ Exp.constant (Const.int (int_of_float f))
    else
      mk_lifted
      @@ call
           (saturated "safe_int")
           [
             call
               ["int_of_float"]
               [Exp.constant @@ Const.float (string_of_float f)];
           ]

  let ( + ) x y = mk_call ~on_zero:Remove ["+"] @@ [x; y]

  let sat_sub x y = mk_call ~on_zero:Remove (saturated "sub") [x; y]

  let ( * ) x y = mk_call ~on_zero:Zero ["*"] [x; y]

  let ( / ) x y = mk_call ~on_zero:Zero ["/"] [x; y]

  let max x y = mk_call ~on_zero:Remove (saturated "max") [x; y]

  let min x y = mk_call ~on_zero:Remove (saturated "min") [x; y]

  let log2 x = mk_call ~on_zero:Remove ["log2"] [x]

  let sqrt x = mk_call ~on_zero:Remove ["sqrt"] [x]

  let free ~name = mk @@ Exp.ident (loc_ident (string_of_fv name))

  let lt x y = mk_call ["<"] [x; y]

  let eq x y = mk_call ["="] [x; y]

  let shift_left i bits =
    mk @@ call ["lsl"] [i.expr; Exp.constant (Const.int bits)]

  let shift_right i bits =
    mk @@ call ["lsr"] [i.expr; Exp.constant (Const.int bits)]

  let lam ~name f =
    let patt = pvar name in
    let var = ident name in
    let f, lifted = lift (f (mk @@ var)) in
    {(mk @@ Exp.fun_ Nolabel None patt f) with lifted}

  let app x y =
    let rec go ?acc x =
      let open Option_syntax in
      match x with
      | [] -> acc
      | x :: rest -> (
          match acc with
          | None -> go ~acc:x rest
          | Some acc ->
              let* res = merge acc x in
              go ~acc:res rest)
    in
    let x, lifted = lift x in
    let y, lifted2 = lift y in
    {
      (mk @@ Exp.apply x [(Nolabel, y)]) with
      lifted = go (List.concat_map Option.to_list [lifted; lifted2]);
    }

  let let_ ~name m f =
    let id = ident name in
    let var = pvar name in
    let f, lifted = lift (f (mk @@ id)) in
    let m, lifted2 = lift m in
    let bindings = ref String.Set.empty in
    let mapper =
      let open Ast_mapper in
      {
        default_mapper with
        expr =
          (fun mapper expr ->
            match expr with
            | {pexp_desc = Parsetree.Pexp_let (_, [binding], e); _} ->
                let expr' = binding.pvb_expr in
                if m = expr' then
                  let () =
                    match binding.pvb_pat.ppat_desc with
                    | Parsetree.Ppat_var x ->
                        bindings := String.Set.add x.txt !bindings
                    | _ -> ()
                  in
                  mapper.expr mapper e
                else default_mapper.expr mapper expr
            | {
             pexp_desc = Parsetree.Pexp_ident {txt = Longident.Lident x; _};
             _;
            } ->
                if String.Set.mem x !bindings then id
                else default_mapper.expr mapper expr
            | other -> default_mapper.expr mapper other);
      }
    in
    let f = mapper.expr mapper f in
    let is_rebind, remap =
      match m.pexp_desc with
      | Parsetree.Pexp_ident {txt = Longident.Lident _; _} ->
          bindings := String.Set.singleton name ;
          let mapper =
            let open Ast_mapper in
            {
              default_mapper with
              expr =
                (fun mapper expr ->
                  match expr with
                  | {
                   pexp_desc =
                     Parsetree.Pexp_ident {txt = Longident.Lident x; _};
                   _;
                  } ->
                      if String.Set.mem x !bindings then m else expr
                  | other -> default_mapper.expr mapper other);
            }
          in
          (true, mapper.expr mapper)
      | _ -> (false, Fun.id)
    in
    let result =
      if is_rebind then remap f else Exp.let_ Nonrecursive [Vb.mk var m] f
    in
    let rec go ?acc x =
      let open Option_syntax in
      match x with
      | [] -> acc
      | x :: rest -> (
          match acc with
          | None -> go ~acc:x rest
          | Some acc ->
              let* res = merge acc x in
              go ~acc:res rest)
    in
    {
      (mk @@ result) with
      lifted = go (List.concat_map Option.to_list [lifted; lifted2]);
    }

  let if_ cond ift iff = mk @@ Exp.ifthenelse cond.expr ift.expr (Some iff.expr)
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

(* let name size1 size2 ... =
     let open S.Syntax in
     let size1 = S.safe_int size1 in
     let size2 = S.safe_int size2 in
     ...
     expr
*)
let generate_let_binding =
  let open Ast_helper in
  let open Codegen_helpers in
  let let_open_in x expr = Exp.open_ (Opn.mk (Mod.ident (loc_ident x))) expr in
  fun name expr' ->
    let args, expr = detach_funcs expr'.expr in
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
    let expr'' = expr'.lifted in
    let expr = restore_funcs ~used_vars (args, expr) in
    let rest =
      match expr'' with
      | None -> expr
      | Some x -> (
          match extract x with
          | Some (bindings, _) -> Exp.let_ Nonrecursive bindings expr
          | _ -> expr)
    in
    Str.value
      Asttypes.Nonrecursive
      [Vb.mk (pvar name) (let_open_in "S.Syntax" rest)]

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

let load_solution (fn : string) : solution =
  In_channel.with_open_bin fn Marshal.from_channel

let save_solution (s : solution) (fn : string) =
  Out_channel.with_open_bin fn @@ fun outfile -> Marshal.to_channel outfile s []

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
  [
    this_file_was_autogenerated;
    suppress_unused_open_warning;
    rename_saturation_repr;
  ]
  @ structure_items

let comment ss = Comment ss

let function_name model_name = "cost_" ^ Namespace.basename model_name

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
  Item {comments; code = generate_let_binding fun_name expr}

let codegen_models models sol transform ~exclusions =
  List.filter_map
    (fun (model_name, {Registration.model; from}) ->
      (* Exclusion is done by the function name *)
      let benchmarks =
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
          from
      in
      if
        String.Set.mem (Namespace.to_string model_name) exclusions
        || List.is_empty benchmarks
      then None
      else
        let code = codegen model sol transform model_name in
        reset_id () ;
        Some (List.map (fun destination -> (destination, code)) benchmarks))
    models
  |> List.flatten

let%expect_test "basic_printing" =
  let open Codegen in
  let term =
    lam ~name:"x" @@ fun x ->
    lam ~name:"y" @@ fun y ->
    let_ ~name:"tmp1" (int 42) @@ fun tmp1 ->
    let_ ~name:"tmp2" (int 43) @@ fun tmp2 -> x + y + tmp1 + tmp2
  in
  let item = generate_let_binding "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let open S.Syntax in
        let x = S.safe_int x in
        let y = S.safe_int y in
        let tmp1 = S.safe_int 42 in
        let tmp2 = S.safe_int 43 in ((x + y) + tmp1) + tmp2 |}]

let%expect_test "anonymous_int_literals" =
  let open Codegen in
  let term =
    lam ~name:"x" @@ fun x ->
    lam ~name:"y" @@ fun y -> x + y + int 42 + int 43
  in
  let item = generate_let_binding "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let open S.Syntax in
        let x = S.safe_int x in
        let y = S.safe_int y in ((x + y) + (S.safe_int 42)) + (S.safe_int 43) |}]

let%expect_test "let_bound_lambda" =
  let open Codegen in
  let term =
    lam ~name:"x" @@ fun x ->
    lam ~name:"y" @@ fun y ->
    let_ ~name:"incr" (lam ~name:"x" (fun x -> x + int 1)) @@ fun incr ->
    app incr x + app incr y
  in
  let item = generate_let_binding "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let open S.Syntax in
        let x = S.safe_int x in
        let y = S.safe_int y in
        let incr x = x + (S.safe_int 1) in (incr x) + (incr y) |}]

let%expect_test "ill_typed_higher_order" =
  let open Codegen in
  let term =
    lam ~name:"incr" @@ fun incr ->
    lam ~name:"x" @@ fun x ->
    lam ~name:"y" @@ fun y -> app incr x + app incr y
  in
  let item = generate_let_binding "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name incr x y =
      let open S.Syntax in
        let incr = S.safe_int incr in
        let x = S.safe_int x in let y = S.safe_int y in (incr x) + (incr y) |}]

let%expect_test "if_conditional_operator" =
  let open Codegen in
  let term =
    lam ~name:"x" @@ fun x ->
    lam ~name:"y" @@ fun y -> if_ (lt x y) y x
  in
  let item = generate_let_binding "name" term in
  Format.printf "%a" Pprintast.structure_item item ;
  [%expect
    {|
    let name x y =
      let open S.Syntax in
        let x = S.safe_int x in let y = S.safe_int y in if x < y then y else x |}]

let%expect_test "module_generation" =
  let open Codegen in
  let term = lam ~name:"x" @@ fun x -> x in
  let module_ =
    make_toplevel_module
      [
        Item
          {comments = ["comment"]; code = generate_let_binding "func_name" term};
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

    (* comment *)
    let func_name x = let open S.Syntax in let x = S.safe_int x in x |}]

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
