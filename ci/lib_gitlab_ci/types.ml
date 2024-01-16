(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** The AST of GitLab CI configurations.

    For reference, see GitLab's {{:https://docs.gitlab.com/ee/ci/yaml/} CI/CD YAML syntax reference}. *)

type variables = (string * string) list

type time_interval =
  | Seconds of int
  | Minutes of int
  | Hours of int
  | Days of int
  | Weeks of int
  | Months of int
  | Years of int

(** Represents values of the [when:] field in job rules. *)
type when_ = Always | Never | On_success | Manual | Delayed of time_interval

(** Represents values of the [when:] field in [workflow:] and [include:] rules. *)
type when_workflow = Always | Never

(** Represents a job rule. *)
type job_rule = {
  changes : string list option;
  if_ : If.t option;
  variables : variables option;
  when_ : when_;
  allow_failure : bool option;
}

(** Represents a workflow rule. *)
type workflow_rule = {
  changes : string list option;
  if_ : If.t option;
  variables : variables option;
  when_ : when_workflow;
}

(** Represents an include rule. *)
type include_rule = {
  changes : string list option;
  if_ : If.t option;
  when_ : when_workflow;
}

type coverage_format = Cobertura

type coverage_report = {coverage_format : coverage_format; path : string}

type reports = {
  dotenv : string option;
  junit : string option;
  coverage_report : coverage_report option;
}

type image = Image of string

type when_artifact = Always | On_success | On_failure

type artifacts = {
  expire_in : time_interval option;
  paths : string list;
  reports : reports option;
  when_ : when_artifact option;
  expose_as : string option;
  name : string option;
}

type default = {image : image option; interruptible : bool option}

type cache = {key : string; paths : string list}

type service = {name : string}

type job = {
  name : string;
      (** Note that [name] does not translate to the a field in a job, but
          instead to the key in the top-level that identifies the job. *)
  after_script : string list option;
  allow_failure : bool option;
  artifacts : artifacts option;
  before_script : string list option;
  cache : cache list option;
  image : image option;
  interruptible : bool option;
  needs : string list option;
  dependencies : string list option;
  rules : job_rule list option;
  script : string list option;
  services : service list option;
  stage : string option;
  variables : variables option;
  timeout : time_interval option;
  tags : string list option;
  when_ : when_ option;
  coverage : string option;
      (** Note: the job field [coverage] is not to be confused with
          {!coverage_report}.
          {{:https://docs.gitlab.com/ee/ci/yaml/#coverage}This
          coverage field} is used to specify a regular expression that
          can be used to capture coverage information from the job's
          trace.  On the other hand, {!coverage_report} is used to
          expose the captured coverage information as a report in a
          job's artifacts
          ({{:https://docs.gitlab.com/ee/ci/yaml/artifacts_reports.html#artifactsreportscoverage_report}ref}). *)
  retry : int option;
  parallel : int option;
}

type workflow = {rules : workflow_rule list; name : string option}

type include_ = {local : string; rules : include_rule list}

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
