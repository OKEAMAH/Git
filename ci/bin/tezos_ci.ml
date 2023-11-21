open Base
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
    let rec loop (workflow, includes) = function
      | {name; if_; variables} :: pipelines ->
          let wf_rule =
            (* Add [PIPELINE_TYPE] to the variables of the workflow rules, so
               that it can be added to the pipeline [name] *)
            let variables =
              ("PIPELINE_TYPE", name) :: Option.value ~default:[] variables
            in
            workflow_rule ~if_ ~variables ~when_:Always ()
          in
          let include_rule = workflow_rule ~if_ ?variables ~when_:Always () in
          let include_ =
            Gitlab_ci.Types.
              {
                local = sf ".gitlab/ci/pipelines/%s.yml" name;
                rules = [include_rule];
              }
          in
          loop (wf_rule :: workflow, include_ :: includes) pipelines
      | [] ->
          ( Gitlab_ci.Types.
              {
                rules = List.rev workflow;
                name = Some "[$PIPELINE_TYPE] $CI_COMMIT_TITLE";
              },
            List.rev includes )
    in
    loop ([], []) (all ())
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

let job ?(arch = Amd64) ?after_script ?allow_failure ?artifacts ?before_script
    ?cache ?image ?interruptible ?(dependencies = []) ?services ?variables
    ?rules ?timeout ?(tags = []) ~stage ~name script : Gitlab_ci.Types.job =
  let tags =
    Some ((match arch with Amd64 -> "gcp" | Arm64 -> "gcp_arm64") :: tags)
  in
  let stage = Some (Stage.name stage) in
  let script = Some script in
  let needs, depends =
    let to_opt = function [] -> None | xs -> Some xs in
    let rec loop (needs, depends) = function
      | Job j :: deps -> loop (j.name :: needs, depends) deps
      | Artifacts j :: deps -> loop (j.name :: needs, j.name :: depends) deps
      | [] -> (to_opt @@ List.rev needs, to_opt @@ List.rev depends)
    in
    loop ([], []) dependencies
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
    depends;
    rules;
    script;
    services;
    stage;
    variables;
    timeout;
    tags;
  }
