open Tezt
open Base

let _config_file_tezt = ".gitlab/ci/jobs/test/tezt.yml"

let _config_file_coverage = ".gitlab/ci/jobs/coverage/coverage.yml"

let records_directory = "tezt/records"

(* Typical overhead of a tezt job *)
(* let job_overhead_s = 60 *)

(* Desired run time of each tezt job, excluding the overhead *)
let desired_run_time_s = 7 * 60

let records_total_time_s () =
  let add_size total filename =
    if filename =~ rex "^\\d+\\.json$" then (
      Log.info "Reading %s" (records_directory // filename) ;
      let record = Tezt.JSON.parse_file (records_directory // filename) in
      let sum_total_time total record =
        total + JSON.(record |-> "successful_runs" |-> "total_time" |> as_int)
      in
      let total_file =
        JSON.(record |> as_list |> List.fold_left sum_total_time 0)
      in
      total + total_file)
    else total
  in
  Array.fold_left add_size 0 (Sys.readdir records_directory) / 1_000_000

let () =
  (* Register a test to benefit from error handling of Test.run,
     as well as [Background.start] etc. *)
  ( Test.register ~__FILE__ ~title:"update tezt ci configuration" ~tags:["ci"]
  @@ fun () ->
    let total_time_s = records_total_time_s () in
    let suggested_number_of_jobs = total_time_s / desired_run_time_s in
    Log.info "Total tezt time: %d minutes" (total_time_s / 60) ;
    Log.info "Suggested number of jobs: %d jobs" suggested_number_of_jobs ;
    unit ) ;
  Test.run ()
