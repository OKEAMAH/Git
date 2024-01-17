(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Base

type var = Var of string

let encode_var = function Var n -> "$" ^ n

type term = Str of string | Null

type t =
  | And of (t * t)
  | Or of (t * t)
  | Eq of (var * term)
  | Neq of (var * term)
  | Match of (var * string)
  | Unmatch of (var * string)

let rec encode expr =
  let prio = function
    | Eq _ -> 1
    | Neq _ -> 1
    | Match _ -> 1
    | Unmatch _ -> 1
    | And _ -> 2
    | Or _ -> 3
  in
  (*
        Precedence: not > and > or > string, var

        And (Or a b) c -> (a || b) && c
        Or a (And b c) -> a || b && c
        Or (And a b) c -> a && b || c
      *)
  let paren_opt sub_expr =
    let s = encode sub_expr in
    if prio expr < prio sub_expr then "(" ^ s ^ ")" else s
  in
  let encode_term = function Null -> "null" | Str s -> sf {|"%s"|} s in
  match expr with
  | And (a, b) -> sf "%s && %s" (paren_opt a) (paren_opt b)
  | Or (a, b) -> sf "%s || %s" (paren_opt a) (paren_opt b)
  | Eq (a, b) -> sf "%s == %s" (encode_var a) (encode_term b)
  | Neq (a, b) -> sf "%s != %s" (encode_var a) (encode_term b)
  | Match (a, b) -> sf "%s =~ %s" (encode_var a) b
  | Unmatch (a, b) -> sf "%s !~ %s" (encode_var a) b

let var n = Var n

let eq a b = Eq (a, b)

let neq a b = Neq (a, b)

let and_ a b = And (a, b)

let or_ a b = Or (a, b)

let str s = Str s

let null = Null

let match_ a b = Match (a, b)

let unmatch a b = Unmatch (a, b)

let ( == ) = eq

let ( != ) = neq

let ( && ) = and_

let ( || ) = or_

let ( =~ ) = match_

let ( =~! ) = unmatch

let rec not = function
  | And (a, b) -> Or (not a, not b)
  | Or (a, b) -> And (not a, not b)
  | Eq (x, b) -> Neq (x, b)
  | Neq (x, b) -> Eq (x, b)
  | Match (x, s) -> Unmatch (x, s)
  | Unmatch (x, s) -> Match (x, s)

let implies_underapprox t t' =
  (* Try to make the clause a bit CNF-like, could be improved ... *)
  let rec and_list t =
    match t with And (x, y) -> and_list x @ and_list y | _ -> [t]
  in
  (* Heuristic for implication in CNF: *)
  (* all the clauses on the RHS must figure on the LHS *)
  let t = and_list t in
  let t' = and_list t' in
  List.for_all (Fun.flip List.mem t) t'
