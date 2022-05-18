(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

let curl_path_cache = ref None

let get () =
  Process.(
    try
      let* curl_path =
        match !curl_path_cache with
        | Some curl_path -> return curl_path
        | None ->
            let* curl_path =
              run_and_read_stdout "sh" ["-c"; "command -v curl"]
            in
            let curl_path = String.trim curl_path in
            curl_path_cache := Some curl_path ;
            return curl_path
      in
      return
      @@ Some
           (fun ~url ->
             let* output = run_and_read_stdout curl_path ["-s"; url] in
             return (JSON.parse ~origin:url output))
    with _ -> return @@ None)

let post () =
  Process.(
    try
      let* curl_path =
        match !curl_path_cache with
        | Some curl_path -> return curl_path
        | None ->
            let* curl_path =
              run_and_read_stdout "sh" ["-c"; "command -v curl"]
            in
            let curl_path = String.trim curl_path in
            curl_path_cache := Some curl_path ;
            return curl_path
      in
      return
      @@ Some
           (fun ~url data ->
             let* output =
               run_and_read_stdout
                 curl_path
                 [
                   "-X";
                   "POST";
                   "-H";
                   "Content-Type: application/json";
                   "-s";
                   url;
                   "-d";
                   JSON.encode data;
                 ]
             in
             return (JSON.parse ~origin:url output))
    with _ -> return @@ None)

let stream () =
  let open Process in
  try
    let* curl_path =
      match !curl_path_cache with
      | Some curl_path -> return curl_path
      | None ->
          let* curl_path = run_and_read_stdout "sh" ["-c"; "command -v curl"] in
          let curl_path = String.trim curl_path in
          curl_path_cache := Some curl_path ;
          return curl_path
    in
    return
    @@ Some
         (fun ~url ->
           let process = spawn curl_path ["-s"; "-N"; url] in
           let line_stream = Lwt_io.read_lines (Process.stdout process) in
           let json_stream =
             Lwt_stream.map
               (fun line -> JSON.parse ~origin:url line)
               line_stream
           in
           let close () = Process.terminate process in
           (json_stream, close))
  with _ -> return None
