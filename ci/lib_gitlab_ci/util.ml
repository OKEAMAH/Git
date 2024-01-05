(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Types

let default ?image ?interruptible () : default = {image; interruptible}

let job_rule ?changes ?if_ ?variables ?(when_ : when_ = On_success) () :
    job_rule =
  {changes; if_; variables; when_}

let workflow_rule ?changes ?if_ ?variables ?(when_ : when_workflow = Always) ()
    : workflow_rule =
  {changes; if_; variables; when_}

let include_rule ?changes ?if_ ?(when_ : when_workflow = Always) () :
    include_rule =
  {changes; if_; when_}

let artifacts ?expire_in ?reports ?when_ ?expose_as paths =
  (match (reports, paths) with
  | Some {dotenv = None; junit = None}, [] ->
      failwith
        "Attempted to register an artifact with no reports or paths -- this \
         doesn't make any sense"
  | _ -> ()) ;
  let reports =
    match reports with
    | Some reports -> reports
    | None -> {dotenv = None; junit = None}
  in
  {expire_in; paths; reports; when_; expose_as}
