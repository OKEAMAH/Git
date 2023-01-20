open Tezt
open Base

let usage () =
  prerr_endline
    {|Usage: PIPELINE=<PIPELINE_ID> dune exec tezt/records/update.exe

Example: to fetch test result records from
https://gitlab.com/tezos/tezos/-/pipelines/426773806, run
(from the root of the repository):

dune exec tezt/records/update.exe -- -a from=426773806

You can use the PROJECT environment variable to specify which GitLab
repository to fetch records from. Default is: tezos/tezos

The script can also be used to fetch records from the last succesful pipeline on the
latest MR merged to the default branch (configurable through the DEFAULT_BRANCH
environment variable) for a given PROJECT:

dune exec tezt/records/update.exe -- -a from=last-merged-pipeline

Finally, the script can be used to fetch the records stored in the last succesful
push pipeline in the default branch of a given project. This assumes that the
records are stored as artifacts in the folder 'tezt/records' of a job called
'tezt:fetch-records':

dune exec tezt/records/update.exe -- -a from=last-default-branch-push

|} ;
  exit 1

let project = Sys.getenv_opt "PROJECT" |> Option.value ~default:"tezos/tezos"

let default_branch =
  Sys.getenv_opt "DEFAULT_BRANCH" |> Option.value ~default:"master"

let records_directory = "tezt/records"

let fetch_record (uri, index) =
  let local_filename = index ^ ".json" in
  let local = records_directory // local_filename in
  let* () = Gitlab.get_output uri ~output_path:local in
  Log.info "Downloaded: %s" local ;
  match JSON.parse_file local with
  | exception (JSON.Error _ as exn) ->
      Log.error
        "Failed to parse downloaded JSON file, maybe the artifact has expired?" ;
      raise exn
  | (_ : JSON.t) -> return local_filename

let remove_existing_records new_records =
  let remove_if_looks_like_an_old_record filename =
    if filename =~ rex "^\\d+\\.json$" && not (List.mem filename new_records)
    then (
      let filename = records_directory // filename in
      Sys.remove filename ;
      Log.info "Removed outdated record: %s" filename)
  in
  Array.iter remove_if_looks_like_an_old_record (Sys.readdir records_directory)

let fetch_pipeline_records_from_jobs pipeline =
  Log.info "Fetching records from tezt executions in %d in %s" pipeline project ;
  let* jobs = Gitlab.(project_pipeline_jobs ~project ~pipeline () |> get_all) in
  let get_record job =
    let job_id = JSON.(job |-> "id" |> as_int) in
    let name = JSON.(job |-> "name" |> as_string) in
    match name =~* rex "^tezt (\\d+)/\\d+$" with
    | None -> None
    | Some index ->
        Some
          ( Gitlab.project_job_artifact
              ~project
              ~job_id
              ~artifact_path:("tezt-results-" ^ index ^ ".json")
              (),
            index )
  in
  let records = List.filter_map get_record jobs in
  Log.info "Found %d Tezt jobs." (List.length records) ;
  (* Return the list of new records *)
  Lwt_list.map_p fetch_record records

let fetch_pipeline_records_from_job pipeline ~job_name ~artifact_folder =
  Log.info
    "Fetching records from artifacts in job %s of pipeline %d in project %s"
    job_name
    pipeline
    project ;
  let* jobs = Gitlab.(project_pipeline_jobs ~project ~pipeline () |> get_all) in
  let job_opt =
    List.find_opt
      (fun job ->
        let name = JSON.(job |-> "name" |> as_string) in
        String.equal name job_name)
      jobs
  in
  match job_opt with
  | None -> Test.fail "Couldn't find job %S in pipeline %d" job_name pipeline
  | Some job ->
      let output_base = sf "artifacts-%d-%s" pipeline job_name in
      let output_path = Temp.file (output_base ^ ".zip") in
      let job_id = JSON.(job |-> "id" |> as_int) in
      let* () =
        Gitlab.(
          get_output ~output_path @@ project_job_artifacts ~project ~job_id ())
      in
      let tmp = Temp.dir output_base in
      let* () =
        Process.run
          "unzip"
          [
            "-b";
            (* treat all files as binary *)
            "-o";
            (* overwrite any existing with no prompts *)
            output_path;
            "-d";
            tmp;
          ]
      in
      let* () = Process.run "mkdir" ["-p"; artifact_folder] in
      let move_if_looks_like_a_record filename =
        if filename =~ rex "^\\d+\\.json$" then (
          let source_filename = tmp // artifact_folder // filename in
          let destination_filename = artifact_folder // filename in
          (* We cannot use [Sys.rename] here because we are not sure the source
             and destination are on the same device. *)
          let* () =
            Process.run "cp" ["-v"; source_filename; destination_filename]
          in
          Log.info "Moved: %s -> %s" source_filename destination_filename ;
          return (Some filename))
        else return None
      in
      (* Return the list of new records *)
      Lwt_list.filter_map_s
        move_if_looks_like_a_record
        (Sys.readdir (tmp // artifact_folder) |> Array.to_list)

let get_last_merged_pipeline () =
  let is_merge_commit commit =
    (* This script assumes that the start commit is part of a branch following
       a semi-linear history and that merged branches are linear (this should
       be the case for the default branch on tezos/tezos).  In that setting,
       only merge commits have two parents. *)
    List.length JSON.(commit |-> "parent_ids" |> as_list) = 2
  in
  Log.info
    "Searching for latest merge commit in project %s on branch %s"
    project
    default_branch ;
  let commit_hash commit = JSON.(commit |-> "id" |> as_string) in
  let* commits =
    Gitlab.(project_commits ~project ~ref_name:default_branch () |> get)
  in
  let commits = JSON.as_list commits in
  let rec aux = function
    | [] | [_] ->
        Test.fail
          "Could not find a merge commit in the last %d commits on '%s'"
          (List.length commits)
          default_branch
    | commit :: commit_parent :: commits ->
        if is_merge_commit commit then (
          Log.info "%s is a merge commit parent" (commit_hash commit_parent) ;
          let* pipelines =
            Gitlab.(
              project_pipelines ~project ~sha:(commit_hash commit_parent) ()
              |> get)
          in
          match JSON.as_list pipelines with
          | pipeline :: _ ->
              let pipeline = JSON.(pipeline |-> "id" |> as_int) in
              Log.info
                "%s has a pipeline %d"
                (commit_hash commit_parent)
                pipeline ;
              return pipeline
          | [] ->
              Log.info "%s has no pipelines, skipping" (commit_hash commit) ;
              aux (commit_parent :: commits))
        else (
          Log.info "%s is not a merge commit, skipping" (commit_hash commit) ;
          aux (commit_parent :: commits))
  in
  aux commits

let get_last_default_branch_push_pipeline () =
  (* Returns the ID of the last push-pipeline on the default branch *)
  let* pipelines =
    Gitlab.(
      project_pipelines
        ~project
        ~status:"success"
        ~source:"push"
        ~ref_:default_branch
        ()
      |> get)
  in
  return JSON.(pipelines |=> 0 |-> "id" |> as_int)

type from = Pipeline of int | Last_merged_pipeline | Last_default_branch_push

let cli_get_from =
  match Cli.get ~default:None (fun s -> Some (Some s)) "from" with
  | Some "last-merged-pipeline" -> Last_merged_pipeline
  | Some "last-default-branch-push" -> Last_default_branch_push
  | Some s -> (
      match int_of_string_opt s with Some i -> Pipeline i | None -> usage ())
  | None -> usage ()

let () =
  (* Register a test to benefit from error handling of Test.run,
     as well as [Background.start] etc. *)
  ( Test.register ~__FILE__ ~title:"update records" ~tags:["update"] @@ fun () ->
    let* new_records =
      match cli_get_from with
      | Pipeline pipeline_id -> fetch_pipeline_records_from_jobs pipeline_id
      | Last_merged_pipeline ->
          let* pipeline_id = get_last_merged_pipeline () in
          fetch_pipeline_records_from_jobs pipeline_id
      | Last_default_branch_push ->
          let* pipeline = get_last_default_branch_push_pipeline () in
          fetch_pipeline_records_from_job
            pipeline
            ~job_name:"tezt:fetch-records"
            ~artifact_folder:"tezt/records"
    in
    remove_existing_records new_records ;
    unit ) ;
  Test.run ()
