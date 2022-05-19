(* Implemenation of a spring model relaxation algorithm. We have objects in
   3d, with springs attached on some of them (no self-spring). Springs are
   parameterised by a stiffness constant. We want to minimise the total
   potential energy by adjusting the positions of the objects. We approximate
   this by computing the classical dynamics of each object, taking into account
   a global drag force. We stop whenever the total energy is below a given
   threshold.
   Our implementation is heavily imperative.
*)

open Gg

module Vertex = struct
  type t = int

  let equal = Int.equal

  let compare = Int.compare

  let hash = Hashtbl.hash

  let pp = Format.pp_print_int

  let label x = x
end

module Label = struct
  type t = unit

  let compare _ _ = 0

  let default = ()
end

module Vertex_table = Hashtbl.Make (Vertex)
module G = Graph.Imperative.Graph.ConcreteLabeled (Vertex) (Label)

let erdos_renyi n p rng_state =
  let coin = Stats.Gen.bernoulli p in
  let graph = G.create ~size:n () in
  for i = 0 to n - 1 do
    G.add_vertex graph i
  done ;
  G.iter_vertex
    (fun v1 ->
      G.iter_vertex
        (fun v2 ->
          if G.V.equal v1 v2 then ()
          else if coin rng_state then G.add_edge graph v1 v2
          else ())
        graph)
    graph ;
  graph

(* As usual, this is implemented by a graph where the edges are labelled by
   a stiffness constant. All springs are considered "relaxed" for a parameter
   length [relax_length]. *)
type t = {
  (* total force applied on each object *)
  state : node_state Vertex_table.t;
  (* edges/springs *)
  relax_length : float;
  (* relaxed length *)
  stiffness : float;
}

and node_state = {
  mutable prev_position : P3.t;
  mutable position : P3.t;
  mutable velocity : V3.t;
  mutable force : V3.t;
  mutable neighbours : (Vertex.t * float) list;
  mutable is_anchor : bool;
}

type anchor = Vertices of Vertex.t list | Random of {count : int}

let pp fmtr (model : t) =
  Vertex_table.iter
    (fun vertex {position; velocity; force; neighbours; _} ->
      Format.fprintf
        fmtr
        "%a -> @[ pos = %a;@, vel = %a;@, frc = %a; @,"
        Vertex.pp
        vertex
        V3.pp
        position
        V3.pp
        velocity
        V3.pp
        force ;
      Format.fprintf
        fmtr
        "%a @]"
        (Format.pp_print_list
           ~pp_sep:(fun fmtr () -> Format.fprintf fmtr ",")
           (fun fmtr (vtx, _) -> Vertex.pp fmtr vtx))
        neighbours)
    model.state

let position {position; _} = position

let velocity {velocity; _} = velocity

let force {force; _} = force

let neighbours {neighbours; _} = neighbours

let state {state; _} = state

let bbox (model : t) =
  Vertex_table.fold
    (fun _ state box ->
      let pos = state.position in
      Box3.add_pt box pos)
    model.state
    Box3.empty

(* Compute the force applied on each given object by all the other ones, taking into
   account a drag parameter (typically, drag ∈ [0;1]) *)
let compute_forces (model : t) (drag_factor : float) (coulomb_factor : float) =
  (* Spring forces *)
  Vertex_table.iter
    (fun v state ->
      (* reset accumulator *)
      state.force <- V3.zero ;
      List.iteri
        (fun _ (target, stiffness) ->
          let c = Vertex.compare v target in
          (* Compute force only once per edge. No loops. *)
          if c < 0 then (
            let target_state = Vertex_table.find model.state target in
            let direction = V3.sub target_state.position state.position in
            (* from v to target *)
            let ndir = V3.norm direction in
            let delta_rel = ndir -. model.relax_length in
            (* delta_rel > 0.0 -> stretched spring -> force towards target *)
            let force = delta_rel *. stiffness in
            let forcevec = V3.smul (force /. ndir) direction in
            (* drag *)
            let drag = V3.smul ~-.drag_factor state.velocity in
            let negdrag = V3.neg drag in
            state.force <- V3.add drag (V3.add state.force forcevec) ;
            target_state.force <-
              V3.add negdrag (V3.add target_state.force (V3.neg forcevec)) ;
            state.force <- V3.add state.force forcevec ;
            target_state.force <- V3.add target_state.force (V3.neg forcevec))
          else ())
        state.neighbours)
    model.state ;
  (* Coulomb potential *)
  Vertex_table.iter
    (fun v state ->
      Vertex_table.iter
        (fun v' state' ->
          let c = Vertex.compare v v' in
          if c = -1 then (
            let open V3 in
            let diff = state'.position - state.position in
            let dist = norm diff in
            let idist = 1. /. dist in
            let dir = smul idist diff in
            let coulomb = smul (coulomb_factor *. (idist *. idist)) dir in
            state.force <- state.force + neg coulomb ;
            state'.force <- state'.force + coulomb)
          else ())
        model.state)
    model.state ;
  let total_energy = ref 0.0 in
  Vertex_table.iter
    (fun _ state -> total_energy := !total_energy +. V3.norm2 state.velocity)
    model.state

let _compute_forces (model : t) (drag_factor : float) (coulomb_factor : float) =
  ignore drag_factor ;
  ignore coulomb_factor ;
  (* reset force acc *)
  Vertex_table.iter (fun _ state -> state.force <- V3.zero) model.state ;
  Vertex_table.iter
    (fun _v0 state ->
      let pos0 = state.position in
      let drag = V3.smul ~-.drag_factor state.velocity in
      state.force <- V3.add drag state.force ;
      List.iter
        (fun (v1, stiffness) ->
          let state1 = Vertex_table.find model.state v1 in
          let pos1 = state1.position in
          let dir1 = V3.sub pos1 pos0 in
          let u = V3.unit dir1 in
          state.force <- V3.add state.force (V3.smul stiffness dir1) ;
          List.iter
            (fun (v2, _) ->
              if Vertex.equal v1 v2 then ()
              else
                let state2 = Vertex_table.find model.state v2 in
                let pos2 = state2.position in
                let v = V3.unit (V3.sub pos2 pos0) in
                let n = V3.cross u v in
                let r = Float.pi -. asin (V3.norm n) in
                let f1 = V3.smul r @@ V3.cross u n in
                let f2 = V3.smul r @@ V3.cross n v in
                state1.force <- V3.add state1.force f1 ;
                state2.force <- V3.add state2.force f2)
            state.neighbours)
        state.neighbours)
    model.state

let _euler model delta_t =
  Vertex_table.iter
    (fun _v state ->
      state.position <- V3.add state.position (V3.smul delta_t state.velocity) ;
      state.velocity <- V3.add state.velocity (V3.smul delta_t state.force))
    model.state

let _symplectic model delta_t =
  Vertex_table.iter
    (fun _v state ->
      state.velocity <- V3.add state.velocity (V3.smul delta_t state.force) ;
      state.position <- V3.add state.position (V3.smul delta_t state.velocity))
    model.state

let verlet model delta_t =
  Vertex_table.iter
    (fun _v state ->
      if state.is_anchor then ()
      else
        let prev_position = state.position in
        let open V3 in
        state.position <-
          V3.smul 2. state.position - state.prev_position
          + V3.smul (delta_t *. delta_t) state.force ;
        state.velocity <-
          V3.smul (1. /. delta_t) (state.position - state.prev_position) ;
        state.prev_position <- prev_position)
    model.state

let integrate = verlet

(* Given [n] objects, we distribute them uniformy on the surface of a sphere
   of radius [radius]. Note that in order to make sense, this radius sould be so that
   the average distance between two points corresponds to the relaxation length. *)
let pi = Float.pi

let spherical_configuration (g : G.t) ?(radius = 50.0) ?(stiffness = 0.1)
    ?(relax_length = 300.0) ?anchor ~add_edges () =
  let table = Vertex_table.create (G.nb_vertex g) in
  G.iter_vertex
    (fun v ->
      let neighbours =
        if add_edges then
          G.fold_succ_e
            (fun (_v, _lab, v') acc -> (v', stiffness) :: acc)
            g
            v
            []
        else []
      in
      let position =
        let theta0 = Random.float (2.0 *. pi) in
        let theta1 = acos (1.0 -. Random.float 2.0) in
        let x = radius *. sin theta0 *. sin theta1 in
        let y = radius *. cos theta0 *. sin theta1 in
        let z = radius *. cos theta1 in
        P3.v x y z
      in
      let state =
        {
          prev_position = position;
          position;
          velocity = V3.zero;
          force = V3.zero;
          neighbours;
          is_anchor = false;
        }
      in
      Vertex_table.add table v state)
    g ;
  let anchors =
    match anchor with
    | None -> []
    | Some (Vertices verts) -> verts
    | Some (Random {count}) ->
        let len = Vertex_table.length table in
        if count > len then invalid_arg "too many anchors" ;
        let verts = G.fold_vertex (fun v l -> v :: l) g [] in
        let shuffled =
          Lwtreslib.Bare.List.shuffle ~rng:(Random.State.make [|1337|]) verts
        in
        let rec pick_n list n acc =
          match list with
          | [] -> acc
          | hd :: tl when n > 0 -> pick_n tl (n - 1) (hd :: acc)
          | _ -> acc
        in
        pick_n shuffled count []
  in
  List.iter
    (fun anchor ->
      let state = Vertex_table.find table anchor in
      state.is_anchor <- true)
    anchors ;
  {state = table; relax_length; stiffness}

let add_edge (model : t) (v1 : Vertex.t) (v2 : Vertex.t) =
  assert (Vertex_table.mem model.state v1) ;
  assert (Vertex_table.mem model.state v2) ;
  let c = Vertex.compare v1 v2 in
  assert (c <> 0) ;
  let (v1, v2) = if c = -1 then (v1, v2) else (v2, v1) in
  let state = Vertex_table.find model.state v1 in
  state.neighbours <- (v2, model.stiffness) :: state.neighbours

let remove_edge (model : t) (v1 : Vertex.t) (v2 : Vertex.t) =
  let v1_state = Vertex_table.find model.state v1 in
  v1_state.neighbours <-
    List.filter (fun (v', _) -> not (Vertex.equal v' v2)) v1_state.neighbours ;
  let v2_state = Vertex_table.find model.state v2 in
  v1_state.neighbours <-
    List.filter (fun (v', _) -> not (Vertex.equal v' v1)) v2_state.neighbours

let random_sign () = if Random.bool () then 1. else ~-.1.

(* Recomputing the bbox at each vertex insertion is inefficient.
   TODO: make this incremental. *)
let add_vertex (model : t) (v : Vertex.t) =
  let box = bbox model in
  let mid = Box3.mid box in
  let size = Box3.size box in
  let delta = V3.map (fun v -> v *. random_sign ()) size in
  let position = V3.add mid delta in
  let state =
    {
      prev_position = position;
      position;
      velocity = V3.zero;
      force = V3.zero;
      neighbours = [];
      is_anchor = false;
    }
  in
  Vertex_table.add model.state v state

let remove_vertex (model : t) (v : Vertex.t) =
  let state = Vertex_table.find model.state v in
  List.iter
    (fun (v', _) ->
      let state' = Vertex_table.find model.state v' in
      state'.neighbours <-
        List.filter (fun (v', _) -> not (Vertex.equal v' v)) state.neighbours)
    state.neighbours ;
  Vertex_table.remove model.state v

let perform_relaxation_step ~model ~drag_factor ~coulomb_factor ~delta_t =
  compute_forces model drag_factor coulomb_factor ;
  integrate model delta_t
