open Tezt
open Base

let config_file_tezt = ".gitlab/ci/jobs/test/tezt.yml"

let config_file_coverage = ".gitlab/ci/jobs/test_reports/coverage.yml"

let records_directory = "tezt/records"

(** Desired run time of each tezt job, excluding the overhead *)
let desired_run_time_s = 7 * 60

(** Number of tezt processes per job, i.e. the value passed to [-j]
    when launching tezt in the CI *)
let intrajob_parallelism = 4

let slack_factor_numerator = 3

let slack_factor_denominator = 2

let slack_factor n = n * slack_factor_numerator / slack_factor_denominator

(** Minimal number of jobs.

    Note that the [parallel:] keyword in [.gitlab-ci.yml] cannot be less than 2. *)
let min_jobs = 2

(** Minimal number of jobs.

    Note that the [parallel:] keyword in [.gitlab-ci.yml] cannot be more than 200. *)
let max_jobs = 50

(** Require a difference of [change_threshold] in the currented and suggested
    number of jobs to propose an MR. *)
let change_threshold = 0

let project = Sys.getenv_opt "PROJECT" |> Option.value ~default:"tezos/tezos"

let default_branch =
  Sys.getenv_opt "DEFAULT_BRANCH" |> Option.value ~default:"master"

(* Default assignee for auto-balancing MR. 4414596 = https://gitlab.com/arvidnl *)
let assignee_id =
  Sys.getenv_opt "ASSIGNEE_ID" |> Option.fold ~none:4414596 ~some:int_of_string

(* GitLab token required to post merge-requests  *)
let private_token_opt = Sys.getenv_opt "PRIVATE_TOKEN"

let remote =
  Sys.getenv_opt "REMOTE"
  |> Option.value ~default:"git@gitlab.com:tezos/tezos.git"

let records_total_time_s ~include_tags records =
  let add_size total record =
    let sum_total_time total record =
      let tags = JSON.(record |-> "tags" |> as_list |> List.map as_string) in
      if List.for_all (fun tag -> List.mem tag tags) include_tags then
        total + JSON.(record |-> "successful_runs" |-> "total_time" |> as_int)
      else total
    in
    let total_file =
      JSON.(record |> as_list |> List.fold_left sum_total_time 0)
    in
    total + total_file
  in
  List.fold_left add_size 0 records / 1_000_000

let get_records () =
  List.filter_map
    (fun filename ->
      if filename =~ rex "^\\d+\\.json$" then
        (*       if filename =~ rex "^29.json$" then *)
        Some (JSON.parse_file (records_directory // filename))
      else None)
    (Sys.readdir records_directory |> Array.to_list)

let suggest_number_of_jobs total_time_s =
  let candidate =
    slack_factor @@ (total_time_s / intrajob_parallelism / desired_run_time_s)
  in
  if candidate < min_jobs then min_jobs
  else if candidate > max_jobs then max_jobs
  else candidate

let map_job config_file job_name f =
  let configuration = Base.read_file config_file |> String.split_on_char '\n' in
  let prefix, configuration =
    Base.span
      (fun line ->
        match line =~* rex "^(\\S+):$" with
        | Some job_name' when job_name = job_name' -> false
        | _ -> true)
      configuration
  in
  let job_configuration, suffix =
    match configuration with
    | [] -> Test.fail "Could not find job %s in %s" job_name config_file_tezt
    | job_name_line :: configuration ->
        let job_configuration, suffix =
          Base.span (fun line -> line =~! rex "^(\\S+):$") configuration
        in
        (job_name_line :: job_configuration, suffix)
  in
  match f job_configuration with
  | Some new_job_configuration ->
      let new_configuration =
        String.concat "\n" (prefix @ new_job_configuration @ suffix)
      in
      Base.write_file config_file ~contents:new_configuration ;
      true
  | None ->
      Log.info "Not updating %s" config_file ;
      false

let update_ci_configuration ~change_threshold job_name number_of_jobs =
  let updated_tezt_configuration =
    map_job config_file_tezt job_name @@ fun job_configuration ->
    let job_configuration, found, updated =
      List.fold_left
        (fun (acc, found, updated) line ->
          match (line =~** rex "^(\\s+)parallel: (\\d+)$", found) with
          | Some (indentation, old_number_of_jobs), false ->
              let old_number_of_jobs = int_of_string old_number_of_jobs in
              if abs (old_number_of_jobs - number_of_jobs) < change_threshold
              then (
                Log.info
                  "Not update job '%s' in %s: difference between old value \
                   (%d) and suggested (%d) is below treshold %d"
                  job_name
                  config_file_tezt
                  old_number_of_jobs
                  number_of_jobs
                  change_threshold ;
                (line :: acc, true, false))
              else (
                Log.info
                  "Updating job '%s' in %s: setting 'parallel' from %d to %d "
                  job_name
                  config_file_tezt
                  old_number_of_jobs
                  number_of_jobs ;
                let line =
                  indentation ^ "parallel: " ^ string_of_int number_of_jobs
                in
                (line :: acc, true, true))
          | _ -> (line :: acc, found, updated))
        ([], false, false)
        job_configuration
    in
    if not found then
      Test.fail
        "Could not find the 'parallel' keyword for job %s in %s"
        job_name
        config_file_tezt
    else if updated then Some (List.rev job_configuration)
    else None
  in
  updated_tezt_configuration

let update_coverage_configuration tezt_job_name number_of_jobs =
  map_job config_file_coverage "unified_coverage" @@ fun job_configuration ->
  let prefix, configuration =
    Base.span (fun line -> line =~! rex "^\\s+dependencies:$") job_configuration
  in
  let dependencies, suffix = Base.span (( <> ) "") configuration in
  let dependencies =
    match dependencies with
    | [] ->
        Test.fail
          "Could not find the 'dependencies' keyword in the 'unified_coverage' \
           job of %s"
          config_file_coverage
    | keyword_line :: dependencies ->
        let dependencies =
          List.filter
            (fun line ->
              line =~! rexf "^(\\s+)- \"%s \\d+/\\d+\"$" tezt_job_name)
            dependencies
          @ List.map
              (fun i -> sf {|    - "%s %d/%d"|} tezt_job_name i number_of_jobs)
              (range 1 number_of_jobs)
        in
        keyword_line :: dependencies
  in
  Some (prefix @ dependencies @ suffix)

let post_merge_request ~private_token () =
  let date_str =
    let Unix.{tm_mday; tm_mon; tm_year; _} = Unix.(time () |> gmtime) in
    sf "%04d-%02d-%02d" (tm_year + 1900) (tm_mon + 1) tm_mday
  in
  let create_push_branch () =
    let branch = "tezt-balancing-bot@update_balancing-" ^ date_str in
    let git = Process.run "git" in
    let* () = git ["checkout"; "-b"; branch] in
    let* () =
      git
        [
          "commit";
          config_file_tezt;
          config_file_coverage;
          "-m";
          "CI/Tezt: Auto-balance jobs";
        ]
    in
    let* () = git ["push"; remote; branch] in
    return branch
  in
  let post_mr branch =
    let data =
      JSON.annotate ~origin:"merge-request"
      @@ `O
           [
             ("source_branch", `String branch);
             ("target_branch", `String default_branch);
             ("title", `String ("Tezt: auto-balancing " ^ date_str));
             ("allow_collaboration", `Bool true);
             ("assignee_id", `Float (float_of_int assignee_id));
             ("description", `String "Tezt auto-balancing.");
             ("labels", `String "test ⚒,CI ⚙,tests:tezt");
             ("remove_source_branch", `Bool true);
           ]
    in
    Gitlab.(
      post
        ~log_call:false
        ~curl_args:["-H"; "PRIVATE-TOKEN: " ^ private_token]
        (project_merge_requests ~project ())
        data)
  in
  let* branch = create_push_branch () in
  let* mr = post_mr branch in
  Log.info "Posted MR: %s" JSON.(mr |-> "web_url" |> as_string) ;
  unit

let () =
  (* Register a test to benefit from error handling of Test.run,
     as well as [Background.start] etc. *)
  ( Test.register ~__FILE__ ~title:"update tezt ci configuration" ~tags:["ci"]
  @@ fun () ->
    let records = get_records () in
    let updates =
      List.exists
        (fun (job_name, include_tags, update_coverage) ->
          let total_time_s = records_total_time_s records ~include_tags in
          let number_of_jobs = suggest_number_of_jobs total_time_s in
          Log.info
            "Total tezt time for {job_name = %s, tags=[%s]}: %d minutes"
            job_name
            (String.concat "," include_tags)
            (total_time_s / 60) ;
          Log.info
            "Suggested degree of parallelism {desired_run_time = %d minutes; \
             slack_factor= %d/%d}: %d jobs"
            (desired_run_time_s / 60)
            slack_factor_numerator
            slack_factor_denominator
            number_of_jobs ;
          let updated =
            update_ci_configuration ~change_threshold job_name number_of_jobs
          in
          if updated && update_coverage then
            ignore (update_coverage_configuration job_name number_of_jobs) ;
          updated)
        [("tezt", [], true); ("tezt:static-binaries", ["cli"], false)]
    in
    let* () =
      if updates && Cli.get_bool ~default:false "post_merge_request" then
        match private_token_opt with
        | None ->
            Test.fail
              "A GitLab token supplied in the environment variable \
               PRIVATE_TOKEN is required to post an MR"
        | Some private_token -> post_merge_request ~private_token ()
      else unit
    in
    unit ) ;
  Test.run ()
