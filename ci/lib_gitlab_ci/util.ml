(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Types

let default ?image ?interruptible () : default = {image; interruptible}

let job_rule ?changes ?if_ ?variables ?(when_ = On_success) () : job_rule =
  {changes; if_; variables; when_}

let workflow_rule ?changes ?if_ ?variables ?(when_ = Always) () : workflow_rule
    =
  {changes; if_; variables; when_}

let include_rule ?changes ?if_ ?(when_ = Always) () : include_rule =
  {changes; if_; when_}
