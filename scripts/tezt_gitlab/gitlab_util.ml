open Tezt
open Base

let get_last_merged_pipeline ~project ~default_branch () =
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
            (* Fetches the latest pipelines by descending id. So the
               first element in the result should be the pipeline with
               the highest id and so most recent. *)
            Gitlab.(
              project_pipelines
                ~project
                ~order_by:"id"
                ~sort:"desc"
                ~sha:(commit_hash commit_parent)
                ()
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
