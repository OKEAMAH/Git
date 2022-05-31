open Gg

module Vertex : sig
  type t = int

  val equal : t -> t -> bool

  val compare : t -> t -> t

  val hash : 'a -> t

  val pp : Format.formatter -> t -> unit

  val label : 'a -> 'a
end

module Vertex_table : Hashtbl.S with type key = int

module G :
  Graph.Sig.I
    with type V.t = int
     and type V.label = int
     and type E.t = int * unit * int
     and type E.label = unit

val erdos_renyi : int -> float -> Random.State.t -> G.t

(* As usual, this is implemented by a graph where the edges are labelled by
   a stiffness constant. All springs are considered "relaxed" for a parameter
   length [relax_length]. *)
type t = {
  state : node_state Vertex_table.t;
  graph : G.t;
  relax_length : float;
  stiffness : float;
}

and node_state = {
  mutable prev_position : P3.t;
  mutable position : P3.t;
  mutable velocity : V3.t;
  mutable force : V3.t;
  mutable is_anchor : bool;
}

type anchor = Vertices of Vertex.t list | Random of {count : int}

val pp : Format.formatter -> t -> unit

val position : node_state -> P3.t

val velocity : node_state -> V3.t

val force : node_state -> V3.t

val state : t -> node_state Vertex_table.t

val compute_forces : t -> float -> float -> unit

val integrate : t -> float -> unit

val spherical_configuration :
  G.t ->
  ?radius:float ->
  ?stiffness:float ->
  ?relax_length:float ->
  ?anchor:anchor ->
  unit ->
  t

val add_edge : t -> Vertex.t -> Vertex.t -> unit

val remove_edge : t -> Vertex.t -> Vertex.t -> unit

val add_vertex : t -> Vertex.t -> unit

val remove_vertex : t -> Vertex.t -> unit

val iter_edges : t -> (int -> int -> unit) -> unit

val perform_relaxation_step :
  model:t -> drag_factor:float -> coulomb_factor:float -> delta_t:float -> unit
