(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
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

open Base

let reset_functions = ref []

let declare_reset_function f = reset_functions := f :: !reset_functions

let before_test_run_functions = ref []

let before_test_run f =
  before_test_run_functions := f :: !before_test_run_functions

(* Prepare a promise that will resolve on SIGINT
   (e.g. when the user presses Ctrl+C).

   We need a new promise everytime because they get canceled. *)
let sigint =
  let received_sigint = ref false in
  fun () ->
    if !received_sigint then unit
    else
      let promise, resolver = Lwt.task () in
      Sys.(set_signal sigint)
        (Signal_handle
           (fun _ ->
             (* If the user presses Ctrl+C again, let the program die immediately. *)
             received_sigint := true ;
             Sys.(set_signal sigint) Signal_default ;
             Lwt.wakeup_later resolver ())) ;
      promise

exception Failed of string

let () =
  Printexc.register_printer @@ function
  | Failed message -> Some message
  | _ -> None

let fail ?__LOC__ x =
  Format.kasprintf
    (fun message ->
      let message =
        match __LOC__ with
        | None -> message
        | Some loc -> sf "%s: %s" loc message
      in
      raise (Failed message))
    x

let global_starting_time = Unix.gettimeofday ()

module Summed_durations : sig
  type t

  val zero : t

  val single_seconds : float -> t

  val ( + ) : t -> t -> t

  val total_seconds : t -> float

  val total_nanoseconds : t -> int64

  val count : t -> int

  val encode : t -> JSON.u

  (* May raise [JSON.Error]. *)
  val decode : JSON.t -> t
end = struct
  (* Information about how much time a test takes to run.
     Field [total_time_ns] contains the sum of the duration of runs in nanoseconds,
     and [count] contains the number of runs.
     By storing integers we ensure commutativity and associativity (which would not
     be the case with floats). *)
  type t = {total_time : int64; count : int}

  let zero = {total_time = 0L; count = 0}

  let single_seconds time =
    {total_time = Int64.of_float (time *. 1_000_000.); count = 1}

  let ( + ) a b =
    {
      total_time = Int64.add a.total_time b.total_time;
      count = a.count + b.count;
    }

  let total_seconds {total_time; count = _} =
    Int64.to_float total_time /. 1_000_000.

  let total_nanoseconds {total_time; count = _} = total_time

  let count {count; _} = count

  let encode {total_time; count} =
    if total_time = 0L && count = 0 then `Null
    else
      `O
        [
          ("total_time", `String (Int64.to_string total_time));
          ("count", `String (string_of_int count));
        ]

  let decode (json : JSON.t) =
    if JSON.is_null json then zero
    else
      {
        total_time = JSON.(json |-> "total_time" |> as_int64);
        count = JSON.(json |-> "count" |> as_int);
      }
end

type seed = Fixed of int | Random

(* Field [id] is used to be able to iterate on tests in order of registration.
   Field [result] contains the result of the last time the test was run.
   If the test was not run, it contains [None]. *)
type test = {
  id : int;
  file : string;
  title : string;
  tags : string list;
  seed : seed;
  body : unit -> unit Lwt.t;
  mutable session_successful_runs : Summed_durations.t;
  mutable session_failed_runs : Summed_durations.t;
  mutable session_retries : int;
  mutable past_records_successful_runs : Summed_durations.t;
  mutable past_records_failed_runs : Summed_durations.t;
  mutable result : Log.test_result option;
}

type t = test

type used_seed = Used_fixed | Used_random of int

type test_result = {test_result : Log.test_result; seed : used_seed}

let really_run ~sleep ~clean_up ~temp_start ~temp_stop ~temp_clean_up test =
  Log.info "Starting test: %s" test.title ;
  let seed =
    match test.seed with
    | Fixed seed ->
        Random.init seed ;
        Used_fixed
    | Random -> (
        match Cli.options.seed with
        | Some seed ->
            Random.init seed ;
            Used_random seed
        | None ->
            Random.self_init () ;
            let seed = Random.int 0x3FFF_FFFF in
            Random.init seed ;
            Log.info "Random seed: %d" seed ;
            Used_random seed)
  in
  List.iter (fun reset -> reset ()) !reset_functions ;
  test.result <- None ;
  (* It may happen that the promise of the function resolves successfully
     at the same time as a background promise is rejected or that we
     receive SIGINT. To handle those race conditions, setting the value
     of [test.result] is done through [set_test_result], which makes sure that:
     - if the test was aborted, [test.result] is [Aborted];
     - otherwise, if anything went wrong, [test.result] is [Failed];
     - the error message in [Failed] is the first error that was encountered. *)
  let set_test_result new_result =
    match test.result with
    | None -> test.result <- Some new_result
    | Some old_result -> (
        match (old_result, new_result) with
        | Successful, _ | Failed _, Aborted -> test.result <- Some new_result
        | Failed _, (Successful | Failed _) | Aborted, _ -> ())
  in
  let fail_promise, fail_awakener = Lwt.task () in
  (* Ensure that errors raised from background promises are logged
     and cause the test to fail immediately. *)
  let already_woke_up_fail_promise = ref false in
  let handle_background_exception exn =
    let message = Printexc.to_string exn in
    Log.error "%s" message ;
    set_test_result (Log.Failed message) ;
    if not !already_woke_up_fail_promise then (
      already_woke_up_fail_promise := true ;
      Lwt.wakeup_later fail_awakener ())
  in
  Background.start handle_background_exception ;
  (* Run the test until it succeeds, fails, or we receive SIGINT. *)
  let main_temporary_directory = temp_start () in
  let* () =
    let run_test () =
      let* () = test.body () in
      set_test_result Successful ;
      unit
    in
    let handle_exception = function
      | Lwt.Canceled ->
          (* Aborted with SIGINT, or [fail_promise] resolved (possibly because of
             an [async] promise). So we already logged what happened. *)
          unit
      | exn ->
          let message = Printexc.to_string exn in
          set_test_result (Failed message) ;
          Log.error "%s" message ;
          unit
    in
    let handle_sigint () =
      let* () = sigint () in
      Log.debug "Received SIGINT." ;
      set_test_result Aborted ;
      unit
    in
    let global_timeout =
      match Cli.options.global_timeout with
      | None -> []
      | Some delay ->
          let local_starting_time = Unix.gettimeofday () in
          let remaining_delay =
            max 0. (delay -. local_starting_time +. global_starting_time)
          in
          [
            (let* () = sleep remaining_delay in
             fail
               "the set of tests took more than specified global timeout (%gs) \
                to run"
               delay);
          ]
    in
    let test_timeout =
      match Cli.options.test_timeout with
      | None -> []
      | Some delay ->
          [
            (let* () = sleep delay in
             fail "test took more than specified timeout (%gs) to run" delay);
          ]
    in
    Lwt.catch
      (fun () ->
        Lwt.pick
          ((run_test () :: handle_sigint () :: fail_promise :: global_timeout)
          @ test_timeout))
      handle_exception
  in
  let* () = clean_up () in
  (* Remove temporary files. *)
  let kept_temp =
    try
      match Cli.options.temporary_file_mode with
      | Delete ->
          temp_clean_up () ;
          false
      | Delete_if_successful ->
          if test.result = Some Successful then (
            temp_clean_up () ;
            false)
          else (
            temp_stop () ;
            true)
      | Keep ->
          temp_stop () ;
          true
    with exn ->
      Log.warn "Failed to clean up: %s" (Printexc.to_string exn) ;
      true
  in
  if kept_temp then
    Log.report "Temporary files can be found in: %s" main_temporary_directory ;
  (* Resolve all pending promises so that they won't do anything
     (like raise [Canceled]) during the next test. *)
  let* () = Background.stop () in
  (* Return test result. *)
  let test_result =
    match test.result with
    | None ->
        (* Should not happen: after the test ends we always set [result] to [Some].
           But if it does happen we assume that it failed and that we failed to
           maintain this invariant. *)
        Log.Failed "unknown error"
    | Some result -> result
  in
  (* Flush logs. *)
  Option.iter flush Cli.options.log_file ;
  return {test_result; seed}

let rec really_run_with_retry ~sleep ~clean_up ~temp_start ~temp_stop
    ~temp_clean_up remaining_retry_count test =
  let* test_result =
    really_run ~sleep ~clean_up ~temp_start ~temp_stop ~temp_clean_up test
  in
  match test_result with
  | {test_result = Failed _; _} when remaining_retry_count > 0 ->
      Log.warn
        "%d retry(ies) left for test: %s"
        remaining_retry_count
        test.title ;
      test.session_retries <- test.session_retries + 1 ;
      really_run_with_retry
        ~sleep
        ~clean_up
        ~temp_start
        ~temp_stop
        ~temp_clean_up
        (remaining_retry_count - 1)
        test
  | x -> return x

let run_one ~sleep ~clean_up ~temp_start ~temp_stop ~temp_clean_up test =
  really_run_with_retry
    ~sleep
    ~clean_up
    ~temp_start
    ~temp_stop
    ~temp_clean_up
    Cli.options.retry
    test

(* Radix trees for string lists.

   Similar to [Set.Make (struct type t = string list end)], except that it provides
   functions to work on prefixes. *)
module String_tree : sig
  type t

  val empty : t

  val add : string list -> t -> t

  (* Test whether a tree contains a list that starts with a given prefix.

     [mem_prefix prefix tree] returns [true] if, and only if [tree] contains
     a [list] of which [prefix] is a prefix. *)
  val mem_prefix : string list -> t -> bool

  (* Test whether a tree contains a prefix of a given list.

     [mem_prefix_of list tree] returns [true] if a list that was added in [tree]
     is a prefix of [list]. *)
  val mem_prefix_of : string list -> t -> bool
end = struct
  (* Note: [value] could actually have type [bool].
     But by storing the list we avoid having to build it again, so it's probably
     more efficient that way, as long as we don't need to take a subtree of a tree
     because we rely on the invariant that [value] is the path from the root. *)
  type t = {subtrees : t String_map.t; value : string list option; count : int}

  let empty = {subtrees = String_map.empty; value = None; count = 0}

  let add path tree =
    let rec add items tree =
      match items with
      | [] -> {tree with value = Some path; count = tree.count + 1}
      | head :: tail ->
          let dir =
            match String_map.find_opt head tree.subtrees with
            | None -> empty
            | Some dir -> dir
          in
          let dir = add tail dir in
          {
            tree with
            subtrees = String_map.add head dir tree.subtrees;
            count = tree.count + 1;
          }
    in
    add path tree

  let rec sub path tree =
    match path with
    | [] -> tree
    | head :: tail -> (
        match String_map.find_opt head tree.subtrees with
        | None -> empty
        | Some tree -> sub tail tree)

  let mem_prefix path tree = (sub path tree).count > 0

  let mem_prefix_of path tree =
    let rec aux items tree =
      if String_map.cardinal tree.subtrees = 0 then true
      else
        match items with
        | [] -> false
        | head :: tail -> (
            match String_map.find_opt head tree.subtrees with
            | None -> false
            | Some tree -> aux tail tree)
    in
    if tree.count = 0 then false else aux path tree
end

let dir_sep =
  if String.length Filename.dir_sep = 1 then Filename.dir_sep.[0] else '/'

let split_file_rev file = String.split_on_char dir_sep file |> List.rev

let files_to_run_tree =
  List.fold_left
    (fun tree file -> String_tree.add (split_file_rev file) tree)
    String_tree.empty
    Cli.options.files_to_run

let files_not_to_run_tree =
  List.fold_left
    (fun tree file -> String_tree.add (split_file_rev file) tree)
    String_tree.empty
    Cli.options.files_not_to_run

let test_should_be_run ~file ~title ~tags =
  let uid = file ^ ": " ^ title in
  let match_uid pattern = uid =~ pattern in
  List.for_all (fun tag -> List.mem tag tags) Cli.options.tags_to_run
  && (not
        (List.exists (fun tag -> List.mem tag tags) Cli.options.tags_not_to_run))
  && (match Cli.options.tests_to_run with
     | [] -> true
     | titles -> List.mem title titles)
  && (not (List.mem title Cli.options.tests_not_to_run))
  && (match Cli.options.patterns_to_run with
     | [] -> true
     | patterns -> List.exists match_uid patterns)
  && (not (List.exists match_uid Cli.options.patterns_not_to_run))
  && (match Cli.options.files_to_run with
     | [] -> true
     | _ -> String_tree.mem_prefix_of (split_file_rev file) files_to_run_tree)
  &&
  match Cli.options.files_not_to_run with
  | [] -> true
  | _ ->
      not
      @@ String_tree.mem_prefix_of (split_file_rev file) files_not_to_run_tree

let tag_rex = rex "^[a-z0-9_]{1,32}$"

let check_tags tags =
  match List.filter (fun tag -> tag =~! tag_rex) tags with
  | [] -> ()
  | invalid_tags ->
      List.iter (Printf.eprintf "Invalid tag: %S\n") invalid_tags ;
      Printf.eprintf
        "Tags may only use lowercase letters, digits and underscores, and must \
         be at most 32 character long.\n" ;
      exit 1

let known_files = ref String_tree.empty

let known_titles = ref String_set.empty

let known_tags = ref String_set.empty

let register_file file =
  known_files := String_tree.add (split_file_rev file) !known_files

let register_title title = known_titles := String_set.add title !known_titles

let register_tag tag = known_tags := String_set.add tag !known_tags

(* Check that all [specified] values are in [!known]. *)
let check_existence kind known specified =
  String_set.iter
    (Log.warn "Unknown %s: %s" kind)
    (String_set.diff (String_set.of_list specified) !known)

(* Check that all [suffixes] are suffixes of files that exist in [!known_files]. *)
let check_suffix_existence suffixes =
  List.iter
    (fun suffix ->
      let suffix_split = split_file_rev suffix in
      if String_tree.(not (mem_prefix suffix_split !known_files)) then
        Log.warn "Unknown file or file suffix: %s" suffix)
    suffixes

(* Tests added using [register] and that match command-line filters. *)
let registered : test String_map.t ref = ref String_map.empty

(* Sort registred jobs in the registration order. *)
let list_registered () =
  let list = ref [] in
  String_map.iter (fun _ test -> list := test :: !list) !registered ;
  let by_id {id = a; _} {id = b; _} = Int.compare a b in
  List.sort by_id !list

(* Using [iter_registered] instead of [String_map.iter] allows to more easily
   change the representation of [registered] in the future if needed. *)
let iter_registered f = List.iter (fun test -> f test) (list_registered ())

let fold_registered acc f =
  String_map.fold (fun _ test acc -> f acc test) !registered acc

(* Map [register] as if it was a list, to obtain a list. *)
let map_registered_list f =
  (* By using [list_registered] we ensure the resulting list is
     in order of registration. *)
  List.map f (list_registered ())

let get_test_by_title test_title = String_map.find_opt test_title !registered

let list_tests include_time format =
  match format with
  | `Tsv ->
      iter_registered
      @@ fun {
               file;
               title;
               tags;
               past_records_successful_runs;
               past_records_failed_runs;
               _;
             } ->
      Printf.printf "%s\t%s\t%s" file title (String.concat " " tags) ;
      if include_time then
        Printf.printf
          "\t%Ld\t%d\t%Ld\t%d"
          (Summed_durations.total_nanoseconds past_records_successful_runs)
          (Summed_durations.count past_records_successful_runs)
          (Summed_durations.total_nanoseconds past_records_failed_runs)
          (Summed_durations.count past_records_failed_runs) ;
      Printf.printf "\n%!"
  | `Ascii_art ->
      let file_header = "FILE" in
      let title_header = "TITLE" in
      let tags_header = "TAGS" in
      let time_header = "TIME" in
      let time_total_header = "TOTAL:" in
      (* Contains the sum of the _average time_ of the past successful
         executions of the selected tests. *)
      let time_total = ref 0L in
      let list =
        map_registered_list
        @@ fun {
                 file;
                 title;
                 tags;
                 past_records_successful_runs;
                 past_records_failed_runs;
                 _;
               } ->
        (* A human-readable digest of the test results from the
           record. Will contain [TIME [(COUNT)]], where [TIME] is the
           average of successful runs in seconds and [COUNT] is
           [SUCCESSFUL/(SUCCESSFUL+FAILED)]. If there is only one
           successful test, then [COUNT] is omitted. If the test lacks
           a past record, then the digest will just be [-]. *)
        let time_s =
          let successful, failed =
            Summed_durations.
              ( count past_records_successful_runs,
                count past_records_failed_runs )
          in
          let count =
            match (successful, failed) with
            | 0, 0 | 1, 0 -> None
            | _ -> Some (sf "(%d/%d)" successful (successful + failed))
          in
          let time_avg =
            if successful > 0 then (
              let time_ns_avg =
                Int64.(
                  div
                    Summed_durations.(
                      past_records_successful_runs |> total_nanoseconds)
                    (of_int successful))
              in
              time_total := Int64.add !time_total time_ns_avg ;
              Some (Int64.to_float time_ns_avg /. 1_000_000.))
            else None
          in
          (match time_avg with Some time -> sf "%.2f" time | None -> "-")
          ^ match count with Some count -> " " ^ count | None -> ""
        in
        (file, title, String.concat ", " tags, time_s)
      in
      let time_total =
        sf
          "%.2f (%d)"
          (Int64.to_float !time_total /. 1_000_000.)
          (List.length list)
      in
      (* Compute the size of each column. *)
      let file_size, title_size, tags_size, time_size =
        List.fold_left
          (fun (max_file, max_title, max_tags, max_time)
               (file, title, tags, time) ->
            ( max max_file (String.length file),
              max max_title (String.length title),
              max max_tags (String.length tags),
              max max_time (String.length time) ))
          ( String.length file_header,
            String.length title_header,
            String.length tags_header,
            String.length time_header )
          list
      in
      let file_size, title_size, tags_size, time_size =
        if include_time then
          ( max file_size (String.length time_total_header),
            title_size,
            tags_size,
            max time_size (String.length time_total) )
        else (file_size, title_size, tags_size, time_size)
      in
      (* Prepare the line separator. *)
      let line =
        "+"
        ^ String.make (file_size + 2) '-'
        ^ "+"
        ^ String.make (title_size + 2) '-'
        ^ "+"
        ^ String.make (tags_size + 2) '-'
        ^ "+"
        ^ (if include_time then String.make (time_size + 2) '-' ^ "+" else "")
        ^ "\n"
      in
      (* Print the header row. *)
      print_string line ;
      let center size header =
        let padding = size - String.length header in
        let left_padding = padding / 2 in
        let right_padding = padding - left_padding in
        String.make left_padding ' ' ^ header ^ String.make right_padding ' '
      in
      Printf.printf
        "| %s | %s | %s |"
        (center file_size file_header)
        (center title_size title_header)
        (center tags_size tags_header) ;
      if include_time then Printf.printf " %s |" (center time_size time_header) ;
      Printf.printf "\n" ;
      print_string line ;
      (* Print rows. *)
      let pad size text =
        let padding = size - String.length text in
        text ^ String.make padding ' '
      in
      List.iter
        (fun (file, title, tags, time) ->
          Printf.printf
            "| %s | %s | %s |%s\n"
            (pad file_size file)
            (pad title_size title)
            (pad tags_size tags)
            (if include_time then sf " %s |" (pad time_size time) else ""))
        list ;

      if list <> [] then (
        if include_time then (
          print_string line ;
          Printf.printf
            "| %s | %s | %s | %s |\n"
            (pad file_size time_total_header)
            (pad title_size "")
            (pad tags_size "")
            (pad time_size time_total)) ;
        print_string line) ;
      ()

(* Total time, in seconds.
   Since this involves floats it should not be used for --job splitting. *)
let total_test_display_time ~past_records ~session test =
  let past_records =
    if past_records then
      Summed_durations.total_seconds test.past_records_successful_runs
      +. Summed_durations.total_seconds test.past_records_failed_runs
    else 0.
  in
  let session =
    if session then
      Summed_durations.total_seconds test.session_successful_runs
      +. Summed_durations.total_seconds test.session_failed_runs
    else 0.
  in
  past_records +. session

let display_time_summary () =
  let test_time = total_test_display_time ~past_records:true ~session:true in
  let total_time =
    fold_registered 0. @@ fun acc test -> acc +. test_time test
  in
  let tests_by_file =
    fold_registered String_map.empty @@ fun acc test ->
    String_map.add
      test.file
      (test :: (String_map.find_opt test.file acc |> Option.value ~default:[]))
      acc
  in
  let show_time seconds =
    let seconds = int_of_float seconds in
    if seconds < 60 then Printf.sprintf "%ds" seconds
    else Printf.sprintf "%dmin %ds" (seconds / 60) (seconds mod 60)
  in
  let print_time prefix title time =
    Printf.printf
      "%s[%d%% - %s] %s\n"
      prefix
      (int_of_float (time *. 100. /. total_time))
      (show_time time)
      title
  in
  let print_time_for_file file tests =
    print_time
      ""
      file
      (List.fold_left (fun acc test -> acc +. test_time test) 0. tests) ;
    List.iter (fun test -> print_time "- " test.title (test_time test)) tests
  in
  String_map.iter print_time_for_file tests_by_file ;
  ()

module Record = struct
  type test = {
    file : string;
    title : string;
    tags : string list;
    successful_runs : Summed_durations.t;
    failed_runs : Summed_durations.t;
  }

  let encode_obj fields =
    `O (List.filter (function _, `Null -> false | _ -> true) fields)

  let encode_test {file; title; tags; successful_runs; failed_runs} : JSON.u =
    encode_obj
      [
        ("file", `String file);
        ("title", `String title);
        ("tags", `A (List.map (fun tag -> `String tag) tags));
        ("successful_runs", Summed_durations.encode successful_runs);
        ("failed_runs", Summed_durations.encode failed_runs);
      ]

  let decode_test (json : JSON.t) : test =
    {
      file = JSON.(json |-> "file" |> as_string);
      title = JSON.(json |-> "title" |> as_string);
      tags = JSON.(json |-> "tags" |> as_list |> List.map as_string);
      successful_runs =
        Summed_durations.decode JSON.(json |-> "successful_runs");
      failed_runs = Summed_durations.decode JSON.(json |-> "failed_runs");
    }

  type t = test list

  let encode (record : t) : JSON.u = `A (List.map encode_test record)

  let decode (json : JSON.t) : t =
    JSON.(json |> as_list |> List.map decode_test)

  let output_file (record : t) filename =
    JSON.encode_to_file_u filename (encode record)

  let input_file filename : t =
    try decode (JSON.parse_file filename)
    with JSON.Error error ->
      Log.error "%s" (JSON.show_error error) ;
      exit 1

  (* Get the record for the current run. *)
  let current () =
    map_registered_list
    @@ fun {
             id = _;
             file;
             title;
             tags;
             seed = _;
             body = _;
             session_retries = _;
             session_successful_runs;
             session_failed_runs;
             past_records_successful_runs = _;
             past_records_failed_runs = _;
             result = _;
           } ->
    {
      file;
      title;
      tags;
      successful_runs = session_successful_runs;
      failed_runs = session_failed_runs;
    }

  (* Read a record and update the time information of registered tests
     that appear in this record. *)
  let use_past (record : t) =
    let update_test (recorded_test : test) =
      match String_map.find_opt recorded_test.title !registered with
      | None ->
          (* Test no longer exists or was not selected, ignoring. *)
          ()
      | Some test ->
          test.past_records_successful_runs <-
            Summed_durations.(
              test.past_records_successful_runs + recorded_test.successful_runs) ;
          test.past_records_failed_runs <-
            Summed_durations.(
              test.past_records_failed_runs + recorded_test.failed_runs)
    in
    List.iter update_test record

  (* Same as [use_past] but for --resume: ignore failed runs, and update
     current session instead of past records. *)
  let resume_from (record : t) =
    let update_test (recorded_test : test) =
      match String_map.find_opt recorded_test.title !registered with
      | None ->
          (* Test no longer exists or was not selected, ignoring. *)
          ()
      | Some test ->
          test.session_successful_runs <-
            Summed_durations.(
              test.session_successful_runs + recorded_test.successful_runs)
    in
    List.iter update_test record
end

(* Get a partition of weighted [items] where the total weights of each subset are
   approximately close to each other. *)
let knapsack (type a) bag_count (items : (int64 * a) list) :
    (int64 * a list) array =
  let bag_count = max 1 bag_count in
  (* [bags] is an array of pairs where the first value is the total
     weight of the bag and the second value is the list of items that
     are currently allocated to this bag. *)
  let bags = Array.make bag_count (0L, []) in
  (* Finding the optimal partition is NP-complete.
     We use a heuristic to find an approximation: allocate heavier items first,
     then fill the gaps with smaller items. *)
  let allocate (item_weight, item) =
    let smallest_bag =
      let best_index = ref 0 in
      let best_weight = ref Int64.max_int in
      for i = 0 to bag_count - 1 do
        let bag_weight, _ = bags.(i) in
        if bag_weight < !best_weight then (
          best_index := i ;
          best_weight := bag_weight)
      done ;
      !best_index
    in
    let bag_weight, bag_items = bags.(smallest_bag) in
    bags.(smallest_bag) <- (Int64.add bag_weight item_weight, item :: bag_items)
  in
  let longest_first (a, _) (b, _) = Int64.compare b a in
  List.iter allocate (List.sort longest_first items) ;
  bags

let split_tests_into_balanced_jobs job_count =
  let test_time test =
    (* Give a default duration of 1 second as specified by --help.
       This allows to split jobs even with no time data (otherwise all jobs
       would be grouped together). *)
    let total, count =
      Summed_durations.
        ( test.past_records_successful_runs |> total_nanoseconds,
          test.past_records_successful_runs |> count )
    in
    if count = 0 || total = 0L then 1L else Int64.(div total (of_int count))
  in
  let tests = String_map.bindings !registered |> List.map snd in
  let weighted_tests = List.map (fun test -> (test_time test, test)) tests in
  knapsack job_count weighted_tests

(* Apply --job: take the list of registered tests, split it into jobs,
   and unregister all tests that are not selected by --job. *)
let select_job () =
  match Cli.options.job with
  | None ->
      (* No --job: do not unregister any test. *)
      ()
  | Some (job_index, job_count) ->
      let jobs = split_tests_into_balanced_jobs job_count in
      (* [Cli] ensures that [1 <= job_index <= job_count],
         and [split_tests_into_balanced_jobs] ensures that its result
         has length [job_count] if [job_count >= 1]. *)
      let _, job_tests = jobs.(job_index - 1) in
      (* Reset the list of tests to run to re-fill it with the requested job. *)
      registered := String_map.empty ;
      List.iter
        (fun (test : test) ->
          registered := String_map.add test.title test !registered)
        job_tests

let skip_test () =
  if Cli.options.skip > 0 || Cli.options.only <> None then (
    (* by using [list_registered] we ensure that we sort jobs in the
       registration order, which is also the order in which tests are
       run. *)
    let list = list_registered () in
    let list = Base.drop Cli.options.skip list in
    let list =
      match Cli.options.only with
      | None -> list
      | Some only -> Base.take only list
    in
    registered := String_map.empty ;
    List.iter
      (fun (test : test) ->
        registered := String_map.add test.title test !registered)
      list)

let suggest_jobs () =
  let jobs = split_tests_into_balanced_jobs Cli.options.job_count in
  let job_count = Array.length jobs in
  (* Jobs are allocated, now display them. *)
  let display_job ~negate (total_job_time, job_tests) =
    print_endline
      (String.concat
         " "
         (List.map
            (fun test ->
              Printf.sprintf
                "%s %s"
                (if negate then "--not-title" else "--title")
                (Log.quote_shell (test : test).title))
            job_tests)
      ^ " # "
      ^ Int64.to_string (Int64.div total_job_time 1_000_000L)
      ^ "s")
  in
  let all_other_tests = ref [] in
  for i = 0 to job_count - 2 do
    display_job ~negate:false jobs.(i) ;
    List.iter
      (fun test -> all_other_tests := test :: !all_other_tests)
      (snd jobs.(i))
  done ;
  (* The last job uses --not-test so that if a test is added and the job list is not
     updated, the new test is automatically added to the last job.
     Note: if [job_count] is 1, this actually outputs no --not-test at all
     since [all_other_tests] is empty, which is consistent
     because it means to run all tests. *)
  display_job ~negate:true (fst jobs.(job_count - 1), !all_other_tests)

let output_junit filename =
  let test_time = total_test_display_time ~past_records:false ~session:true in
  with_open_out filename @@ fun ch ->
  let echo x =
    Printf.ksprintf
      (fun s ->
        output_string ch s ;
        output_char ch '\n')
      x
  in
  let count, fail_count, skipped_count, total_time =
    fold_registered (0, 0, 0, 0.)
    @@ fun (count, fail_count, skipped_count, total_time) test ->
    ( count + 1,
      (fail_count + match test.result with Some (Failed _) -> 1 | _ -> 0),
      (skipped_count
      + match test.result with None | Some Aborted -> 1 | _ -> 0),
      total_time +. test_time test )
  in
  echo {|<?xml version="1.0" encoding="UTF-8" ?>|} ;
  echo
    {|<testsuites id="tezt" name="Tezt" tests="%d" failures="%d" skipped="%d" time="%f">|}
    count
    fail_count
    skipped_count
    total_time ;
  echo
    {|  <testsuite id="tezt" name="Tezt" tests="%d" failures="%d" skipped="%d" time="%f">|}
    count
    fail_count
    skipped_count
    total_time ;
  ( iter_registered @@ fun test ->
    match test.result with
    | None | Some Aborted ->
        (* Skipped test, do not output. *)
        ()
    | Some (Successful | Failed _) ->
        let replace_entities s =
          let buffer = Buffer.create (String.length s * 2) in
          for i = 0 to String.length s - 1 do
            match s.[i] with
            | '"' -> Buffer.add_string buffer "&quot;"
            | '&' -> Buffer.add_string buffer "&amp;"
            | '\'' -> Buffer.add_string buffer "&apos;"
            | '<' -> Buffer.add_string buffer "&lt;"
            | '>' -> Buffer.add_string buffer "&gt;"
            | c -> Buffer.add_char buffer c
          done ;
          Buffer.contents buffer
        in
        let title = replace_entities test.title in
        echo
          {|    <testcase id="%s" name="%s: %s" time="%f" retries="%d">|}
          title
          (replace_entities test.file)
          title
          (test_time test)
          test.session_retries ;
        (match test.result with
        | None | Some Successful | Some Aborted -> ()
        | Some (Failed message) ->
            echo
              {|      <failure message="test failed" type="ERROR">%s</failure>|}
              (replace_entities message)) ;
        echo "    </testcase>" ) ;
  echo "  </testsuite>" ;
  echo "</testsuites>" ;
  ()

let next_id = ref 0

let register ~__FILE__ ~title ~tags ?(seed = Fixed 0) body =
  let file = __FILE__ in
  (match String_map.find_opt title !registered with
  | None -> ()
  | Some {file = other_file; tags = other_tags; _} ->
      Printf.eprintf "Error: there are several tests with title: %S\n" title ;
      Printf.eprintf
        "- first seen in: %s with tags: %s\n"
        other_file
        (String.concat ", " other_tags) ;
      Printf.eprintf
        "- also seen in: %s with tags: %s\n%!"
        file
        (String.concat ", " tags) ;
      exit 1) ;
  check_tags tags ;
  register_file file ;
  register_title title ;
  List.iter register_tag tags ;
  let id = !next_id in
  incr next_id ;
  if test_should_be_run ~file ~title ~tags then
    let test =
      {
        id;
        file;
        title;
        tags;
        seed;
        body;
        session_successful_runs = Summed_durations.zero;
        session_failed_runs = Summed_durations.zero;
        session_retries = 0;
        past_records_successful_runs = Summed_durations.zero;
        past_records_failed_runs = Summed_durations.zero;
        result = None;
      }
    in
    registered := String_map.add title test !registered

module type SCHEDULER = sig
  type request = Run_test of {test_title : string}

  type response = Test_result of test_result

  (* Run a scheduler that manages several workers.

     This starts [worker_count] workers.
     As soon as a worker is available, it calls [on_worker_available].
     [on_worker_available] shall return [None] if there is nothing else to do,
     in which case the worker is killed, or [Some (request, on_response)],
     in which case the worker executes [request].
     The result of this request, [response], is then given to [on_response]. *)
  val run :
    on_worker_available:(unit -> (request * (response -> unit)) option) ->
    worker_count:int ->
    (unit -> unit) ->
    unit

  val get_current_worker_id : unit -> int option
end

(* [iteration] is between 1 and the value of [--loop-count].
   [index] is between 1 and [test_count]. *)
type test_instance = {iteration : int; index : int}

let current_worker_id_ref = ref (fun () -> None)

let current_worker_id () = !current_worker_id_ref ()

let run_with_scheduler scheduler =
  let module Scheduler = (val scheduler : SCHEDULER) in
  current_worker_id_ref := Scheduler.get_current_worker_id ;
  List.iter (fun f -> f ()) !before_test_run_functions ;
  (* Check command-line options. *)
  check_suffix_existence Cli.options.files_to_run ;
  check_suffix_existence Cli.options.files_not_to_run ;
  check_existence "--title" known_titles Cli.options.tests_to_run ;
  check_existence "--not-title" known_titles Cli.options.tests_not_to_run ;
  check_existence
    "tag"
    known_tags
    (Cli.options.tags_to_run @ Cli.options.tags_not_to_run) ;
  (* Apply --skip and --only if needed. *)
  skip_test () ;
  (* Print a warning if no test was selected. *)
  if String_map.is_empty !registered then (
    Printf.eprintf
      "No test found for filters: %s\n%!"
      (String.concat
         " "
         (List.map
            (fun x -> "--file " ^ Log.quote_shell x)
            Cli.options.files_to_run
         @ List.map
             (fun x -> "--not-file " ^ Log.quote_shell x)
             Cli.options.files_not_to_run
         @ List.map
             (fun x -> "--title " ^ Log.quote_shell x)
             Cli.options.tests_to_run
         @ List.map
             (fun x -> "--not-title " ^ Log.quote_shell x)
             Cli.options.tests_not_to_run
         @ List.map
             (fun r -> "--match " ^ Log.quote_shell (show_rex r))
             Cli.options.patterns_to_run
         @ List.map
             (fun r -> "--not-match " ^ Log.quote_shell (show_rex r))
             Cli.options.patterns_not_to_run
         @ (match Cli.options.job with
           | Some (index, count) -> [sf "--job %d/%d" index count]
           | None -> [])
         @ (if Cli.options.skip > 0 then
            ["--skip " ^ string_of_int Cli.options.skip]
           else [])
         @ Cli.options.tags_to_run
         @ List.map (sf "/%s") Cli.options.tags_not_to_run)) ;
    if Cli.options.list = None then
      prerr_endline
        "You can use --list to get the list of tests and their tags." ;
    exit 3) ;
  (* Read records. *)
  List.iter
    Record.(fun filename -> use_past (input_file filename))
    Cli.options.from_records ;
  (* Apply --job if needed. *)
  select_job () ;
  if Cli.options.resume then (
    if Cli.options.resume_file = None then
      Cli.options.resume_file <- Some "tezt-resume.json" ;
    Option.iter
      Record.(
        fun filename ->
          if Sys.file_exists filename then resume_from (input_file filename))
      Cli.options.resume_file) ;
  (* Actually run the tests (or list them). *)
  match (Cli.options.list, Cli.options.suggest_jobs) with
  | Some format, false -> (
      match (Cli.options.time, Cli.options.from_records) with
      | true, [] ->
          prerr_endline
            "Cannot use both --list and --time without --from-record."
      | _ -> list_tests Cli.options.time format)
  | None, true -> suggest_jobs ()
  | Some _, true ->
      prerr_endline
        "Cannot use both --list and --suggest-jobs at the same time."
  | None, false ->
      let test_count = String_map.cardinal !registered in
      let failure_count = ref 0 in
      let test_queue = Queue.create () in
      let refills = ref 0 in
      let refill_queue () =
        incr refills ;
        let index = ref 0 in
        iter_registered @@ fun test ->
        incr index ;
        let test_instance = {iteration = !refills; index = !index} in
        Queue.add (test, test_instance) test_queue
      in
      (match Cli.options.loop_mode with
      | Count n when n <= 0 -> ()
      | Count _ | Infinite -> refill_queue ()) ;
      (* [stop] is used to stop dequeuing tests.
         When [stop] is [true] we no longer start new tests but we wait for
         running ones to finish. *)
      let stop = ref false in
      (* [aborted] is used to exit with the right error code in case of Ctrl+C.
         It implies [stop]. *)
      let aborted = ref false in
      let rec next_test () =
        if !stop then None
        else
          match Queue.take_opt test_queue with
          | None -> (
              match Cli.options.loop_mode with
              | Count n when !refills >= n -> None
              | Count _ | Infinite ->
                  refill_queue () ;
                  if Queue.is_empty test_queue then None else next_test ())
          | Some (test, test_instance) as x ->
              if
                Summed_durations.count test.session_successful_runs
                >= test_instance.iteration
              then
                (* Test was successful in the past according to --resume, skip. *)
                next_test ()
              else x
      in
      let a_test_failed = ref false in
      let on_worker_available () =
        match next_test () with
        | None -> None
        | Some (test, test_instance) ->
            let start = Unix.gettimeofday () in
            let on_response (Scheduler.Test_result {test_result; seed}) =
              test.result <- Some test_result ;
              let time = Unix.gettimeofday () -. start in
              (match test_result with
              | Failed _ -> incr failure_count
              | Successful | Aborted -> ()) ;
              Log.test_result
                ~test_index:test_instance.index
                ~test_count
                ~failure_count:!failure_count
                ~iteration:test_instance.iteration
                test_result
                test.title ;
              match test_result with
              | Successful ->
                  test.session_successful_runs <-
                    Summed_durations.(
                      test.session_successful_runs + single_seconds time)
              | Failed _ ->
                  Log.report
                    "Try again with: %s --verbose --file %s --title %s%s"
                    Sys.argv.(0)
                    (Log.quote_shell test.file)
                    (Log.quote_shell test.title)
                    (match seed with
                    | Used_fixed -> ""
                    | Used_random seed -> sf " --seed %d" seed) ;
                  test.session_failed_runs <-
                    Summed_durations.(
                      test.session_failed_runs + single_seconds time) ;
                  a_test_failed := true ;
                  if not Cli.options.keep_going then stop := true
              | Aborted ->
                  stop := true ;
                  aborted := true
            in
            Some (Scheduler.Run_test {test_title = test.title}, on_response)
      in
      Scheduler.run ~on_worker_available ~worker_count:Cli.options.job_count
      @@ fun () ->
      (* Output reports. *)
      Option.iter output_junit Cli.options.junit ;
      let record = Record.current () in
      Option.iter (Record.output_file record) Cli.options.record ;
      Option.iter (Record.output_file record) Cli.options.resume_file ;
      if Cli.options.time then display_time_summary () ;
      if !aborted then exit 2 else if !a_test_failed then exit 1
