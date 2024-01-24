open Gitlab_ci.Util

let header =
  {|# This file was automatically generated, do not edit.
# Edit file ci/bin/main.ml instead.

|}

module Stage = struct
  type t = Stage of string

  let stages : t list ref = ref []

  let register name =
    let stage = Stage name in
    if List.mem stage !stages then
      failwith (sf "[Stage.register] attempted to register stage %S twice" name)
    else (
      stages := stage :: !stages ;
      stage)

  let name (Stage name) = name

  let to_string_list () = List.map name (List.rev !stages)
end

module Pipeline = struct
  type t = {
    name : string;
    if_ : Gitlab_ci.If.t;
    variables : Gitlab_ci.Types.variables option;
    jobs : Gitlab_ci.Types.job list;
  }

  let pipelines : t list ref = ref []

  let filename : name:string -> string =
   fun ~name -> sf ".gitlab/ci/pipelines/%s.yml" name

  let register ?variables ?(jobs = []) name if_ =
    let pipeline : t = {variables; if_; name; jobs} in
    (* TODO: check that stages have not been crossed. *)
    (* TODO: check that there are no dependencies on jobs that do not produce artifacts (makes no sense)  *)
    if List.exists (fun {name = name'; _} -> name' = name) !pipelines then
      failwith
        (sf "[Pipeline.register] attempted to register pipeline %S twice" name)
    else pipelines := pipeline :: !pipelines

  let all () = List.rev !pipelines

  (* Perform a set of static checks on the full pipeline before writing it. *)
  let precheck {name = pipeline_name; jobs; _} =
    let job_by_name : (string, Gitlab_ci.Types.job) Hashtbl.t =
      Hashtbl.create 5
    in
    (* Populate [job_by_name] and check that no two different jobs have the same name. *)
    List.iter
      (fun (job : Gitlab_ci.Types.job) ->
        match Hashtbl.find_opt job_by_name job.name with
        | None -> Hashtbl.add job_by_name job.name job
        | Some _ ->
            failwith
              (sf "[%s] the job '%s' is included twice" pipeline_name job.name))
      jobs ;
    (* Check usage of [needs:] & [depends:] *)
    Fun.flip List.iter jobs @@ fun job ->
    (* Get the [needs:] / [dependencies:] of job *)
    let opt_set l =
      List.fold_right
        String_set.add
        (Option.value ~default:[] l)
        String_set.empty
    in
    let needs =
      match job.needs with
      | Some needs ->
          List.fold_right
            (fun Gitlab_ci.Types.{job; optional} mandatory_needs ->
              if not optional then String_set.add job mandatory_needs
              else mandatory_needs)
            needs
            String_set.empty
      | None -> String_set.empty
    in
    let dependencies = opt_set job.dependencies in
    (* Check that dependencies are a subset of needs.
       Note: this is already enforced by the smart constructor {!job}
       defined below. Is it redundant? Nothing enforces the usage if
       this smart constructor at this point.*)
    String_set.iter
      (fun dependency ->
        if not (String_set.mem dependency needs) then
          failwith
            (sf
               "[%s] the job '%s' has a [dependency:] on '%s' which is not \
                included in it's [need:]"
               pipeline_name
               job.name
               dependency))
      dependencies ;
    (* Check that needed jobs (which thus includes dependencies) are defined *)
    ( Fun.flip String_set.iter needs @@ fun need ->
      match Hashtbl.find_opt job_by_name need with
      | Some _needed_job ->
          (* TODO: check rule implication *)
          ()
      | None when need = "trigger" ->
          (* TODO: special handling for trigger *)
          ()
      | None ->
          (* TODO: handle optional needs *)
          failwith
            (sf
               "[%s] job '%s' has a need on '%s' which is not defined in this \
                pipeline."
               pipeline_name
               job.name
               need) ) ;
    (* Check that all [dependencies:] are on jobs that produce artifacts *)
    ( Fun.flip String_set.iter dependencies @@ fun dependency ->
      match Hashtbl.find_opt job_by_name dependency with
      | Some {artifacts = Some {paths = _ :: _; _}; _}
      | Some {artifacts = Some {reports = Some {dotenv = Some _; _}; _}; _} ->
          (* This is fine: we depend on a job that define non-report artifacts, or a dotenv file. *)
          ()
      | Some _ ->
          failwith
            (sf
               "[%s] the job '%s' has a [dependency:] on '%s' which produces \
                neither regular, [paths:] artifacts or a dotenv report."
               pipeline_name
               job.name
               dependency)
      | None ->
          (* This case is precluded by the dependency analysis above. *)
          assert false ) ;

    ()

  let write () =
    all ()
    |> List.iter @@ fun ({name; jobs; _} as pipeline) ->
       if not (Sys.getenv_opt "CI_DISABLE_PRECHECK" = Some "true") then
         precheck pipeline ;
       match jobs with
       | [] -> ()
       | _ :: _ ->
           let filename = filename ~name in
           let config = List.map (fun j -> Gitlab_ci.Types.Job j) jobs in
           Gitlab_ci.To_yaml.to_file ~header ~filename config

  let workflow_includes () :
      Gitlab_ci.Types.workflow * Gitlab_ci.Types.include_ list =
    let workflow_rule_of_pipeline = function
      | {name; if_; variables; jobs = _} ->
          (* Add [PIPELINE_TYPE] to the variables of the workflow rules, so
             that it can be added to the pipeline [name] *)
          let variables =
            ("PIPELINE_TYPE", name) :: Option.value ~default:[] variables
          in
          workflow_rule ~if_ ~variables ~when_:Always ()
    in
    let include_of_pipeline = function
      | {name; if_; variables = _; jobs = _} ->
          (* Note that variables associated to the pipeline are not
             set in the include rule, they are set in the workflow
             rule *)
          let rule = include_rule ~if_ ~when_:Always () in
          Gitlab_ci.Types.{local = filename ~name; rules = [rule]}
    in
    let pipelines = all () in
    let workflow =
      let rules = List.map workflow_rule_of_pipeline pipelines in
      Gitlab_ci.Types.{rules; name = Some "[$PIPELINE_TYPE] $CI_COMMIT_TITLE"}
    in
    let includes = List.map include_of_pipeline pipelines in
    (workflow, includes)
end

module Image = struct
  type t = Gitlab_ci.Types.image

  let images : t String_map.t ref = ref String_map.empty

  let register ~name ~image_path =
    let image : t = Image image_path in
    if String_map.mem name !images then
      failwith (sf "[Image.register] attempted to register image %S twice" name)
    else (
      images := String_map.add name image !images ;
      image)

  let name (Gitlab_ci.Types.Image name) = name

  let all () = String_map.bindings !images
end

type arch = Amd64 | Arm64

type dependency =
  | Job of Gitlab_ci.Types.job
  | Optional of Gitlab_ci.Types.job
  | Artifacts of Gitlab_ci.Types.job

type dependencies = Staged | Dependent of dependency list

type git_strategy = Fetch | Clone | No_strategy

let enc_git_strategy = function
  | Fetch -> "fetch"
  | Clone -> "clone"
  | No_strategy -> "none"

let job ?arch ?after_script ?allow_failure ?artifacts ?before_script ?cache
    ?interruptible ?(dependencies = Staged) ?services ?variables ?rules ?timeout
    ?tags ?git_strategy ?when_ ?coverage ?retry ?parallel ~image ~stage ~name
    script : Gitlab_ci.Types.job =
  (match (rules, when_) with
  | Some _, Some _ ->
      failwith
        "[job] do not use [~when_] and [~rules] at the same time -- it's \
         confusing."
  | _ -> ()) ;
  let tags =
    Some
      (match (arch, tags) with
      | Some arch, None ->
          [(match arch with Amd64 -> "gcp" | Arm64 -> "gcp_arm64")]
      | None, Some tags -> tags
      | None, None ->
          (* By default, we assume Amd64 runners as given by the [gcp] tag. *)
          ["gcp"]
      | Some _, Some _ ->
          failwith
            "[job] cannot specify both [arch] and [tags] at the same time.")
  in
  let stage = Some (Stage.name stage) in
  let script = Some script in
  let needs, dependencies =
    match dependencies with
    | Staged -> (None, Some [])
    | Dependent dependencies ->
        let rec loop (needs, dependencies) = function
          | Job j :: deps ->
              loop
                ( Gitlab_ci.Types.{job = j.name; optional = false} :: needs,
                  dependencies )
                deps
          | Optional j :: deps ->
              loop
                ( Gitlab_ci.Types.{job = j.name; optional = true} :: needs,
                  dependencies )
                deps
          | Artifacts j :: deps ->
              loop
                ( Gitlab_ci.Types.{job = j.name; optional = false} :: needs,
                  j.name :: dependencies )
                deps
          | [] ->
              (* Note that [dependencies] is always filled, because we want to
                 fetch no dependencies by default ([dependencies = Some
                 []]), whereas the absence of [dependencies = None] would
                 fetch all the dependencies of the preceding jobs. *)
              (Some (List.rev needs), Some (List.rev dependencies))
        in
        loop ([], []) dependencies
  in
  let variables =
    match git_strategy with
    | Some strategy ->
        Some
          (("GIT_STRATEGY", enc_git_strategy strategy)
          :: Option.value ~default:[] variables)
    | None -> variables
  in
  (match retry with
  | Some retry when retry < 0 || retry > 2 ->
      failwith
        (sf
           "Invalid [retry] value '%d' for job [%s]: must be 0, 1 or 2."
           retry
           name)
  | _ -> ()) ;
  {
    name;
    after_script;
    allow_failure;
    artifacts;
    before_script;
    cache;
    image = Some image;
    interruptible;
    needs;
    dependencies;
    rules;
    script;
    services;
    stage;
    variables;
    timeout;
    tags;
    when_;
    coverage;
    retry;
    parallel;
  }

let external_jobs = ref String_set.empty

let job_external ?directory ?filename_suffix (job : Gitlab_ci.Types.job) :
    Gitlab_ci.Types.job =
  let stage =
    match job.stage with
    | Some stage -> stage
    | None ->
        (* Test is the name of the default stage in GitLab CI *)
        "test"
  in
  let basename =
    match filename_suffix with
    | None -> job.name
    | Some suffix -> job.name ^ "-" ^ suffix
  in
  let directory = Option.value ~default:stage directory in
  let filename = sf ".gitlab/ci/jobs/%s/%s.yml" directory basename in
  if String_set.mem filename !external_jobs then
    failwith
      (sf
         "Attempted to write external job %s twice -- perhaps you need to set \
          filename_suffix?"
         filename)
  else (
    external_jobs := String_set.add filename !external_jobs ;
    let config = [Gitlab_ci.Types.Job job] in
    Gitlab_ci.To_yaml.to_file ~header ~filename config ;
    job)
