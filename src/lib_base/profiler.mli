module StringMap : Map.S with type key = string

type time = {wall : float; cpu : float}

val zero_time : time

val ( -* ) : time -> time -> time

val ( +* ) : time -> time -> time

type aggregate = Node of int * time * aggregate StringMap.t

type seq = time * (string * float * report) list

and report = Seq of seq | Aggregate of aggregate

module type DRIVER = sig
  (** Start an aggregation node. Children with the same identifier are
      grouped, counted, and their running times are added. Aggregation
      nodes can only contain other aggregation nodes, not sequence
      nodes. *)
  val aggregate : string -> unit

  (** Start a sequence node, every direct child is recorded separately
      with its time relative to when recording starts. Sequences can
      contain both child sequence nodes and aggregation nodes. If a
      sequence node is placed in an aggregation node, it is converted
      to an aggregation. *)
  val record : string -> unit

  (** Close the last opened aggregation or sequence node. The
      identifier should match. If not, the currently opened nodes are
      closed from latest to earliest, until a node with the same
      identifier is found. Fails if no identifier is found. *)
  val stop : string -> unit

  (** A time stamp, useful to record a single time offest in a
      sequence, or an event in an aggregation. *)
  val mark : string list -> unit

  (** A time span, useful to record time spent in a specific, non
      nested section, using external time measurement. *)
  val span : time -> string list -> unit

  (** Gives the current time in seconds. *)
  val time : unit -> time

  (** Consume the last toplevel report, if any. *)
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

module Make () : PROFILER

module Main : PROFILER
