val with_pool : (unit -> 'a) -> 'a

val map2_one_chunk_per_core :
  (start:int -> len:int -> 'a array -> 'b -> 'c) -> 'a array -> 'b -> 'c list

val pmap : ('a -> 'b) -> 'a list -> 'b list
