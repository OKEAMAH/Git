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

  let sanity = Stage.register "sanity"

  let build = Stage.register "build"

  let test = Stage.register "test"

  let test_coverage = Stage.register "test_coverage"

  let packaging = Stage.register "packaging"

  let doc = Stage.register "doc"

  let prepare_release = Stage.register "prepare_release"

  let publish_release_gitlab = Stage.register "publish_release_gitlab"

  let publish_release = Stage.register "publish_release"

  let publish_package_gitlab = Stage.register "publish_package_gitlab"

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
  let runtime_e2etest_dependencies =
    Image.register
      ~name:"runtime_e2etest_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-e2etest-dependencies--${build_deps_image_version}"

  let runtime_build_test_dependencies =
    Image.register
      ~name:"runtime_build_test_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-build-test-dependencies--${build_deps_image_version}"

  let runtime_build_dependencies =
    Image.register
      ~name:"runtime_build_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-build-dependencies--${build_deps_image_version}"

  let runtime_prebuild_dependencies =
    Image.register
      ~name:"runtime_prebuild_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-prebuild-dependencies--${build_deps_image_version}"

  let runtime_client_libs_dependencies =
    Image.register
      ~name:"runtime_client_libs_dependencies"
      ~image_path:
        "${build_deps_image_name}:runtime-client-libs-dependencies--${build_deps_image_version}"

  let rust_toolchain =
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

  let ci_release =
    Image.register
      ~name:"ci_release"
      ~image_path:"${CI_REGISTRY}/tezos/docker-images/ci-release:v1.1.0"

  let debian_bookworm =
    Image.register ~name:"debian_bookworm" ~image_path:"debian:bookworm"

  let debian_bullseye =
    Image.register ~name:"debian_bullseye" ~image_path:"debian:bullseye"

  let ubuntu_focal =
    Image.register
      ~name:"ubuntu_focal"
      ~image_path:"public.ecr.aws/lts/ubuntu:20.04_stable"

  let ubuntu_jammy =
    Image.register
      ~name:"ubuntu_jammy"
      ~image_path:"public.ecr.aws/lts/ubuntu:22.04_stable"

  let fedora_37 = Image.register ~name:"fedora_37" ~image_path:"fedora:37"

  let fedora_39 = Image.register ~name:"fedora_39" ~image_path:"fedora:39"

  let opam_ubuntu_focal =
    Image.register
      ~name:"opam_ubuntu_focal"
      ~image_path:"ocaml/opam:ubuntu-20.04"

  let opam_debian_bullseye =
    Image.register
      ~name:"opam_debian_bullseye"
      ~image_path:"ocaml/opam:debian-11"

  let hadolint =
    Image.register ~name:"hadolint" ~image_path:"hadolint/hadolint:2.9.3-debian"

  (* We specify the semgrep image by hash to avoid flakiness. Indeed, if we took the
     latest release, then an update in the parser or analyser could result in new
     errors being found even if the code doesn't change. This would place the
     burden for fixing the code on the wrong dev (the devs who happen to open an
     MR coinciding with the semgrep update rather than the dev who wrote the
     infringing code in the first place).
     Update the hash in scripts/semgrep/README.md too when updating it here
     Last update: 2022-01-03 *)
  let semgrep_agent =
    Image.register
      ~name:"semgrep_agent"
      ~image_path:"returntocorp/semgrep-agent:sha-c6cd7cf"
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

let job_append_variables variables (job : job) : job =
  let existing_variables = Option.value ~default:[] job.variables in
  if List.exists (Fun.flip List.mem existing_variables) variables then
    (* TODO: no need to complain if we're setting the same value *)
    failwith "[job_append_variables] attempting to set an already set variable" ;
  {job with variables = Some (existing_variables @ variables)}

let opt_join o1 o2 f =
  match (o1, o2) with
  | None, None -> None
  | Some x, None | None, Some x -> Some x
  | Some x, Some y -> Some (f x y)

let opt_either field o1 o2 =
  match (o1, o2) with
  | None, None -> None
  | Some x, None | None, Some x -> Some x
  | Some _, Some _ ->
      failwith
        (sf "[job_merge_artifacts] attempted to merge two [%s:] fields." field)

let max_when : when_artifact -> when_artifact -> when_artifact =
 fun w1 w2 ->
  match (w1, w2) with
  | Always, _ | _, Always | On_success, On_failure | On_failure, On_success ->
      Always
  | On_success, _ -> On_success
  | On_failure, _ -> On_failure

let merge_reports : reports -> reports -> reports =
 fun r1 r2 ->
  {
    dotenv = opt_either "artifacts:reports:dotenv" r1.dotenv r2.dotenv;
    junit = opt_either "artifacts:reports:junit" r1.junit r2.junit;
    coverage_report =
      opt_either
        "artifacts:reports:coverage_report"
        r1.coverage_report
        r2.coverage_report;
  }

let job_merge_artifacts (new_artifacts : artifacts) (job : job) : job =
  let artifacts =
    match job.artifacts with
    | None -> new_artifacts
    | Some {expire_in; paths; reports; when_; expose_as; name} ->
        (* This is necessarily inexact. E.g. the length of a day in
           seconds depends on leap seconds and stuff. However, this
           approximation is sufficient for the purpose of comparing
           intervals. *)
        let time_interval_to_seconds = function
          | Seconds n -> n
          | Minutes n -> n * 60
          | Hours n -> n * 60 * 60
          | Days n -> n * 24 * 60 * 60
          | Weeks n -> n * 7 * 24 * 60 * 60
          | Months n -> n * 7 * 24 * 60 * 60
          | Years n -> n * 365 * 7 * 24 * 60 * 60
        in
        let max_time_interval ti1 ti2 =
          if
            compare
              (time_interval_to_seconds ti1)
              (time_interval_to_seconds ti2)
            < 0
          then ti1
          else ti2
        in
        let expire_in =
          opt_join expire_in new_artifacts.expire_in max_time_interval
        in
        let paths = paths @ new_artifacts.paths in
        let reports = opt_join reports new_artifacts.reports merge_reports in
        let when_ = opt_join when_ new_artifacts.when_ max_when in
        (* There is no obvious way to join the [name:] and [expose_as:] fields.
           We'll prefer the right-most one. *)
        let expose_as =
          opt_join expose_as new_artifacts.expose_as (fun _ new_expose_as ->
              new_expose_as)
        in
        let name =
          opt_join name new_artifacts.name (fun _ new_name -> new_name)
        in
        {expire_in; paths; reports; when_; expose_as; name}
  in
  {job with artifacts = Some artifacts}

(* Coverage collection for OCaml using bisect_ppx consists of three parts:

   1. [job_enable_coverage_instrumentation]: configures dune to add
   [bisect_ppx] when compiling. This is done by
   [job_enable_coverage_instrumentation].

   2. [job_enable_coverage_output]: configures the runtime environment
   to activate the output of coverage traces and storing these as
   artifacts.

   3. Collecting coverage trace artifacts, producing a report using
   [bisect-ppx-report], storing the report as an artifact and exposing
   the collected coverage percentage to GitLab. This is facilitated by
   [job_enable_coverage_report] that setups the artifacts for the
   report.

   For integration tests, this means that we perform step 1. in build
   jobs, we do step 2. in test jobs and we do 3. in [unified_coverage]
   job. Unit tests are built and executed in the same jobs. There, we
   do 1. and 2. in the same job. *)
let bisect_file = "$CI_PROJECT_DIR/_coverage_output/"

let job_enable_coverage_instrumentation (job : job) =
  job_append_variables
    [("COVERAGE_OPTIONS", "--instrument-with bisect_ppx")]
    job

let job_enable_coverage_output ?(expire_in = Days 1) (job : job) =
  job
  (* Set the run-time environment variable that specifies the
     directory where coverage traces should be stored. *)
  |> job_append_variables [("BISECT_FILE", bisect_file)]
  (* Store the directory of coverage traces as an artifact. *)
  |> job_merge_artifacts
       (artifacts
          ~name:"coverage-files-$CI_JOB_ID"
          ~expire_in
          ~when_:On_success
          ["$BISECT_FILE"])

let job_enable_coverage_report job : job =
  {job with coverage = Some "/Coverage: ([^%]+%)/"}
  (* Set the run-time environment variable that specifies the
     directory where coverage traces have been received as artifacts
     and the Slack channel where corrupt traces are reported. *)
  |> job_append_variables
       [("BISECT_FILE", bisect_file); ("SLACK_COVERAGE_CHANNEL", "C02PHBE7W73")]
  (* Store the directory of the reports as well as the merged traces
     as an artifact. *)
  |> job_merge_artifacts
       (artifacts
          ~expose_as:"Coverage report"
          ~reports:
            (reports
               ~coverage_report:
                 {
                   coverage_format = Cobertura;
                   path = "_coverage_report/cobertura.xml";
                 }
               ())
          ~expire_in:(Days 15)
          ~when_:Always
          ["_coverage_report/"; "$BISECT_FILE"])

let enable_sccache ?(sccache_dir = "$CI_PROJECT_DIR/_sccache") job =
  job_append_variables
    [("SCCACHE_DIR", sccache_dir); ("RUSTC_WRAPPER", "sccache")]
    job

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

(* Used in [before_merging] pipeline. *)
let job_static_x86_64_experimental =
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

(* Used in external [before_merging] pipeline *)
let _job_docker_amd64_test_manual : job =
  job_docker_build ~external_:true ~arch:Amd64 Test_manual

(* Used in external [before_merging] pipeline *)
let _job_docker_arm64_test_manual : job =
  job_docker_build ~external_:true ~arch:Arm64 Test_manual

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

type bin_package_target = Dpkg | Rpm

let job_build_bin_package ?(manual = false) ~arch ~target () : job =
  let arch_string =
    match arch with Tezos_ci.Amd64 -> "amd64" | Arm64 -> "arm64"
  in
  let target_string = match target with Dpkg -> "dpkg" | Rpm -> "rpm" in
  let name = sf "oc.build:%s:%s" target_string arch_string in
  let image =
    match target with Dpkg -> Images.debian_bookworm | Rpm -> Images.fedora_39
  in
  let artifacts =
    let artifact_path =
      "octez-*." ^ match target with Dpkg -> "deb" | Rpm -> "rpm"
    in
    artifacts
      ~expire_in:(Days 1)
      ~when_:On_success
      ~name:"${TARGET}-$ARCH-$CI_COMMIT_REF_SLUG"
      [artifact_path]
  in
  let before_script =
    before_script
      ~source_version:true
      (match target with
      | Dpkg ->
          [
            "apt update";
            "apt-get install -y rsync git m4 build-essential patch unzip wget \
             opam jq bc autoconf cmake libev-dev libffi-dev libgmp-dev \
             libhidapi-dev pkg-config zlib1g-dev";
          ]
      | Rpm ->
          [
            "dnf update -y";
            "dnf install -y libev-devel gmp-devel hidapi-devel libffi-devel \
             zlib-devel libpq-devel m4 perl git pkg-config rpmdevtools \
             python3-devel python3-setuptools wget opam rsync which cargo \
             autoconf mock systemd systemd-rpm-macros cmake python3-wheel \
             python3-tox-current-env gcc-c++";
          ])
  in
  let stage = if manual then Stages.manual else Stages.build in
  let when_ = if manual then Some Manual else None in
  job
    ?when_
    ~name
    ~arch
    ~image
    ~stage
    ~dependencies:(Dependent [])
    ~variables:
      [
        ("TARGET", target_string);
        ("OCTEZ_PKGMAINTAINER", "nomadic-labs");
        ("BLST_PORTABLE", "yes");
        ("ARCH", arch_string);
      ]
    ~artifacts
    ~before_script
    [
      "wget https://sh.rustup.rs/rustup-init.sh";
      "chmod +x rustup-init.sh";
      "./rustup-init.sh --profile minimal --default-toolchain  \
       $recommended_rust_version -y";
      ". $HOME/.cargo/env";
      "export OPAMYES=\"true\"";
      "opam init --bare --disable-sandboxing";
      "make build-deps";
      "eval $(opam env)";
      "make $TARGET";
    ]

let job_build_dpkg_amd64 =
  job_build_bin_package ~target:Dpkg ~arch:Tezos_ci.Amd64 ()

let job_build_rpm_amd64 =
  job_build_bin_package ~target:Rpm ~arch:Tezos_ci.Amd64 ()

let _job_build_bin_packages_manual =
  let manual = true in
  let arch = Tezos_ci.Amd64 in
  jobs_external ~path:"build/bin_packages_manual.yml"
  @@ [
       job_build_bin_package ~manual ~arch ~target:Dpkg ();
       job_build_bin_package ~manual ~arch ~target:Rpm ();
     ]

let _job_build_rpm_amd64 =
  job_build_bin_package ~manual:true ~target:Rpm ~arch:Tezos_ci.Amd64

(** Type of release tag pipelines.

    The semantics of the type is summed up in this table:

   |                       | Release_tag | Beta_release_tag | Non_release_tag |
   |-----------------------+-------------+------------------+-----------------|
   | GitLab release type   | Release     | Release          | Create          |
   | Experimental binaries | No          | No               | No              |
   | Docker build type     | Release     | Release          | Release         |
   | Publishes to opam     | Yes         | No               | No              |

    - All release tag pipelines types publish [Release] type Docker builds.
    - No release tag pipelines include experimental binaries.
    - [Release_tag] and [Beta_release_tag] pipelines creates GitLab
    and publishes releases. [Non_release_tag] pipelines creates the
    GitLab release but do not publish them.
    - Only [Release_tag] pipelines publish to opam. *)
type release_tag_pipeline_type =
  | Release_tag
  | Beta_release_tag
  | Non_release_tag

(** Create a release tag pipeline of type {!release_tag_pipeline_type}.

    If [test] is true (default is [false]), then the Docker images are
    built of the [Test] type and are published to the GitLab registry
    instead of Docker hub. *)
let release_tag_pipeline ?(test = false) release_tag_pipeline_type =
  let job_docker_amd64 =
    job_docker_build ~arch:Amd64 (if test then Test else Release)
  in
  let job_docker_arm64 =
    job_docker_build ~arch:Arm64 (if test then Test else Release)
  in
  let job_docker_merge =
    job_docker_merge_manifests
      ~ci_docker_hub:(not test)
      ~job_docker_amd64
      ~job_docker_arm64
  in
  let job_static_arm64_release =
    job_build_static_binaries ~arch:Arm64 ~release:true ()
  in
  let job_static_x86_64_release =
    job_build_static_binaries ~arch:Amd64 ~release:true ~needs_trigger:true ()
  in
  let job_gitlab_release ~dependencies : job =
    job
      ~image:Images.ci_release
      ~stage:Stages.publish_release_gitlab
      ~interruptible:false
      ~dependencies
      ~name:"gitlab:release"
      ["./scripts/ci/gitlab-release.sh"]
  in
  let job_gitlab_publish ~dependencies : job =
    job
      ~image:Images.ci_release
      ~stage:Stages.publish_package_gitlab
      ~interruptible:false
      ~dependencies
      ~name:"gitlab:publish"
      ["${CI_PROJECT_DIR}/scripts/ci/create_gitlab_package.sh"]
  in
  let job_opam_release : job =
    job
      ~image:Images.runtime_build_test_dependencies
      ~stage:Stages.publish_release
      ~interruptible:false
      ~name:"opam:release"
      ["./scripts/ci/opam-release.sh"]
  in
  let job_gitlab_release_or_publish =
    let dependencies =
      Dependent
        [
          Artifacts job_static_x86_64_release;
          Artifacts job_static_arm64_release;
          Artifacts job_build_dpkg_amd64;
          Artifacts job_build_rpm_amd64;
        ]
    in
    match release_tag_pipeline_type with
    | Non_release_tag -> job_gitlab_publish ~dependencies
    | _ -> job_gitlab_release ~dependencies
  in
  [
    job_static_x86_64_release;
    job_static_arm64_release;
    job_docker_amd64;
    job_docker_arm64;
    job_build_dpkg_amd64;
    job_build_rpm_amd64;
    job_docker_merge;
    job_gitlab_release_or_publish;
  ]
  @
  match (test, release_tag_pipeline_type) with
  | false, Release_tag -> [job_opam_release]
  | _ -> []

let arm64_build_extra =
  [
    "src/bin_tps_evaluation/main_tps_evaluation.exe";
    "src/bin_octogram/octogram_main.exe tezt/tests/main.exe";
  ]

let amd64_build_extra =
  [
    "src/bin_tps_evaluation/main_tps_evaluation.exe";
    "src/bin_octogram/octogram_main.exe";
    "tezt/tests/main.exe";
    "contrib/octez_injector_server/octez_injector_server.exe";
  ]

let job_build_dynamic_binaries ?rules ~arch ?(external_ = false)
    ?(release = false) ?(needs_trigger = false) () =
  let arch_string =
    match arch with Tezos_ci.Amd64 -> "x86_64" | Arm64 -> "arm64"
  in
  let name =
    sf
      "oc.build_%s-%s"
      arch_string
      (if release then "released" else "exp-dev-extra")
  in
  let executable_files =
    if release then "script-inputs/released-executables"
    else "script-inputs/experimental-executables script-inputs/dev-executables"
  in
  let build_extra =
    match (release, arch) with
    | true, _ -> None
    | false, Amd64 -> Some amd64_build_extra
    | false, Arm64 -> Some arm64_build_extra
  in
  let variables =
    [
      ("ARCH", arch_string);
      ("EXECUTABLE_FILES", executable_files);
      (* We fix the value of GIT_{SHORTREF,DATETIME,VERSION} (these are
         read by src/lib_version and output by the binaries `--version`
         option). Fixing these values on development builds improves
         cache usage. *)
      ("GIT_SHORTREF", "00000000");
      ("GIT_DATETIME", "1970-01-01 00:00:00 +0000%");
      ("GIT_VERSION", "dev");
    ]
    @
    match build_extra with
    | Some build_extra -> [("BUILD_EXTRA", String.concat " " build_extra)]
    | None -> []
  in
  let artifacts =
    artifacts
      ~name:"build-$ARCH-$CI_COMMIT_REF_SLUG"
      ~when_:On_success
      ~expire_in:(Days 1)
      (* TODO: [paths] can be refined based on [release] *)
      [
        "octez-*";
        "src/proto_*/parameters/*.json";
        "_build/default/src/lib_protocol_compiler/bin/main_native.exe";
        "_build/default/tezt/tests/main.exe";
        "_build/default/contrib/octez_injector_server/octez_injector_server.exe";
      ]
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
      ?rules
      ~stage:Stages.build
      ~arch
      ~name
      ~image:Images.runtime_build_dependencies
      ~before_script:
        (before_script
           ~take_ownership:true
           ~source_version:true
           ~eval_opam:true
           [])
      ~variables
      ~dependencies
      ~artifacts
      ["./scripts/ci/build_full_unreleased.sh"]
  in
  let job =
    (* Disable coverage for arm64 *)
    if arch = Amd64 then job |> job_enable_coverage_instrumentation else job
  in
  if external_ then job_external job else job

let build_arm_rules =
  [
    job_rule ~if_:Rules.schedule_extended_tests ~when_:Always ();
    job_rule ~if_:Rules.(has_mr_label "ci--arm64") ~when_:On_success ();
    job_rule
      ~changes:["src/**/*"; ".gitlab/**/*"; ".gitlab-ci.yml"]
      ~when_:Manual
      ~allow_failure:Yes
      ();
  ]

let changeset_octez =
  [
    "src/**/*";
    "etherlink/**/*";
    "tezt/**/*";
    ".gitlab/**/*";
    ".gitlab-ci.yml";
    "michelson_test_scripts/**/*";
    "tzt_reference_test_suite/**/*";
  ]

let build_x86_64_rules =
  [
    job_rule ~changes:changeset_octez ();
    job_rule ~if_:Rules.triggered_by_marge_bot ();
  ]

(* Write external files for build_{arm64, x86_64} jobs *)

(* Used in external [before_merging] pipelines *)
let job_build_arm64_release =
  job_build_dynamic_binaries
    ~external_:true
    ~arch:Arm64
    ~needs_trigger:false
    ~release:true
    ~rules:build_arm_rules
    ()

(* Used in external [before_merging] pipelines *)
let job_build_arm64_exp_dev_extra =
  job_build_dynamic_binaries
    ~external_:true
    ~arch:Arm64
    ~needs_trigger:false
    ~release:false
    ~rules:build_arm_rules
    ()

(* Used in external [before_merging] pipelines *)
let job_build_x86_64_release =
  job_build_dynamic_binaries
    ~external_:true
    ~arch:Amd64
    ~needs_trigger:true
    ~release:true
    ~rules:build_x86_64_rules
    ()

(* Used in [before_merging] and [schedule_extended_test] pipelines *)
let job_build_x86_64_exp_dev_extra =
  job_build_dynamic_binaries
    ~external_:true
    ~arch:Amd64
    ~needs_trigger:true
    ~release:false
    ~rules:build_x86_64_rules
    ()

let changeset_octez_docs =
  [
    "scripts/**/*/";
    "script-inputs/**/*/";
    "src/**/*";
    "tezt/**/*";
    "vendors/**/*";
    "dune";
    "dune-project";
    "dune-workspace";
    "docs/**/*";
    ".gitlab/**/*";
    ".gitlab-ci.yml";
  ]

(* The set of [changes:] that trigger opam jobs *)
let changeset_opam_jobs =
  [
    "**/dune";
    "**/dune.inc";
    "**/*.dune.inc";
    "**/dune-project";
    "**/dune-workspace";
    "**/*.opam";
    ".gitlab/ci/jobs/packaging/opam:prepare.yml";
    ".gitlab/ci/jobs/packaging/opam_package.yml";
    "manifest/manifest.ml";
    "manifest/main.ml";
    "scripts/opam-prepare-repo.sh";
    "scripts/version.sh";
  ]

(* We *)
type opam_package_group = Executable | All

type opam_package = {
  name : string;
  group : opam_package_group;
  batch_index : int;
}

let opam_rules ~only_marge_bot ?batch_index () =
  let when_ =
    match batch_index with
    | Some batch_index -> Delayed (Minutes batch_index)
    | None -> On_success
  in
  [
    job_rule ~if_:Rules.schedule_extended_tests ~when_ ();
    job_rule ~if_:(Rules.has_mr_label "ci--opam") ~when_ ();
    job_rule
      ~if_:
        (if only_marge_bot then
         If.(Rules.merge_request && Rules.triggered_by_marge_bot)
        else Rules.merge_request)
      ~changes:changeset_opam_jobs
      ~when_
      ();
    job_rule ~when_:Never ();
  ]

let job_opam_prepare : job =
  job_external
  @@ job
       ~name:"opam:prepare"
       ~image:Images.runtime_prebuild_dependencies
       ~stage:Stages.packaging
       ~dependencies:(Dependent [Job trigger])
       ~before_script:(before_script ~eval_opam:true [])
       ~artifacts:(artifacts ["_opam-repo-for-release/"])
       ~rules:(opam_rules ~only_marge_bot:false ~batch_index:1 ())
       [
         "git init _opam-repo-for-release";
         "./scripts/opam-prepare-repo.sh dev ./ ./_opam-repo-for-release";
         "git -C _opam-repo-for-release add packages";
         "git -C _opam-repo-for-release commit -m \"tezos packages\"";
       ]

let job_opam_package {name; group; batch_index} : job =
  (* We store caches in [_build] for two reasons: (1) the [_build]
     folder is excluded from opam's rsync. (2) gitlab ci cache
     requires that cached files are in a sub-folder of the checkout. *)
  enable_sccache ~sccache_dir:"$CI_PROJECT_DIR/_build/_sccache"
  @@ job
       ~name:("opam:" ^ name)
       ~image:Images.runtime_prebuild_dependencies
       ~stage:Stages.packaging
         (* FIXME: https://gitlab.com/nomadic-labs/tezos/-/issues/663
            FIXME: https://gitlab.com/nomadic-labs/tezos/-/issues/664
            At the time of writing, the opam tests were quite flaky.
            Therefore, a retry was added. This should be removed once the
            underlying tests have been fixed. *)
       ~retry:2
       ~dependencies:(Dependent [Artifacts job_opam_prepare])
       ~rules:(opam_rules ~only_marge_bot:(group = All) ~batch_index ())
       ~variables:
         [
           (* See [.gitlab-ci.yml] for details on [RUNTEZTALIAS] *)
           ("RUNTEZTALIAS", "true");
           ("package", name);
         ]
       ~before_script:(before_script ~eval_opam:true [])
       [
         "opam remote add dev-repo ./_opam-repo-for-release";
         "opam install --yes ${package}.dev";
         "opam reinstall --yes --with-test ${package}.dev";
       ]
       (* Stores logs in opam_logs for artifacts and outputs an excerpt on
          failure. [after_script] runs in a separate shell and so requires
          a second opam environment initialization. *)
       ~after_script:
         [
           "eval $(opam env)";
           "OPAM_LOGS=opam_logs ./scripts/ci/opam_handle_output.sh";
         ]
       ~artifacts:(artifacts ~expire_in:(Weeks 1) ~when_:Always ["opam_logs/"])
       ~cache:[{key = "opam-sccache"; paths = ["_build/_sccache"]}]

let ci_opam_package_tests = "script-inputs/ci-opam-package-tests"

let read_opam_packages =
  Fun.flip List.filter_map (read_lines_from_file ci_opam_package_tests)
  @@ fun line ->
  let fail () =
    failwith
      (sf "failed to parse %S: invalid line: %S" ci_opam_package_tests line)
  in
  if line = "" then None
  else
    match String.split_on_char '\t' line with
    | [name; group; batch_index] ->
        let batch_index =
          match int_of_string_opt batch_index with
          | Some i -> i
          | None -> fail ()
        in
        let group =
          match group with "exec" -> Executable | "all" -> All | _ -> fail ()
        in
        Some {name; group; batch_index}
    | _ -> fail ()

let make_opam_packages (packages : opam_package list) : job list =
  let jobs = List.map job_opam_package packages in
  jobs_external ~path:"packaging/opam_package.yml" jobs

let jobs_opam_package : job list = make_opam_packages read_opam_packages

let enable_kernels job =
  job_append_variables
    [
      ("CC", "clang");
      ("CARGO_HOME", "$CI_PROJECT_DIR/cargo");
      ("NATIVE_TARGET", "x86_64-unknown-linux-musl");
    ]
    job

let job_build_kernels : job =
  job_external @@ enable_kernels @@ enable_sccache
  @@ job
       ~name:"oc.build_kernels"
       ~image:Images.rust_toolchain
       ~stage:Stages.build
       ~dependencies:(Dependent [Job trigger])
       ~rules:[job_rule ~changes:changeset_octez ()]
       ["make -f kernels.mk build"]
       ~artifacts:
         (artifacts
            ~name:"build-kernels-$CI_COMMIT_REF_SLUG"
            ~expire_in:(Days 1)
            ~when_:On_success
            [
              "evm_kernel.wasm";
              "smart-rollup-installer";
              "sequenced_kernel.wasm";
              "tx_kernel.wasm";
              "tx_kernel_dal.wasm";
              "dal_echo_kernel.wasm";
              "risc-v-sandbox";
              "risc-v-dummy.elf";
              "src/risc_v/tests/inline_asm/rv64-inline-asm-tests";
            ])
       ~cache:
         [
           {key = "kernels"; paths = ["cargo/"]};
           {key = "kernels-sccache"; paths = ["_sccache"]};
         ]

type install_octez_distribution = Ubuntu_focal | Ubuntu_jammy | Fedora_37

let all_install_octez_distribution = [Ubuntu_focal; Ubuntu_jammy; Fedora_37]

let image_of_distribution = function
  | Ubuntu_focal -> Images.ubuntu_focal
  | Ubuntu_jammy -> Images.ubuntu_jammy
  | Fedora_37 -> Images.fedora_37

let jobs_install_octez : job list =
  let changeset_install_jobs =
    ["docs/introduction/install*.sh"; "docs/introduction/compile*.sh"]
  in
  let install_octez_rules =
    [
      job_rule ~if_:Rules.schedule_extended_tests ~when_:Always ();
      job_rule
        ~if_:Rules.merge_request
        ~changes:changeset_install_jobs
        ~when_:On_success
        ();
      job_rule ~when_:Manual ~allow_failure:Yes ();
    ]
  in
  let dependencies = Dependent [Job trigger] in
  let job_install_bin ?(rc = false) distribution =
    let distribution_string =
      match distribution with
      | Ubuntu_focal | Ubuntu_jammy -> "ubuntu"
      | Fedora_37 -> "fedora"
    in
    let name : string =
      sf
        "oc.install_%s_%s_%s"
        (if rc then "bin_rc" else "bin")
        distribution_string
        (match distribution with
        | Ubuntu_focal -> "focal"
        | Ubuntu_jammy -> "jammy"
        | Fedora_37 -> "37")
    in
    let script =
      sf "./docs/introduction/install-bin-%s.sh" distribution_string
      ^ if rc then " rc" else ""
    in
    job
      ~name
      ~image:(image_of_distribution distribution)
      ~dependencies
      ~rules:install_octez_rules
      ~stage:Stages.test
      [script]
  in
  let job_install_opam_focal =
    job
      ~name:"oc.install_opam_focal"
      ~image:Images.opam_ubuntu_focal
      ~dependencies
      ~when_:Manual (* temporarily disable until these jobs are optimized *)
      ~allow_failure:Yes
      ~stage:Stages.test
      ~variables:[("OPAMJOBS", "4")]
      ["./docs/introduction/install-opam.sh"]
  in
  let job_compile_sources_bullseye ~name ~project ~branch =
    job
      ~name
      ~image:Images.opam_debian_bullseye
      ~dependencies
      ~rules:install_octez_rules
      ~stage:Stages.test
      [sf "./docs/introduction/compile-sources.sh %s %s" project branch]
  in
  jobs_external ~path:"test/install_octez.yml"
  (* Test installing binary / binary RC distributions in all distributions *)
  @@ List.map job_install_bin all_install_octez_distribution
  @ List.map (job_install_bin ~rc:true) all_install_octez_distribution
  (* Test installing through opam *)
  @ [job_install_opam_focal]
  (* Test compiling from source *)
  @ [
      (* Test compiling the [latest-release] branch on Bullseye *)
      job_compile_sources_bullseye
        ~name:"oc.compile_release_sources_bullseye"
        ~project:"tezos/tezos"
        ~branch:"latest-release";
      (* Test compiling the [master] branch on Bullseye *)
      job_compile_sources_bullseye
        ~name:"oc.compile_sources_bullseye"
        ~project:"${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH:-tezos/tezos}"
        ~branch:"${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-master}";
    ]

(* Fetch records for Tezt generated on the last merge request pipeline
   on the most recently merged MR and makes them available in artifacts
   for future merge request pipelines. *)
let job_tezt_fetch_records : job =
  job_external
  @@ job
       ~name:"oc.tezt:fetch-records"
       ~image:Images.runtime_build_dependencies
       ~stage:Stages.build
       ~before_script:
         (before_script
            ~take_ownership:true
            ~source_version:true
            ~eval_opam:true
            [])
       ~rules:[job_rule ~changes:changeset_octez ()]
       [
         "dune exec scripts/ci/update_records/update.exe -- --log-file \
          tezt-fetch-records.log --test-arg from=last-merged-pipeline --info";
       ]
       ~after_script:["./scripts/ci/filter_corrupted_records.sh"]
         (* Allow failure of this job, since Tezt can use the records
            stored in the repo as backup for balancing. *)
       ~allow_failure:Yes
       ~artifacts:
         (artifacts
            ~expire_in:(Hours 4)
            ~when_:Always
            [
              "tezt-fetch-records.log";
              "tezt/records/*.json";
              (* Keep broken records for debugging *)
              "tezt/records/*.json.broken";
            ])

let job_tezt ?rules ?parallel ?(tags = ["gcp_tezt"]) ~name ~tezt_tests
    ?(retry = 2) ?(tezt_retry = 1) ?(tezt_parallel = 1) ?(tezt_variant = "")
    ?(before_script = before_script ~source_version:true ~eval_opam:true [])
    ~dependencies () : job =
  let variables =
    [
      ("JUNIT", "tezt-junit.xml");
      ("TEZT_VARIANT", tezt_variant);
      ("TESTS", tezt_tests);
      ("TEZT_RETRY", string_of_int tezt_retry);
      ("TEZT_PARALLEL", string_of_int tezt_parallel);
    ]
  in
  let artifacts =
    artifacts
      ~name:("coverage-files-" ^ Predefined_vars.(show ci_job_id))
      ~reports:(reports ~junit:"$JUNIT" ())
      [
        "tezt.log";
        "tezt-*.log";
        "tezt-results-${CI_NODE_INDEX}${TEZT_VARIANT}.json";
        "$JUNIT";
      ]
      (* The record artifacts [tezt-results-$CI_NODE_INDEX.json]
         should be stored for as long as a given commit on master is
         expected to be HEAD in order to support auto-balancing. At
         the time of writing, we have approximately 6 merges per day,
         so 1 day should more than enough. However, we set it to 3
         days to keep records over the weekend. The tezt artifacts
         (including records and coverage) take up roughly 2MB /
         job. Total artifact storage becomes [N*P*T*W] where [N] is
         the days of retention (3 atm), [P] the number of pipelines
         per day (~200 atm), [T] the number of Tezt jobs per pipeline
         (60) and [W] the artifact size per tezt job (2MB). This makes
         35GB which is less than 0.5% than our
         {{:https://gitlab.com/tezos/tezos/-/artifacts}total artifact
         usage}. *)
      ~expire_in:(Days 3)
      ~when_:Always
  in
  let print_variables =
    [
      "TESTS";
      "JUNIT";
      "CI_NODE_INDEX";
      "CI_NODE_TOTAL";
      "TEZT_PARALLEL";
      "TEZT_VARIANT";
    ]
  in
  let retry = if retry = 0 then None else Some retry in
  job
    ~image:Images.runtime_e2etest_dependencies
    ~name
    ?parallel
    ~tags
    ~stage:Stages.test
    ?rules
    ~artifacts
    ~variables
    ~dependencies
    ?retry
    ~before_script
    [
      (* Print [print_variables] in a shell-friendly manner for easier debugging *)
      "echo \""
      ^ String.concat
          " "
          (List.map (fun var -> sf {|%s=\"${%s}\"|} var var) print_variables)
      ^ "\"";
      (* For Tezt tests, there are multiple timeouts:
         - --global-timeout is the internal timeout of Tezt, which only works if tests
           are cooperative;
         - the "timeout" command, which we set to send SIGTERM to Tezt 60s after --global-timeout
           in case tests are not cooperative;
         - the "timeout" command also sends SIGKILL 60s after having sent SIGTERM in case
           Tezt is still stuck;
         - the CI timeout.
         The use of the "timeout" command is to make sure that Tezt eventually exits,
         because if the CI timeout is reached, there are no artefacts,
         and thus no logs to investigate.
         See also: https://gitlab.com/gitlab-org/gitlab/-/issues/19818 *)
      "./scripts/ci/exit_code.sh timeout -k 60 1860 ./scripts/ci/exit_code.sh \
       _build/default/tezt/tests/main.exe ${TESTS} --color --log-buffer-size \
       5000 --log-file tezt.log --global-timeout 1800 \
       --on-unknown-regression-files fail --junit ${JUNIT} --from-record \
       tezt/records --job ${CI_NODE_INDEX:-1}/${CI_NODE_TOTAL:-1} --record \
       tezt-results-${CI_NODE_INDEX}${TEZT_VARIANT}.json --job-count \
       ${TEZT_PARALLEL:-3} --retry ${TEZT_RETRY:-1}";
      "./scripts/ci/merge_coverage.sh";
    ]

let job_documentation_linkcheck =
  job_external
  @@ job
       ~name:"documentation:linkcheck"
       ~image:Images.runtime_build_test_dependencies
       ~stage:Stages.doc
       ~dependencies:(Dependent [])
       ~rules:
         [
           job_rule ~if_:Rules.schedule_extended_tests ~when_:Always ();
           job_rule ~if_:(Rules.has_mr_label "ci--docs") ();
           job_rule ~when_:Manual ();
         ]
       ~before_script:
         (before_script
            ~source_version:true
            ~eval_opam:true
            ~init_python_venv:true
            [])
       ~allow_failure:Yes
       ["make all"; "make -C docs redirectcheck"; "make -C docs linkcheck"]

let job_install_python ~name ~image =
  job
    ~name
    ~image
    ~stage:Stages.doc
    ~dependencies:(Dependent [Job trigger])
    ~rules:
      [
        job_rule ~if_:Rules.schedule_extended_tests ~when_:Always ();
        job_rule
          ~if_:Rules.merge_request
          ~changes:["docs/developer/install-python-debian-ubuntu.sh"]
          ~when_:On_success
          ();
        job_rule ~if_:(Rules.has_mr_label "ci--docs") ();
        job_rule ~when_:Manual ~allow_failure:Yes ();
      ]
    [
      "./docs/developer/install-python-debian-ubuntu.sh \
       ${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH:-tezos/tezos} \
       ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-master}";
    ]

let jobs_install_python =
  jobs_external
    ~path:"doc/oc.install_python.yml"
    [
      job_install_python
        ~name:"oc.install_python_focal"
        ~image:Images.ubuntu_focal;
      job_install_python
        ~name:"oc.install_python_jammy"
        ~image:Images.ubuntu_jammy;
      job_install_python
        ~name:"oc.install_python_bullseye"
        ~image:Images.debian_bullseye;
    ]

let _job_sanity_ci =
  job_external
  @@ job
       ~name:"sanity_ci"
       ~image:Images.runtime_build_dependencies
       ~stage:Stages.sanity
       ~before_script:(before_script ~take_ownership:true ~eval_opam:true [])
       [
         "make -C manifest check";
         "./scripts/lint.sh --check-gitlab-ci-yml";
         (* Check that the opam-repo images' Alpine version corresponds to
            the value in scripts/version.sh. *)
         "./scripts/ci/check_alpine_version.sh";
         (* Check that .gitlab-ci.yml is up to date. *)
         "make -C ci check";
       ]

let changeset_docker_files = ["build.Dockerfile"; "Dockerfile"]

let _job_docker_hadolint =
  job_external
  @@ job
       ~name:"docker:hadolint"
       ~image:Images.hadolint
       ~stage:Stages.sanity
       ~rules:
         [
           job_rule
             ~if_:Rules.merge_request
             ~changes:changeset_docker_files
             ~allow_failure:Yes
             ();
         ]
       ["hadolint build.Dockerfile"; "hadolint Dockerfile"]

let changeset_ocaml_files =
  ["src/**/*"; "tezt/**/*"; ".gitlab/**/*"; ".gitlab-ci.yml"; "devtools/**/*"]

let _job_ocaml_check =
  job_external
  @@ job
       ~name:"ocaml-check"
       ~image:Images.runtime_build_dependencies
       ~stage:Stages.build
       ~dependencies:(Dependent [Job trigger])
       ~rules:[job_rule ~changes:changeset_ocaml_files ()]
       ~before_script:
         (before_script
            ~take_ownership:true
            ~source_version:true
            ~eval_opam:true
            [])
       ["dune build @check"]

(* Misc checks *)

(* The linting job runs over the set of [source_directories]
   defined in [scripts/lint.sh] that must be included here: *)
let changeset_lint_files =
  [
    "src/**/*";
    "tezt/**/*";
    "devtools/**/*";
    "scripts/**/*";
    "docs/**/*";
    "contrib/**/*";
    "etherlink/**/*";
    ".gitlab-ci.yml";
    ".gitlab/**/*";
  ]

let _job_oc_misc_checks =
  job_external
  @@ job
       ~name:"oc.misc_checks"
       ~image:Images.runtime_build_test_dependencies
       ~stage:Stages.test
       ~dependencies:(Dependent [Job trigger])
       ~rules:[job_rule ~changes:changeset_lint_files ()]
       ~before_script:
         (before_script
            ~take_ownership:true
            ~source_version:true
            ~eval_opam:true
            ~init_python_venv:true
            [])
       [
         "./scripts/ci/lint_misc_check.sh";
         "scripts/check_wasm_pvm_regressions.sh check";
       ]

let _job_oc_commit_titles =
  job_external
  @@ job
       ~name:"commit_titles"
       ~image:Images.runtime_prebuild_dependencies
       ~stage:Stages.test
       ~dependencies:(Dependent [Job trigger])
         (* ./scripts/ci/check_commit_messages.sh exits with code 65 when a git history contains invalid commits titles in situations where that is allowed. *)
       ["./scripts/ci/check_commit_messages.sh || exit $?"]
       ~allow_failure:(With_exit_codes [65])

let changeset_kaitai_files =
  ["src/**/*"; "contrib/*kaitai*/**/*"; ".gitlab/**/*"; ".gitlab-ci.yml"]

(* check that ksy files are still up-to-date with octez *)
let job_kaitai_checks =
  job_external
  @@ job
       ~name:"kaitai_checks"
       ~image:Images.runtime_build_dependencies
       ~stage:Stages.test
       ~dependencies:(Dependent [Job job_build_x86_64_release])
       ~rules:[job_rule ~changes:changeset_kaitai_files ()]
       ~before_script:(before_script ~source_version:true ~eval_opam:true [])
       [
         "make -C ${CI_PROJECT_DIR} check-kaitai-struct-files || (echo 'Octez \
          encodings and Kaitai files seem to be out of sync. You might need to \
          run `make check-kaitai-struct-files` and commit the resulting diff.' \
          ; false)";
       ]

(* check that ksy files are still up-to-date with octez *)
let _job_kaitai_e2e_checks =
  job_external
  @@ job
       ~name:"kaitai_e2e_checks"
       ~image:Images.runtime_client_libs_dependencies
       ~stage:Stages.test
       ~dependencies:(Dependent [Job job_kaitai_checks])
       ~rules:[job_rule ~changes:changeset_kaitai_files ()]
       ~before_script:
         (before_script ~source_version:true ~install_js_deps:true [])
       [
         "./contrib/kaitai-struct-files/scripts/kaitai_e2e.sh \
          contrib/kaitai-struct-files/files contrib/kaitai-struct-files/input";
       ]

let changeset_lift_limits_patch =
  [
    "src/bin_tps_evaluation/lift_limits.patch";
    "src/proto_alpha/lib_protocol/main.ml";
    ".gitlab/**/*";
    ".gitlab-ci.yml";
  ]

let _job_oc_check_lift_limits_patch =
  job_external
  @@ job
       ~name:"oc.check_lift_limits_patch"
       ~image:Images.runtime_build_dependencies
       ~stage:Stages.test
       ~dependencies:(Dependent [Job trigger])
       ~rules:[job_rule ~changes:changeset_lift_limits_patch ()]
       ~before_script:(before_script ~source_version:true ~eval_opam:true [])
       [
         (* Check that the patch only modifies the
            src/proto_alpha/lib_protocol. If not, the rules above have to be
            updated. *)
         "[ $(git apply --numstat src/bin_tps_evaluation/lift_limits.patch | \
          cut -f3) = \"src/proto_alpha/lib_protocol/main.ml\" ]";
         "git apply src/bin_tps_evaluation/lift_limits.patch";
         "dune build @src/proto_alpha/lib_protocol/check";
       ]

let _job_misc_opam_checks =
  job_external
  @@ job
       ~name:"misc_opam_checks"
       ~image:Images.runtime_build_dependencies
       ~stage:Stages.test
       ~retry:2
       ~dependencies:(Dependent [Job trigger])
       ~rules:[job_rule ~changes:changeset_octez ()]
       ~before_script:(before_script ~source_version:true ~eval_opam:true [])
       [
         (* checks that all deps of opam packages are already installed *)
         "./scripts/opam-check.sh";
       ]
       ~artifacts:
         (artifacts ~when_:Always ["opam_repo.patch"] ~expire_in:(Days 1))

let changeset_semgrep_files =
  [
    "src/**/*";
    "tezt/**/*";
    "devtools/**/*";
    "scripts/semgrep/**/*";
    ".gitlab/**/*";
    ".gitlab-ci.yml";
  ]

let _job_semgrep =
  job_external
  @@ job
       ~name:"oc.semgrep"
       ~image:Images.semgrep_agent
       ~stage:Stages.test
       ~dependencies:(Dependent [Job trigger])
       ~rules:[job_rule ~changes:changeset_semgrep_files ()]
       [
         "echo \"OCaml code linting. For information on how to reproduce \
          locally, check out scripts/semgrep/README.md\"";
         "sh ./scripts/semgrep/lint-all-ocaml-sources.sh";
       ]

let changeset_unit_test_arm64 = ["src/**/*"; ".gitlab/**/*"; ".gitlab-ci.yml"]

let _jobs_unit_tests =
  let build_dependencies = function
    | Amd64 ->
        Dependent
          [Job job_build_x86_64_release; Job job_build_x86_64_exp_dev_extra]
    | Arm64 ->
        Dependent
          [Job job_build_arm64_release; Job job_build_arm64_exp_dev_extra]
  in
  let unit_test ?(image = Images.runtime_build_dependencies) ?timeout ?parallel
      ~arch ~name ?(enable_coverage = true)
      ?(rules = [job_rule ~changes:changeset_octez ()]) ~make_targets () : job =
    let arch_string =
      match arch with Tezos_ci.Amd64 -> "x86_64" | Arm64 -> "arm64"
    in
    let script =
      ["make $MAKE_TARGETS"]
      @ if enable_coverage then ["./scripts/ci/merge_coverage.sh"] else []
    in
    let dependencies = build_dependencies arch in
    let variables =
      [("ARCH", arch_string); ("MAKE_TARGETS", String.concat " " make_targets)]
      @
      (* When parallel is set to non-zero (translating to the
         [parallel:] clause), set the variable
         [DISTRIBUTE_TESTS_TO_PARALLELS] to [true], so that
         [scripts/test_wrapper.sh] partitions the set of @runtest
         targets to build. *)
      match parallel with
      | Some n when n > 1 -> [("DISTRIBUTE_TESTS_TO_PARALLELS", "true")]
      | _ -> []
    in
    let job =
      job
        ?timeout
        ?parallel
        ~retry:2
        ~name
        ~stage:Stages.test
        ~image
        ~arch
        ~dependencies
        ~rules
        ~variables
        ~artifacts:
          (artifacts
             ~name:"$CI_JOB_NAME-$CI_COMMIT_SHA-${ARCH}"
             ["test_results"]
             ~reports:(reports ~junit:"test_results/*.xml" ())
             ~expire_in:(Days 1)
             ~when_:Always)
        ~before_script:(before_script ~source_version:true ~eval_opam:true [])
        script
    in
    if enable_coverage then
      job |> job_enable_coverage_instrumentation |> job_enable_coverage_output
    else job
  in
  let oc_unit_non_proto_x86_64 =
    unit_test
      ~name:"oc.unit:non-proto-x86_64"
      ~arch:Amd64 (* The [lib_benchmark] unit tests require Python *)
      ~image:Images.runtime_build_test_dependencies
      ~make_targets:["test-nonproto-unit"]
      ()
  in
  let oc_unit_other_x86_64 =
    (* Runs unit tests for contrib. *)
    unit_test
      ~name:"oc.unit:other-x86_64"
      ~arch:Amd64
      ~make_targets:["test-other-unit"]
      ()
  in
  let oc_unit_proto_x86_64 =
    (* Runs unit tests for contrib. *)
    unit_test
      ~name:"oc.unit:proto-x86_64"
      ~arch:Amd64
      ~make_targets:["test-proto-unit"]
      ()
  in
  let oc_unit_non_proto_arm64 =
    unit_test
      ~name:"oc.unit:non-proto-arm64"
      ~parallel:2
      ~arch:Arm64 (* The [lib_benchmark] unit tests require Python *)
      ~image:Images.runtime_build_test_dependencies
      ~rules:[job_rule ~changes:changeset_unit_test_arm64 ()]
      ~make_targets:["test-nonproto-unit"; "test-webassembly"]
        (* No coverage for arm64 jobs -- the code they test is a
           subset of that tested by x86_64 unit tests. *)
      ~enable_coverage:false
      ()
  in
  let oc_unit_webassembly_x86_64 =
    job
      ~name:"oc.unit:webassembly-x86_64"
      ~arch:Amd64 (* The wasm tests are written in Python *)
      ~image:Images.runtime_build_test_dependencies
      ~stage:Stages.test
      ~dependencies:(build_dependencies Amd64)
      ~rules:[job_rule ~changes:changeset_octez ()]
      ~before_script:(before_script ~source_version:true ~eval_opam:true [])
        (* TODO: https://gitlab.com/tezos/tezos/-/issues/4663
           This test takes around 2 to 4min to complete, but it sometimes
           hangs. We use a timeout to retry the test in this case. The
           underlying issue should be fixed eventually, turning this timeout
           unnecessary. *)
      ~timeout:(Minutes 20)
      ["make test-webassembly"]
  in
  let oc_unit_js_components =
    job
      ~name:"oc.unit:js_components"
      ~arch:Amd64
      ~image:Images.runtime_build_test_dependencies
      ~stage:Stages.test
      ~dependencies:(build_dependencies Amd64)
      ~rules:[job_rule ~changes:changeset_octez ()]
      ~retry:2
      ~variables:[("RUNTEZTALIAS", "true")]
      ~before_script:
        (before_script
           ~take_ownership:true
           ~source_version:true
           ~eval_opam:true
           ~install_js_deps:true
           [])
      ["make test-js"]
  in
  let oc_unit_protocol_compiles =
    job
      ~name:"oc.unit:protocol_compiles"
      ~arch:Amd64
      ~image:Images.runtime_build_dependencies
      ~stage:Stages.test
      ~dependencies:(build_dependencies Amd64)
      ~rules:[job_rule ~changes:changeset_octez ()]
      ~before_script:(before_script ~source_version:true ~eval_opam:true [])
      ["dune build @runtest_compile_protocol"]
  in
  jobs_external ~path:"test/oc.unit.yml"
  @@ [
       oc_unit_non_proto_x86_64;
       oc_unit_other_x86_64;
       oc_unit_proto_x86_64;
       oc_unit_non_proto_arm64;
       oc_unit_webassembly_x86_64;
       oc_unit_js_components;
       oc_unit_protocol_compiles;
     ]

let _job_oc_integration_compiler_rejections =
  job_external
  @@ job
       ~name:"oc.integration:compiler-rejections"
       ~stage:Stages.test
       ~image:Images.runtime_build_dependencies
       ~rules:[job_rule ~changes:changeset_octez ()]
       ~dependencies:
         (Dependent
            [Job job_build_x86_64_release; Job job_build_x86_64_exp_dev_extra])
       ~before_script:(before_script ~source_version:true ~eval_opam:true [])
       ["dune build @runtest_rejections"]

let changeset_script_snapshot_alpha_and_link =
  [
    "src/proto_alpha/**/*";
    ".gitlab/**/*";
    ".gitlab-ci.yml";
    "scripts/snapshot_alpha_and_link.sh";
    "scripts/snapshot_alpha.sh";
    "scripts/user_activated_upgrade.sh";
  ]

let _job_oc_script_snapshot_alpha_and_link =
  job_external
  @@ job
       ~name:"oc.script:snapshot_alpha_and_link"
       ~stage:Stages.test
       ~image:Images.runtime_build_dependencies
       ~rules:
         [
           job_rule
             ~if_:Rules.merge_request
             ~changes:changeset_script_snapshot_alpha_and_link
             ();
         ]
         (* Note: this job actually probably doesn't need the oc.build_x86_64 job
            to have finished, but we don't want to start before oc.build_x86_64 has finished either.
            However, when oc.build_x86_64-* don't exist, we don't need to wait for them. *)
       ~dependencies:
         (Dependent
            [
              Job trigger;
              Optional job_build_x86_64_release;
              Optional job_build_x86_64_exp_dev_extra;
            ])
       ~before_script:
         (before_script
            ~take_ownership:true
            ~source_version:true
            ~eval_opam:true
            [])
       ["./.gitlab/ci/jobs/test/script:snapshot_alpha_and_link.sh"]

let _job_oc_script_test_gen_genesis =
  job_external
  @@ job
       ~name:"oc.script:test-gen-genesis"
       ~stage:Stages.test
       ~image:Images.runtime_build_dependencies
       ~rules:[job_rule ~changes:changeset_octez ()]
       ~dependencies:(Dependent [Job trigger])
       ~before_script:(before_script ~eval_opam:true ["cd scripts/gen-genesis"])
       ["dune build gen_genesis.exe"]

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
  register
    "master_branch"
    If.(on_tezos_namespace && push && on_branch "master")
    ~jobs:
      (let job_docker_amd64 : job = job_docker_build ~arch:Amd64 Experimental in
       let job_docker_arm64 : job = job_docker_build ~arch:Arm64 Experimental in
       (* Here we use this hack to publish the Octez documentation on
          {{:gitlab.io}} because we want to publish the doc for the project
          [tezos] under {{:https://tezos.gitlab.io}} and not
          {{:https://tezos.gitlab.io/tezos}} The latter follows the GitLab
          URL convention of
          [https://<projectname_space>.gitlab.io/<project_name>/].

          Notice that we push only if [CI_COMMIT_REF_NAME] is really [master].
          This allows to test the release workflow *)
       let publish_documentation =
         job
           ~name:"publish:documentation"
           ~image:Images.runtime_build_test_dependencies
           ~stage:Stages.doc
           ~dependencies:(Dependent [])
           ~before_script:
             (before_script
                ~eval_opam:true
                  (* Load the environment poetry previously created in the docker image.
                     Give access to the Python dependencies/executables. *)
                ~init_python_venv:true
                [
                  {|echo "${CI_PK_GITLAB_DOC}" > ~/.ssh/id_ed25519|};
                  {|echo "${CI_KH}" > ~/.ssh/known_hosts|};
                  {|chmod 400 ~/.ssh/id_ed25519|};
                ])
           ~interruptible:false
           ~rules:[job_rule ~changes:changeset_octez_docs ~when_:On_success ()]
           ["./scripts/ci/doc_publish.sh"]
       in
       let unified_coverage_default =
         job_enable_coverage_report
         @@ job
              ~image:Images.runtime_build_test_dependencies
              ~name:"oc.unified_coverage"
              ~stage:Stages.test_coverage
              ~variables:
                [
                  ("PROJECT", Predefined_vars.(show ci_project_path));
                  ("DEFAULT_BRANCH", Predefined_vars.(show ci_commit_sha));
                ]
              ~allow_failure:Yes
              [
                (* sets COVERAGE_OUTPUT *)
                ". ./scripts/version.sh";
                (* On the project default branch, we fetch coverage from the last merged MR *)
                "mkdir -p _coverage_report";
                "dune exec scripts/ci/download_coverage/download.exe -- -a \
                 from=last-merged-pipeline --info --log-file \
                 _coverage_report/download_coverage.log";
                "./scripts/ci/report_coverage.sh";
              ]
       in
       (* Smart Rollup: Kernel SDK

          See [src/kernel_sdk/RELEASE.md] for more information. *)
       let publish_kernel_sdk =
         job
           ~name:"publish_kernel_sdk"
           ~image:Images.rust_toolchain
           ~stage:Stages.manual
           ~when_:Manual
           ~allow_failure:Yes
           ~dependencies:(Dependent [])
           ~interruptible:false
           ~variables:
             [("CARGO_HOME", Predefined_vars.(show ci_project_dir) // "cargo")]
           ~cache:[{key = "kernels"; paths = ["cargo/"]}]
           [
             "make -f kernels.mk publish-sdk-deps";
             (* Manually set SSL_CERT_DIR as default setting points to empty dir *)
             "SSL_CERT_DIR=/etc/ssl/certs CC=clang make -f kernels.mk \
              publish-sdk";
           ]
       in
       [
         (* Stage: build *)
         job_static_x86_64_experimental;
         job_build_static_binaries ~arch:Arm64 ();
         job_build_arm64_release;
         job_build_arm64_exp_dev_extra;
         job_docker_amd64;
         job_docker_arm64;
         (* Stage: test_coverage *)
         unified_coverage_default;
         (* Stage: doc *)
         publish_documentation;
         (* Stage: prepare_release *)
         job_docker_merge_manifests
           ~ci_docker_hub:true
           ~job_docker_amd64
           ~job_docker_arm64;
         (* Stage: manual *)
         publish_kernel_sdk;
       ]) ;
  register
    "release_tag"
    If.(on_tezos_namespace && push && has_tag_match release_tag_re)
    ~jobs:(release_tag_pipeline Release_tag) ;
  register
    "beta_release_tag"
    If.(on_tezos_namespace && push && has_tag_match beta_release_tag_re)
    ~jobs:(release_tag_pipeline Beta_release_tag) ;
  register
    "release_tag_test"
    If.(not_on_tezos_namespace && push && has_any_release_tag)
    ~jobs:(release_tag_pipeline ~test:true Release_tag) ;
  register
    "non_release_tag"
    If.(on_tezos_namespace && push && has_non_release_tag)
    ~jobs:(release_tag_pipeline Non_release_tag) ;
  register
    "non_release_tag_test"
    If.(not_on_tezos_namespace && push && has_non_release_tag)
    ~jobs:(release_tag_pipeline ~test:true Non_release_tag) ;
  register
    "schedule_extended_test"
    schedule_extended_tests
    ~jobs:
      (let tezt_flaky_dependencies =
         [
           job_build_x86_64_release;
           job_build_x86_64_exp_dev_extra;
           job_build_kernels;
           job_tezt_fetch_records;
         ]
       in
       let job_tezt_flaky : job =
         job_tezt
           ~name:"tezt_flaky"
           ~tezt_tests:"flaky"
             (* To handle flakiness, consider tweaking [~tezt_parallel] (passed to
                Tezt's '--job-count'), and [~tezt_retry] (passed to Tezt's
                '--retry') *)
           ~retry:2
           ~tezt_retry:3
           ~tezt_parallel:1
           ~parallel:1
           ~dependencies:
             (Dependent
                (List.map (fun job -> Artifacts job) tezt_flaky_dependencies))
           ()
       in
       [job_build_arm64_release; job_build_arm64_exp_dev_extra]
       (* These jobs are necessary to run flaky tezts *)
       @ tezt_flaky_dependencies
       (* Stage: packaging *)
       @ (job_opam_prepare :: jobs_opam_package)
       (* Stage: test *)
       @ jobs_install_octez (* Flaky tezts *)
       @ [job_tezt_flaky; job_documentation_linkcheck]
       @ jobs_install_python)

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
