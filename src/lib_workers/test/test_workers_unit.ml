(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

module Assert = Lib_test.Assert
open Mocked_worker
module Event = Internal_event.Simple

type error += TzCrashError

exception RaisedExn

module type SELF = sig
  type self

  val log_event : self -> string -> unit Lwt.t
end

module Handlers (S : SELF) = struct
  type self = S.self

  let on_request :
      type r request_error.
      self -> (r, request_error) Request.t -> (r, request_error) result Lwt.t =
   fun w request ->
    let open Lwt_result_syntax in
    match request with
    | Request.RqA i ->
        let*! () = S.log_event w (Format.sprintf "RqA %d" i) in
        let*! () = if i = 1 then Lwt.pause () else Lwt.return_unit in
        return_unit
    | Request.RqB ->
        let*! () = S.log_event w (Format.sprintf "RqB") in
        return_unit
    | Request.RqErr Crash -> Lwt.return_error CrashError
    | Request.RqErr Simple -> Lwt.return_error SimpleError
    | Request.RqErr RaiseExn -> raise RaisedExn

  type launch_error = error trace

  let on_launch _w _name _param =
    let open Lwt_result_syntax in
    return (ref [], ref 0)

  let on_error (type a b) w _st (r : (a, b) Request.t) (errs : b) :
      unit tzresult Lwt.t =
    let open Lwt_result_syntax in
    let (history, _) = Worker.state w in
    match r with
    | Request.RqA _ -> return_unit
    | Request.RqB -> return_unit
    | Request.RqErr _ -> (
        match errs with
        | CrashError -> Lwt.return_error [TzCrashError]
        | SimpleError ->
            history := "RqErr" :: !history ;
            return_unit)

  let on_completion w r _ _st =
    let (history, n_completion) = Worker.state w in
    let () =
      match Request.view r with
      | Request.View (RqA i) -> history := Format.sprintf "RqA %d" i :: !history
      | View RqB -> history := "RqB" :: !history
      | View (RqErr _) -> ()
    in
    incr n_completion ;
    Lwt.return_unit

  let on_no_request _ = Lwt.return_unit

  let on_close _w = Lwt.return_unit
end

let create table handlers ?max_completion ?timeout name =
  Worker.launch ?timeout table name max_completion handlers

let create_queue =
  let table = Worker.create_table Queue in
  create
    table
    (module Handlers (struct
      type self = Worker.infinite Worker.queue Worker.t

      let log_event = Worker.log_event
    end))

let create_bounded =
  let table = Worker.create_table (Bounded {size = 2}) in
  create
    table
    (module Handlers (struct
      type self = Worker.bounded Worker.queue Worker.t

      let log_event = Worker.log_event
    end))

let create_dropbox =
  let table =
    let open Worker in
    let merge _w (Any_request neu) (old : _ option) =
      let (Any_request r) =
        match (neu, old) with
        | (RqA i1, Some (Any_request (RqA i2))) -> Any_request (RqA (i1 + i2))
        | ((RqA _ as rqa), _) -> Any_request rqa
        | (_, Some (Any_request (RqA _ as rqa))) -> Any_request rqa
        | (RqB, _) -> Any_request neu
        | (RqErr _, _) -> Any_request neu
      in
      Some (Worker.Any_request r)
    in
    Worker.create_table (Dropbox {merge})
  in
  create
    table
    (module Handlers (struct
      type self = Worker.dropbox Worker.t

      let log_event = Worker.log_event
    end))

open Mocked_worker.Request

type abs

type _ box = Box : (unit, _) Request.t -> abs box

let build_expected_history l =
  let rec loop acc l =
    match l with
    | [] -> acc
    | Box (RqA i) :: t -> loop (Format.sprintf "RqA %d" i :: acc) t
    | Box RqB :: t -> loop ("RqB" :: acc) t
    | Box (RqErr Simple) :: t -> loop ("RqErr" :: acc) t
    | Box (RqErr _) :: _ -> acc
  in
  loop [] l

let assert_status w expected_status =
  let status_str =
    match Worker.status w with
    | Launching _ -> "Launching"
    | Running _ -> "Running"
    | Closing _ -> "Closing"
    | Closed _ -> "Closed"
  in
  Assert.assert_true
    (Format.asprintf "Worker should be of status %s" expected_status)
    (status_str = expected_status)

open Lib_test.Qcheck2_helpers

module Generators = struct
  open QCheck2

  let request =
    let open Gen in
    oneof
      [
        Gen.map (fun i -> Box (RqA i)) int;
        return (Box RqB);
        return (Box (RqErr Simple));
      ]

  let request_series =
    let open Gen in
    small_list (small_list request)
end

let get_history w =
  let (history, _) = Worker.state w in
  !history

let push_multiple_requests w l =
  let open Lwt_syntax in
  let history = ref [] in
  let* () =
    Lwt.catch
      (fun () ->
        List.iter_s
          (fun (Box r) ->
            let open Lwt_syntax in
            let* _ = Worker.Queue.push_request_and_wait w r in
            history := get_history w ;
            Lwt.return_unit)
          l)
      (fun _ -> Lwt.return_unit)
  in
  return !history

let print_list l = Format.sprintf "[%s]" (String.concat ", " l)

let test_random_requests create_queue =
  let open QCheck2 in
  Test.make ~name:"Non-failing requests" Generators.request_series
  @@ fun series ->
  let actual_t =
    List.map_s
      (fun l ->
        let open Lwt_syntax in
        let* w = create_queue "random_worker" in
        match w with
        | Ok w ->
            let* r = push_multiple_requests w l in
            let* () = Worker.shutdown w in
            return r
        | Error _ -> Lwt.return_nil)
      series
  in
  let actual = Lwt_main.run actual_t in
  let expected = List.map build_expected_history series in
  let pp fmt l =
    Format.fprintf fmt "%s" (print_list @@ List.map print_list l)
  in
  qcheck_eq' ~expected ~actual ~eq:( = ) ~pp ()

let assert_history actual expected =
  Assert.assert_true
    (Format.asprintf
       "History is different from expected: actual %s vs expected %s"
       (print_list actual)
       (print_list expected))
    (actual = expected)

let push_and_assert_history w l =
  let open Lwt_syntax in
  let expected = build_expected_history l in
  let* actual = push_multiple_requests w l in
  assert_history actual expected ;
  return_unit

let test_push_crashing_request () =
  let open Lwt_result_syntax in
  let* w = create_queue "crashing_worker" in
  assert_status w "Running" ;
  let*! () =
    push_and_assert_history w [Box RqB; Box RqB; Box (RqErr Crash); Box RqB]
  in
  assert_status w "Closed" ;
  return_unit

let test_cancel_worker () =
  let open Lwt_result_syntax in
  let* w = create_queue "canceled_worker" in
  let*! () = push_and_assert_history w [Box RqB] in
  assert_status w "Running" ;
  let*! () = Worker.shutdown w in
  let state_not_available =
    try
      let _ = Worker.state w in
      false
    with Invalid_argument _ -> true
  in
  Assert.assert_true
    (Format.asprintf "State should not be available")
    state_not_available ;
  assert_status w "Closed" ;
  return_unit

(* TODO in follow-up MR: fix the handling of exceptions and
   integrate this test *)
let test_raise_exn () =
  let open Lwt_result_syntax in
  let* w = create_queue "exn_worker" in
  assert_status w "Running" ;
  let*! _ = Worker.Queue.push_request_and_wait w (RqErr RaiseExn) in
  (* TODO Define the right behavior when exception is raised *)
  return_unit

let test_async_requests () =
  let open Lwt_result_syntax in
  let* w = create_queue "worker_async_req" in
  let rqa = RqA 1 in
  for _i = 1 to 9 do
    Worker.Queue.push_request_now w rqa
  done ;
  let*! _ = Worker.Queue.push_request_and_wait w rqa in
  let actual = get_history w in
  let expected = build_expected_history (TzList.repeat 10 (Box rqa)) in
  assert_history actual expected ;
  let*! () = Worker.shutdown w in
  return_unit

let test_async_dropbox () =
  let open Lwt_result_syntax in
  let* w =
    create_dropbox
      ~timeout:(Time.System.Span.of_seconds_exn 5.)
      "dropbox_worker"
  in
  let rqa = RqA 1 in
  for _i = 1 to 10 do
    Worker.Dropbox.put_request w rqa
  done ;
  let*! () = Lwt.pause () in
  let expected = build_expected_history [Box (RqA 10)] in
  let actual = get_history w in
  assert_history actual expected ;
  return_unit

let test_bounded () =
  let open Lwt_result_syntax in
  let rqa = RqA 1 in
  let* w = create_bounded "bounded_worker" in
  let n = 17 in
  let rec loop n =
    if n <= 1 then
      let*! _ = Worker.Queue.push_request_and_wait w rqa in
      Lwt.return_unit
    else
      let*! _ = Worker.Queue.push_request w rqa in
      loop (n - 1)
  in
  let*! () = loop n in
  let actual = get_history w in
  let expected = build_expected_history (TzList.repeat n (Box rqa)) in
  assert_history actual expected ;
  let*! () = Worker.shutdown w in
  return_unit

let wrap_qcheck test () =
  let _ = QCheck_alcotest.to_alcotest test in
  Lwt_result_syntax.return_unit

let tests_history =
  ( Format.sprintf "Queue history",
    [
      Tztest.tztest
        "Random normal requests"
        `Quick
        (wrap_qcheck (test_random_requests create_queue));
      Tztest.tztest
        "Random normal requests on Bounded"
        `Quick
        (wrap_qcheck (test_random_requests create_bounded));
    ] )

let tests_status =
  ( "Status",
    [
      Tztest.tztest "Canceled worker" `Quick test_cancel_worker;
      Tztest.tztest "Crashing requests" `Quick test_push_crashing_request;
    ] )

let tests_buffer =
  ( "Buffer handling",
    [
      Tztest.tztest "Queue/Async/Yield" `Quick test_async_requests;
      Tztest.tztest "Dropbox/Async/Yield" `Quick test_async_dropbox;
      Tztest.tztest "Bounded/Async/Yield" `Quick test_bounded;
    ] )

let () =
  Alcotest_lwt.run "Workers" [tests_history; tests_status; tests_buffer]
  |> Lwt_main.run
