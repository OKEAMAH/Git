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

(**
   File hierarchy:

   _snoop
   ├── benchmark_results
   │  ├── KAbs_int_alpha_raw.csv
   │  ├── KAbs_int_alpha.workload
   │  ├── ...
   │  └── TYPECHECKING_CODE_alpha.workload
   ├── bench_config.json
   ├── michelson_data
   │  ├── code.mich
   │  └── data.mich
   └── sapling_data
       ├── tx_0.sapling
       ├── ...
       └── tx_n.sapling
*)

let working_dir = "_snoop"

let data_generation_cfg_file = "data_generation.json"

let sapling_data_dir = "sapling_data"

let sapling_txs_file n = sf "tx_%d.sapling" n

let michelson_data_dir = "michelson_data"

let michelson_code_file = "code.mich"

let michelson_data_file = "data.mich"

let errors_file = "errors.json"

let benchmark_results_dir = "benchmark_results"

let workload name = sf "%s.workload" name

let csv name = sf "%s_raw.csv" name

let inference_results_dir = "inference_results"

let solution_csv model_name = sf "inferred_%s.csv" model_name

let solution_bin model_name = sf "inferred_%s.sol" model_name

let report_tex model_name = sf "report_%s.tex" model_name

let dep_graph model_name = sf "graph_%s.dot" model_name

(* ------------------------------------------------------------------------- *)
(* Helpers *)

type dirclass = Does_not_exist | Exists_and_is_not_a_dir | Exists

let classify_dirname dir =
  Lwt.catch
    (fun () ->
      let* stat = Lwt_unix.stat dir in
      match stat with
      | {Unix.st_kind; _} ->
          if st_kind = Unix.S_DIR then Lwt.return Exists
          else Lwt.return Exists_and_is_not_a_dir)
    (function
      | Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return Does_not_exist
      | exn -> Lwt.fail exn)

let create_dir dir =
  let* dirname = classify_dirname dir in
  match dirname with
  | Does_not_exist -> Lwt_unix.mkdir dir 0o700
  | Exists -> Lwt.return_unit
  | Exists_and_is_not_a_dir ->
      Test.fail "Can't create directory: file %s exists, aborting" dir

let copy =
  let buffer_size = 8192 in
  let buffer = Bytes.create buffer_size in
  fun input_name output_name ->
    let open Lwt_unix in
    let* fd_in = openfile input_name [O_RDONLY] 0 in
    let* fd_out = openfile output_name [O_WRONLY; O_CREAT; O_TRUNC] 0o660 in
    let rec copy_loop () =
      let* nread = read fd_in buffer 0 buffer_size in
      match nread with
      | 0 -> return ()
      | r ->
          let* _nwritten = write fd_out buffer 0 r in
          copy_loop ()
    in
    let* () = copy_loop () in
    let* () = close fd_in in
    close fd_out

let fold_dir f dirname =
  let* d = Lwt_unix.opendir dirname in
  let rec loop acc =
    Lwt.catch
      (fun () ->
        let* entry = Lwt_unix.readdir d in
        loop (f entry acc))
      (function
        | End_of_file ->
            let* () = Lwt_unix.closedir d in
            Lwt.return @@ List.rev acc
        | exn -> Lwt.fail exn)
  in

  loop []

let is_directory_nonempty dir =
  let* st = Lwt_unix.stat dir in
  match st.Unix.st_kind with
  | S_DIR -> (
      let* entries = fold_dir (fun x acc -> x :: acc) dir in
      let entries =
        List.filter
          (fun entry ->
            entry <> Filename.current_dir_name
            && entry <> Filename.parent_dir_name)
          entries
      in
      match entries with [] -> return false | _ -> return true)
  | S_REG | S_CHR | S_BLK | S_LNK | S_FIFO | S_SOCK ->
      Test.fail "Expected %s to be a directory" dir

let read_json name =
  Lwt_io.with_file ~mode:Lwt_io.Input name (fun oc ->
      let* contents = Lwt_io.read oc in
      let contents = Ezjsonm.from_string contents in
      Lwt.return contents)

let write_json ?minify json file =
  Lwt_io.with_file ~mode:Lwt_io.Output file (fun oc ->
      let contents = Ezjsonm.value_to_string ?minify json in
      let* () = Lwt_io.write oc contents in
      Lwt_io.flush oc)

let unlink_if_present file =
  Lwt.try_bind
    (fun () -> Lwt_unix.stat file)
    (function
      | {Unix.st_kind; _} -> (
          match st_kind with
          | Unix.S_REG ->
              Log.info "Removing existing %s" file ;
              let* () =
                Lwt.catch
                  (fun () -> Lwt_unix.unlink file)
                  (function
                    | Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return_unit
                    | exn -> Lwt.fail exn)
              in
              Lwt.return_unit
          | _ -> Test.fail "%s is not a regular file" file))
    (function
      | Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return_unit
      | exn -> Lwt.fail exn)
