module type Evaluations_sig = sig
  type scalar

  type polynomial

  type t

  val make_evaluation : int * scalar array -> t

  val zero : t

  val equal : t -> t -> bool

  type domain

  val evaluation_fft : domain -> polynomial -> t

  val size_evaluations : t Misc.StringMap.t -> int

  val get_domain : t Misc.StringMap.t -> domain

  val add_evaluations :
    ?domain:domain ->
    evaluations:t Misc.StringMap.t ->
    polynomial Misc.StringMap.t ->
    t Misc.StringMap.t

  val compute_evaluations :
    domain:domain -> polynomial Misc.StringMap.t -> t Misc.StringMap.t

  val polynomial_of_evaluation : t -> polynomial

  val mul_evaluations :
    evaluations:t Misc.StringMap.t -> poly_names:string list -> t

  val op_2 :
    evaluations:t Misc.StringMap.t ->
    func:(scalar -> scalar -> scalar) ->
    func_degree:(int -> int -> int) ->
    names_p1_p2:string * string ->
    ?composition_pow_order_1:int * int ->
    ?composition_pow_order_2:int * int ->
    unit ->
    t

  val op_3 :
    evaluations:t Misc.StringMap.t ->
    func:(scalar -> scalar -> scalar -> scalar) ->
    func_degree:(int -> int -> int -> int) ->
    names_p1_p2_p3:Misc.StringMap.key * Misc.StringMap.key * Misc.StringMap.key ->
    ?composition_pow_order_1:int * int ->
    ?composition_pow_order_2:int * int ->
    ?composition_pow_order_3:int * int ->
    unit ->
    t

  val op_3_add :
    evaluations:t Misc.StringMap.t ->
    func:(scalar -> scalar -> scalar -> scalar) ->
    func_degree:(int -> int -> int -> int) ->
    names_p1_p2_p3:string * string * string ->
    name_result:string ->
    ?composition_pow_order_1:int * int ->
    ?composition_pow_order_2:int * int ->
    ?composition_pow_order_3:int * int ->
    unit ->
    t Misc.StringMap.t

  val linear_2 :
    evaluations:t Misc.StringMap.t ->
    coefs:scalar * scalar ->
    names_p1_p2:Misc.StringMap.key * Misc.StringMap.key ->
    name_result:Misc.StringMap.key ->
    t Misc.StringMap.t

  val op_4 :
    evaluations:t Misc.StringMap.t ->
    func:(scalar -> scalar -> scalar -> scalar -> scalar) ->
    func_degree:(int -> int -> int -> int -> int) ->
    names_p1_p2_p3_p4:string * string * string * string ->
    ?composition_pow_order_1:int * int ->
    ?composition_pow_order_2:int * int ->
    ?composition_pow_order_3:int * int ->
    ?composition_pow_order_4:int * int ->
    unit ->
    t

  val op_n :
    evaluations:t Misc.StringMap.t ->
    func:(scalar array -> scalar) ->
    func_degree:(int array -> int) ->
    names:string array ->
    ?composition:int array * int ->
    unit ->
    t

  val compute_l1 : int -> domain -> polynomial -> t

  val add : t -> t -> t

  val mul : t -> t -> t

  val compute_ssigma : int -> domain -> polynomial -> t

  val get_degree : t -> int

  val compute_sid : int -> int -> scalar array -> scalar array -> t

  val of_domain : domain -> t

  val to_domain : t -> domain

  val get_array : t -> scalar array

  val mul_by_scalar : scalar -> t -> t

  val one : size:int -> degree:int -> t
end

module Make_impl
    (Scalar : Ff_sig.PRIME)
    (Poly : Polynomial_c.Polynomial_sig with type scalar = Scalar.t) =
struct
  module Fr_generation = Fr_generation.Make (Scalar)

  type scalar = Scalar.t

  type polynomial = Poly.t

  type t = int * scalar array

  type domain = Poly.Domain.t

  let make_evaluation (d, p) =
    if d < 0 then
      raise @@ Invalid_argument "make_evaluation: degree must be non negative" ;
    if Array.length p <= d then
      raise
      @@ Invalid_argument "make_evaluation: array must be longer than degree" ;
    (d, p)

  let print_evaluation map =
    let s_eval =
      "{"
      ^ Misc.StringMap.fold
          (fun k (d, ev) acc ->
            acc ^ Printf.sprintf "\n  %s -> (%d, %d)" k d (Array.length ev))
          map
          ""
      ^ "\n}"
    in
    Printf.printf "\nevaluations : %s" s_eval

  let string_of_eval (d, e) =
    Printf.sprintf
      "%d : [%s]"
      d
      (String.concat
         " ; "
         Array.(
           to_list (map (fun s -> string_of_int (Z.hash (Scalar.to_z s))) e)))

  (* Returns the size of a non-nul element of evaluations ; raise failure if such an element is not found *)
  let rec size_evaluations evaluations =
    try
      let (name, e) = Misc.StringMap.choose evaluations in
      let l = Array.length (snd e) in
      if l = 0 then size_evaluations Misc.StringMap.(remove name evaluations)
      else l
    with Not_found ->
      failwith
        "Evaluations.size_evaluations : couldn't find evaluation of size \
         greater than zero : can't compute expected size of PI."

  let of_domain domain =
    let array = Poly.Domain.to_array domain in
    (1, array)

  let to_domain (_, eval) = Poly.Domain.of_array eval

  let get_array (_deg, array) = array

  let get_degree (deg, _eval) = deg

  let zero n = (0, Array.make n Scalar.zero)

  let one ~size ~degree =
    (degree, Poly.Domain.to_array @@ Poly.Domain.build ~log:size)

  let mul_by_scalar lambda (deg, eval) =
    if Scalar.is_zero lambda then zero deg
    else (deg, Array.map (fun coef -> Scalar.mul lambda coef) eval)

  let evaluation_fft domain poly =
    let degree = Poly.degree poly in
    (degree, Poly.evaluation_fft domain poly)

  let not_found x =
    raise
      (Invalid_argument
         (Printf.sprintf "Evaluations : %s not found in evaluations map." x))

  let find_eval ~evaluations name =
    match Misc.StringMap.find_opt name evaluations with
    | None -> not_found name
    | Some (d, eval) -> (d, eval)

  (* Returns the evals of "X" as a domain
     @raise Invalid_argument if "X" is not in evaluations
  *)
  let get_domain evaluations = to_domain (find_eval ~evaluations "X")

  (* Adds evaluation of poly_map’s polynomials on the domain given by the evaluation of "X"
     @raise Invalid_argument if "X" is not in evaluations
  *)
  let add_evaluations ?domain ~evaluations poly_map =
    let domain =
      match domain with Some domain -> domain | None -> get_domain evaluations
    in
    Misc.StringMap.(
      union_disjoint evaluations (map (evaluation_fft domain) poly_map))

  let compute_evaluations ~domain poly_map =
    Misc.StringMap.map (evaluation_fft domain) poly_map

  (* list_array contains the arrays to "multiply"
      length_result is the expected length of the resulting array
      Returns an array which contains at position i
     the multiplication of all elements of the arrays at position
     i * length of the array / length of the result.
      Arrays’ lengths and length_result are expected to be a power of two.
      Usefull for fft.
  *)
  let multiply_arrays list_array length_result =
    let res = Array.init length_result (fun _ -> Scalar.one) in
    let list_step =
      List.map (fun array -> Array.length array / length_result) list_array
    in
    let () =
      try
        Array.iteri
          (fun i _value ->
            List.iter2
              (fun array step -> res.(i) <- Scalar.mul res.(i) array.(i * step))
              list_array
              list_step)
          res
      with Invalid_argument _ ->
        failwith
          "The domain of the provided evaluation is to short with regard too \
           the desired length of the output."
    in
    res

  let polynomial_of_evaluation_without_degree ~evaluation =
    if evaluation = [||] then Poly.zero
    else
      let log = Z.(log2 (of_int (Array.length evaluation))) in
      let domain = Poly.Domain.build ~log in
      Poly.interpolation_fft domain evaluation

  let polynomial_of_evaluation (d, evaluation) =
    if evaluation = [||] || d = -1 then Poly.zero
    else
      let d = d + 1 in
      let log = Z.(log2up (of_int d)) in
      let length_result = Z.(to_int (one lsl log)) in
      let length_eval = Array.length evaluation in
      if length_result = length_eval then
        polynomial_of_evaluation_without_degree ~evaluation
      else if length_result > length_eval then
        failwith
          (Printf.sprintf
             "Evaluations.polynomial_of_evaluation : degree (= %d) is to large \
              regarding evaluation's length (= %d)."
             length_result
             length_eval)
      else
        let res =
          let step = length_eval / length_result in
          Array.init length_result (fun i -> evaluation.(i * step))
        in
        let domain = Poly.Domain.build ~log in
        Poly.interpolation_fft domain res

  (* multiplies evaluations of all polynomials with name in poly_names ; the resulting eval has the size of the smaller evaluation *)
  let mul_evaluations ~evaluations ~poly_names =
    let (deg_result, list_array, is_zero, (name_min, min_length_eval)) =
      List.fold_left
        (fun (acc_degree, list, is_zero, (min_name, min_length_eval)) x ->
          let (d, eval) = find_eval ~evaluations x in
          let is_zero = if d = -1 then true else is_zero in
          let new_min_length_eval =
            let l = Array.length eval in
            if l < min_length_eval then (x, l) else (min_name, min_length_eval)
          in
          (acc_degree + d, eval :: list, is_zero, new_min_length_eval))
        (0, [], false, ("", Int.max_int))
        poly_names
    in
    if is_zero then (-1, [||])
    else
      let log = Z.(log2up (of_int deg_result)) in
      let length_degree = Z.(to_int (one lsl log)) in
      if length_degree > min_length_eval then
        raise
          (Invalid_argument
             (Printf.sprintf
                "Utils.mul_evaluations : %s's evaluation is too short \
                 (length=%d) for expected result size %d"
                name_min
                min_length_eval
                length_degree))
      else (deg_result, multiply_arrays list_array min_length_eval)

  module Composition = struct
    (* for p_eval (fft evaluation of p), computes p(gX) fft evaluation on the same domain, for g n-th root of unity *)
    let composition_g_eval p_eval n =
      let length = Array.length p_eval in
      assert (length >= n) ;
      let shift = length / n in
      Array.init length (fun i -> p_eval.((shift + i) mod length))

    (* add compute_eval_g p n in evaluations for each p whose name is in poly_name *)
    let composition_g_evals_map ?(suffix = "") n ~evaluations ~poly_names =
      let fun_map name =
        let (d, eval) = find_eval ~evaluations name in
        (name ^ "g" ^ suffix, (d, composition_g_eval eval n))
      in
      let map_g = Misc.StringMap.of_list (List.map fun_map poly_names) in
      Misc.StringMap.union_disjoint map_g evaluations
  end

  type eval = {
    degree : int;
    evals : Scalar.t array;
    length : int;
    shift : int;
    step : int;
  }

  module Auxiliary = struct
    let id x = x

    (* These apply functions help to apply functions of given arity to array’s elements *)

    let apply_2_degree func x = func x.(0).degree x.(1).degree

    let apply_3_degree func x = func x.(0).degree x.(1).degree x.(2).degree

    let apply_4_degree func x =
      func x.(0).degree x.(1).degree x.(2).degree x.(3).degree

    let apply_2 func x = func x.(0) x.(1)

    let apply_3 func x = func x.(0) x.(1) x.(2)

    let apply_4 func x = func x.(0) x.(1) x.(2) x.(3)

    let apply_func_degree func array_evals =
      func (Array.map (fun e -> e.degree) array_evals)

    let compute_shift length (deg_compo, n) =
      if deg_compo = 0 || n = 0 then 0
      else
        let () = assert (length >= n) in
        deg_compo * length / n

    let get_min_list list = List.(fold_left min (hd list) (tl list))

    (* returns the minimum length of all evals *)
    let get_min evals =
      Array.(fold_left (fun acc li -> min acc li.length) evals.(0).length evals)

    (* returns the i-th evaluation of eval considering the shift & the step *)
    let get_ith_eval evals i =
      let index i step shift length = ((i * step) + shift) mod length in
      evals.evals.(index i evals.step evals.shift evals.length)

    (* returns for name in evaluations the binded (degree, evaluation), the length of evaluation & the shift needed for composition *)
    let get_eval_simple ~evaluations name composition =
      let (d, eval) = find_eval ~evaluations name in
      let l = Array.length eval in
      let shift = compute_shift l composition in
      (d, eval, l, shift)

    (* same as get_eval_simple, but for an array of names and compositions & the result is given in the eval type *)
    let get_evals ~evaluations names compos =
      let evals =
        Array.map2
          (fun name compo ->
            let (d, evals) = find_eval ~evaluations name in
            let l = Array.length evals in
            let shift = compute_shift l compo in
            (* step is set to -1 because it can’t be computed before the minimum length is known *)
            {degree = d; evals; length = l; shift; step = -1})
          names
          compos
      in
      (get_min evals, evals)

    (* update evals with the needed step computed from length_result *)
    let update_step length_result evals =
      Array.iteri
        (fun i e -> evals.(i) <- {e with step = e.length / length_result})
        evals

    (* returns Some(degree, evaluation) computed from all the evaluations of names with the right composition, by applying func and func_degree ; apply_nb & apply_nb_degree are helpers function that convert a function of arity k to a function of an array
       degree_is_len has to be set to true if the result has to be sized from the resulting degree (i.e. if polynomial_of_evaluation is directly used on the result) ; if it’s false, the size of the result will be the size of the smaller evaluation involved in the computation
       returns None if degree_is_len is true & the resulting poly is null
    *)
    let compute_degree_evals ~degree_is_len ~evaluations ~func ~func_degree
        names compositions apply_nb apply_nb_degree =
      let nb = Array.length names in
      let (min_lengths, all_evals) =
        get_evals ~evaluations names compositions
      in
      let res_degree = apply_nb_degree func_degree all_evals in
      if degree_is_len && res_degree < 0 then None
      else
        let length_result =
          if degree_is_len then 1 lsl Z.(log2up (succ (of_int res_degree)))
          else min_lengths
        in
        assert (length_result <= min_lengths) ;
        update_step length_result all_evals ;
        let res_eval =
          Array.init length_result (fun i ->
              let evals_i =
                Array.init nb (fun j -> get_ith_eval all_evals.(j) i)
              in
              apply_nb func evals_i)
        in
        Some (res_degree, res_eval)
  end

  (* /!\ func_degree may not be always accurate ; especially, in a sum,
     the resulting degree may not be the max of the 2 polynomials degrees,
     or when multiplying by the null polynomial, the sum of degree is not the degree of the result *)

  (* Returns evaluation of func(p1, p2) ; name1 (resp. name2) is the name of p1 (resp. p2) in evaluations map ; composition_pow_order_1 refers to the first & composition_pow_order_2 to the second ; if not set to (0, 0) composition_pow_order_1 = (i, n) produces the result func(p1(gⁱX), p2), where gⁿ = 1 ; func_degree is used to compute the degree of the resulting polynomial *)
  let op_2 ~evaluations ~func ~func_degree ~names_p1_p2:(name1, name2)
      ?(composition_pow_order_1 = (0, 0)) ?(composition_pow_order_2 = (0, 0)) ()
      =
    let names = [|name1; name2|] in
    let compos = [|composition_pow_order_1; composition_pow_order_2|] in
    Option.get
      (Auxiliary.compute_degree_evals
         ~degree_is_len:false
         ~evaluations
         ~func
         ~func_degree
         names
         compos
         Auxiliary.apply_2
         Auxiliary.apply_2_degree)

  let op_3 ~evaluations ~func ~func_degree ~names_p1_p2_p3:(name1, name2, name3)
      ?(composition_pow_order_1 = (0, 0)) ?(composition_pow_order_2 = (0, 0))
      ?(composition_pow_order_3 = (0, 0)) () =
    let names = [|name1; name2; name3|] in
    let compos =
      [|
        composition_pow_order_1;
        composition_pow_order_2;
        composition_pow_order_3;
      |]
    in
    Option.get
      (Auxiliary.compute_degree_evals
         ~degree_is_len:false
         ~evaluations
         ~func
         ~func_degree
         names
         compos
         Auxiliary.apply_3
         Auxiliary.apply_3_degree)

  let op_4 ~evaluations ~func ~func_degree
      ~names_p1_p2_p3_p4:(name1, name2, name3, name4)
      ?(composition_pow_order_1 = (0, 0)) ?(composition_pow_order_2 = (0, 0))
      ?(composition_pow_order_3 = (0, 0)) ?(composition_pow_order_4 = (0, 0)) ()
      =
    let names = [|name1; name2; name3; name4|] in
    let compos =
      [|
        composition_pow_order_1;
        composition_pow_order_2;
        composition_pow_order_3;
        composition_pow_order_4;
      |]
    in
    Option.get
      (Auxiliary.compute_degree_evals
         ~degree_is_len:false
         ~evaluations
         ~func
         ~func_degree
         names
         compos
         Auxiliary.apply_4
         Auxiliary.apply_4_degree)

  (* Same as previous op_x but for a variable number of polynomials ; func & func_degree now must take array, and composition contains for each polynomial, the degree of the generator in the composition, and the order of the generator *)
  let op_n ~evaluations ~func ~func_degree ~names ?(composition = ([||], 0)) ()
      =
    let composition =
      Array.map (fun x -> (x, snd composition)) (fst composition)
    in
    Option.get
      (Auxiliary.compute_degree_evals
         ~degree_is_len:false
         ~evaluations
         ~func
         ~func_degree
         names
         composition
         Auxiliary.id
         Auxiliary.apply_func_degree)

  (* Same as op_3 but adds the result in evaluations ; composition_pow_order_1 refers to the first, composition_pow_order_2 to the second & composition_pow_order_3 to the third *)
  let op_3_add ~evaluations ~func ~func_degree
      ~names_p1_p2_p3:(name1, name2, name3) ~name_result
      ?(composition_pow_order_1 = (0, 0)) ?(composition_pow_order_2 = (0, 0))
      ?(composition_pow_order_3 = (0, 0)) () =
    let names = [|name1; name2; name3|] in
    let compos =
      [|
        composition_pow_order_1;
        composition_pow_order_2;
        composition_pow_order_3;
      |]
    in
    let (res_degree, res_eval) =
      Option.get
        (Auxiliary.compute_degree_evals
           ~degree_is_len:false
           ~evaluations
           ~func
           ~func_degree
           names
           compos
           Auxiliary.apply_3
           Auxiliary.apply_3_degree)
    in
    Misc.StringMap.add_unique name_result (res_degree, res_eval) evaluations

  (* Adds evaluation of a1 × p1 + a2 × p2 in evaluations *)
  let linear_2 ~evaluations ~coefs:(a1, a2) ~names_p1_p2:(name1, name2)
      ~name_result =
    let (d1, eval1, l1, _shift1) =
      Auxiliary.get_eval_simple ~evaluations name1 (0, 0)
    in
    let (d2, eval2, l2, _shift2) =
      Auxiliary.get_eval_simple ~evaluations name2 (0, 0)
    in
    if d1 = -1 then
      Misc.StringMap.add_unique
        name_result
        (d2, Array.map Scalar.(mul a2) eval2)
        evaluations
    else if d2 = -1 then
      Misc.StringMap.add_unique
        name_result
        (d1, Array.map Scalar.(mul a1) eval1)
        evaluations
    else
      let length_result = Auxiliary.get_min_list [l1; l2] in
      let (step1, step2) = (l1 / length_result, l2 / length_result) in
      let res_eval =
        Array.init (min l1 l2) (fun i ->
            let (e1, e2) = (eval1.(i * step1), eval2.(i * step2)) in
            Scalar.((a1 * e1) + (a2 * e2)))
      in
      let res_degree = max d1 d2 in
      Misc.StringMap.add_unique name_result (res_degree, res_eval) evaluations

  (* Adds 2 evaluations *)
  let add (d1, eval1) (d2, eval2) =
    if d1 = -1 then (d2, eval2)
    else if d2 = -1 then (d1, eval1)
    else
      let l1 = Array.length eval1 in
      let l2 = Array.length eval2 in
      let deg_result = max d1 d2 in
      let length_result = min l1 l2 in
      let (step1, step2) = (l1 / length_result, l2 / length_result) in
      let res_eval =
        Array.init length_result (fun i ->
            let (e1, e2) = (eval1.(i * step1), eval2.(i * step2)) in
            Scalar.(e1 + e2))
      in
      (deg_result, res_eval)

  (* Multiplies 2 evaluations *)
  let mul a b =
    let evaluations = Misc.StringMap.of_list [("a", a); ("b", b)] in
    mul_evaluations ~evaluations ~poly_names:["a"; "b"]

  let compute_l1 n domain l1 = (n - 1, Poly.evaluation_fft domain l1)

  let compute_ssigma = compute_l1

  let compute_sid i n domain qnr =
    let k =
      if i < Array.length qnr then qnr.(i)
      else
        raise
          (Invalid_argument
             (Printf.sprintf
                "Compute_sid: not enough quadratic non-residues, asked %i but \
                 only %i available."
                i
                (Array.length qnr)))
    in
    let evals = Array.map (Scalar.mul k) domain in
    (n - 1, evals)

  let zero = (-1, [||])

  let equal (deg_1, array_1) (deg_2, array_2) =
    if deg_1 <> deg_2 || Array.length array_1 <> Array.length array_2 then false
    else Array.for_all2 Scalar.eq array_1 array_2
end

module Make
    (Scalar : Ff_sig.PRIME)
    (Poly : Polynomial_c.Polynomial_sig with type scalar = Scalar.t) :
  Evaluations_sig
    with type scalar = Scalar.t
     and type polynomial = Poly.t
     and type domain = Poly.Domain.t =
  Make_impl (Scalar) (Poly)
