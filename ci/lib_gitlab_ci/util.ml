(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Types

let default ?image ?interruptible () : default = {image; interruptible}

let job_rule ?changes ?if_ ?variables ?(when_ = On_success) () : when_ rule =
  {changes; if_; variables; when_}

let workflow_rule ?changes ?if_ ?variables ?(when_ = Always) () :
    when_workflow rule =
  {changes; if_; variables; when_}

let include_rule ?changes ?if_ ?(when_ = Always) () : when_workflow rule =
  {changes; if_; variables = None; when_}
