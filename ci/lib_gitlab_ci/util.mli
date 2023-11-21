(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** Smart constructors for values of {!Types} *)

open Types

(** Constructs a [default:] configuration element. *)
val default : ?image:image -> ?interruptible:bool -> unit -> default

(** Constructs a job rule.

    [when_] defaults to [On_success]. *)
val job_rule :
  ?changes:string list ->
  ?if_:If.t ->
  ?variables:variables ->
  ?when_:when_ ->
  unit ->
  when_ rule

(** Constructs a workflow rule.

    [when_] defaults to [Always]. *)
val workflow_rule :
  ?changes:string list ->
  ?if_:If.t ->
  ?variables:variables ->
  ?when_:when_workflow ->
  unit ->
  when_workflow rule

(** Constructs an include rule.

    Include rules do not permit [variables] and there is consequently
    no such parameter.

    [when_] defaults to [Always]. *)
val include_rule :
  ?changes:string list ->
  ?if_:If.t ->
  ?when_:when_workflow ->
  unit ->
  when_workflow rule
