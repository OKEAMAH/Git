(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** Predefined CI/CD variables in all pipelines.

    This contains a subset of the
    {{:https://docs.gitlab.com/ee/ci/variables/predefined_variables.html}
    predefined variables}. *)

(** Corresponds to [CI_COMMIT_BRANCH].*)
val ci_commit_branch : If.t

(** Corresponds to [CI_COMMIT_TAG].*)
val ci_commit_tag : If.t

(** Corresponds to [CI_DEFAULT_BRANCH].*)
val ci_default_branch : If.t

(** Corresponds to [CI_OPEN_MERGE_REQUESTS].*)
val ci_open_merge_requests : If.t

(** Corresponds to [CI_MERGE_REQUEST_ID].*)
val ci_merge_request_id : If.t

(** Corresponds to [CI_PIPELINE_SOURCE].*)
val ci_pipeline_source : If.t

(** Corresponds to [CI_PROJECT_NAMESPACE].*)
val ci_project_namespace : If.t

(** Corresponds to [CI_MERGE_REQUEST_ASSIGNEES].*)
val ci_merge_request_assignees : If.t
