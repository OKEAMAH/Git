(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* ------------------------------------------------------------------------- *)
(* Data generation parameters*)

type cfg = {
  sapling_tx_count : int;
  micheline_jobs : int;
  micheline_code_count : int;
  micheline_data_count : int;
}

let default_cfg =
  {
    sapling_tx_count = 40;
    micheline_jobs = 4;
    micheline_code_count = 75;
    micheline_data_count = 75;
  }

let pp_cfg fmtr cfg =
  Format.fprintf
    fmtr
    "@[<v 1>{ sapling_tx_counts = %d ;@;\
    \ micheline_jobs = %d;@;\
    \ micheline_code_count = %d;@;\
    \ micheline_data_count = %d }@]"
    cfg.sapling_tx_count
    cfg.micheline_jobs
    cfg.micheline_code_count
    cfg.micheline_data_count

let cfg_to_json cfg =
  let open Ezjsonm in
  dict
    [
      ("sapling_tx_count", int cfg.sapling_tx_count);
      ("micheline_jobs", int cfg.micheline_jobs);
      ("micheline_code_count_per_process", int cfg.micheline_code_count);
      ("micheline_data_count_per_process", int cfg.micheline_code_count);
    ]

let get_field json field =
  match Ezjsonm.find_opt json field with
  | None -> 0
  | Some value -> (
      match Ezjsonm.get_int value with
      | exception Ezjsonm.Parse_error _ ->
          let pp_sep fmtr () = Format.fprintf fmtr "/" in
          let fmtr = Format.pp_print_list ~pp_sep Format.pp_print_string in
          let field = Format.asprintf "%a" fmtr field in
          Test.fail "Expected integer value for field %s" field
      | i -> i)

let bound_check var bound name =
  if var < bound then Test.fail "Prepare_data: %s < %d" name bound

let cfg_of_json json =
  let sapling_tx_count = get_field json ["sapling_tx_count"] in
  let micheline_jobs = get_field json ["micheline_jobs"] in
  let micheline_code_count =
    get_field json ["micheline_code_count_per_process"]
  in
  let micheline_data_count =
    get_field json ["micheline_data_count_per_process"]
  in
  bound_check sapling_tx_count 0 "sapling_tx_count" ;
  bound_check micheline_jobs 1 "micheline_jobs" ;
  bound_check micheline_code_count 0 "micheline_code_count_per_process" ;
  bound_check micheline_data_count 0 "micheline_data_count_per_process" ;
  {sapling_tx_count; micheline_jobs; micheline_code_count; micheline_data_count}

(* ------------------------------------------------------------------------- *)

let prepare_workdir () =
  Lwt.catch
    (fun () ->
      let open Files in
      let* () = create_dir working_dir in
      let* () = create_dir (working_dir // sapling_data_dir) in
      let* () = create_dir (working_dir // michelson_data_dir) in
      let* () = create_dir (working_dir // benchmark_results_dir) in
      create_dir (working_dir // inference_results_dir))
    (function
      | Unix.Unix_error (code, fname, prm) ->
          Test.fail
            "Error %s in %s, called with %s@."
            (Unix.error_message code)
            fname
            prm
      | e -> raise e)

let call_if_no_file ~file ~if_present ~if_absent =
  let* exists = Lwt_unix.file_exists file in
  if exists then (
    Log.info "%s exists, skipping" file ;
    if_present)
  else if_absent ()

let prepare_sapling_data snoop cfg protocol =
  let file =
    ( Files.(working_dir // sapling_data_dir // sapling_txs_file 0),
      fun file ->
        call_if_no_file ~file ~if_present:Lwt.return_unit ~if_absent:(fun () ->
            Snoop.sapling_generate
              ~protocol
              ~tx_count:1
              ~max_inputs:0
              ~max_outputs:0
              ~file
              snoop) )
  in
  let file1 =
    ( Files.(working_dir // sapling_data_dir // sapling_txs_file 1),
      fun file ->
        call_if_no_file ~file ~if_present:Lwt.return_unit ~if_absent:(fun () ->
            Snoop.sapling_generate
              ~protocol
              ~tx_count:cfg.sapling_tx_count
              ~max_inputs:0
              ~max_outputs:60
              ~file
              snoop) )
  in
  let file2 =
    ( Files.(working_dir // sapling_data_dir // sapling_txs_file 2),
      fun file ->
        call_if_no_file ~file ~if_present:Lwt.return_unit ~if_absent:(fun () ->
            Snoop.sapling_generate
              ~protocol
              ~tx_count:cfg.sapling_tx_count
              ~max_inputs:60
              ~max_outputs:0
              ~file
              snoop) )
  in
  let file3 =
    ( Files.(working_dir // sapling_data_dir // sapling_txs_file 3),
      fun file ->
        call_if_no_file ~file ~if_present:Lwt.return_unit ~if_absent:(fun () ->
            Snoop.sapling_generate
              ~protocol
              ~tx_count:cfg.sapling_tx_count
              ~max_inputs:60
              ~max_outputs:60
              ~file
              snoop) )
  in
  let stream = Lwt_stream.of_list [file; file1; file2; file3] in
  let affinity = Lwt_unix.get_affinity () |> List.length in
  let affinity = match affinity with 1 -> 1 | n -> n - 1 in
  Lwt_stream.iter_n ~max_concurrency:affinity (fun (file, f) -> f file) stream

let concat snoop protocol tmp_files target =
  Log.info "Copying %s to %s" (List.hd tmp_files) target ;
  let* () = Files.copy (List.hd tmp_files) target in
  Lwt_list.iter_s
    (fun tmp_file ->
      Snoop.michelson_concat
        ~protocol
        ~file1:target
        ~file2:tmp_file
        ~target
        snoop)
    (List.tl tmp_files)

(* We spawn several michelson generation processes in parallel for speed
   and concat the results *)

let prepare_michelson affinity kind snoop cfg protocol =
  let target, terms_count =
    match kind with
    | Snoop.Code ->
        ( Files.(working_dir // michelson_data_dir // michelson_code_file),
          cfg.micheline_code_count )
    | Snoop.Data ->
        ( Files.(working_dir // michelson_data_dir // michelson_data_file),
          cfg.micheline_data_count )
  in
  call_if_no_file ~file:target ~if_present:Lwt.return_unit ~if_absent:(fun () ->
      let indices = range 0 (cfg.micheline_jobs - 1) in
      let tmp_files =
        List.map
          (fun n ->
            Files.(working_dir // michelson_data_dir // sf "generated.tmp.%d" n))
          indices
      in
      let stream = Lwt_stream.of_list tmp_files in
      Lwt.finalize
        (fun () ->
          let* () =
            Lwt_stream.iter_n
              ~max_concurrency:affinity
              (fun file ->
                let* process =
                  call_if_no_file
                    ~file
                    ~if_present:Lwt.return_none
                    ~if_absent:(fun () ->
                      Lwt.return_some
                      @@ Snoop.spawn_michelson_generate
                           ~protocol
                           ~terms_count
                           ~kind
                           ~file
                           snoop)
                in
                match process with
                | Some pr -> Process.check pr
                | None -> Lwt.return_unit)
              stream
          in
          concat snoop protocol tmp_files target)
        (fun () -> Lwt_list.iter_s Files.unlink_if_present tmp_files))

let prepare_michelson_data snoop cfg protocol =
  let affinity = Lwt_unix.get_affinity () |> List.length in
  match affinity with
  | n when n <= 2 ->
      let* () = prepare_michelson n Snoop.Code snoop cfg protocol in
      prepare_michelson n Snoop.Data snoop cfg protocol
  | n when n mod 2 = 0 ->
      let affinity = (n - 1) / 2 in
      let* () = prepare_michelson affinity Snoop.Code snoop cfg protocol in
      prepare_michelson affinity Snoop.Data snoop cfg protocol
  | n ->
      let affinity = n / 2 in
      let* () = prepare_michelson affinity Snoop.Code snoop cfg protocol in
      prepare_michelson affinity Snoop.Data snoop cfg protocol

let load_cfg () =
  let file = Files.(working_dir // data_generation_cfg_file) in
  let* exists = Lwt_unix.file_exists file in
  if exists then (
    let* json = Files.read_json file in
    let cfg = cfg_of_json json in
    Log.info "Loaded data generation parameters" ;
    return cfg)
  else (
    Log.info "Using default data generation parameters" ;
    return default_cfg)

let main protocol =
  Log.info "Entering Prepare_data.main" ;
  let snoop = Snoop.create () in
  let* () = prepare_workdir () in
  let* cfg = load_cfg () in
  Log.info "%s" (Format.asprintf "%a" pp_cfg cfg) ;
  let* () = prepare_sapling_data snoop cfg protocol in
  prepare_michelson_data snoop cfg protocol
