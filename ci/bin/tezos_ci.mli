(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** A facility for registering pipeline stages. *)
module Stage : sig
  (* Represents a pipeline stage *)
  type t

  (** Register a stage.

      Fails if a stage of the same name has already been registered. *)
  val register : string -> t

  (** Name of a stage *)
  val name : t -> string

  (** Returns the list of registered stages, in order of registration, as a list of strings.

      This is appropriate to use with the [Stages] constructor of
      {!Gitlab_ci.Types.config_element} generating a [stages:]
      element. *)
  val to_string_list : unit -> string list
end

(** A facility for registering pipelines. *)
module Pipeline : sig
  (* Register a pipeline.

     [register ?variables name rule] will register a pipeline [name]
     that runs when [rule] is true. The pipeline is expected to be
     defined in [.gitlab/ci/pipelines/NAME.yml] which will be included
     from the top-level [.gitlab-ci.yml].

     If [variables] is set, then these variables will be added to the
     [workflow:] clause for this pipeline in the top-level [.gitlab-ci.yml]. *)
  val register :
    ?variables:Gitlab_ci.Types.variables -> string -> Gitlab_ci.If.t -> unit

  (** Splits the set of registered pipelines into workflow rules and includes.

      The result of this function is used in the top-level
      [.gitlab-ci.yml] to filter pipelines (using [workflow:] rules)
      and to include the select pipeline (using [include:]). *)
  val workflow_includes :
    unit -> Gitlab_ci.Types.workflow * Gitlab_ci.Types.include_ list
end

(** A facility for registering images for [image:] keywords.

    During the transition from hand-written [.gitlab-ci.yml] to
    CI-in-OCaml, we write a set of templates corresponding to the
    registered images, to make them available for hand-written jobs. *)
module Image : sig
  (** Represents an image *)
  type t = Gitlab_ci.Types.image

  (** Register an image of the given [name] and [image_path]. *)
  val register : name:string -> image_path:string -> t

  (** The name of an image *)
  val name : t -> string

  (** Returns the set of registered images as [name, image] tuples. *)
  val all : unit -> (string * t) list
end

(** Represents architectures. *)
type arch = Amd64 | Arm64

(** A job dependency.

    - A job that depends on [Job j] will not start until [j] finishes.

    - A job that depends on [Artefacts j] will not start until [j] finishes
      and will also have the artefacts of [j] available. *)
type dependency =
  | Job of Gitlab_ci.Types.job
  | Artifacts of Gitlab_ci.Types.job

(** Job dependencies.

    - A [Staged] job implements the default GitLab CI behavior of running once all
    jobs in the previous stage have terminated.
    - An [Independent] job runs immediately, regardless of its stage. This corresponds to setting [needs: []].
    - An [Dependent deps] job runs once all the jobs in [deps] have terminated. *)
type dependencies = Staged | Independent | Dependent of dependency list

(** Values for the [GIT_STRATEGY] variable.

    This can be used to specify whether a job should [Fetch] or [Clone]
    the git repository, or not get it at all with [No_strategy].

    For more information, see
   {{:https://docs.gitlab.com/ee/ci/runners/configure_runners.html#git-strategy}GIT_STRATEGY} *)
type git_strategy =
  | Fetch  (** Translates to [fetch]. *)
  | Clone  (** Translates to [clone]. *)
  | No_strategy
      (** Translates to [].

          Renamed to avoid clashes with {!Option.None}. *)

(** GitLab CI/CD YAML representation of [git_strategy].

    Translates {!git_strategy} to values of accepted by the GitLab
    CI/CD YAML variable [GIT_STRATEGY]. *)
val enc_git_strategy : git_strategy -> string

(** Define a job.

    This smart constructor for {!Gitlab_ci.Types.job} additionally:

    - Translates each {!dependency} to [needs:] and [dependencies:]
    keywords as detailed in the documentation of {!dependency}.
    - Adds [tags:] based on [arch]. *)
val job :
  ?arch:arch ->
  ?after_script:string list ->
  ?allow_failure:bool ->
  ?artifacts:Gitlab_ci.Types.artifacts ->
  ?before_script:string list ->
  ?cache:Gitlab_ci.Types.cache list ->
  ?image:Image.t ->
  ?interruptible:bool ->
  ?dependencies:dependencies ->
  ?services:Gitlab_ci.Types.service list ->
  ?variables:Gitlab_ci.Types.variables ->
  ?rules:Gitlab_ci.Types.job_rule list ->
  ?timeout:Gitlab_ci.Types.time_interval ->
  ?tags:string list ->
  ?git_strategy:git_strategy ->
  ?when_:Gitlab_ci.Types.when_ ->
  ?coverage:string ->
  stage:Stage.t ->
  name:string ->
  string list ->
  Gitlab_ci.Types.job
