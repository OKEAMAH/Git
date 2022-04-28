(* EXCEPTIONS *)

exception Random_from_list_empty_input

exception Random_from_list_overflowed_choice of Q.t list

exception Random_qt_non_positive_interval of Q.t

module StringMap : sig
  include Map.S with type key = string

  val to_bytes : ('a -> bytes) -> 'a t -> bytes

  val of_list : (string * 'a) list -> 'a t

  val union_disjoint :
    ?common_keys_equal_elt:string list * ('a -> 'a -> bool) ->
    'a t ->
    'a t ->
    'a t

  val union_disjoint_list :
    ?common_keys_equal_elt:string list * ('a -> 'a -> bool) -> 'a t list -> 'a t

  val add_unique : string -> 'a -> 'a t -> 'a t

  val pmap : ('a -> 'b) -> 'a t -> 'b t

  module Aggregation : sig
    val sep : string

    val merge_equal_set_of_keys :
      ?extra_prefix:string ->
      ?common_keys_equal_elt:string list * ('a -> 'a -> bool) ->
      len_prefix:int ->
      'a t list ->
      'a t

    val int_to_string : len_prefix:int -> int -> string

    val compute_len_prefix : nb_proofs:int -> int

    val rename :
      ?extra_prefix:string ->
      ?update_value:(string -> 'a -> 'a) ->
      len_prefix:int ->
      common_keys:string list ->
      int ->
      'a t ->
      'a t

    val prefix_map : prefix:key -> 'a t -> 'a t
  end
end

module StringMatrix : Map.S with type key = string * string

val monomial_of_list : string list -> int StringMap.t

(* RANDOM FUNCTIONS ON Q.t *)

(** [random_qt state interval] computes a random Q.t between 0 and 1, given a random state
    and an precision interval.
    The resulting distribution is so that, for each segment between 0 and 1 of size [interval],
    there exists at least 2 obtainable values. Basically, [interval] controlls the precision of
    the segmentation of [0,1] for the sampling of Q.t.
 *)
val random_qt : Q.t -> Random.State.t -> Q.t

(** [random_from_list state l] picks a random element from [l].
    Each element of [l] is given a weight which describes the distribution
    probability of [l]. An element with a bigger weight relative to the other
    elements of [l] will occur more frequently.
 *)
val random_from_list : (Q.t * 'a) list -> Random.State.t -> 'a

(** Bernouilli distribution.
    [random_bern state x] returns [true] with probability [x], and [false]
    with probability [1-x].
 *)

val random_bern : Q.t -> Random.State.t -> bool

(* Tree printer helpers *)

(** [pp_tree root_tag sub_trees] prints a tree, from a tag for the root [root_tag],
    and a list of sub-trees, each represented by its list of lines to print. *)
val pp_tree : string -> string list list -> string list

(** [pp_string_list] formats a list of string by separating them with newlines *)
val pp_string_list : Format.formatter -> string list -> unit
