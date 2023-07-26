type lod = Terse | Detailed | Verbose

val record : ?lod:lod -> string -> unit

val aggregate : ?lod:lod -> string -> unit

val stop : unit -> unit

val stamp : ?lod:lod -> string -> unit

val record_f : ?lod:lod -> string -> (unit -> 'a) -> 'a

val record_s : ?lod:lod -> string -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val aggregate_f : ?lod:lod -> string -> (unit -> 'a) -> 'a

val aggregate_s : ?lod:lod -> string -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val mark : ?lod:lod -> string list -> unit

val span_f : ?lod:lod -> string list -> (unit -> 'a) -> 'a

val span_s : ?lod:lod -> string list -> (unit -> 'a Lwt.t) -> 'a Lwt.t
