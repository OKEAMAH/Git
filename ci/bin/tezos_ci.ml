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
    if List.exists (fun {name = name'; _} -> name' = name) !pipelines then
      failwith
        (sf "[Pipeline.register] attempted to register pipeline %S twice" name)
    else pipelines := pipeline :: !pipelines

  let all () = List.rev !pipelines

  type needs_error_type =
    (*     | Missing_need *)
    | Empty_dependency_ruleset
    | Mixed_polarity of {
        index : int;
        rule : Gitlab_ci.Types.job_rule;
        rule_needed : Gitlab_ci.Types.job_rule;
      }
    | No_if_implication of {
        index : int;
        exclusion : bool;
        rule : Gitlab_ci.Types.job_rule;
        rule_needed : Gitlab_ci.Types.job_rule;
      }
    | No_change_implication of {
        index : int;
        exclusion : bool;
        rule : Gitlab_ci.Types.job_rule;
        rule_needed : Gitlab_ci.Types.job_rule;
      }
    | Not_a_prefix

  type needs_error = {
    pipeline_name : string;
    job : Gitlab_ci.Types.job;
    job_needed : Gitlab_ci.Types.job;
    needs_error_type : needs_error_type;
  }

  let shows_need_error {pipeline_name; job; job_needed; needs_error_type} :
      string =
    let open Gitlab_ci in
    let open Gitlab_ci.Types in
    let show_if_opt = Option.fold ~none:"None" ~some:If.encode in
    let show_changes_opt =
      Option.fold ~none:"[]" ~some:(fun changes ->
          String.concat ", " @@ List.map (fun glob -> sf "%S" glob) changes)
    in
    let msg =
      sf
        "[%s] job '%s' needs job '%s' but"
        pipeline_name
        job.name
        job_needed.name
    in
    msg
    ^
    match needs_error_type with
    (* | Missing_need -> _ *)
    | Empty_dependency_ruleset ->
        sf
          "the job '%s' has an empty ruleset and so is never included."
          job_needed.name
    | Mixed_polarity {index; rule; rule_needed} ->
        sf
          "their %dth rule has mixed polarity: one includes (with 'when: %s'), \
           one excludes (with 'when: %s')"
          index
          (show_when rule_needed.when_)
          (show_when rule.when_)
    | No_if_implication {index; exclusion; rule; rule_needed} ->
        sf
          "the %dth, %s rule of '%s' ('%s') is not statically guaranteed to \
           imply the rule of '%s' ('%s')"
          index
          (if exclusion then "excluding" else "including")
          job_needed.name
          (show_if_opt rule_needed.if_)
          job.name
          (show_if_opt rule.if_)
    | No_change_implication {index; exclusion; rule; rule_needed} ->
        sf
          "the %dth, %s rule of '%s's changeset (%s) is not statically \
           guaranteed to include the changeset of rule '%s' (%s)"
          index
          (if exclusion then "excluding" else "including")
          job_needed.name
          (show_changes_opt rule_needed.changes)
          job.name
          (show_changes_opt rule.changes)
    | Not_a_prefix ->
        sf
          "we cannot statically guarantee that the latter is included when the \
           former is, since the rules of '%s' is not a prefix of '%s'"
          job_needed.name
          job.name

  (* Perform a set of static checks on the full pipeline before writing it. *)
  let precheck {name = pipeline_name; jobs; _} =
    let open Gitlab_ci in
    let open Gitlab_ci.Types in
    (* Check that the rules of job implies the [job] of [job_needed].

       If [job] has specified [job_needed] in its [need:] clause, and
       there is an environment (variable values & change set) in which
       [job] is not included in the pipeline (i.e. by matching a rule
       for which [when: never]), then GitLab will not allow the
       creation of that pipeline, and it is in general an error in the
       configuration.

       This function applies a heuristic to rule out the absence of
       such cases. First, we raise an alarm immediately if the rules
       of [job_needed] is [[]] -- this would always exclude
       [job_needed].

       If not, we check that the rules of [job_needed]
       is a prefix (Condition 0) of [job] such that point-wise:
       - Condition 1. both rules either exclude (with [when: = never]) or
         includes (with [when: <> never])
       - Condition 2. all [when:  = never]-rules of [job_needed] implies
         its corresponding rule in [job]
       - Condition 3. all [when: <> never]-rules of [job] implies its
         corresponding rule in [job]. *)
    let precheck_rule_implication (job : Types.job) (job_needed : Types.job) :
        (unit, needs_error) result =
      (* A job rule A implies another rule B when: in all environments
         where A are matched, then B is also matched.

         This function under-approximates implication of [if:], such that:

         - if [if_implies if_ if_'] is [true], then
           [if_'] is always matched when [if_] is matched.
         - if [if_implies if if_'] is [false], then
           [if_'] may, or not, always match when [if_] is
           matched. *)
      let if_implies if_ if_' =
        (* An omitted [if:] clause is always implictly matched. *)
        match (if_, if_') with
        | None, None -> true
        | None, Some _ ->
            (* [if_] is always matched, so we don't know about [if_'] evaluation. *)
            false
        | Some _, None ->
            (* [if_'] is always matched, so the implication always holds, since {true,false} -> true. *)
            true
        | Some if_, Some if_' ->
            (* In the general case, we rely on the syntactic
               under-approximation of implication from
               {!Gitlab_ci.If}. *)
            If.implies_underapprox if_ if_'
      in
      (* As [if_implies] but for [changes:] clauses of job rules.

         See the description of [if_implies]. *)
      let changes_implies changes changes' =
        (* Same logic as above for omitted [changes:] clauses *)
        match (changes, changes') with
        | None, None -> true
        | None, Some _ -> false
        | Some _, None -> true
        | Some changes, Some changes' ->
            (* If all the changes-paths of [changes] are included in those of [changes'],
               then a change triggering [changes] will always trigger those of [changes'] *)
            String_set.subset
              (String_set.of_list changes)
              (String_set.of_list changes')
      in
      let fail needs_error_type =
        Result.error {pipeline_name; job; job_needed; needs_error_type}
      in
      let return, ( let* ) = Result.(ok, bind) in
      let job_rules =
        match job.rules with
        | None ->
            (* [job] has no rule set, and so is always included.
               Consequently, this must also be the case for
               [job_needed].  This will be assured below by checking
               that the rules of [job_needed] is a prefix of [job]'s
               rule -- it must thus necessarily also be empty and
               always included. *)
            []
        | Some rules -> rules
      in
      let* job_needed_rules =
        match job_needed.rules with
        | None ->
            (* [job_needed] has no rule set and so is always included. *)
            return []
        | Some [] -> fail Empty_dependency_ruleset
        | Some rules -> return rules
      in
      (* Check point-wise implication of rules *)
      let rec loop index (job_needed_rules : job_rule list)
          (job_rules : job_rule list) : (unit, needs_error) result =
        match (job_needed_rules, job_rules) with
        | rule_needed :: job_needed_rules, rule :: rules ->
            (* Check Condition 1. *)
            let* exclusion =
              match (rule_needed.when_, rule.when_) with
              | Never, Never -> return true
              | Never, _ | _, Never ->
                  fail (Mixed_polarity {index; rule_needed; rule})
              | _ -> return false
            in
            (* Check condition 2 and 3. *)
            (* The direction of the implication depends on rule-polarity *)
            let precedent, consequent =
              if exclusion then (rule_needed, rule) else (rule, rule_needed)
            in
            let* () =
              if not (if_implies precedent.if_ consequent.if_) then
                fail (No_if_implication {index; exclusion; rule; rule_needed})
              else return ()
            in
            let* () =
              if not (changes_implies precedent.changes consequent.changes) then
                fail
                  (No_change_implication {index; exclusion; rule; rule_needed})
              else return ()
            in
            loop (index + 1) job_needed_rules rules
        | [], _ :: _ ->
            (* Condition 0: The rules of [job_needed] is not a prefix of [job]'s rules *)
            fail Not_a_prefix
        | _, [] ->
            (* We've finished checking that [job_needed]'s rule is a "implying" prefix of [job]'s rules *)
            return ()
      in
      loop 1 job_needed_rules job_rules
    in
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
      | Some job_needed -> (
          match precheck_rule_implication job job_needed with
          | Ok () -> ()
          | Error needs_error -> failwith (shows_need_error needs_error))
      | None when need = "trigger" ->
          (* TODO: Temporarily disable the existance check for the job
             [trigger].  Currently, this job is generated in the
             top-level .gitlab-ci.yml file and is included on all
             jobs.  In the future, we can probably move this job into
             the pipelines that actually need a manual pipeline (only
             [before_merging]) and then this case can be removed. *)
          ()
      | None when need = "trigger" ->
          (* TODO: special handling for trigger *)
          ()
      | None ->
          (* TODO: if/when optional needs are added, then they should
             be excluded from this error. *)
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
          (* This is fine: we depend on a job that define non-report
             artifacts, or a dotenv file. *)
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
          (* This case is precluded by the preceding check verifying
             the definition of dependencies. *)
          assert false ) ;
    (* TODO: check for cycles *)
    (* TODO: if a job rule is manual, make a warning if allow_failure is not set to true? *)
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
  if parallel = Some 0 then
    failwith "[job] the argument to [parallel] must be strictly positive." ;
  let needs, dependencies =
    match dependencies with
    | Staged -> (None, Some [])
    | Dependent dependencies ->
        let rec loop (needs, dependencies) = function
          | dep :: deps ->
              let job_expanded =
                match dep with
                | Job j | Optional j | Artifacts j -> (
                    match j with
                    | Gitlab_ci.Types.{name; parallel; _} -> (
                        match parallel with
                        | None -> [name]
                        | Some n ->
                            List.rev
                            @@ List.map
                                 (fun i -> sf "%s %d/%d" name i n)
                                 (range 1 n)))
              in
              let needs ~optional =
                List.map
                  (fun name -> Gitlab_ci.Types.{job = name; optional})
                  job_expanded
                @ needs
              in
              let needs, dependencies =
                match dep with
                | Job _ -> (needs ~optional:false, dependencies)
                | Optional _ -> (needs ~optional:true, dependencies)
                | Artifacts _ ->
                    (needs ~optional:false, job_expanded @ dependencies)
              in
              loop (needs, dependencies) deps
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

let jobs_external ~path (jobs : Gitlab_ci.Types.job list) :
    Gitlab_ci.Types.job list =
  let filename = sf ".gitlab/ci/jobs/%s" path in
  if String_set.mem filename !external_jobs then
    failwith
      (sf
         "[job_external] attempted to write external job file %s twice."
         filename)
  else (
    external_jobs := String_set.add filename !external_jobs ;
    let config = List.map (fun job -> Gitlab_ci.Types.Job job) jobs in
    Gitlab_ci.To_yaml.to_file ~header ~filename config ;
    jobs)
