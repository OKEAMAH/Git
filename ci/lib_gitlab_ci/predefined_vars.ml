(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open If

let ci_commit_branch = var "CI_COMMIT_BRANCH"

let ci_commit_tag = var "CI_COMMIT_TAG"

let ci_default_branch = var "CI_DEFAULT_BRANCH"

let ci_open_merge_requests = var "CI_OPEN_MERGE_REQUESTS"

let ci_merge_request_id = var "CI_MERGE_REQUEST_ID"

let ci_pipeline_source = var "CI_PIPELINE_SOURCE"

let ci_project_namespace = var "CI_PROJECT_NAMESPACE"

let ci_merge_request_assignees = var "CI_MERGE_REQUEST_ASSIGNEES"
