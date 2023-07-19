val aggregate : string -> unit

val record : string -> unit

val stop : string -> unit

val mark : string list -> unit

val aggregate_f : string -> (unit -> 'a) -> 'a

val record_f : string -> (unit -> 'a) -> 'a

val span_f : string list -> (unit -> 'a) -> 'a

val aggregate_s : string -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val record_s : string -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val span_s : string list -> (unit -> 'a Lwt.t) -> 'a Lwt.t
