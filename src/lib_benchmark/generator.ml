(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs. <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

type 'aspect probe = {
  apply : 'a. 'aspect -> (unit -> 'a) -> 'a;
  aspects : unit -> 'aspect list;
  get : 'aspect -> float list;
}

type 'workload benchmark =
  | Plain : {
      workload : 'workload;
      closure : unit -> unit;
    }
      -> 'workload benchmark
  | PlainWithAllocation : {
      workload : 'workload;
      closure : unit -> unit;
      measure_allocation : unit -> int option;
    }
      -> 'workload benchmark
  | With_context : {
      workload : 'workload;
      closure : 'context -> unit;
      with_context : 'a. ('context -> 'a) -> 'a;
    }
      -> 'workload benchmark
  | With_probe : {
      workload : 'aspect -> 'workload;
      probe : 'aspect probe;
      closure : 'aspect probe -> unit;
    }
      -> 'workload benchmark

module type S = sig
  type config

  (** Workload corresponding to a benchmark run *)
  type workload

  (** Creates a list of benchmarks, ready to be run. The [bench_num] option
      corresponds to the argument command-line specified by the user on command
      line, but it can be overriden by the [config]-specific settings.
      This is the case for instance when the benchmarks are performed on
      external artifacts.
      The benchmarks are thunked to prevent evaluating the workload until
      needed. *)
  val create_benchmarks :
    rng_state:Random.State.t ->
    bench_num:int ->
    config ->
    (unit -> workload benchmark) list
end

module V2 = struct
  module Reader = struct
    type ('e, 'a) t = Reader of ('e -> 'a)

    let run = function Reader r -> r

    let bind f m = Reader (fun env -> run (f (run m env)) env)

    let return x = Reader (fun _ -> x)

    let ask = Reader (fun env -> env)

    let ( let* ) m f = bind f m
  end

  module GOpt = struct
    type nothing = private Nothing_tag

    type just = private Just_tag

    type ('a, 'b) t = Nothing : ('a, nothing) t | Just : 'a -> ('a, just) t
  end

  module Pipeline = struct
    type (_, _) pipeline =
      | Step : ('a -> 'b) * ('b, 'c) pipeline -> ('a, 'c) pipeline
      | Empty : ('a, 'a) pipeline

    let ( @> ) f pipeline = Step (f, pipeline)

    let empty = Empty
  end

  type _ setup =
    | No_setup : unit setup
    | Load_data_list : (unit -> 'data list) -> 'data setup
    | Load_data : (unit -> 'data) -> 'data setup

  type (_, _) eq = Refl : ('a, 'a) eq

  let present (type a elt) (x : (elt, a) GOpt.t) : (a, GOpt.just) eq option =
    match x with Just _ -> Some Refl | Nothing -> None

  module DSL = struct
    type ('a, 'b) step = ('a, 'b) Pipeline.pipeline

    type 'config params = {
      config : 'config;
      rng_state : Random.State.t;
      bench_num : int;
    }

    type 'a state = {
      pre_hook : (unit -> unit, 'pre_hook_status) GOpt.t;
      setup_data : 'setup_data setup;
      create_benchmark :
        ( bench_num:int -> (unit -> 'workload benchmark) list,
          'bench_status )
        GOpt.t;
    }
      constraint
        'a =
        < pre_hooks : 'pre_hook_status
        ; bench_status : 'bench_status
        ; setup_data : 'setup_data
        ; workload : 'workload >

    type present = GOpt.just = private Just_tag

    type absent = GOpt.nothing = private Nothing_tag

    type ('config, 'workload) t =
      ('config params, (unit -> 'workload benchmark) list) Reader.t

    type ('config, 'workload) builder = ('config, 'workload) Reader.t

    let pre_hook ~f :
        < pre_hooks : absent ; .. > state -> < pre_hooks : present ; .. > state
        =
     fun state ->
      match present state.pre_hook with
      | None ->
          let new_state = {state with pre_hook = Just f} in
          new_state

    let setup_data ~data :
        < setup_data : unit ; bench_status : absent ; .. > state ->
        < setup_data : 'b ; .. > state =
     fun state ->
      let new_state = {state with setup_data = data} in
      new_state

    let get (GOpt.Just x) = x

    let benchmark (type a) :
        f:(a -> 'b benchmark option) ->
        < bench_status : absent ; setup_data : a ; workload : 'd ; .. > state ->
        < bench_status : present ; setup_data : a ; workload : 'd ; .. > state =
     fun ~f state ->
      match present state.create_benchmark with
      | None ->
          let new_state =
            {
              state with
              create_benchmark =
                Just
                  (fun ~bench_num ->
                    let data : a list =
                      match state.setup_data with
                      | No_setup -> List.repeat bench_num ()
                      | Load_data x ->
                          let data = x () in
                          List.repeat bench_num data
                      | Load_data_list x -> x ()
                    in
                    let gen = List.filter_map f data in
                    let gen = List.map (fun x () -> x) gen in
                    gen);
            }
          in
          new_state

    let rec exec : type a b. (a, b) Pipeline.pipeline -> a -> b =
     fun pipeline input ->
      match pipeline with
      | Empty -> input
      | Step (f, tail) -> exec tail (f input)

    let run_opt (type a) (opt : (unit -> unit, a) GOpt.t) : 'a =
      match opt with Nothing -> () | Just x -> x ()

    let get_params : ('a, 'a) builder = Reader.ask

    let to_v1 (type config) (m : (config, _) t) ~rng_state ~bench_num config =
      match m with Reader.Reader r -> r {rng_state; bench_num; config}

    let complete = Pipeline.empty

    let runner :
        ( unit,
          < bench_status : present
          ; pre_hooks : 'a
          ; setup_data : 'b
          ; workload : _ >
          state )
        step ->
        ('config, _) t =
     fun res ->
      let open Reader in
      let* params = ask in
      let s = exec res () in
      run_opt s.pre_hook ;
      let gen =
        match present s.create_benchmark with
        | Some Refl -> get s.create_benchmark
        | None -> assert false
      in
      return @@ gen ~bench_num:params.bench_num

    let ( @> ) = Pipeline.( @> )

    let ( let$ ) :
        type workload.
        ('config, _) builder ->
        (_ ->
        ( unit,
          < bench_status : present
          ; pre_hooks : 'c
          ; setup_data : 'd
          ; workload : workload
          ; .. >
          state )
        step) ->
        ('a, workload) t =
     fun m f ->
      let open Reader in
      let* x = bind (fun s -> return @@ f s) m in
      runner x

    let return f = runner f

    let describe _ =
      {pre_hook = Nothing; create_benchmark = Nothing; setup_data = No_setup}
  end
end
