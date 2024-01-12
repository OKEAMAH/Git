(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Types

let default ?image ?interruptible () : default = {image; interruptible}

let job_rule ?changes ?if_ ?variables ?(when_ : when_ = On_success)
    ?allow_failure ?start_in () : job_rule =
  (* Alternatively, this restriction can be encoded in the type system
     by making [start_in] a parameter of the [Delayed] constructor.
     However, that would be a step away from Octez-agnosticism of [lib_gitlab_ci]. *)
  (match (start_in, when_) with
  | None, _ -> ()
  | Some _, Delayed -> ()
  | Some _, _ ->
      failwith "[job_rule] cannot set [start_in] if [when_] is not [Delayed]") ;
  {changes; if_; variables; when_; allow_failure; start_in}

let workflow_rule ?changes ?if_ ?variables ?(when_ : when_workflow = Always) ()
    : workflow_rule =
  {changes; if_; variables; when_}

let include_rule ?changes ?if_ ?(when_ : when_workflow = Always) () :
    include_rule =
  {changes; if_; when_}

let artifacts ?expire_in ?reports ?when_ ?expose_as ?name paths =
  (match (reports, paths) with
  | Some {dotenv = None; junit = None; coverage_report = None}, [] ->
      failwith
        "Attempted to register an artifact with no reports or paths -- this \
         doesn't make any sense"
  | _ -> ()) ;
  {expire_in; paths; reports; when_; expose_as; name}

let reports ?dotenv ?junit ?coverage_report () =
  (match (dotenv, junit, coverage_report) with
  | None, None, None ->
      failwith
        "Attempted to register a empty [reports] -- this doesn't make any sense"
  | _ -> ()) ;
  {dotenv; junit; coverage_report}
