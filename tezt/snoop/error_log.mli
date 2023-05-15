type t

val encoding : t Data_encoding.t

val non_empty : unit -> bool

val add_error : bench_name:string -> error:string -> unit

val to_file : unit -> Data_encoding.json
