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

(** Base test functions. *)

(** Add a function to be called before each test start.

    Used to reset counters such as the ones which are used to
    choose default process names. *)
val declare_reset_function : (unit -> unit) -> unit

(** Log an error and stop the test right here.

    If the optional location [__LOC__] is provided,
    it is prepended to the error message.
    You would typically use it simply as [Test.fail ~__LOC__ "..."]
    to prepend location of the failure. *)
val fail : ?__LOC__:string -> ('a, Format.formatter, unit, 'b) format4 -> 'a

(** How to initialize [Stdlib.Random] at the beginning of a test.

    - [Fixed seed]: the test is initialized using [Random.init seed].
      This makes sure that using the [Random] module does not cause the test
      to be non-deterministic. Note that [--seed] has no effect in this case.

    - [Random]: the test is initialized using a random seed, unless [--seed]
      is specified on the command-line, in which case this seed is used.
      The random seed that is chosen is logged at the beginning of the test. *)
type seed = Fixed of int | Random

(** Register a test.

    The [__FILE__] argument, which should be equal to [__FILE__]
    (i.e. just write [Test.register ~__FILE__]), is used to let the user
    select which files to run from the command-line.

    One should be able to infer, from [title], what the test will do.
    It is typically a short sentence like ["addition is commutative"]
    or ["server runs until client tells it to stop"].

    The list of [tags] must be composed of short strings which are
    easy to type on the command line (lowercase letters, digits
    and underscores). Run the test executable with [--list]
    to get the list of tags which are already used by existing tests.
    Try to reuse them if possible.

    The last argument is a function [f] which implements the test.
    If [f] needs to spawn external processes, it should use
    the [Process] module to do so, so that those processes are automatically
    killed at the end of the test. Similarly, if this function needs to
    create temporary files, it should declare them with [Temp], and if it
    needs to have promises that run in the background, it should use
    [Background.register] (and not [Lwt.async] in particular).

    If [f] raises an exception, act as if [fail] was called (without the
    error location unfortunately).

    You can call [register] several times in the same executable if you want
    it to run several tests. Each of those tests should be standalone, as
    the user is able to specify the list of tests to run on the command-line.

    The test is not actually run until you call {!run}. *)
val register :
  __FILE__:string ->
  title:string ->
  tags:string list ->
  ?seed:seed ->
  (unit -> unit Lwt.t) ->
  unit

(** Get the current worker id.

    In single-process mode (with [-j 1]), this always returns [None].

    In multi-process mode, this returns either:
    - [None] (if called in the scheduler process, i.e. outside of a test);
    - or [Some id] where [0 <= id < Cli.options.job_count] and where [id]
      uniquely identifies the current worker process that is running the current test. *)
val current_worker_id : unit -> int option

(** {2 Internals} *)

(** The rest of this module is used by other modules of Tezt.
    You usually do not need to use it yourself. *)

(** Add a function to be called by [run_with_scheduler] before it does anything. *)
val before_test_run : (unit -> unit) -> unit

(** How the seed for the PRNG was chosen.

    - [Used_fixed]: used the [Fixed] seed given to [Test.register].
    - [Used_random seed]: chose [seed] using self-initialization. *)
type used_seed = Used_fixed | Used_random of int

(** Data that a test sends to the scheduler after it is done. *)
type test_result = {test_result : Log.test_result; seed : used_seed}

module type SCHEDULER = sig
  (** Signature of schedulers to pass to {!run_with_scheduler}. *)

  (** Requests that schedulers can perform. *)
  type request = Run_test of {test_title : string}

  (** Request results. *)
  type response = Test_result of test_result

  (** Run a scheduler that manages several workers.

      This starts [worker_count] workers.
      As soon as a worker is available, it calls [on_worker_available].
      [on_worker_available] shall return [None] if there is nothing else to do,
      in which case the worker is killed, or [Some (request, on_response)],
      in which case the worker executes [request].
      The result of this request, [response], is then given to [on_response].

      The last argument is a continuation to call once there is nothing left to do. *)
  val run :
    on_worker_available:(unit -> (request * (response -> unit)) option) ->
    worker_count:int ->
    (unit -> unit) ->
    unit

  (** Get the current worker id. *)
  val get_current_worker_id : unit -> int option
end

(** Generic function to run registered tests that should be run.

    Depending on command-line options, this may do something else,
    such as printing the list of tests.

    Instead of calling this directly, call [Test.run], which is provided
    by the particular variant of Tezt you are using (Unix or JavaScript). *)
val run_with_scheduler : (module SCHEDULER) -> unit

(** Test descriptions. *)
type t

(** Get a test by its title.

    Return [None] if no test was [register]ed with this title. *)
val get_test_by_title : string -> t option

(** Run one test.

    [sleep] is a function such as [Lwt_unix.sleep] or [Lwt_js.sleep].
    It is used to implement timeouts.

    [clean_up] is a function such as [Process.clean_up] (plus a wrapper
    to handle exceptions). It is ran at the end of the test. *)
val run_one :
  sleep:(float -> unit Lwt.t) ->
  clean_up:(unit -> unit Lwt.t) ->
  temp_start:(unit -> string) ->
  temp_stop:(unit -> unit) ->
  temp_clean_up:(unit -> unit) ->
  t ->
  test_result Lwt.t

module String_tree : sig
  (** Radix trees for string lists. *)

  (** This module is only exposed so that it can be tested in test/common/tests.ml. *)

  type t

  val empty : t

  val add : string list -> t -> t

  val mem_prefix_of : string list -> t -> bool
end
