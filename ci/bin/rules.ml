(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Gitlab_ci
open Gitlab_ci.If

(** The source of a pipeline. *)
type pipeline_source = Schedule | Merge_request_event | Push

(** Convert at {!pipeline_source} to string. *)
let pipeline_source_to_string = function
  | Schedule -> "schedule"
  | Merge_request_event -> "merge_request_event"
  | Push -> "push"

let pipeline_source_eq pipeline_source =
  Predefined_vars.ci_pipeline_source
  == str (pipeline_source_to_string pipeline_source)

let merge_request = pipeline_source_eq Merge_request_event

let push = pipeline_source_eq Push

let scheduled = pipeline_source_eq Schedule

let on_master = Predefined_vars.ci_commit_branch == str "master"

let on_branch branch = Predefined_vars.ci_commit_branch == str branch

let on_tezos_namespace = Predefined_vars.ci_project_namespace == str "tezos"

let not_on_tezos_namespace = Predefined_vars.ci_project_namespace != str "tezos"

let has_tag_match tag = Predefined_vars.ci_commit_tag =~ tag

let has_tag_not_match tag =
  Predefined_vars.(ci_commit_tag != null && ci_commit_tag =~! tag)

let assigned_to_marge_bot =
  Predefined_vars.ci_merge_request_assignees =~! "/nomadic-margebot/"
