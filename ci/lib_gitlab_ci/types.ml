(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** The AST of GitLab CI configurations.

    For reference, see GitLab's {{:https://docs.gitlab.com/ee/ci/yaml/} CI/CD YAML syntax reference}. *)

type variables = (string * string) list

(** Represents values to the [when:] field in job rules. *)
type when_ = Always | Never | On_success | Manual

(** Represents values to the [when:] field in [workflow:] and [include:] rules. *)
type when_workflow = Always | Never

(** ['when_type rule] Represents a rule with the [when:]-type ['when_type].

    - Rules that appears in the definition of jobs instantiate
      ['when_type] to [when_].
    - Rules that appears in the definition of workflows and includes
      ['when_type] to [when_workflow].
    - Additionally, for when in includes, [variables] must be [None]. *)
type 'when_type rule = {
  changes : string list option;
  if_ : If.t option;
  variables : variables option;
  when_ : 'when_type;
}

type reports = {dotenv : string option; junit : string option}

type image = Image of string

type artifacts = {
  expire_in : string;
  paths : string list;
  reports : reports;
  when_ : string;
  expose_as : string option;
}

type default = {image : image option; interruptible : bool option}

type cache = {key : string; paths : string list}

type timeout =
  | Seconds of int
  | Minutes of int
  | Hours of int
  | Days of int
  | Weeks of int
  | Months of int
  | Years of int

type service = {name : string}

type job = {
  name : string;
      (** Note that [name] does not translate to the a field in a job, but
          instead to the key in the top-level that identifies the job. *)
  after_script : string list option;
  allow_failure : bool option;
  artifacts : artifacts option;
  before_script : string list option;
  cache : cache option;
  image : image option;
  interruptible : bool option;
  needs : string list option;
  dependencies : string list option;
  rules : when_ rule list option;
  script : string list option;
  services : service list option;
  stage : string option;
  variables : variables option;
  timeout : timeout option;
  tags : string list option;
}

type workflow = {rules : when_workflow rule list; name : string option}

type include_ = {local : string; rules : when_workflow rule list}

type config_element =
  | Workflow of workflow  (** Corresponds to a [workflow:] key. *)
  | Stages of string list  (** Corresponds to a [stages:] key. *)
  | Variables of variables  (** Corresponds to a [variables:] key. *)
  | Default of default  (** Corresponds to a [default:] key. *)
  | Job of job  (** Corresponds to a job, identified by it's key. *)
  | Include of include_ list  (** Corresponds to a [include:] key *)

(** A GitLab CI/CD configuration.

    Note that a configuration can consists of a sequence of
    [config_element]s. The same element can occur multiple times, and
    their order has semantic significance (for instance, with [include:]). *)
type config = config_element list
