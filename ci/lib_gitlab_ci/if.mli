(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** Type of a GitLab [if:] expression, as used in [rules:] clauses. *)
type t

(** The string representation of an [if:] expression. *)
val encode : t -> string

(** [var name] is the [if:] expression [$name]. *)
val var : string -> t

(** [str s] is the [if:] expression ["s"]. *)
val str : string -> t

(** The [if:]-expression [null]. *)
val null : t

(** Equality in [if:]-expressions.

    Example: [var "foo" == str "bar"] translates to [$foo == "bar"]. *)
val ( == ) : t -> t -> t

(** Inequality in [if:]-expressions.

    Example: [var "foo" != str "bar"] translates to [$foo != "bar"]. *)
val ( != ) : t -> t -> t

(** Conjunction of [if:]-expressions. *)
val ( && ) : t -> t -> t

(** Disjunction of [if:]-expressions. *)
val ( || ) : t -> t -> t

(** Pattern match on [if:]-expressions.

    Example: [var "foo" =~ str "/bar/"] translates to [$foo =~ "/bar/"]. *)
val ( =~ ) : t -> string -> t

(** Negated pattern match on [if:]-expressions.

    Example: [var "foo" =~! str "/bar/"] translates to [$foo !~ "/bar/"]. *)
val ( =~! ) : t -> string -> t
