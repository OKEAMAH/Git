module Plookup_gate_impl (PP : Polynomial_protocol.Polynomial_protocol_sig) =
struct
  module PP = PP
  module MP = PP.MP
  module Poly = PP.PC.Polynomial.Polynomial
  module Scalar = PP.PC.Scalar
  module Scalar_map = PP.PC.Scalar_map
  module Fr_generation = PP.PC.Fr_generation
  module Evaluations = PP.Evaluations

  exception Entry_not_in_table of string

  let q_label = "q_plookup"

  let q_table = "q_table"

  let f = "f_plookup"

  let fg = "fg_plookup"

  let z = "z_plookup"

  let t = "table"

  let h1 = "h1"

  let h2 = "h2"

  let zg = "zg_plookup"

  let tg = "tg_plookup"

  let h1g = "h1g"

  let h2g = "h2g"

  let l1 = "L1"

  let ln_p_1 = "L_n_plus_1"

  let x_m_1 = "x_minus_1"

  let x = "X"

  type public_parameters =
    (PP.prover_public_parameters * PP.verifier_public_parameters)
    * PP.PC.Scalar.t array list

  let zero = Scalar.zero

  let one = Scalar.one

  let mone = Scalar.negate one

  let gate_identity ~prefix ~wires_name ~alpha ~beta ~gamma ~ultra =
    let t = prefix ^ t in
    let tg = prefix ^ tg in
    let z = prefix ^ z in
    let zg = prefix ^ zg in
    let f = prefix ^ f in
    let fg = prefix ^ fg in
    let h1 = prefix ^ h1 in
    let h2 = prefix ^ h2 in
    let h1g = prefix ^ h1g in
    let h2g = prefix ^ h2g in
    let q_label = prefix ^ q_label in
    let q_table = prefix ^ q_table in
    let wires_name = Array.map (fun x -> prefix ^ x) wires_name in
    let neg x = Scalar.negate x in
    let mul x y = Scalar.mul x y in
    let one_p_b = Scalar.(one + beta) in
    let g_one_p_b = Scalar.(gamma * one_p_b) in
    let g_one_p_b_2 = Scalar.square g_one_p_b in
    (* Identity: L1(x)·[Z(x) - 1] = 0 *)
    let id_a = [(one, [l1; z]); (mone, [l1])] in
    (* Identity: Ln+1(x)·[h1(x) - h2(x)] = 0 *)
    let id_c = [(one, [ln_p_1; h1]); (mone, [ln_p_1; h2g])] in
    (* Identity: Ln+1(x)·[Z(x) - 1] = 0 *)
    let id_d = [(one, [ln_p_1; z]); (mone, [ln_p_1])] in
    (* Identity:
       (x - g^{n+1})·Z(x)·(1 + β)·[γ + f(x)]·[γ(1 + β) + t(x) + β·t(gx)]
       = (x - g^{n+1})·Z(g·x)·[γ(1 + β) + h1(x) + β·h1(gx)]·[γ(1 + β) + h2(x) + β·h2(gx)]
    *)
    (* Developping the left part of the equality *)
    let l_g_a = (g_one_p_b_2, [x_m_1; z]) in
    let l_g_b = (g_one_p_b, [x_m_1; t; z]) in
    let l_g_c = (mul beta g_one_p_b, [x_m_1; z; tg]) in
    let l_f_a = (mul g_one_p_b one_p_b, [x_m_1; z; f]) in
    let l_f_b = (one_p_b, [x_m_1; t; z; f]) in
    let l_f_c = (mul beta one_p_b, [x_m_1; z; f; tg]) in
    (* Developping the right part of the equality *)
    let ra_a_a = (neg g_one_p_b_2, [x_m_1; zg]) in
    let ra_a_b = (neg g_one_p_b, [x_m_1; h2; zg]) in
    let ra_a_c = (neg (mul g_one_p_b beta), [x_m_1; zg; h2g]) in
    let ra_b_a = (neg g_one_p_b, [x_m_1; h1; zg]) in
    let ra_b_b = (mone, [x_m_1; h1; h2; zg]) in
    let ra_b_c = (neg beta, [x_m_1; h1; zg; h2g]) in
    let ra_c_a = (neg (mul g_one_p_b beta), [x_m_1; h1g; zg]) in
    let ra_c_b = (neg beta, [x_m_1; h1g; h2; zg]) in
    let ra_c_c = (neg (Scalar.square beta), [x_m_1; h1g; zg; h2g]) in
    let id_b =
      [
        l_g_a;
        l_g_b;
        l_g_c;
        l_f_a;
        l_f_b;
        l_f_c;
        ra_a_a;
        ra_a_b;
        ra_a_c;
        ra_b_a;
        ra_b_b;
        ra_b_c;
        ra_c_a;
        ra_c_b;
        ra_c_c;
      ]
    in
    let ids =
      let monome str_list = SMap.monomial_of_list str_list in
      let switch l = List.map (fun (a, b) -> (monome (q_label :: b), a)) l in
      let base = List.map (fun id -> switch id) [id_a; id_b; id_c; id_d] in
      let updated_base =
        if ultra then
          let (_i, id_agg) =
            List.fold_left
              (fun (i, l) fi ->
                let alpha_i = Scalar.pow alpha (Z.of_int i) in
                (i + 1, (monome [q_label; fi], alpha_i) :: l))
              (0, [(monome [q_label; fg], mone)])
              (q_table :: Array.to_list wires_name)
          in
          id_agg :: base
        else base
      in
      List.map (fun id -> MP.Polynomial.of_list id) updated_base
    in
    let id_names =
      let base =
        [
          prefix ^ "Plookup.a";
          prefix ^ "Plookup.b";
          prefix ^ "Plookup.c";
          prefix ^ "Plookup.d";
        ]
      in
      if ultra then (prefix ^ "Plookup.ultra") :: base else base
    in
    SMap.of_list (List.combine id_names ids)

  let v_map ~prefix generator ultra =
    let map =
      let g_poly = Poly.of_coefficients [(generator, 1)] in
      SMap.of_list
        [
          (prefix ^ fg, (prefix ^ f, g_poly));
          (prefix ^ zg, (prefix ^ z, g_poly));
          (prefix ^ tg, (prefix ^ t, g_poly));
          (prefix ^ h1g, (prefix ^ h1, g_poly));
          (prefix ^ h2g, (prefix ^ h2, g_poly));
        ]
    in
    if ultra then SMap.remove l1 map else SMap.remove fg map

  let precomputed_poly_contribution ~wires_name ~alpha ~beta ~gamma ~f_map
      ~ultra ~evaluations n =
    let fs = if ultra then q_table :: Array.to_list wires_name else [] in
    let evaluations =
      if ultra then evaluations
      else
        let poly name = (name, SMap.find name f_map) in
        let poly_map = SMap.of_list [poly z; poly h1; poly h2; poly f] in
        Evaluations.compute_evaluations_update_map ~evaluations poly_map
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[z]
        ~add_constant:mone
        ~name_result:"z - 1"
        ()
    in
    let ida =
      Evaluations.mul ~evaluations ~poly_names:[q_label; l1; "z - 1"] ()
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[h1; h2]
        ~linear_coeffs:[one; mone]
        ~composition_gx:([0; 1], n)
        ~name_result:"h1 - h2g"
        ()
    in

    let idc =
      Evaluations.mul ~evaluations ~poly_names:[q_label; ln_p_1; "h1 - h2g"] ()
    in
    let idd =
      Evaluations.mul ~evaluations ~poly_names:[q_label; ln_p_1; "z - 1"] ()
    in
    let one_p_b = Scalar.(one + beta) in
    let g_one_p_b = Scalar.(gamma * one_p_b) in

    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[x]
        ~add_constant:mone
        ~name_result:"x - 1"
        ()
    in

    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[f]
        ~add_constant:gamma
        ~name_result:"f + gamma"
        ()
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[t; t]
        ~add_constant:g_one_p_b
        ~composition_gx:([0; 1], n)
        ~linear_coeffs:[one; beta]
        ~name_result:"gamma * (1 + beta) + t + beta * tg"
        ()
    in
    let evaluations =
      Evaluations.mul_update_map
        ~evaluations
        ~poly_names:
          [z; "x - 1"; "f + gamma"; "gamma * (1 + beta) + t + beta * tg"]
        ~name_result:
          "z * (x - 1) * (f + gamma) * (gamma * (1 + beta) + t + beta * tg)"
        ()
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:
          ["z * (x - 1) * (f + gamma) * (gamma * (1 + beta) + t + beta * tg)"]
        ~linear_coeffs:[one_p_b]
        ~name_result:
          "one_p_b * (z * (x - 1) * (f + gamma) * (gamma * (1 + beta) + t + \
           beta * tg))"
        ()
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[h1; h1]
        ~add_constant:g_one_p_b
        ~composition_gx:([0; 1], n)
        ~linear_coeffs:[one; beta]
        ~name_result:"g_one_p_b + h1 + beta * h1g"
        ()
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:[h2; h2]
        ~add_constant:g_one_p_b
        ~composition_gx:([0; 1], n)
        ~linear_coeffs:[one; beta]
        ~name_result:"g_one_p_b + h2 + beta * h2g"
        ()
    in
    let evaluations =
      Evaluations.mul_update_map
        ~evaluations
        ~poly_names:
          [
            z;
            "x - 1";
            "g_one_p_b + h1 + beta * h1g";
            "g_one_p_b + h2 + beta * h2g";
          ]
        ~composition_gx:([1; 0; 0; 0], n)
        ~name_result:
          "zg * (x - 1) * (g_one_p_b + h1 + beta * h1g) * (g_one_p_b + h2 + \
           beta * h2g)"
        ()
    in
    let evaluations =
      Evaluations.linear_update_map
        ~evaluations
        ~poly_names:
          [
            "one_p_b * (z * (x - 1) * (f + gamma) * (gamma * (1 + beta) + t + \
             beta * tg))";
            "zg * (x - 1) * (g_one_p_b + h1 + beta * h1g) * (g_one_p_b + h2 + \
             beta * h2g)";
          ]
        ~linear_coeffs:[one; mone]
        ~name_result:"identity_b"
        ()
    in
    let idb =
      Evaluations.mul ~evaluations ~poly_names:[q_label; "identity_b"] ()
    in

    let base = [ida; idb; idc; idd] in
    let ids =
      if ultra then
        let id_agg =
          let (_alpha, name_ai_fi, evaluations) =
            List.fold_left
              (fun (alpha_i, acc_name, evaluations) name ->
                let new_acc_name = acc_name ^ " + " ^ name in
                let evaluations =
                  Evaluations.linear_update_map
                    ~evaluations
                    ~linear_coeffs:[one; alpha_i]
                    ~poly_names:[acc_name; name]
                    ~name_result:new_acc_name
                    ()
                in
                (Scalar.(alpha_i * alpha), new_acc_name, evaluations))
              (alpha, List.hd fs, evaluations)
              (List.tl fs)
          in
          let evaluations =
            Evaluations.linear_update_map
              ~evaluations
              ~poly_names:[name_ai_fi; f]
              ~linear_coeffs:[one; mone]
              ~composition_gx:([0; 1], n)
              ~name_result:"s - f"
              ()
          in
          Evaluations.mul ~evaluations ~poly_names:[q_label; "s - f"] ()
        in
        id_agg :: base
      else base
    in
    let id_names =
      let base = ["Plookup.a"; "Plookup.b"; "Plookup.c"; "Plookup.d"] in
      if ultra then "Plookup.ultra" :: base else base
    in
    SMap.of_list (List.combine id_names ids)

  module Plookup_poly = struct
    let l1 n domain =
      let scalar_list =
        Array.(
          append
            Fr_generation.[|fr_of_int_safe 0; fr_of_int_safe 1|]
            (init (n - 2) (fun _ -> zero)))
      in
      Evaluations.interpolation_fft2 domain scalar_list

    let ln_p_1 n domain =
      let scalar_list =
        Array.(
          append
            [|Fr_generation.fr_of_int_safe 1|]
            (init (n - 1) (fun _ -> zero)))
      in
      Evaluations.interpolation_fft2 domain scalar_list

    (* computes an array where the i-th element is sum_j alpha_j*x_i,j
       where x_i,j is the i-th elementof the j_th array of the list*)
    let compute_aggregation array_list alpha =
      let n = Array.length (List.hd array_list) in
      let nb_wires = List.length array_list in
      let alpha_array = Fr_generation.powers nb_wires alpha in
      Array.init n (fun i ->
          let fis = List.map (fun array -> array.(i)) array_list in
          List.fold_left2
            (fun acc alpha_j fij -> Scalar.(acc + (alpha_j * fij)))
            Scalar.zero
            (Array.to_list alpha_array)
            fis)

    let compute_f_aggregation gates wires alpha n =
      let q = Array.of_list (SMap.find q_label gates) in
      let nb_wires = SMap.cardinal wires in
      let alpha_array = Fr_generation.powers nb_wires alpha in
      let array_list =
        List.map (fun (_k, l) -> Array.of_list l) (SMap.bindings wires)
      in
      let compute_aggregate qi fis =
        List.fold_left2
          (fun acc alpha_j fij -> Scalar.(acc + (alpha_j * qi * fij)))
          Scalar.zero
          (Array.to_list alpha_array)
          fis
      in
      (* Store previous lookup to pad with *)
      let previous_lookup =
        let index =
          List.find
            (fun i -> not (Scalar.is_zero q.(i)))
            (List.init n (fun i -> i))
        in
        let q0 = q.(index) in
        let f0s = List.map (fun array -> array.(index)) array_list in
        ref (compute_aggregate q0 f0s)
      in
      Array.init n (fun i ->
          let qi = q.(i) in
          if Scalar.is_zero qi then !previous_lookup
          else
            let fis = List.map (fun array -> array.(i)) array_list in
            let lookup = compute_aggregate qi fis in
            if not (Scalar.eq !previous_lookup lookup) then
              previous_lookup := lookup ;
            lookup)

    let sort_by f t =
      let (indexes_t, _) =
        Array.fold_left
          (fun (map, i) z -> (Scalar_map.add z i map, i + 1))
          (Scalar_map.empty, 0)
          t
      in
      let my_compare a b =
        let a_index_opt = Scalar_map.find_opt a indexes_t in
        let b_index_opt = Scalar_map.find_opt b indexes_t in
        match (a_index_opt, b_index_opt) with
        | (Some a_index, Some b_index) -> a_index - b_index
        | _ -> raise (Entry_not_in_table "Array f is not included in array t")
      in
      Array.sort my_compare f ;
      f

    let switch t =
      let k = Array.length t in
      Array.init k (fun i -> if i = 0 then t.(k - 1) else t.(i - 1))

    let t_poly_from_tables tables alpha domain =
      let t = compute_aggregation tables alpha in
      Evaluations.interpolation_fft2 domain (switch t)

    let compute_s f t = sort_by (Array.concat [f; t]) t

    let compute_h s domain n =
      let compute_hi ~domain ~start s n =
        Evaluations.interpolation_fft2 domain (switch (Array.sub s start n))
      in
      let h1 = compute_hi ~domain ~start:0 s n in
      let h2 = compute_hi ~domain ~start:(n - 1) s n in
      (h1, h2)

    let compute_z beta gamma f t s n domain =
      let one_p_beta = Scalar.(one + beta) in
      let gamma_one_p_beta = Scalar.(gamma * one_p_beta) in
      let rec fill_product_array i acc func array =
        if i = n - 1 then ()
        else
          let acc = func acc i in
          array.(i) <- acc ;
          fill_product_array (i + 1) acc func array
      in
      let f_product_array = Array.make (n - 1) one in
      let f_func acc i = Scalar.(acc * (f.(i) + gamma)) in
      (* todo check it starts at one *)
      fill_product_array 0 one f_func f_product_array ;
      let to_acc array i =
        Scalar.(gamma_one_p_beta + array.(i) + (beta * array.(Int.succ i)))
      in
      let t_product_array = Array.make (n - 1) one in
      let t_func acc i =
        let acc_i = to_acc t i in
        Scalar.mul acc acc_i
      in
      fill_product_array 0 one t_func t_product_array ;
      let s_product_array = Array.make (n - 1) one in
      let s_func acc i =
        let acc_i = to_acc s i in
        let acc_n_i = to_acc s (n - 1 + i) in
        Scalar.(acc * acc_i * acc_n_i)
      in
      fill_product_array 0 one s_func s_product_array ;
      let one_p_beta_array = Array.make (n - 1) one in
      let b_func acc _i = Scalar.mul acc one_p_beta in
      fill_product_array 0 one b_func one_p_beta_array ;
      let z_array =
        Array.init n (fun i ->
            if i = 0 || i = 1 then one
            else
              let k = i - 2 in
              Scalar.(
                one_p_beta_array.(k) * f_product_array.(k) * t_product_array.(k)
                / s_product_array.(k)))
      in
      Evaluations.interpolation_fft2 domain z_array
  end

  let srs_size ~length_table =
    let log = Z.(log2up (of_int length_table)) in
    let length_padded = Int.shift_left 1 log in
    length_padded

  (* max degree of Plookup identities is idb’s degree, which is ~4n *)
  let polynomials_degree () = 4

  let common_preprocessing ~n:nb_records ~domain =
    let l_map =
      SMap.of_list
        [
          (l1, Plookup_poly.l1 nb_records domain);
          (ln_p_1, Plookup_poly.ln_p_1 nb_records domain);
        ]
    in
    l_map

  let preprocessing ?(prefix = "") ~domain ~tables ~alpha () =
    let t_poly = Plookup_poly.t_poly_from_tables tables alpha domain in
    SMap.singleton (prefix ^ t) t_poly

  let format_tables ~tables ~nb_columns ~length_not_padded ~length_padded =
    let concatenated_table =
      (* We make sure that all tables have the same number of columns as the number of wires by filling with columns of 0s.
         We also index tables. *)
      let corrected_tables =
        List.mapi
          (fun i t ->
            let nb_subtable_columns = List.length t in
            let sub_table_size = Array.length (List.hd t) in
            (* Pad table to have constant number of columns. *)
            let padding_columns =
              List.init (nb_columns - nb_subtable_columns) (fun _ ->
                  Array.make sub_table_size zero)
            in
            let full_table = t @ padding_columns in
            (* Indexing table. *)
            Array.make sub_table_size (Scalar.of_z (Z.of_int i)) :: full_table)
          tables
      in
      (* Concatenating tables. *)
      let acc_n = List.init (nb_columns + 1) (fun _ -> [||]) in
      List.fold_left
        (fun aa ll -> List.map2 (fun a l -> Array.append a l) aa ll)
        acc_n
        corrected_tables
    in
    (* Padding table. *)
    List.map
      (fun t ->
        let last = t.(length_not_padded - 1) in
        let padding = Array.make (length_padded - length_not_padded) last in
        Array.append t padding)
      concatenated_table

  let setup ~nb_wires ~domain ~size_domain ~tables ~table_size ~alpha ~srs_file
      =
    let tables =
      format_tables
        ~tables
        ~nb_columns:nb_wires
        ~length_not_padded:table_size
        ~length_padded:size_domain
    in
    let map_preprocessed_poly =
      SMap.union_disjoint
        (common_preprocessing ~n:size_domain ~domain)
        (preprocessing ~domain ~tables ~alpha ())
    in
    let (prover_pp_parameters, verifier_pp_parameters) =
      PP.setup
        ~setup_params:((2 * size_domain) + 1, 0)
        map_preprocessed_poly
        ~subgroup_size:size_domain
        srs_file
    in
    ((prover_pp_parameters, verifier_pp_parameters), tables)

  let prover_query ?(prefix = "") ~generator ~f_map ~wires_name ~alpha ~beta
      ~gamma ~ultra ~evaluations ~n () =
    let precomputed_polys =
      precomputed_poly_contribution
        ~wires_name
        ~alpha
        ~beta
        ~gamma
        ~f_map
        ~ultra
        ~evaluations
        n
    in
    let v_map = v_map ~prefix generator ultra in
    PP.{v_map; precomputed_polys}

  (* Add a [not_committed] variant to represent Scalar.(add x.(0) mone) *)
  type PP.not_committed += XmOne

  let () =
    (* NB: do not change tag, it will break the encoding *)
    PP.register_nc_eval_and_encoding
      (function XmOne -> Some (fun x -> Scalar.(x.(0) + mone)) | _ -> None)
      ~title:"plookup"
      ~tag:2
      Data_encoding.unit
      (function XmOne -> Some () | _ -> None)
      (fun () -> XmOne)

  let verifier_query ?(prefix = "") ~generator ~wires_name ~alpha ~beta ~gamma
      ~ultra () =
    let v_map = v_map ~prefix generator ultra in
    PP.
      {
        v_map;
        identities =
          gate_identity ~prefix ~wires_name ~alpha ~beta ~gamma ~ultra;
        not_committed = SMap.singleton x_m_1 XmOne;
      }

  (* wires must be correctly padded *)
  (*TODO : do this in evaluation*)
  (*TODO : use mul z_s*)
  let f_map_contribution ~wires ~gates ~tables ~blinds ~alpha ~beta ~gamma
      ~domain ~size_domain ~circuit_size ~ultra =
    let t_agg = Plookup_poly.compute_aggregation tables alpha in
    (* We add the table selector to be aggregated alongside the wires. *)
    let wires_to_agg =
      let table_selector = SMap.find q_table gates in
      (* We add the prefix _ to the selector's label to make sure the selector is first in the map. *)
      SMap.add ("_" ^ q_table) table_selector wires
    in
    let final_size = size_domain - 1 in
    (* /!\ We remove here the last value of each wire, this is ok as it always corresponds to padding. *)
    let padded_f_list =
      SMap.map
        (fun w -> List.resize w ~size:circuit_size ~final_size)
        wires_to_agg
    in
    let f_agg =
      Plookup_poly.compute_f_aggregation gates padded_f_list alpha final_size
    in
    let f_poly =
      Evaluations.interpolation_fft2 domain Array.(append [|zero|] f_agg)
    in
    let s = Plookup_poly.compute_s f_agg t_agg in
    let (h1_poly, h2_poly) = Plookup_poly.compute_h s domain size_domain in
    let z_poly =
      Plookup_poly.compute_z beta gamma f_agg t_agg s size_domain domain
    in
    let (z_poly, f_poly, h1_poly, h2_poly) =
      match blinds with
      | None -> (z_poly, f_poly, h1_poly, h2_poly)
      | Some b ->
          let p_z = Poly.of_coefficients [(b.(0), 2); (b.(1), 1); (b.(2), 0)] in
          let p_h1 =
            Poly.of_coefficients [(b.(3), 2); (b.(4), 1); (b.(5), 0)]
          in
          let p_h2 =
            Poly.of_coefficients [(b.(6), 2); (b.(7), 1); (b.(8), 0)]
          in
          let p_f =
            if ultra then
              Poly.of_coefficients [(b.(9), 2); (b.(10), 1); (b.(11), 0)]
            else Poly.of_coefficients [(b.(9), 1); (b.(10), 0)]
          in
          let zs =
            Poly.of_coefficients [(one, size_domain); (Scalar.(negate one), 0)]
          in
          Poly.
            ( (zs * p_z) + z_poly,
              (zs * p_f) + f_poly,
              (zs * p_h1) + h1_poly,
              (zs * p_h2) + h2_poly )
    in
    SMap.of_list [(h1, h1_poly); (h2, h2_poly); (z, z_poly); (f, f_poly)]
end

module type Plookup_gate_sig = sig
  module PP : Polynomial_protocol.Polynomial_protocol_sig

  exception Entry_not_in_table of string

  type public_parameters =
    (PP.prover_public_parameters * PP.verifier_public_parameters)
    * PP.PC.Scalar.t array list

  val srs_size : length_table:int -> int

  val polynomials_degree : unit -> int

  val format_tables :
    tables:PP.PC.Scalar.t array list list ->
    nb_columns:int ->
    length_not_padded:int ->
    length_padded:int ->
    PP.PC.Scalar.t array list

  val common_preprocessing :
    n:int ->
    domain:PP.PC.Polynomial.Domain.t ->
    PP.PC.Polynomial.Polynomial.t SMap.t

  val preprocessing :
    ?prefix:string ->
    domain:PP.PC.Polynomial.Domain.t ->
    tables:PP.PC.Scalar.t array list ->
    alpha:PP.PC.Scalar.t ->
    unit ->
    PP.PC.Polynomial.Polynomial.t SMap.t

  val setup :
    nb_wires:int ->
    domain:PP.PC.Polynomial.Domain.t ->
    size_domain:int ->
    tables:PP.PC.Scalar.t array list list ->
    table_size:int ->
    alpha:PP.PC.Scalar.t ->
    srs_file:string ->
    public_parameters

  val prover_query :
    ?prefix:string ->
    generator:PP.PC.Scalar.t ->
    f_map:PP.PC.Polynomial.Polynomial.t SMap.t ->
    wires_name:string array ->
    alpha:PP.PC.Scalar.t ->
    beta:PP.PC.Scalar.t ->
    gamma:PP.PC.Scalar.t ->
    ultra:bool ->
    evaluations:PP.Evaluations.t SMap.t ->
    n:int ->
    unit ->
    PP.prover_query

  val verifier_query :
    ?prefix:string ->
    generator:PP.PC.Scalar.t ->
    wires_name:string array ->
    alpha:PP.PC.Scalar.t ->
    beta:PP.PC.Scalar.t ->
    gamma:PP.PC.Scalar.t ->
    ultra:bool ->
    unit ->
    PP.verifier_query

  val f_map_contribution :
    wires:PP.PC.Scalar.t list SMap.t ->
    gates:PP.PC.Scalar.t list SMap.t ->
    tables:PP.PC.Scalar.t array list ->
    blinds:PP.PC.Scalar.t array option ->
    alpha:PP.PC.Scalar.t ->
    beta:PP.PC.Scalar.t ->
    gamma:PP.PC.Scalar.t ->
    domain:PP.PC.Polynomial.Domain.t ->
    size_domain:int ->
    circuit_size:int ->
    ultra:bool ->
    PP.PC.secret
end

module Plookup_gate (PP : Polynomial_protocol.Polynomial_protocol_sig) :
  Plookup_gate_sig with module PP = PP =
  Plookup_gate_impl (PP)
