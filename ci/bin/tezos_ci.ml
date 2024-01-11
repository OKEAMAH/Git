open Gitlab_ci.Util

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
  }

  let pipelines : t list ref = ref []

  let register ?variables name if_ =
    let pipeline : t = {variables; if_; name} in
    if List.exists (fun {name = name'; _} -> name' = name) !pipelines then
      failwith
        (sf "[Pipeline.register] attempted to register pipeline %S twice" name)
    else pipelines := pipeline :: !pipelines

  let all () = List.rev !pipelines

  let workflow_includes () :
      Gitlab_ci.Types.workflow * Gitlab_ci.Types.include_ list =
    let workflow_rule_of_pipeline = function
      | {name; if_; variables} ->
          (* Add [PIPELINE_TYPE] to the variables of the workflow rules, so
             that it can be added to the pipeline [name] *)
          let variables =
            ("PIPELINE_TYPE", name) :: Option.value ~default:[] variables
          in
          workflow_rule ~if_ ~variables ~when_:Always ()
    in
    let include_of_pipeline = function
      | {name; if_; variables = _} ->
          (* Note that variables associated to the pipeline are not
             set in the include rule, they are set in the workflow
             rule *)
          let rule = include_rule ~if_ ~when_:Always () in
          Gitlab_ci.Types.
            {local = sf ".gitlab/ci/pipelines/%s.yml" name; rules = [rule]}
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
  | Artifacts of Gitlab_ci.Types.job

type dependencies = Staged | Independent | Dependent of dependency list

type git_strategy = Fetch | Clone | No_strategy

let enc_git_strategy = function
  | Fetch -> "fetch"
  | Clone -> "clone"
  | No_strategy -> "none"

let job ?(arch = Amd64) ?after_script ?allow_failure ?artifacts ?before_script
    ?cache ?image ?interruptible ?(dependencies = Staged) ?services ?variables
    ?rules ?timeout ?(tags = []) ?git_strategy ?when_ ~stage ~name script :
    Gitlab_ci.Types.job =
  let tags =
    Some ((match arch with Amd64 -> "gcp" | Arm64 -> "gcp_arm64") :: tags)
  in
  let stage = Some (Stage.name stage) in
  let script = Some script in
  let needs, dependencies =
    match dependencies with
    | Staged -> (None, Some [])
    | Independent -> (Some [], Some [])
    | Dependent dependencies ->
        let to_opt = function [] -> None | xs -> Some xs in
        let rec loop (needs, dependencies) = function
          | Job j :: deps -> loop (j.name :: needs, dependencies) deps
          | Artifacts j :: deps ->
              loop (j.name :: needs, j.name :: dependencies) deps
          | [] ->
              (* Note that [dependencies] is always filled, because we want to
                 fetch no dependencies by default ([dependencies = Some
                 []]), whereas the absence of [dependencies = None] would
                 fetch all the dependencies of the preceding jobs. *)
              (to_opt @@ List.rev needs, Some (List.rev dependencies))
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
  {
    name;
    after_script;
    allow_failure;
    artifacts;
    before_script;
    cache;
    image;
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
  }
