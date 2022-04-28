module Fr = Bls12_381.Fr

(* Alternative representation of polynomials containing
   the evluations of a polynomial on a certain set and its
   degree *)

module type Evaluations_sig = sig
  include Polynomial__Evaluations_c.Evaluations_c_sig

  val size_evaluations : t SMap.t -> int

  val print_evaluations_name : t SMap.t -> unit

  val get_domain : t SMap.t -> domain

  val compute_evaluations : domain:domain -> polynomial SMap.t -> t SMap.t

  val compute_evaluations_update_map :
    ?domain:domain -> evaluations:t SMap.t -> polynomial SMap.t -> t SMap.t

  val mul :
    evaluations:t SMap.t ->
    poly_names:string list ->
    ?composition_gx:int list * int ->
    ?powers:int list ->
    unit ->
    t

  val mul_update_map :
    evaluations:t SMap.t ->
    poly_names:string list ->
    ?composition_gx:int list * int ->
    ?powers:int list ->
    name_result:string ->
    unit ->
    t SMap.t

  val linear :
    evaluations:t SMap.t ->
    poly_names:SMap.key list ->
    ?linear_coeffs:scalar list ->
    ?composition_gx:int list * int ->
    ?add_constant:scalar ->
    unit ->
    t

  val linear_update_map :
    evaluations:t SMap.t ->
    poly_names:SMap.key list ->
    ?linear_coeffs:scalar list ->
    ?composition_gx:int list * int ->
    ?add_constant:scalar ->
    name_result:string ->
    unit ->
    t SMap.t
end

module Make (E : Polynomial__Evaluations_c.Evaluations_c_sig) :
  Evaluations_sig
    with type scalar = E.scalar
     and type domain = E.domain
     and type polynomial = E.polynomial
     and type t = E.t = struct
  include E

  let print_evaluations_name map =
    let s_eval =
      "{"
      ^ SMap.fold
          (fun k eval acc ->
            acc
            ^ Printf.sprintf "\n  %s -> (%d, %d)" k (degree eval) (length eval))
          map
          ""
      ^ "\n}"
    in
    Printf.printf "\nevaluations : %s" s_eval

  (* Returns the size of a non-null element of evaluations ;
     raise failure if such an element is not found *)
  let rec size_evaluations evaluations =
    try
      let (name, eval) = SMap.choose evaluations in
      let l = length eval in
      if l = 0 then size_evaluations SMap.(remove name evaluations) else l
    with Not_found ->
      failwith
        "Evaluations.size_evaluations : couldn't find evaluation of size \
         greater than zero : can't compute expected size of PI."

  let not_found x =
    raise
      (Invalid_argument
         (Printf.sprintf "Evaluations : %s not found in evaluations map." x))

  let find_eval ~evaluations name =
    match SMap.find_opt name evaluations with
    | None -> not_found name
    | Some x -> x

  (* Returns the evals of "X" as a domain
     @raise Invalid_argument if "X" is not in evaluations
  *)
  let get_domain evaluations = to_domain (find_eval ~evaluations "X")

  let compute_evaluations ~domain poly_map =
    SMap.map (evaluation_fft domain) poly_map

  (* Adds evaluation of poly_map’s polynomials on the domain given by the evaluation of "X"
     @raise Invalid_argument if "X" is not in evaluations
  *)
  let compute_evaluations_update_map ?domain ~evaluations poly_map =
    let domain =
      match domain with Some domain -> domain | None -> get_domain evaluations
    in
    SMap.union_disjoint evaluations (compute_evaluations ~domain poly_map)

  let mul ~evaluations ~poly_names ?composition_gx ?powers () =
    let list_name_eval =
      List.map (fun name -> (name, find_eval ~evaluations name)) poly_names
    in
    mul_c ~evaluations:list_name_eval ?composition_gx ?powers ()

  let mul_update_map ~evaluations ~poly_names ?composition_gx ?powers
      ~name_result () =
    let res = mul ~evaluations ~poly_names ?composition_gx ?powers () in
    SMap.add_unique name_result res evaluations

  let linear ~evaluations ~poly_names ?linear_coeffs ?composition_gx
      ?add_constant () =
    let list_name_eval =
      List.map (fun name -> (name, find_eval ~evaluations name)) poly_names
    in
    linear_c
      ~evaluations:list_name_eval
      ?linear_coeffs
      ?composition_gx
      ?add_constant
      ()

  let linear_update_map ~evaluations ~poly_names ?linear_coeffs ?composition_gx
      ?add_constant ~name_result () =
    let res =
      linear
        ~evaluations
        ~poly_names
        ?linear_coeffs
        ?composition_gx
        ?add_constant
        ()
    in
    SMap.add_unique name_result res evaluations
end
