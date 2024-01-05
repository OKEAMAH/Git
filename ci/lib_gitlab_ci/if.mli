(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** Predicates for GitLab [if:] expression, as used in [rules:] clauses. *)
type t

(** Terms for predicates in GitLab [if:] clauses. *)
type term

(** The string representation of an [if:] expression. *)
val encode : t -> string

(** [var name] is the [if:] expression [$name]. *)
val var : string -> term

(** [str s] is the [if:] expression ["s"]. *)
val str : string -> term

(** The [if:]-expression [null]. *)
val null : term

(** Equality in [if:]-expressions.

    Example: [var "foo" == str "bar"] translates to [$foo == "bar"]. *)
val ( == ) : term -> term -> t

(** Inequality in [if:]-expressions.

    Example: [var "foo" != str "bar"] translates to [$foo != "bar"]. *)
val ( != ) : term -> term -> t

(** Conjunction of [if:]-expressions. *)
val ( && ) : t -> t -> t

(** Disjunction of [if:]-expressions. *)
val ( || ) : t -> t -> t

(** Pattern match on [if:]-expressions.

    Example: [var "foo" =~ str "/bar/"] translates to [$foo =~ "/bar/"]. *)
val ( =~ ) : term -> string -> t

(** Negated pattern match on [if:]-expressions.

    Example: [var "foo" =~! str "/bar/"] translates to [$foo !~ "/bar/"]. *)
val ( =~! ) : term -> string -> t
