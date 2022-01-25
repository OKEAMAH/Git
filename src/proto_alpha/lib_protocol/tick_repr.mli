type t = private int

val encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

val make : int -> t

val next : t -> t

val distance : t -> t -> int

val ( = ) : t -> t -> bool

module Map : Map.S with type key = t
