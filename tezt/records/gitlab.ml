open Tezt
open Base

let make path =
  Uri.make ~scheme:"https" ~host:"gitlab.com" ~path:("api/v4/" ^ path)

let query_opt name value_opt =
  match value_opt with None -> [] | Some value -> [(name, [value])]

let project_pipelines ~project ?source ?ref_ ?sha ?status =
  make
    (sf "projects/%s/pipelines/" (Uri.pct_encode project))
    ~query:
      (query_opt "ref" ref_ @ query_opt "source" source @ query_opt "sha" sha
     @ query_opt "status" status)

let project_pipeline_jobs ~project ~pipeline =
  make (sf "projects/%s/pipelines/%d/jobs" (Uri.pct_encode project) pipeline)

let project_commits ~project ?ref_name =
  make
    (sf "projects/%s/repository/commits" (Uri.pct_encode project))
    ~query:(query_opt "ref_name" ref_name)

let project_job_artifact ~project ~job_id ~artifact_path =
  make
    (sf
       "projects/%s/jobs/%d/artifacts/%s"
       (Uri.pct_encode project)
       job_id
       artifact_path)

let project_job_artifacts ~project ~job_id =
  make (sf "projects/%s/jobs/%d/artifacts" (Uri.pct_encode project) job_id)

let project_merge_requests ~project =
  make (sf "projects/%s/merge_requests" (Uri.pct_encode project))

let get ?(curl_args = []) uri =
  let url = Uri.to_string uri in
  let* raw_json = Process.run_and_read_stdout "curl" (curl_args @ [url]) in
  return (JSON.parse ~origin:url raw_json)

let post ?log_call ?(curl_args = []) uri data =
  let url = Uri.to_string uri in
  let* raw_json =
    let process =
      Process.spawn
        ?log_command:log_call
        "curl"
        (curl_args
        @ [
            "-X";
            "POST";
            "-H";
            "Content-Type: application/json";
            "-s";
            url;
            "-d";
            JSON.encode data;
          ])
    in
    Process.check_and_read_stdout process
  in
  return (JSON.parse ~origin:url raw_json)

let get_output ~output_path uri =
  let url = Uri.to_string uri in
  Process.run "curl" ["--location"; url; "--output"; output_path]

let get_all uri =
  let url = Uri.to_string uri in
  let rec aux from acc =
    (* GitLab uses a lot of redirections so we use --location to follow them. *)
    let full_url = url ^ "?per_page=100&page=" ^ string_of_int from in
    let* response_body = Process.run_and_read_stdout "curl" [full_url] in
    let list = JSON.parse ~origin:url response_body |> JSON.as_list in
    Log.info "Found %d items in page %d of %s." (List.length list) from url ;
    match list with
    | [] -> return (List.rev acc)
    | _ :: _ -> aux (from + 1) (List.rev_append list acc)
  in
  aux 1 []
