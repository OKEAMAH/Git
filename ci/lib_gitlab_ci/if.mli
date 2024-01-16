(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** Predicates for GitLab [if:] expression, as used in [rules:] clauses. *)
type t

(** Variables for GitLab [if:] expressions. *)
type var

(** The string representation of a variable.

    In other words, [encode_var @@ "foo"] translates to ["$foo"]. *)
val encode_var : var -> string

(** Terms for predicates in GitLab [if:] clauses. *)
type term

(** The string representation of an [if:] expression. *)
val encode : t -> string

(** [var name] is the [if:] expression [$name]. *)
val var : string -> var

(** [str s] is the [if:] expression ["s"]. *)
val str : string -> term

(** The [if:]-expression [null]. *)
val null : term

(** Equality in [if:]-expressions.

    Example: [var "foo" == str "bar"] translates to [$foo == "bar"]. *)
val ( == ) : var -> term -> t

(** Inequality in [if:]-expressions.

    Example: [var "foo" != str "bar"] translates to [$foo != "bar"]. *)
val ( != ) : var -> term -> t

(** Conjunction of [if:]-expressions. *)
val ( && ) : t -> t -> t

(** Disjunction of [if:]-expressions. *)
val ( || ) : t -> t -> t

(** Pattern match on [if:]-expressions.

    Example: [var "foo" =~ str "/bar/"] translates to [$foo =~ "/bar/"]. *)
val ( =~ ) : var -> string -> t

(** Negated pattern match on [if:]-expressions.

    Example: [var "foo" =~! str "/bar/"] translates to [$foo !~ "/bar/"]. *)
val ( =~! ) : var -> string -> t

(** Negation of a predicate.

    If [t] evaluates to true, then [not t] evaluates to false.  Note
    that [if:] expressions have no native negation operator. Therefore
    this function works by rewriting the expression using de Morgan's
    laws and swapping (negated) operators for their (un)negated
    counter-parts. *)
val not : t -> t
