module StringMap = Map.Make (String)

type time = {wall : float; cpu : float}

let zero_time = {wall = 0.; cpu = 0.}

let ( +* ) {wall = walla; cpu = cpua} {wall = wallb; cpu = cpub} =
  {wall = walla +. wallb; cpu = cpua +. cpub}

let ( -* ) {wall = walla; cpu = cpua} {wall = wallb; cpu = cpub} =
  {wall = walla -. wallb; cpu = cpua -. cpub}

type aggregate = Node of int * time * aggregate StringMap.t

type seq = time * (string * float * report) list

and report = Seq of seq | Aggregate of aggregate

module type DRIVER = sig
  val aggregate : string -> unit

  val record : string -> unit

  val stop : string -> unit

  val mark : string list -> unit

  val span : time -> string list -> unit

  val time : unit -> time

  val report : unit -> (string * float * report) option
end

module type PROFILER = sig
  include DRIVER

  val plug : (module DRIVER) option -> unit

  val aggregate_f : string -> (unit -> 'a) -> 'a

  val aggregate_s : string -> (unit -> 'a Lwt.t) -> 'a Lwt.t

  val record_f : string -> (unit -> 'a) -> 'a

  val record_s : string -> (unit -> 'a Lwt.t) -> 'a Lwt.t

  val span_f : string list -> (unit -> 'a) -> 'a

  val span_s : string list -> (unit -> 'a Lwt.t) -> 'a Lwt.t
end

module Make () = struct
  let p : (module DRIVER) option ref = ref None

  let plug d =
    match (!p, d) with
    | Some _, Some _ -> invalid_arg "Intrusive_profiler.plug_driver"
    | _ -> p := d

  let if_plugged f = match !p with Some d -> f d | None -> ()

  let time () =
    match !p with
    | Some (module Driver) -> Driver.time ()
    | None -> {wall = 0.; cpu = 0.}

  let aggregate id = if_plugged (fun (module Driver) -> Driver.aggregate id)

  let record id = if_plugged (fun (module Driver) -> Driver.record id)

  let mark ids = if_plugged (fun (module Driver) -> Driver.mark ids)

  let span d ids = if_plugged (fun (module Driver) -> Driver.span d ids)

  let stop id = if_plugged (fun (module Driver) -> Driver.stop id)

  let report () =
    match !p with Some (module Driver) -> Driver.report () | None -> None

  let section start id f =
    start id ;
    let r = try Ok (f ()) with exn -> Error exn in
    stop id ;
    match r with Ok r -> r | Error exn -> raise exn

  let aggregate_f id f = section aggregate id f

  let record_f id f = section record id f

  let span_f ids f =
    let t0 = time () in
    let r = try Ok (f ()) with exn -> Error exn in
    span (time () -* t0) ids ;
    match r with Ok r -> r | Error exn -> raise exn

  let section_s start id f =
    start id ;
    Lwt.catch
      (fun () ->
        Lwt.bind (f ()) (fun r ->
            stop id ;
            Lwt.return r))
      (fun exn ->
        stop id ;
        Lwt.fail exn)

  let aggregate_s id f = section_s aggregate id f

  let record_s id f = section_s record id f

  let span_s ids f =
    let t0 = time () in
    Lwt.catch
      (fun () ->
        Lwt.bind (f ()) (fun r ->
            span (time () -* t0) ids ;
            Lwt.return r))
      (fun exn ->
        span (time () -* t0) ids ;
        Lwt.fail exn)
end

module Main = Make ()
