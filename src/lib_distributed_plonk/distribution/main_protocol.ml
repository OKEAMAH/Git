(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Kzg.Bls
open Kzg.Utils
open Plonk.Identities
module SMap = Kzg.SMap

let nb_wires = Plompiler.Csir.nb_wires_arch

module type S = sig
  module PP : Polynomial_protocol.S

  type proof = {
    perm_and_plook : PP.PC.Commitment.t;
    wires_cm : PP.PC.Commitment.t;
    pp_proof : PP.proof;
  }

  include Plonk.Main_protocol_intf.S with type proof := proof

  type gate_randomness = {beta : Scalar.t; gamma : Scalar.t; delta : Scalar.t}

  val build_gates_randomness : Transcript.t -> gate_randomness * Transcript.t

  val filter_prv_pp_circuits :
    prover_public_parameters -> 'a SMap.t -> prover_public_parameters

  module Prover : sig
    val build_all_keys_z : prover_public_parameters -> string list

    val commit_to_wires :
      ?all_keys:string list ->
      ?shifts_map:(int * int) SMap.t ->
      prover_public_parameters ->
      circuit_prover_input list SMap.t ->
      Evaluations.t SMap.t list SMap.t
      * Poly.t SMap.t list SMap.t
      * Poly.t SMap.t option list SMap.t
      * Poly.t SMap.t
      * Input_commitment.public
      * PP.PC.Commitment.prover_aux

    val build_evaluations :
      prover_public_parameters ->
      Evaluations.polynomial SMap.t ->
      Evaluations.t SMap.t

    val build_f_map_plook :
      ?shifts_map:(int * int) SMap.t ->
      prover_public_parameters ->
      gate_randomness ->
      Evaluations.t SMap.t list SMap.t ->
      Poly.t SMap.t

    val build_f_map_perm :
      prover_public_parameters ->
      gate_randomness ->
      Evaluations.t SMap.t SMap.t ->
      Poly.t SMap.t

    (* builds the range check’s permutation proof polynomials *)
    val build_f_map_rc_2 :
      prover_public_parameters ->
      gate_randomness ->
      Evaluations.t SMap.t SMap.t ->
      Poly.t SMap.t

    val build_perm_rc2_identities :
      prover_public_parameters -> gate_randomness -> prover_identities

    val build_gates_plook_rc1_identities :
      ?shifts_map:(int * int) SMap.t ->
      prover_public_parameters ->
      gate_randomness ->
      circuit_prover_input list SMap.t ->
      prover_identities
  end

  type worker_inputs [@@deriving repr]

  val split_inputs_map :
    nb_workers:int ->
    circuit_prover_input list SMap.t ->
    worker_inputs SMap.t list

  type commit_to_wires_reply = PP.PC.Commitment.t [@@deriving repr]

  (* shifts_maps binds circuits names to pairs of integers.
     'c1' -> (7, 20) means that 20 proofs are expected for circuit 'c1' and
     there must be a shift of 7 in indexing considering the worker is starting
     at proof No. 7 *)
  type commit_to_wires_remember = {
    all_f_wires : Poly.t SMap.t;
    wires_list_map : Evaluations.t SMap.t list SMap.t;
    inputs_map : circuit_prover_input list SMap.t;
    shifts_map : (int * int) SMap.t;
    f_wires : Poly.t SMap.t list SMap.t;
    cm_aux_wires : PP.PC.Commitment.prover_aux;
  }

  val worker_commit_to_wires :
    prover_public_parameters ->
    worker_inputs SMap.t ->
    commit_to_wires_reply * commit_to_wires_remember

  type commit_to_plook_rc_reply = {
    batched_wires_map : Evaluations.t SMap.t SMap.t;
    cmt : PP.PC.Commitment.t;
    f_map : Poly.t SMap.t;
    prover_aux : PP.PC.Commitment.prover_aux;
  }
  [@@deriving repr]

  type commit_to_plook_rc_remember = {beta : scalar; gamma : scalar}

  val commit_to_plook_rc :
    prover_public_parameters ->
    (int * int) SMap.t ->
    Transcript.t ->
    Evaluations.t SMap.t list SMap.t ->
    commit_to_plook_rc_reply * commit_to_plook_rc_remember

  val batch_evaluated_ids :
    alpha:scalar -> Evaluations.t SMap.t -> string list -> Evaluations.t

  val kzg_eval_at_x :
    prover_public_parameters ->
    Transcript.t ->
    (PP.PC.secret * PP.PC.Commitment.prover_aux) list ->
    scalar ->
    PP.PC.answer list

  val shared_perm_rc_argument :
    prover_public_parameters ->
    int ->
    gate_randomness ->
    'a list SMap.t ->
    commit_to_plook_rc_reply list ->
    Poly.t SMap.t
    * Evaluations.t SMap.t
    * (commit_to_wires_reply * PP.PC.Commitment.prover_aux)

  val make_secret :
    prover_public_parameters ->
    Poly.t SMap.t * PP.PC.Commitment.prover_aux ->
    (Poly.t SMap.t * PP.PC.Commitment.prover_aux) list

  val make_eval_points :
    prover_public_parameters -> eval_point list list * eval_point list list

  val get_srs : prover_public_parameters -> PP.prover_public_parameters

  (** Returns (g, n, nb_t), where n is the size of the circuit padded to the
      next power of two, g is a primitive n-th root of unity, & nb_t is the
      number of T polynomials in the answers
   *)
  val get_gen_n_nbt : prover_public_parameters -> scalar * int * int

  val get_transcript : prover_public_parameters -> Transcript.t

  val check_no_zk : prover_public_parameters -> unit
end

module Common (PP : Polynomial_protocol.S) = struct
  open Plonk.Main_protocol.Make_impl (PP)

  open Prover
  module Commitment = PP.PC.Commitment

  type commit_to_wires_reply = Commitment.t [@@deriving repr]

  type worker_inputs = {inputs : circuit_prover_input list; shift : int * int}
  [@@deriving repr]

  let split_inputs_map ~nb_workers inputs_map =
    let list_range i1 i2 = List.filteri (fun i _ -> i1 <= i && i < i2) in
    List.map
      (fun i ->
        SMap.map
          (fun l ->
            let n = List.length l in
            let chunk_size =
              Z.(cdiv (of_int n) (of_int nb_workers) |> to_int)
            in
            let inputs = list_range (chunk_size * i) (chunk_size * (i + 1)) l in
            let shift = (chunk_size * i, n) in
            {inputs; shift})
          inputs_map)
      (List.init nb_workers Fun.id)

  type commit_to_plook_rc_reply = {
    batched_wires_map : Evaluations.t SMap.t SMap.t;
    cmt : Commitment.t;
    f_map : Poly.t SMap.t;
    prover_aux : Commitment.prover_aux;
  }
  [@@deriving repr]

  type commit_to_plook_rc_remember = {beta : scalar; gamma : scalar}

  type commit_to_wires_remember = {
    all_f_wires : Poly.t SMap.t;
    wires_list_map : Evaluations.t SMap.t list SMap.t;
    inputs_map : circuit_prover_input list SMap.t;
    shifts_map : (int * int) SMap.t;
    f_wires : Poly.t SMap.t list SMap.t;
    cm_aux_wires : Commitment.prover_aux;
  }

  let worker_commit_to_wires pp worker_inputs_map =
    let inputs_map = SMap.map (fun wi -> wi.inputs) worker_inputs_map in
    let shifts_map = SMap.map (fun wi -> wi.shift) worker_inputs_map in
    let all_keys = build_all_wires_keys pp (SMap.map snd shifts_map) nb_wires in
    let wires_list_map, f_wires, _, all_f_wires, cm_wires, cm_aux_wires =
      commit_to_wires ~all_keys ~shifts_map pp inputs_map
    in
    ( cm_wires,
      {
        all_f_wires;
        wires_list_map;
        inputs_map;
        shifts_map;
        f_wires;
        cm_aux_wires;
      } )

  let commit_to_plook_rc pp shifts_map transcript f_wires_list_map =
    let rd, _transcript = build_gates_randomness transcript in
    (* we should compute this in an other function *)
    let batched_wires_map =
      Perm.Shared_argument.build_batched_wires_values
        ~delta:rd.delta
        ~wires:f_wires_list_map
        ()
    in
    (* ******************************************* *)
    let f_map = build_f_map_plook ~shifts_map pp rd f_wires_list_map in
    (* commit to the plookup polynomials *)
    let cmt, prover_aux =
      (* TODO #5551
         Implement Plookup
      *)
      let all_keys = build_all_keys_z pp in
      PP.PC.commit ~all_keys pp.common_pp.pp_public_parameters f_map
    in
    ( {batched_wires_map; cmt; f_map; prover_aux},
      {beta = rd.beta; gamma = rd.gamma} )

  let batch_evaluated_ids ~alpha evaluated_ids all_ids_keys =
    let powers_map =
      SMap.of_list @@ List.mapi (fun i s -> (s, i)) all_ids_keys
    in
    let ids_keys, evaluations = List.split @@ SMap.bindings evaluated_ids in
    let powers =
      List.map (fun s -> SMap.find s powers_map) ids_keys
      |> List.map (fun i -> Scalar.pow alpha @@ Z.of_int i)
    in
    Evaluations.linear_c ~evaluations ~linear_coeffs:powers ()

  let kzg_eval_at_x pp transcript secrets_worker generator =
    let eval_points_worker =
      [List.hd @@ List.rev @@ pp.common_pp.eval_points]
    in
    let x, _transcript = Fr_generation.random_fr transcript in
    let polys_list_worker = List.map fst secrets_worker in
    let query_list_worker =
      List.map (convert_eval_points ~generator ~x) eval_points_worker
    in
    List.map2 PP.PC.evaluate polys_list_worker query_list_worker

  (* Same as Plonk.Main_protocol.build_batched_witness_poly, but the IFFT
     version every times.
     Because I don’t know how to use f_wires in distributed_prover
  *)
  let build_batched_witness_polys_bis pp batched_witnesses =
    let batched_witness_polys =
      SMap.map
        (fun batched_witness ->
          (* we apply an IFFT on the batched witness *)
          Perm.Shared_argument.batched_wires_poly_of_batched_wires
            pp
            batched_witness
            (Scalar.zero, []))
        batched_witnesses
    in
    batched_witness_polys |> SMap.Aggregation.smap_of_smap_smap

  let shared_perm_rc_argument pp nb_workers randomness inputs_map replies =
    let recombine_batched_wires pieces =
      (* we want the last worker to be first to apply Horner's method *)
      let pieces = List.rev pieces in
      List.fold_left
        (fun acc m ->
          SMap.union
            (fun circuit_name witness_acc witness_m ->
              let n = List.length (SMap.find circuit_name inputs_map) in
              let chunk_size = Z.(cdiv (of_int n) (of_int nb_workers)) in
              let delta_factor = Scalar.pow randomness.delta chunk_size in
              let sum =
                SMap.mapi
                  (fun i w_acc ->
                    let w = SMap.find i witness_m in
                    Evaluations.(add w (mul_by_scalar delta_factor w_acc)))
                  witness_acc
              in
              Some sum)
            acc
            m)
        (List.hd pieces)
        (List.tl pieces)
    in
    let batched_wires_map =
      recombine_batched_wires (List.map (fun r -> r.batched_wires_map) replies)
    in
    let open Prover in
    let f_map_perm = build_f_map_perm pp randomness batched_wires_map in
    let f_map_rc = build_f_map_rc_2 pp randomness batched_wires_map in
    let f_map_perm_rc = SMap.union_disjoint f_map_perm f_map_rc in

    let evaluated_perm_ids =
      let evaluations =
        let batched_wires_polys =
          build_batched_witness_polys_bis
            (pp.common_pp.zk, pp.common_pp.n, pp.common_pp.domain)
            batched_wires_map
        in
        build_evaluations
          pp
          (SMap.union_disjoint f_map_perm_rc batched_wires_polys)
      in
      (build_perm_rc2_identities pp randomness) evaluations
    in
    let cmt =
      let all_keys = build_all_keys_z pp in
      PP.PC.commit ~all_keys pp.common_pp.pp_public_parameters f_map_perm_rc
    in
    (f_map_perm_rc, evaluated_perm_ids, cmt)

  let build_f_map_rc_2 = Prover.build_f_map_rc_2

  let make_secret pp (f_map, f_prv_aux) =
    [(pp.common_pp.g_map, pp.common_pp.g_prover_aux); (f_map, f_prv_aux)]

  let make_eval_points pp = Plonk.List.split_n 2 pp.common_pp.eval_points

  let get_generator pp = Domain.get pp.common_pp.domain 1

  let get_srs pp = pp.common_pp.pp_public_parameters

  let get_gen_n_nbt pp =
    ( Domain.get pp.common_pp.domain 1,
      pp.common_pp.n,
      pp.common_pp.nb_of_t_chunks )

  let get_transcript pp = pp.transcript

  let check_no_zk pp =
    if pp.common_pp.zk then failwith "Distribution with ZK is not supported"
end

module Make (PP : Polynomial_protocol.S) = struct
  module PP = PP
  module MP = Plonk.Main_protocol.Make_impl (PP)

  include (MP : module type of MP with module PP := PP)

  include Common (PP)
end

module MakeSuper (PP : Polynomial_protocol.Super) = struct
  module PP = PP
  module MP = Aggregation.Main_protocol.Make_impl (PP)

  include (MP : module type of MP with module PP := PP)

  include Common (PP)
end
