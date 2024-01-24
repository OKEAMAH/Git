(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(* Main entrypoint of CI-in-OCaml.

   Here we register the set of pipelines, stages and images used to
   generate the top-level [.gitlab-ci.yml] file. *)

open Gitlab_ci
open Gitlab_ci.Types
open Gitlab_ci.Util
open Tezos_ci

(* Sets up the [default:] top-level configuration element. *)
let default = default ~interruptible:true ()

(* Define [stages:]

   The "manual" stage exists to fix a UI problem that occurs when mixing
   manual and non-manual jobs. *)
module Stages = struct
  let trigger = Stage.register "trigger"

  let _sanity = Stage.register "sanity"

  let build = Stage.register "build"

  let _test = Stage.register "test"

  let _test_coverage = Stage.register "test_coverage"

  let _packaging = Stage.register "packaging"

  let _doc = Stage.register "doc"

  let prepare_release = Stage.register "prepare_release"

  let _publish_release_gitlab = Stage.register "publish_release_gitlab"

  let publish_release = Stage.register "publish_release"

  let _publish_package_gitlab = Stage.register "publish_package_gitlab"

  let manual = Stage.register "manual"
end

(* Get the [build_deps_image_version] from the environment, which is
   typically set by sourcing [scripts/version.sh]. This is used to write
   [build_deps_image_version] in the top-level [variables:], used to
   specify the versions of the [build_deps] images. *)
let build_deps_image_version =
  match Sys.getenv_opt "opam_repository_tag" with
  | None ->
      failwith
        "Please set the environment variable [opam_repository_tag], by e.g. \
         sourcing [scripts/version.sh] before running."
  | Some v -> v

(* Get the [alpine_version] from the environment, which is typically
   set by sourcing [scripts/version.sh]. This is used to set the tag
   of the image {!Images.alpine}. *)
let alpine_version =
  match Sys.getenv_opt "alpine_version" with
  | None ->
      failwith
        "Please set the environment variable [alpine_version], by e.g. \
         sourcing [scripts/version.sh] before running."
  | Some v -> v

(* Top-level [variables:] *)
let variables : variables =
  [
    (* /!\ CI_REGISTRY is overriden to use a private Docker registry mirror in AWS ECR
       in GitLab namespaces `nomadic-labs` and `tezos`
       /!\ This value MUST be the same as `opam_repository_tag` in `scripts/version.sh` *)
    ("build_deps_image_version", build_deps_image_version);
    ("build_deps_image_name", "${CI_REGISTRY}/tezos/opam-repository");
    ("GIT_STRATEGY", "fetch");
    ("GIT_DEPTH", "1");
    ("GET_SOURCES_ATTEMPTS", "2");
    ("ARTIFACT_DOWNLOAD_ATTEMPTS", "2");
    (* Sets the number of tries before failing opam downloads. *)
    ("OPAMRETRIES", "5");
    (* An addition to working around a bug in gitlab-runner's default
       unzipping implementation
       (https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27496),
       this setting cuts cache creation time. *)
    ("FF_USE_FASTZIP", "true");
    (* If RUNTEZTALIAS is true, then Tezt tests are included in the
       @runtest alias. We set it to false to deactivate these tests in
       the unit test jobs, as they already run in the Tezt jobs. It is
       set to true in the opam jobs where we want to run the tests
       --with-test. *)
    ("RUNTEZTALIAS", "false");
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/6764
       "false" is the GitLab default but we've overridden it in the runner settings.
       This should be fixed at the runner level but we reset it to the
       default here in the meantime. *)
    ("FF_KUBERNETES_HONOR_ENTRYPOINT", "false");
  ]

(* Register images.

   The set of registered images are written to
   [.gitlab/ci/jobs/shared/images.yml] for interoperability with
   hand-written .yml files.

   For documentation on the [runtime_X_dependencies] and the
   [rust_toolchain] images, refer to
   {{:https://gitlab.com/tezos/opam-repository/}
   tezos/opam-repository}. *)
module Images = struct
  let _runtime_e2etest_dependencies =
    Image.register
      ~name:"runtime_e2etest_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-e2etest-dependencies--${build_deps_image_version}"

  let _runtime_build_test_dependencies =
    Image.register
      ~name:"runtime_build_test_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-build-test-dependencies--${build_deps_image_version}"

  let runtime_build_dependencies =
    Image.register
      ~name:"runtime_build_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-build-dependencies--${build_deps_image_version}"

  let _runtime_prebuild_dependencies =
    Image.register
      ~name:"runtime_prebuild_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-prebuild-dependencies--${build_deps_image_version}"

  let _runtime_client_libs_dependencies =
    Image.register
      ~name:"runtime_client_libs_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-client-libs-dependencies--${build_deps_image_version}"

  let _rust_toolchain =
    Image.register
      ~name:"rust_toolchain"
      ~image_path:
        "${build_deps_image_name}:rust-toolchain--${build_deps_image_version}"

  (* Match GitLab executors version and directly use the Docker socket
     The Docker daemon is already configured, experimental features are enabled
     The following environment variables are already set:
     - [BUILDKIT_PROGRESS]
     - [DOCKER_DRIVER]
     - [DOCKER_VERSION]
     For more info, see {{:https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding}} here.

     This image is defined in {{:https://gitlab.com/tezos/docker-images/ci-docker}tezos/docker-images/ci-docker}. *)
  let docker =
    Image.register
      ~name:"docker"
      ~image_path:"${CI_REGISTRY}/tezos/docker-images/ci-docker:v1.9.0"

  (* The Alpine version should be kept up to date with the version
     used for the [build_deps_image_name] images and specified in the
     variable [alpine_version] in [scripts/version.sh]. This is
     checked by the jobs [trigger] and [sanity_ci]. *)
  let alpine =
    Image.register ~name:"alpine" ~image_path:("alpine:" ^ alpine_version)
end

let before_script ?(take_ownership = false) ?(source_version = false)
    ?(eval_opam = false) ?(init_python_venv = false) ?(install_js_deps = false)
    before_script =
  let toggle t x = if t then [x] else [] in
  (* FIXME: https://gitlab.com/tezos/tezos/-/issues/2865 *)
  toggle take_ownership "./scripts/ci/take_ownership.sh"
  @ toggle source_version ". ./scripts/version.sh"
    (* TODO: this must run in the before_script of all jobs that use the opam environment.
       how to enforce? *)
  @ toggle eval_opam "eval $(opam env)"
  (* Load the environment poetry previously created in the docker image.
     Give access to the Python dependencies/executables *)
  @ toggle init_python_venv ". $HOME/.venv/bin/activate"
  @ toggle install_js_deps ". ./scripts/install_build_deps.js.sh"
  @ before_script

(* Define the [trigger] job *)
let trigger =
  job
    ~image:Images.alpine
    ~stage:Stages.trigger
    ~rules:
      [
        job_rule
          ~if_:If.(Rules.(merge_request && assigned_to_marge_bot))
          ~when_:Manual (* Explicit [allow_failure] to make this job blocking *)
          ~allow_failure:No
          ();
        job_rule ~when_:Always ();
      ]
    ~allow_failure:No
    ~timeout:(Minutes 10)
    ~name:"trigger"
    ~git_strategy:No_strategy
      (* This job requires no checkout, setting [No_strategy] saves ~10 seconds. *)
    ["echo 'Trigger pipeline!'"]

(** Helper to create jobs that uses the docker deamon.

    It:
    - Sets the appropriate image.
    - Activates the docker Daemon as a service.
    - It sets up authentification with docker registries *)
let job_docker_authenticated ?variables ?arch ?dependencies ?rules ?when_
    ?allow_failure ~stage ~name script : job =
  let docker_version = "24.0.6" in
  job
    ?arch
    ?dependencies
    ?rules
    ?when_
    ?allow_failure
    ~image:Images.docker
    ~variables:
      ([("DOCKER_VERSION", docker_version)] @ Option.value ~default:[] variables)
    ~before_script:
      [
        "./scripts/ci/docker_wait_for_daemon.sh";
        "./scripts/ci/docker_check_version.sh ${DOCKER_VERSION}";
        "./scripts/ci/docker_registry_auth.sh";
      ]
    ~services:[{name = "docker:${DOCKER_VERSION}-dind"}]
    ~stage
    ~name
    script

let job_docker_promote_to_latest ~ci_docker_hub : job =
  job_docker_authenticated
    ~stage:Stages.publish_release
    ~name:"docker:promote_to_latest"
    ~variables:[("CI_DOCKER_HUB", Bool.to_string ci_docker_hub)]
    ["./scripts/ci/docker_promote_to_latest.sh"]

(* This version of the job builds both released and experimental executables.
   It is used in the following pipelines:
   - Before merging: check whether static executables still compile,
     i.e. that we do pass the -static flag and that when we do it does compile
   - Master branch: executables (including experimental ones) are used in some test networks
   Variants:
   - an arm64 variant exist, but is only used in the master branch pipeline
     (no need to test that we pass the -static flag twice)
   - released variants exist, that are used in release tag pipelines
     (they do not build experimental executables) *)
let job_build_static_binaries ~arch ?(external_ = false) ?(release = false)
    ?(needs_trigger = false) () =
  let arch_string =
    match arch with Tezos_ci.Amd64 -> "x86_64" | Arm64 -> "arm64"
  in
  let name = "oc.build:static-" ^ arch_string ^ "-linux-binaries" in
  let filename_suffix = if release then "release" else "experimental" in
  let artifacts =
    (* Extend the lifespan to prevent failure for external tools using artifacts. *)
    let expire_in = if release then Some (Days 90) else None in
    artifacts ?expire_in ["octez-binaries/$ARCH/*"]
  in
  let executable_files =
    "script-inputs/released-executables"
    ^ if not release then " script-inputs/experimental-executables" else ""
  in
  let dependencies =
    (* Even though not many tests depend on static executables, some
       of those that do are limiting factors in the total duration of
       pipelines. So when requested through [needs_trigger] we start
       this job as early as possible, without waiting for
       sanity_ci. *)
    if needs_trigger then Dependent [Job trigger] else Staged
  in
  let job =
    job
      ~stage:Stages.build
      ~arch
      ~name
      ~image:Images.runtime_build_dependencies
      ~before_script:(before_script ~take_ownership:true ~eval_opam:true [])
      ~variables:[("ARCH", arch_string); ("EXECUTABLE_FILES", executable_files)]
      ~dependencies
      ~artifacts
      ["./scripts/ci/build_static_binaries.sh"]
  in
  if external_ then job_external ~filename_suffix job else job

let _job_static_arm64_experimental =
  job_build_static_binaries ~external_:true ~arch:Arm64 ()

let _job_static_x86_64_experimental =
  job_build_static_binaries ~external_:true ~arch:Amd64 ~needs_trigger:true ()

(** Type of Docker build jobs.

    The semantics of the type is summed up in this table:

    |                       | Release    | Experimental | Test   | Test_manual |
    |-----------------------+------------+--------------+--------+-------------|
    | Image registry        | Docker hub | Docker hub   | GitLab | GitLab      |
    | Experimental binaries | no         | yes          | yes    | yes         |
    | EVM Kernels           | no         | On amd64     | no     | On amd64    |
    | Manual job            | no         | no           | no     | yes         |

    - [Release] Docker builds include only released executables whereas other
      types also includes experimental ones.
    - [Test_manual] and [Experimental] Docker builds include the EVM kernels in
      amd64 builds.
    - [Release] and [Experimental] Docker builds are pushed to Docker hub,
      whereas other types are pushed to the GitLab registry.
    - [Test_manual] Docker builds are triggered manually, put in the stage
      [manual] and their failure is allowed. The other types are in the build
      stage, run [on_success] and are not allowed to fail. *)
type docker_build_type = Experimental | Release | Test | Test_manual

(** Creates a Docker build job of the given [arch] and [docker_build_type].

    If [external_] is set to true (default [false]), then the job is
    also written to an external file. *)
let job_docker_build ?rules ~arch ?(external_ = false) docker_build_type : job =
  let arch_string =
    match arch with Tezos_ci.Amd64 -> "amd64" | Arm64 -> "arm64"
  in
  let variables =
    [
      ( "DOCKER_BUILD_TARGET",
        match (arch, docker_build_type) with
        | Amd64, (Test_manual | Experimental) -> "with-evm-artifacts"
        | _ -> "without-evm-artifacts" );
      ("IMAGE_ARCH_PREFIX", arch_string ^ "_");
      ( "CI_DOCKER_HUB",
        Bool.to_string
          (match docker_build_type with
          | Release | Experimental -> true
          | Test | Test_manual -> false) );
      ( "EXECUTABLE_FILES",
        match docker_build_type with
        | Release -> "script-inputs/released-executables"
        | Test | Test_manual | Experimental ->
            "script-inputs/released-executables \
             script-inputs/experimental-executables" );
    ]
  in
  let stage, dependencies, when_, (allow_failure : allow_failure_job option) =
    match docker_build_type with
    | Test_manual -> (Stages.manual, Dependent [], Some Manual, Some Yes)
    | _ -> (Stages.build, Staged, None, None)
  in
  let name = "oc.docker:" ^ arch_string in
  let filename_suffix =
    match docker_build_type with
    | Release -> "release"
    | Experimental -> "experimental"
    | Test -> "test"
    | Test_manual -> "test_manual"
  in
  let job =
    job_docker_authenticated
      ?when_
      ?allow_failure
      ?rules
      ~stage
      ~dependencies
      ~arch
      ~name
      ~variables
      ["./scripts/ci/docker_release.sh"]
  in
  if external_ then job_external ~directory:"build" ~filename_suffix job
  else job

let changeset_octez_docker_changes_or_master =
  [
    "scripts/**/*";
    "script-inputs/**/*";
    "src/**/*";
    "tezt/**/*";
    "vendors/**/*";
    "dune";
    "dune-project";
    "dune-workspace";
    "opam";
    "Makefile";
    "kernels.mk";
    "build.Dockerfile";
    "Dockerfile";
    ".gitlab/**/*";
    ".gitlab-ci.yml";
  ]

let rules_octez_docker_changes_or_master =
  [
    job_rule ~if_:Rules.on_master ();
    job_rule ~changes:changeset_octez_docker_changes_or_master ();
  ]

let job_docker_amd64_experimental : job =
  job_docker_build
    ~external_:true
    ~rules:rules_octez_docker_changes_or_master
    ~arch:Amd64
    Experimental

let _job_docker_amd64_release : job =
  job_docker_build
    ~external_:true
    ~rules:rules_octez_docker_changes_or_master
    ~arch:Amd64
    Release

let _job_docker_amd64_test_manual : job =
  job_docker_build ~external_:true ~arch:Amd64 Test_manual

let job_docker_amd64_test : job =
  job_docker_build
    ~external_:true
    ~rules:rules_octez_docker_changes_or_master
    ~arch:Amd64
    Test

let job_docker_arm64_experimental : job =
  job_docker_build
    ~external_:true
    ~rules:rules_octez_docker_changes_or_master
    ~arch:Arm64
    Experimental

let _job_docker_arm64_release : job =
  job_docker_build
    ~external_:true
    ~rules:rules_octez_docker_changes_or_master
    ~arch:Arm64
    Release

let _job_docker_arm64_test_manual : job =
  job_docker_build ~external_:true ~arch:Arm64 Test_manual

let job_docker_arm64_test : job =
  job_docker_build
    ~external_:true
    ~rules:rules_octez_docker_changes_or_master
    ~arch:Arm64
    Test

(* Note: here we rely on [$IMAGE_ARCH_PREFIX] to be empty.
   Otherwise, [$DOCKER_IMAGE_TAG] would contain [$IMAGE_ARCH_PREFIX] too.
   [$IMAGE_ARCH_PREFIX] is only used when building Docker images,
   here we handle all architectures so there is no such variable. *)
let job_docker_merge_manifests ~ci_docker_hub ~job_docker_amd64
    ~job_docker_arm64 : job =
  job_docker_authenticated
    ~stage:Stages.prepare_release
    ~name:"docker:merge_manifests"
      (* This job merges the images produced in the jobs
         [docker:{amd64,arm64}] into a single multi-architecture image, and
         so must be run after these jobs. *)
    ~dependencies:(Dependent [Job job_docker_amd64; Job job_docker_arm64])
    ~variables:[("CI_DOCKER_HUB", Bool.to_string ci_docker_hub)]
    ["./scripts/ci/docker_merge_manifests.sh"]

let _job_docker_merge_manifests_release =
  job_external ~filename_suffix:"release"
  @@ job_docker_merge_manifests
       ~ci_docker_hub:true
         (* TODO: In theory, actually uses either release or
            experimental variant of docker jobs depending on
            pipeline. In practice, this does not matter as these jobs
            have the same name in the generated files
            ([oc.build:ARCH]). However, when the merge_manifest jobs
            are created directly in the appropriate pipeline, the
            correcty variant must be used. *)
       ~job_docker_amd64:job_docker_amd64_experimental
       ~job_docker_arm64:job_docker_arm64_experimental

let _job_docker_merge_manifests_test =
  job_external ~filename_suffix:"test"
  @@ job_docker_merge_manifests
       ~ci_docker_hub:false
       ~job_docker_amd64:job_docker_amd64_test
       ~job_docker_arm64:job_docker_arm64_test

(* Register pipelines types. Pipelines types are used to generate
   workflow rules and includes of the files where the jobs of the
   pipeline is defined. At the moment, all these pipelines are defined
   manually in .yml, but will eventually be generated. *)
let () =
  (* Matches release tags, e.g. [v1.2.3] or [v1.2.3-rc4]. *)
  let release_tag_re = "/^v\\d+\\.\\d+(?:\\-rc\\d+)?$/" in
  (* Matches beta release tags, e.g. [v1.2.3-beta5]. *)
  let beta_release_tag_re = "/^v\\d+\\.\\d+\\-beta\\d*$/" in
  let open Rules in
  let open Pipeline in
  (* Matches either release tags or beta release tags, e.g. [v1.2.3],
     [v1.2.3-rc4] or [v1.2.3-beta5]. *)
  let has_any_release_tag =
    If.(has_tag_match release_tag_re || has_tag_match beta_release_tag_re)
  in
  let has_non_release_tag =
    If.(Predefined_vars.ci_commit_tag != null && not has_any_release_tag)
  in
  register "before_merging" If.(on_tezos_namespace && merge_request) ;
  register
    "latest_release"
    ~jobs:[job_docker_promote_to_latest ~ci_docker_hub:true]
    If.(on_tezos_namespace && push && on_branch "latest-release") ;
  register
    "latest_release_test"
    If.(not_on_tezos_namespace && push && on_branch "latest-release-test")
    ~jobs:[job_docker_promote_to_latest ~ci_docker_hub:false] ;
  register "master_branch" If.(on_tezos_namespace && push && on_branch "master") ;
  register
    "release_tag"
    If.(on_tezos_namespace && push && has_tag_match release_tag_re) ;
  register
    "beta_release_tag"
    If.(on_tezos_namespace && push && has_tag_match beta_release_tag_re) ;
  register
    "release_tag_test"
    If.(not_on_tezos_namespace && push && has_any_release_tag) ;
  register
    "non_release_tag"
    If.(on_tezos_namespace && push && has_non_release_tag) ;
  register
    "non_release_tag_test"
    If.(not_on_tezos_namespace && push && has_non_release_tag) ;
  register "schedule_extended_test" schedule_extended_tests

(* Split pipelines and writes image templates *)
let config =
  (* Split pipelines types into workflow and includes *)
  let workflow, includes = Pipeline.workflow_includes () in
  (* Write image templates.

     This is a temporary stop-gap and only necessary for jobs that are
     not define in OCaml. Once all jobs have been migrated, this can
     be removed. *)
  let image_templates_include =
    let filename = ".gitlab/ci/jobs/shared/images.yml" in
    let image_template (name, image_path) : string * Yaml.value =
      let name = ".image_template__" ^ name in
      (name, `O [("image", `String (Image.name image_path))])
    in
    let config : Yaml.value = `O (List.map image_template (Image.all ())) in
    Base.write_yaml ~header:Tezos_ci.header filename config ;
    {local = filename; rules = []}
  in
  let includes =
    image_templates_include
    :: {local = ".gitlab/ci/jobs/shared/templates.yml"; rules = []}
    :: includes
  in
  Pipeline.write () ;
  [
    Workflow workflow;
    Default default;
    Variables variables;
    Stages (Stage.to_string_list ());
    Job trigger;
    Include includes;
  ]

let () =
  let filename = Base.(project_root // ".gitlab-ci.yml") in
  To_yaml.to_file ~header:Tezos_ci.header ~filename config
