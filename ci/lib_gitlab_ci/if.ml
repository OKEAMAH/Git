(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Base

type term = Var of string | Str of string | Null

type t =
  | And of (t * t)
  | Or of (t * t)
  | Eq of (term * term)
  | Match of (term * string)
  | Unmatch of (term * string)
  | Neq of (term * term)

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
  let encode_term = function
    | Null -> "null"
    | Var n -> "$" ^ n
    | Str s -> sf {|"%s"|} s
  in
  match expr with
  | And (a, b) -> sf "%s && %s" (paren_opt a) (paren_opt b)
  | Or (a, b) -> sf "%s || %s" (paren_opt a) (paren_opt b)
  | Eq (a, b) -> sf "%s == %s" (encode_term a) (encode_term b)
  | Neq (a, b) -> sf "%s != %s" (encode_term a) (encode_term b)
  | Match (a, b) -> sf "%s =~ %s" (encode_term a) b
  | Unmatch (a, b) -> sf "%s !~ %s" (encode_term a) b

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
