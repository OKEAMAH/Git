(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 DaiLambda, Inc. <contact@dailambda.jp>                 *)
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

open Costlang

module type S = sig
  type size

  type unop = Log2 | Sqrt

  (* binops of [size -> size -> size] *)
  type binop_size = Add | Sat_sub | Mul | Div | Max | Min

  (* binops of [size -> size -> bool] *)
  type binop_bool = Eq | Lt

  type _ t =
    | Size : Num.t -> size t
    | Bool : bool -> bool t
    | Unop : unop * size t -> size t
    | Binop_size : binop_size * size t * size t -> size t
    | Binop_bool : binop_bool * size t * size t -> bool t
    | Shift : [`Left | `Right] * size t * int -> size t
    | Free : Free_variable.t -> size t
    | Lam : string * 'a Ty.t * 'b t -> ('a -> 'b) t
    | App : ('a -> 'b) t * 'a t -> 'b t
    | Let : string * 'a t * 'b t -> 'b t
    | If : bool t * 'a t * 'a t -> 'a t
    | Variable : string * 'a Ty.t -> 'a t

  val type_of : 'a t -> 'a Ty.t

  val pp : Format.formatter -> _ t -> unit

  (** To OCaml parsetree *)
  val to_expression : _ t -> Parsetree.expression

  (* Charge at least 10 milli-gas. For example,
     [fun size1 size2 -> size1 + size2]
     => [fun size1 size2 -> max 10 (size1 + size2)]
  *)
  val at_least_10 : 'a t -> 'a t

  (* [let x = e1 in e2] => [e2[e1/x]] *)
  val subst_let : 'a t -> 'a t

  val optimize_affine : 'a t -> 'a t

  val cse : 'a t -> 'a t
end

(* Need to parameterize the size if we want to make a transformer *)
module Make (A : sig
  type size

  val size_ty : size Ty.t
end) =
struct
  type size = A.size

  type unop = Log2 | Sqrt

  (* binops of [size -> size -> size] *)
  type binop_size = Add | Sat_sub | Mul | Div | Max | Min

  (* binops of [size -> size -> bool] *)
  type binop_bool = Eq | Lt

  type _ t =
    | Size : Num.t -> size t
    | Bool : bool -> bool t
    | Unop : unop * size t -> size t
    | Binop_size : binop_size * size t * size t -> size t
    | Binop_bool : binop_bool * size t * size t -> bool t
    | Shift : [`Left | `Right] * size t * int -> size t
    | Free : Free_variable.t -> size t
    | Lam : string * 'a Ty.t * 'b t -> ('a -> 'b) t
    | App : ('a -> 'b) t * 'a t -> 'b t
    | Let : string * 'a t * 'b t -> 'b t
    | If : bool t * 'a t * 'a t -> 'a t
    | Variable : string * 'a Ty.t -> 'a t

  let rec type_of : type a. a t -> a Ty.t = function
    | Size _ -> A.size_ty
    | Bool _ -> Ty.Bool
    | Unop _ -> A.size_ty
    | Shift _ -> A.size_ty
    | Binop_size _ -> A.size_ty
    | Binop_bool _ -> Ty.Bool
    | Free _ -> A.size_ty
    | Lam (_name, ty, b) -> Ty.Arrow (ty, type_of b)
    | Let (_v, _m, t) -> type_of t
    | App (f, _t) -> ( match type_of f with Ty.Arrow (_tf, tr) -> tr)
    | Variable (_, ty) -> ty
    | If (_, t, _) -> type_of t

  (* Roughly, how much computations are needed to evaluate *)
  let rec num_of_ops : type a. a t -> int = function
    | Size _ -> 0
    | Bool _ -> 0
    | Unop (_, t) -> num_of_ops t + 1
    | Binop_size (_, t1, t2) -> num_of_ops t1 + num_of_ops t2 + 1
    | Binop_bool (_, t1, t2) -> num_of_ops t1 + num_of_ops t2 + 1
    | Shift (_, t, _) -> num_of_ops t + 1
    | Free _ -> 0
    | Lam (_, _, t) -> num_of_ops t + 1
    | App (f, t) -> num_of_ops f + num_of_ops t + 1
    | Let (_, m, n) -> num_of_ops m + num_of_ops n + 1
    | If (b, t, e) -> num_of_ops b + max (num_of_ops t) (num_of_ops e) + 1
    | Variable _ -> 0

  let _ = num_of_ops

  module Parsetree = struct
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

    let rec to_expression : type a. a t -> Parsetree.expression = function
      | Bool true -> Exp.construct (loc_ident "true") None
      | Bool false -> Exp.construct (loc_ident "false") None
      | Size (Int i) -> call (saturated "safe_int") [Exp.constant (Const.int i)]
      | Size (Float f) ->
          call
            (saturated "safe_int")
            [
              call
                ["int_of_float"]
                [Exp.constant @@ Const.float (string_of_float f)];
            ]
      | Binop_size (Add, t1, t2) ->
          call ["+"] [to_expression t1; to_expression t2]
      | Binop_size (Sat_sub, t1, t2) ->
          call (saturated "sub") [to_expression t1; to_expression t2]
      | Binop_size (Mul, t1, t2) ->
          call ["*"] [to_expression t1; to_expression t2]
      | Binop_size (Div, t1, t2) ->
          call ["/"] [to_expression t1; to_expression t2]
      | Binop_size (Max, t1, t2) ->
          call (saturated "max") [to_expression t1; to_expression t2]
      | Binop_size (Min, t1, t2) ->
          call (saturated "min") [to_expression t1; to_expression t2]
      | Unop (Log2, t) -> call ["log2"] [to_expression t]
      | Unop (Sqrt, t) -> call ["sqrt"] [to_expression t]
      | Free name -> Exp.ident (loc_ident (string_of_fv name))
      | Binop_bool (Lt, t1, t2) ->
          call ["<"] [to_expression t1; to_expression t2]
      | Binop_bool (Eq, t1, t2) ->
          call ["="] [to_expression t1; to_expression t2]
      | Shift (`Left, t, bits) ->
          call ["lsl"] [to_expression t; Exp.constant (Const.int bits)]
      | Shift (`Right, t, bits) ->
          call ["lsr"] [to_expression t; Exp.constant (Const.int bits)]
      | Lam (name, _ty, b) ->
          let patt = pvar name in
          Exp.fun_ Nolabel None patt (to_expression b)
      | App (f, t) -> Exp.apply (to_expression f) [(Nolabel, to_expression t)]
      | Let (name, m, b) ->
          let var = pvar name in
          let m = to_expression m in
          let b = to_expression b in
          Exp.let_ Nonrecursive [Vb.mk var m] b
      | If (c, t, f) ->
          Exp.ifthenelse
            (to_expression c)
            (to_expression t)
            (Some (to_expression f))
      | Variable (name, _ty) -> ident name
  end

  let to_expression = Parsetree.to_expression

  let pp ppf t = Pprintast.expression ppf @@ Parsetree.to_expression t

  (* Existential *)

  type packed = Packed : 'a Ty.t * 'a t -> packed

  let pack t = Packed (type_of t, t)

  let unpack : type a. a Ty.t -> packed -> a t option =
   fun ty (Packed (ty', t)) ->
    match Ty.equal ty ty' with None -> None | Some Refl -> Some t

  (* Dig into lambdas and apply [f] to the first expression of type [Ty.Size] *)
  let apply_to_size =
    let rec g : type a. (size t -> size t) -> a t -> a t =
     fun f t ->
      match t with
      | Lam (name, ty, t) -> Lam (name, ty, g f t)
      | Free _ -> f t
      | Unop _ -> f t
      | Shift _ -> f t
      | Size _ -> f t
      | Binop_size _ -> f t
      | If (_, _, _) | Let (_, _, _) | App _ | Variable _ -> (
          match Ty.equal (type_of t) A.size_ty with
          | None -> t
          | Some Refl -> f t)
      | Binop_bool _ -> t
      | Bool _ -> t
    in
    g

  let at_least_10 t =
    let rec f = function
      | Let (v, m, t) -> Let (v, m, f t)
      | t -> Binop_size (Max, Size (Int 10), t)
    in
    apply_to_size f t

  let subst_let t =
    let rec f : type a. (string * packed) list -> a t -> a t =
     fun env t ->
      match t with
      | Variable (name, ty) -> (
          match List.assoc ~equal:String.equal name env with
          | None -> t (* The variable may be lambda-bound *)
          | Some entry -> (
              match unpack ty entry with None -> assert false | Some t -> t))
      | Let (name, m, t) ->
          let m = f env m in
          f ((name, pack m) :: env) t
      | Unop (op, t) -> Unop (op, f env t)
      | Binop_size (op, t1, t2) -> Binop_size (op, f env t1, f env t2)
      | Binop_bool (op, t1, t2) -> Binop_bool (op, f env t1, f env t2)
      | Shift (dir, t, n) -> Shift (dir, f env t, n)
      | Lam (name, ty, body) ->
          (* No check of name collisions *)
          Lam (name, ty, f env body)
      | App (t1, t2) -> App (f env t1, f env t2)
      | If (c, t, e) -> If (f env c, f env t, f env e)
      | Size _ | Bool _ | Free _ -> t
    in
    f [] t

  module Affine = struct
    (* [n * expr * expr * .. * expr]
       where [expr] is neither addition nor multiplication.
    *)
    type component = size t option * Num.t

    let pp_component ppf (t, sz) =
      match t with
      | None -> Num.pp ppf sz
      | Some t -> Format.fprintf ppf "%a * %a" pp t Num.pp sz

    (* m * (n * expr * expr * .. * expr) = (m * n) * expr * expr * .. * expr *)
    let mul_component (k, size) = function
      | Num.Int 0 | Float 0.0 -> (k, Num.Int 0)
      | s -> (k, Num.mul size s)

    type t = component list

    let pp ppf comps =
      let open Format in
      pp_print_list
        ~pp_sep:(fun ppf () -> fprintf ppf "@ + ")
        pp_component
        ppf
        comps

    let mul_scalar comps size =
      match size with
      | Num.Int 0 | Float 0.0 -> []
      | _ -> List.map (fun c -> mul_component c size) comps

    let normalize (comps : t) : t =
      let open List in
      let keys = sort_uniq Stdlib.compare @@ map fst comps in
      filter_map
        (fun key ->
          let weight =
            fold_left Num.add (Int 0) @@ map snd
            @@ find_all (fun (key', _) -> key = key') comps
          in
          match weight with Int 0 | Float 0.0 -> None | _ -> Some (key, weight))
        keys

    let repr_of_component : component -> _ = function
      | None, sz -> Size sz
      | Some t, (Int 1 | Float 1.0) -> t
      | Some t, size -> Binop_size (Mul, Size size, t)

    (* x1 op x2 op .. op xn *)
    let rec combine_ts id op = function
      | [] -> id
      | [t] -> t
      | t :: ts -> Binop_size (op, t, combine_ts id op ts)

    let to_repr comps =
      combine_ts (Size (Int 0)) Add
      @@ List.map repr_of_component @@ normalize comps

    let one t = [(Some t, Num.Int 1)]

    (* n * exp * .. * exp =>  n, [exp; ..; exp]
       [exp]s are sorted.
    *)
    let extract_mults t =
      let rec extract_mults t =
        match t with
        | Size sz -> (sz, [])
        | Binop_size (Mul, t1, t2) ->
            let sz1, mults1 = extract_mults t1 in
            let sz2, mults2 = extract_mults t2 in
            (Num.mul sz1 sz2, mults1 @ mults2)
        | _ -> (Int 1, [t])
      in
      let sz, mults = extract_mults t in
      (sz, List.sort Stdlib.compare mults)

    let rec extract_maxes t =
      match t with
      | Binop_size (Max, t1, t2) ->
          let maxes1 = extract_maxes t1 in
          let maxes2 = extract_maxes t2 in
          maxes1 @ maxes2
      | _ -> [t]

    let rec of_repr ast : t =
      match ast with
      | Size (Int i) -> [(None, Int i)]
      | Size (Float f) -> [(None, Float f)]
      | Binop_size (Add, t1, t2) -> of_repr t1 @ of_repr t2
      | Binop_size (Mul, _, _) -> (
          let sz, ts = extract_mults ast in
          match ts with
          | [] -> [(None, sz)]
          | _ -> [(Some (combine_ts (Size (Int 1)) Mul ts), sz)])
      | _ -> one ast

    let compare t1 t2 =
      if
        List.for_all
          (fun (k1, w1) ->
            match List.assoc ~equal:Stdlib.( = ) k1 t2 with
            | None -> false
            | Some w2 -> Num.compare w1 w2 <= 0)
          t1
      then `Lt
      else if
        List.for_all
          (fun (k2, w2) ->
            match List.assoc ~equal:Stdlib.( = ) k2 t1 with
            | None -> false
            | Some w1 -> Num.compare w1 w2 >= 0)
          t2
      then `Gt
      else `Unknown

    let _max t1 t2 =
      let res =
        match compare t1 t2 with
        | `Lt -> t2
        | `Gt -> t1
        | `Unknown -> one @@ Binop_size (Max, to_repr t1, to_repr t2)
      in
      Format.eprintf "max (%a) (%a) => (%a)@." pp t1 pp t2 pp res ;
      res
  end

  let optimize_affine =
    let rec f : type a. a t -> a t =
     fun t ->
      match t with
      | Binop_size (Add, t1, t2) ->
          let t1 = f t1 in
          let t2 = f t2 in
          Affine.(to_repr (normalize (of_repr t1 @ of_repr t2)))
      | Binop_size (Mul, t1, t2) -> (
          let t1 = f t1 in
          let t2 = f t2 in
          let t1comps = Affine.(normalize (of_repr t1)) in
          let t2comps = Affine.(normalize (of_repr t2)) in
          match (t1comps, t2comps) with
          | [(None, s)], comps | comps, [(None, s)] ->
              Affine.(to_repr @@ mul_scalar comps s)
          | _ -> Binop_size (Mul, f t1, f t2))
      | Binop_size (Max, _, _) ->
          let maxes = Affine.extract_maxes t in
          let maxes = List.map f maxes in
          let maxes = List.map Affine.of_repr maxes in
          (* try to simplify *)
          let maxes =
            let rec f acc = function
              | [] -> List.rev acc
              | m :: ms ->
                  if
                    List.exists
                      (fun m' ->
                        match Affine.compare m m' with
                        | `Lt -> true
                        | _ -> false)
                      (acc @ ms)
                  then f acc ms
                  else f (m :: acc) ms
            in
            f [] maxes
          in
          let maxes = List.map Affine.to_repr maxes in
          Affine.combine_ts (Size (Int 0)) Max maxes
      | Variable _ | Size _ | Free _ | Bool _ -> t
      | Lam (v, ty, t) -> Lam (v, ty, f t)
      | Unop (op, t) -> Unop (op, f t)
      | Shift (dir, t, n) -> Shift (dir, f t, n)
      | If (c, t, e) -> If (f c, f t, f e)
      | Let (n, t1, t2) -> Let (n, f t1, f t2)
      | App (t1, t2) -> App (f t1, f t2)
      | Binop_size (Sat_sub, t1, t2) -> Binop_size (Sat_sub, f t1, f t2)
      | Binop_size (Div, t1, t2) -> Binop_size (Div, f t1, f t2)
      | Binop_size (Min, t1, t2) -> Binop_size (Min, f t1, f t2)
      | Binop_bool (op, t1, t2) -> Binop_bool (op, f t1, f t2)
    in
    f

  module PackMap = Map.Make (struct
    type t = packed

    let compare = Stdlib.compare
  end)

  module CSE = struct
    (* Count the sub-term occurrences for CSE *)
    let count t =
      let add : type a. a t -> int PackMap.t -> int PackMap.t =
       fun t map ->
        let k = pack t in
        let n = Option.value ~default:0 @@ PackMap.find k map in
        PackMap.add k (n + 1) map
      in
      let rec f : type a. a t -> int PackMap.t -> int PackMap.t =
       fun t map ->
        match t with
        | Free _ | Variable _ | Size _ | Bool _ -> map
        | Unop (_, t') ->
            let map = f t' map in
            add t map
        | Shift (_, t', _) ->
            let map = f t' map in
            add t map
        | Binop_size (_op, t1, t2) ->
            let map = f t1 map in
            let map = f t2 map in
            add t map
        | Binop_bool (_op, t1, t2) ->
            let map = f t1 map in
            let map = f t2 map in
            add t map
        | If (c, t1, t2) ->
            let map = f c map in
            let map = f t1 map in
            let map = f t2 map in
            add t map
        | Let (_, t1, t2) ->
            let map = f t1 map in
            let map = f t2 map in
            add t map
        | App (t1, t2) ->
            let map = f t1 map in
            let map = f t2 map in
            add t map
        | Lam (_, _, t') ->
            let map = f t' map in
            add t map
      in
      f t PackMap.empty

    let build_replace_map t =
      let count_map = count t in
      let cntr = ref 0 in
      PackMap.filter_map
        (fun _entry -> function
          | 1 -> None
          | _ ->
              incr cntr ;
              let name = Printf.sprintf "w%d" !cntr in
              Some name)
        count_map

    (* Replace sub-terms occur multiple times and returns the replaced variables *)
    let rec replace : type a. a t -> string PackMap.t -> a t * String.Set.t =
     fun t map ->
      let ( ++ ) = String.Set.union in
      match PackMap.find (pack t) map with
      | Some name -> (Variable (name, type_of t), String.Set.singleton name)
      | None -> (
          match t with
          | Free _ | Variable _ | Size _ | Bool _ -> (t, String.Set.empty)
          | Unop (op, t') ->
              let t', s = replace t' map in
              (Unop (op, t'), s)
          | Shift (dir, t', n) ->
              let t', s = replace t' map in
              (Shift (dir, t', n), s)
          | Binop_size (op, t1, t2) ->
              let t1, s1 = replace t1 map in
              let t2, s2 = replace t2 map in
              (Binop_size (op, t1, t2), s1 ++ s2)
          | Binop_bool (op, t1, t2) ->
              let t1, s1 = replace t1 map in
              let t2, s2 = replace t2 map in
              (Binop_bool (op, t1, t2), s1 ++ s2)
          | If (t1, t2, t3) ->
              let t1, s1 = replace t1 map in
              let t2, s2 = replace t2 map in
              let t3, s3 = replace t3 map in
              (If (t1, t2, t3), s1 ++ s2 ++ s3)
          | Let (v, t1, t2) ->
              let t1, s1 = replace t1 map in
              let t2, s2 = replace t2 map in
              (Let (v, t1, t2), s1 ++ s2)
          | App (t1, t2) ->
              let t1, s1 = replace t1 map in
              let t2, s2 = replace t2 map in
              (App (t1, t2), s1 ++ s2)
          | Lam (v, ty, t') ->
              let t', s = replace t' map in
              (Lam (v, ty, t'), s))

    let cse : type a. a t -> a t =
     fun t ->
      let ty = type_of t in
      let replace_map = build_replace_map t in
      let vs =
        PackMap.fold
          (fun key name acc ->
            let (Packed (_ty, t)) = key in
            (* Stop replacing to itself *)
            let replace_map' = PackMap.remove key replace_map in
            let t, s = replace t replace_map' in
            (Some name, (pack t, s)) :: acc)
          replace_map
          [
            (let t, s = replace t replace_map in
             (None, (pack t, s)));
          ]
      in
      let module V = struct
        type t = string option * (packed * String.Set.t)

        let compare (so1, _) (so2, _) = Option.compare String.compare so1 so2

        let hash (so, _) = Hashtbl.hash so

        let equal (so1, _) (so2, _) = Option.equal String.equal so1 so2
      end in
      let module G = struct
        module G = Graph.Persistent.Digraph.Concrete (V)
        include G
        include Graph.Topological.Make (G)
      end in
      let g = List.fold_left G.add_vertex G.empty vs in
      let g =
        List.fold_left
          (fun g ((_so, (_, deps)) as v) ->
            String.Set.fold
              (fun s g ->
                let v' =
                  Stdlib.Option.get @@ List.find (fun (so, _) -> so = Some s) vs
                in
                G.add_edge g v v')
              deps
              g)
          g
          vs
      in
      let vs = List.rev @@ G.fold (fun v acc -> v :: acc) g [] in
      match vs with
      | [] -> assert false
      | (Some _, _) :: _ -> assert false
      | (None, (entry, _)) :: vs -> (
          match unpack ty entry with
          | None -> assert false
          | Some t ->
              List.fold_left
                (fun acc v ->
                  match v with
                  | None, _ -> assert false
                  | Some name, (Packed (_ty, t), _) -> Let (name, t, acc))
                t
                vs)

    let cse t = apply_to_size cse t
  end

  let cse = CSE.cse
end

module Ast = Make (struct
  type size = Num.t

  let size_ty = Ty.num
end)

module To_ast : Costlang.S with type 'a repr = 'a Ast.t and type size = Num.t =
struct
  type size = Num.t

  let size_ty = Ty.num

  type 'a repr = 'a Ast.t

  open Ast

  let false_ = Bool false

  let true_ = Bool true

  let float f = Size (Float f)

  let int i = Size (Int i)

  let ( + ) x y = Binop_size (Add, x, y)

  let ( * ) x y = Binop_size (Mul, x, y)

  let sat_sub x y = Binop_size (Sat_sub, x, y)

  let ( / ) x y = Binop_size (Div, x, y)

  let max x y = Binop_size (Max, x, y)

  let min x y = Binop_size (Min, x, y)

  let shift_left x s = Shift (`Left, x, s)

  let shift_right x s = Shift (`Right, x, s)

  let log2 x = Unop (Log2, x)

  let sqrt x = Unop (Sqrt, x)

  let free ~name = Free name

  let lt x y = Binop_bool (Lt, x, y)

  let eq x y = Binop_bool (Eq, x, y)

  let lam ~name ty (f : 'a repr -> 'b repr) =
    Lam (name, ty, f (Variable (name, ty)))

  let app f arg = App (f, arg)

  let let_ ~name (type a) (m : a repr) (f : a repr -> 'b repr) : 'b repr =
    let var = Variable (name, type_of m) in
    Let (name, m, f var)

  let if_ cond ift iff = If (cond, ift, iff)
end

module Transform
    (Ast : S) (F : sig
      val transform : 'a Ast.t -> 'a Ast.t
    end)
    (X : Costlang.S with type size = Ast.size) =
struct
  type size = X.size

  let size_ty = X.size_ty

  open Ast

  type 'a repr = 'a Ast.t

  type x_repr_ex = X_repr_ex : 'a Ty.t * 'a X.repr -> x_repr_ex

  let rec prj' : type a. (string * x_repr_ex) list -> a repr -> a X.repr =
   fun env t ->
    match t with
    | Variable (name, ty) -> (
        match List.assoc ~equal:String.equal name env with
        | None -> assert false
        | Some (X_repr_ex (ty', xa)) -> (
            match Ty.equal ty ty' with None -> assert false | Some Refl -> xa))
    | Lam (name, ty, b) ->
        X.lam ~name ty (fun xa ->
            let env = (name, X_repr_ex (ty, xa)) :: env in
            prj' env b)
    | Let (name, m, t) ->
        X.let_ ~name (prj' env m) (fun xa ->
            let env = (name, X_repr_ex (Ast.type_of m, xa)) :: env in
            prj' env t)
    | Size (Int i) -> X.int i
    | Size (Float f) -> X.float f
    | Bool true -> X.true_
    | Bool false -> X.false_
    | Unop (Log2, t) -> X.log2 (prj' env t)
    | Unop (Sqrt, t) -> X.sqrt (prj' env t)
    | Binop_size (Add, t1, t2) -> X.( + ) (prj' env t1) (prj' env t2)
    | Binop_size (Sat_sub, t1, t2) -> X.sat_sub (prj' env t1) (prj' env t2)
    | Binop_size (Mul, t1, t2) -> X.( * ) (prj' env t1) (prj' env t2)
    | Binop_size (Div, t1, t2) -> X.( / ) (prj' env t1) (prj' env t2)
    | Binop_size (Max, t1, t2) -> X.max (prj' env t1) (prj' env t2)
    | Binop_size (Min, t1, t2) -> X.min (prj' env t1) (prj' env t2)
    | Binop_bool (Eq, t1, t2) -> X.eq (prj' env t1) (prj' env t2)
    | Binop_bool (Lt, t1, t2) -> X.lt (prj' env t1) (prj' env t2)
    | Shift (`Left, t, n) -> X.shift_left (prj' env t) n
    | Shift (`Right, t, n) -> X.shift_right (prj' env t) n
    | Free name -> X.free ~name
    | App (f, t) -> X.app (prj' env f) (prj' env t)
    | If (c, t, e) -> X.if_ (prj' env c) (prj' env t) (prj' env e)

  let prj t = prj' [] (F.transform t)

  let false_ = Bool false

  let true_ = Bool true

  let float f = Size (Float f)

  let int i = Size (Int i)

  let ( + ) x y = Binop_size (Add, x, y)

  let ( * ) x y = Binop_size (Mul, x, y)

  let sat_sub x y = Binop_size (Sat_sub, x, y)

  let ( / ) x y = Binop_size (Div, x, y)

  let max x y = Binop_size (Max, x, y)

  let min x y = Binop_size (Min, x, y)

  let shift_left x s = Shift (`Left, x, s)

  let shift_right x s = Shift (`Right, x, s)

  let log2 x = Unop (Log2, x)

  let sqrt x = Unop (Sqrt, x)

  let free ~name = Free name

  let lt x y = Binop_bool (Lt, x, y)

  let eq x y = Binop_bool (Eq, x, y)

  let lam ~name ty (f : 'a repr -> 'b repr) =
    Lam (name, ty, f (Variable (name, ty)))

  let app f arg = App (f, arg)

  let let_ ~name (type a) (m : a repr) (f : a repr -> 'b repr) : 'b repr =
    let var = Variable (name, type_of m) in
    Let (name, m, f var)

  let if_ cond ift iff = If (cond, ift, iff)
end
