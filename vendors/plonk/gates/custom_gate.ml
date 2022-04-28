module Custom_gate_impl (PP : Polynomial_protocol.Polynomial_protocol_sig) =
struct
  module PP = PP
  module MP = PP.MP
  module Scalar = PP.PC.Scalar
  module Domain = PP.PC.Polynomial.Domain
  module Poly = PP.PC.Polynomial.Polynomial
  module Evaluations = PP.Evaluations
  module MPoly = PP.MP.Polynomial
  module Fr_generation = PP.PC.Fr_generation

  let monomial_of_list = SMap.monomial_of_list

  let one = Scalar.one

  let minus_one = Scalar.negate one

  let x_poly = Poly.of_coefficients [(one, 1)]

  let left = "a"

  let right = "b"

  let output = "c"

  let next_left = "ag"

  let next_right = "bg"

  let next_output = "cg"

  let prefix_list prefix x = List.map (fun x -> prefix ^ x) x

  (* Block names to merge identities within, if identities are independent, use q_label instead.
     For instance, we want to have want AddLeft and Addright identities to be merged inside the Arithmetic block,
     we thus use "arith" as Map key for these gates identities.
     We also want to use the ECC point addition identity independently, as such we put ECCAdd gate's q_label as key. *)
  let arith = "Arith"

  module type Gate_base_sig = sig
    val q_label : string

    (* array.(i) = 1 <=> f is evaluated at (g^i)X *)
    val blinds : int array SMap.t

    val identity : string * int

    val equations :
      q:PP.PC.Scalar.t ->
      a:PP.PC.Scalar.t ->
      b:PP.PC.Scalar.t ->
      c:PP.PC.Scalar.t ->
      ag:PP.PC.Scalar.t ->
      bg:PP.PC.Scalar.t ->
      cg:PP.PC.Scalar.t ->
      ?table:PP.PC.Scalar.t array array ->
      unit ->
      PP.PC.Scalar.t list

    val prover_query :
      prefix:string ->
      public_inputs:PP.PC.Scalar.t array ->
      domain:PP.PC.Polynomial.Domain.t ->
      evaluations:Evaluations.t SMap.t ->
      PP.prover_query

    val verifier_query :
      prefix:string ->
      generator:PP.PC.Scalar.t ->
      size_domain:int ->
      PP.verifier_query

    (* Give the size of the domain on which the identities
       of the gate need to have the evaluation of each of his polynomial
       divided by the size of the citcuit. *)
    val polynomials_degree : int SMap.t
  end

  module type Params = sig
    val wire : string

    val selector : string

    val is_next : bool
  end

  module AddWire_gate (Params : Params) : Gate_base_sig = struct
    let next_name = Params.wire ^ "g"

    let q_label = Params.selector

    let identity = (arith, 1)

    let equations ~q ~a ~b ~c ~ag ~bg ~cg ?table:_ () =
      let var =
        match Params.wire with
        | s when s = left -> if Params.is_next then ag else a
        | s when s = right -> if Params.is_next then bg else b
        | s when s = output -> if Params.is_next then cg else c
        | _ -> assert false
      in
      Scalar.[q * var]

    let blinds =
      let array = if Params.is_next then [|0; 1|] else [|1; 0|] in
      SMap.singleton Params.wire array

    let identities prefix =
      let wire_name = if Params.is_next then next_name else Params.wire in
      SMap.singleton
        (prefix ^ arith ^ ".0")
        (MP.Polynomial.of_list
           [(monomial_of_list (prefix_list prefix [q_label; wire_name]), one)])

    let v_map ~prefix generator =
      if Params.is_next then
        let g_poly = Poly.of_coefficients [(generator, 1)] in
        SMap.singleton (prefix ^ next_name) (prefix ^ Params.wire, g_poly)
      else SMap.empty

    let prover_query ~prefix ~public_inputs:_ ~domain ~evaluations =
      let qf =
        let poly_names = [q_label; Params.wire] in
        let composition_gx =
          if Params.is_next then ([0; 1], Domain.length domain) else ([0; 0], 1)
        in

        Evaluations.mul ~evaluations ~poly_names ~composition_gx ()
      in
      let precomputed_polys = SMap.singleton (arith ^ ".0") qf in
      PP.{v_map = v_map ~prefix (Domain.get domain 1); precomputed_polys}

    let verifier_query ~prefix ~generator ~size_domain:_ =
      let v_map = v_map ~prefix generator in
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree = SMap.of_list [(Params.wire, 2); (q_label, 2)]
  end

  module AddOutput_gate = AddWire_gate (struct
    let wire = output

    let selector = "qo"

    let is_next = false
  end)

  module AddLeft_gate = AddWire_gate (struct
    let wire = left

    let selector = "ql"

    let is_next = false
  end)

  module AddRight_gate = AddWire_gate (struct
    let wire = right

    let selector = "qr"

    let is_next = false
  end)

  module AddNextOutput_gate = AddWire_gate (struct
    let wire = output

    let selector = "qog"

    let is_next = true
  end)

  module AddNextLeft_gate = AddWire_gate (struct
    let wire = left

    let selector = "qlg"

    let is_next = true
  end)

  module AddNextRight_gate = AddWire_gate (struct
    let wire = right

    let selector = "qrg"

    let is_next = true
  end)

  module Constant_gate : Gate_base_sig = struct
    let q_label = "qc"

    let blinds = SMap.empty

    let identity = (arith, 1)

    let equations ~q ~a:_ ~b:_ ~c:_ ~ag:_ ~bg:_ ~cg:_ ?table:_ () = [q]

    let identities prefix =
      SMap.singleton
        (prefix ^ arith ^ ".0")
        (MP.Polynomial.of_list [(monomial_of_list [prefix ^ q_label], one)])

    let v_map = SMap.empty

    let prover_query ~prefix:_ ~public_inputs:_ ~domain:_ ~evaluations =
      PP.
        {
          v_map;
          precomputed_polys =
            SMap.singleton (arith ^ ".0") (SMap.find q_label evaluations);
        }

    let verifier_query ~prefix ~generator:_ ~size_domain:_ =
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree = SMap.empty
  end

  module Multiplication_gate : Gate_base_sig = struct
    let q_label = "qm"

    let identity = (arith, 1)

    let equations ~q ~a ~b ~c:_ ~ag:_ ~bg:_ ~cg:_ ?table:_ () =
      Scalar.[q * a * b]

    let blinds = SMap.of_list [(right, [|1; 0|]); (left, [|1; 0|])]

    let identities prefix =
      SMap.singleton
        (prefix ^ arith ^ ".0")
        (MP.Polynomial.of_list
           [(monomial_of_list (prefix_list prefix [q_label; left; right]), one)])

    let v_map = SMap.empty

    let prover_query ~prefix:_ ~public_inputs:_ ~domain:_ ~evaluations =
      let qmflfr =
        Evaluations.mul ~evaluations ~poly_names:[q_label; left; right] ()
      in
      let precomputed_polys = SMap.singleton (arith ^ ".0") qmflfr in
      PP.{v_map; precomputed_polys}

    let verifier_query ~prefix ~generator:_ ~size_domain:_ =
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree = SMap.of_list [(left, 3); (right, 3); (q_label, 3)]
  end

  module AddWeierstrass_gate : Gate_base_sig = struct
    let q_label = "qecc_ws_add"

    let blinds =
      SMap.of_list [(right, [|1; 1|]); (left, [|1; 1|]); (output, [|1; 1|])]

    let identity = (q_label, 2)

    let equations ~q ~a ~b ~c ~ag ~bg ~cg ?table:_ () =
      if Scalar.is_zero q then Scalar.[zero; zero]
      else
        let lambda = Scalar.(div_exn (bg + negate ag) (b + negate a)) in
        let x = Scalar.((lambda * lambda) + negate a + negate b) in
        let y = Scalar.((lambda * (a + negate x)) + negate ag) in
        Scalar.[x + negate c; y + negate cg]

    (* Let P = (x_p; y_p), Q = (x_q; y_q), R = (x_r; y_r) such that P + Q = R.
       We thus have the following identities:
         lambda = (y_q - y_p) / (x_q - x_p)
         x_r = lambda^2 - x_p - x_q
         y_r = lambda * (x_p - x_r) - y_p
       We put in the wires a, b and c the point coordinates in the following order:
                     a     b     c
       wire #i:    x_p   x_q   x_r
       wire #i+1:  y_p   y_q   y_r
    *)

    let identities prefix =
      let q_label = prefix ^ q_label in
      let left = prefix ^ left in
      let right = prefix ^ right in
      let output = prefix ^ output in
      let next_left = prefix ^ next_left in
      let next_right = prefix ^ next_right in
      let next_output = prefix ^ next_output in
      let q_poly = MP.Polynomial.of_list [(monomial_of_list [q_label], one)] in
      let num_lambda =
        MP.Polynomial.of_list
          [
            (monomial_of_list [next_right], one);
            (monomial_of_list [next_left], minus_one);
          ]
      in
      let denom_lambda =
        MP.Polynomial.of_list
          [
            (monomial_of_list [right], one); (monomial_of_list [left], minus_one);
          ]
      in
      (* identity on new point's x coordinate:
         [fo + fr + fl] [fr - fl]^2 - [frg - flg]^2 = 0
      *)
      let first_identity =
        let left_part =
          let sum_fi =
            MP.Polynomial.of_list
              [
                (monomial_of_list [output], one);
                (monomial_of_list [right], one);
                (monomial_of_list [left], one);
              ]
          in
          let denom_lambda2 = MPoly.mul denom_lambda denom_lambda in
          MPoly.mul sum_fi denom_lambda2
        in
        let right_part = MPoly.mul num_lambda num_lambda in
        let first = MPoly.sub left_part right_part in
        MPoly.mul q_poly first
      in
      (* identity on new point's y coordinate:
         [fog + flg] [fr - fl] - [frg - flg] [fl - fo] = 0
      *)
      let second_identity =
        let fog_p_flg =
          MP.Polynomial.of_list
            [
              (monomial_of_list [next_output], one);
              (monomial_of_list [next_left], one);
            ]
        in
        let left_part = MPoly.mul fog_p_flg denom_lambda in
        let fl_m_fo =
          MP.Polynomial.of_list
            [
              (monomial_of_list [left], one);
              (monomial_of_list [output], minus_one);
            ]
        in
        let right_part = MPoly.mul fl_m_fo num_lambda in
        let second = MPoly.sub left_part right_part in
        MPoly.mul q_poly second
      in
      SMap.of_list
        [(q_label ^ ".0", first_identity); (q_label ^ ".1", second_identity)]

    let v_map ~prefix generator =
      let g_poly = Poly.of_coefficients [(generator, 1)] in
      SMap.of_list
        [
          (prefix ^ next_left, (prefix ^ left, g_poly));
          (prefix ^ next_right, (prefix ^ right, g_poly));
          (prefix ^ next_output, (prefix ^ output, g_poly));
        ]

    let prover_query ~prefix ~public_inputs:_ ~domain ~evaluations =
      let g = Domain.get domain 1 in

      (* lambda:
         numerator =  [bg - ag] ;
         denominator = [b - a] *)
      (* identity on new point's x coordinate:
         [c + b + a] [b - a]^2 - [bg - ag]^2 = 0
      *)
      let domain_size = Domain.length domain in
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:[left; right; output]
          ~name_result:"a + b + c"
          ()
      in

      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:[right; left]
          ~linear_coeffs:[one; minus_one]
          ~name_result:"b - a"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["b - a"]
          ~powers:[2]
          ~name_result:"(b - a)^2"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["a + b + c"; "(b - a)^2"]
          ~name_result:"left_term"
          ()
      in
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:["left_term"; "(b - a)^2"]
          ~composition_gx:([0; 1], domain_size)
          ~linear_coeffs:[one; minus_one]
          ~name_result:"first_identity"
          ()
      in
      let first_identity =
        Evaluations.mul ~evaluations ~poly_names:[q_label; "first_identity"] ()
      in
      (* identity on new point's y coordinate:
         [cg + ag] [b - a] - [bg - ag] [a - c] = 0
      *)
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:[output; left]
          ~composition_gx:([1; 1], domain_size)
          ~name_result:"cg + ag"
          ()
      in
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:[left; output]
          ~linear_coeffs:[one; minus_one]
          ~name_result:"a - c"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["cg + ag"; "b - a"]
          ~name_result:"left_term_2"
          ()
      in

      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["b - a"; "a - c"]
          ~composition_gx:([1; 0], domain_size)
          ~name_result:"right_term_2"
          ()
      in

      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:["left_term_2"; "right_term_2"]
          ~linear_coeffs:[one; minus_one]
          ~name_result:"second_identity"
          ()
      in
      let second_identity =
        Evaluations.mul ~evaluations ~poly_names:[q_label; "second_identity"] ()
      in
      let precomputed_polys =
        SMap.of_list
          [(q_label ^ ".0", first_identity); (q_label ^ ".1", second_identity)]
      in
      PP.{v_map = v_map ~prefix g; precomputed_polys}

    let verifier_query ~prefix ~generator ~size_domain:_ =
      let v_map = v_map ~prefix generator in
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree =
      SMap.of_list [(left, 4); (right, 4); (output, 4); (q_label, 4)]
  end

  module AddEdwards_gate : Gate_base_sig = struct
    let q_label = "qecc_ed_add"

    let blinds =
      SMap.of_list [(right, [|1; 1|]); (left, [|1; 1|]); (output, [|1; 1|])]

    let identity = (q_label, 2)

    (* JubJub curve parameters *)
    let a = Scalar.(negate one)

    let d =
      Scalar.of_string
        "19257038036680949359750312669786877991949435402254120286184196891950884077233"

    let equations ~q ~a ~b ~c ~ag ~bg ~cg ?table:_ () =
      if Scalar.is_zero q then Scalar.[zero; zero]
      else
        let a_curve = Scalar.(negate one) in
        let xpyq = Scalar.(a * bg) in
        let xqyp = Scalar.(b * ag) in
        let ypyq = Scalar.(bg * ag) in
        let xpxq = Scalar.(b * a) in
        let xr = Scalar.((xpyq + xqyp) / (one + (d * xpyq * xqyp))) in
        let yr =
          Scalar.(
            (ypyq + (negate a_curve * xpxq)) / (one + (negate d * xpyq * xqyp)))
        in
        Scalar.[xr + negate c; yr + negate cg]

    (* Let P = (x_p; y_p), Q = (x_q; y_q), R = (x_r; y_r) such that P + Q = R.
        Let a et d the Edwards curve parameters. We thus have the following identities:
          x_r =     (x_p * y_q + x_q * y_p) / (1 + d * x_p * x_q * y_p * y_q)
          y_r = (y_p * y_q - a * x_p * x_q) / (1 - d * x_p * x_q * y_p * y_q)
        We put in the wires a, b and c the point coordinates in the following order:
                      a     b     c
        wire #i:    x_p   x_q   x_r
        wire #i+1:  y_p   y_q   y_r
       Assuming the points are on the curve, we do not need to check that the denominators,
       1 +/- d * x_p * y_p * x_q * y_q, are non-zero because the Edwards formulas are complete.
    *)
    let identities prefix =
      let q_label = prefix ^ q_label in
      let left = prefix ^ left in
      let right = prefix ^ right in
      let output = prefix ^ output in
      let next_left = prefix ^ next_left in
      let next_right = prefix ^ next_right in
      let next_output = prefix ^ next_output in
      let q_poly = MP.Polynomial.of_list [(monomial_of_list [q_label], one)] in
      let one_poly = MP.Polynomial.of_list [(MP.Monomial.one, one)] in
      let x1 = MP.Polynomial.singleton left in
      let y1 = MP.Polynomial.singleton next_left in
      let x2 = MP.Polynomial.singleton right in
      let y2 = MP.Polynomial.singleton next_right in
      let x3 = MP.Polynomial.singleton output in
      let y3 = MP.Polynomial.singleton next_output in
      let x1x2 = MPoly.mul x1 x2 in
      let y1y2 = MPoly.mul y1 y2 in
      let x1y2 = MPoly.mul x1 y2 in
      let x2y1 = MPoly.mul x2 y1 in
      let xys = MPoly.mul x1x2 y1y2 in
      let denom = MPoly.mul_scalar d xys in
      (* q * [x3 * (1 + Params_d*x1*x2*y1*y2) - (x1*y2 + y1*x2)]  = 0 *)
      let first_identity =
        let num = MPoly.add x1y2 x2y1 in
        let denom = MPoly.add one_poly denom in
        let x3_times_denom = MPoly.mul x3 denom in
        let first = MPoly.sub x3_times_denom num in
        MPoly.mul q_poly first
      in
      (* q * [y3 * (1 - Params_d*x1*x2*y1*y2) - (y1*y2 - Params_a*x1*x2)]  = 0 *)
      let second_identity =
        let tmp = MPoly.mul_scalar a x1x2 in
        let num = MPoly.sub y1y2 tmp in
        let denom = MPoly.sub one_poly denom in
        let y3_times_denom = MPoly.mul y3 denom in
        let second = MPoly.sub y3_times_denom num in
        MPoly.mul q_poly second
      in
      SMap.of_list
        [(q_label ^ ".0", first_identity); (q_label ^ ".1", second_identity)]

    let v_map ~prefix generator =
      let g_poly = Poly.of_coefficients [(generator, 1)] in
      SMap.of_list
        [
          (prefix ^ next_left, (prefix ^ left, g_poly));
          (prefix ^ next_right, (prefix ^ right, g_poly));
          (prefix ^ next_output, (prefix ^ output, g_poly));
        ]

    let prover_query ~prefix ~public_inputs:_ ~domain ~evaluations =
      let g = Domain.get domain 1 in
      let domain_size = Domain.length domain in
      (* identity on new point's x coordinate:
         q * [x3 * (1 + Params_d * x1 * x2 * y1 * y2) - (x1 * y2 + y1 * x2)]  = 0
         q * [c * (1 + Params_d * a * b * ag * bg) - (a * bg + b * ag)] = 0
      *)
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:[left; right]
          ~composition_gx:([0; 1], domain_size)
          ~name_result:"a * bg"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:[left; right]
          ~composition_gx:([1; 0], domain_size)
          ~name_result:"b * ag"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["a * bg"; "b * ag"]
          ~name_result:"a * b * ag * bg"
          ()
      in

      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:["a * b * ag * bg"]
          ~linear_coeffs:[d]
          ~add_constant:one
          ~name_result:"1 + Params_d * a * b * ag * bg"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["1 + Params_d * a * b * ag * bg"; output]
          ~name_result:"c * (1 + Params_d * a * b * ag * bg)"
          ()
      in

      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:["a * bg"; "b * ag"]
          ~name_result:"a * bg + b * ag"
          ()
      in
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:
            ["c * (1 + Params_d * a * b * ag * bg)"; "a * bg + b * ag"]
          ~linear_coeffs:[one; minus_one]
          ~name_result:"first_identity"
          ()
      in
      let first_identity =
        Evaluations.mul ~evaluations ~poly_names:[q_label; "first_identity"] ()
      in
      (* identity on new point's y coordinate:
         q * [y3 * (1 - Params_d * x1 * x2 * y1 * y2) - (y1 * y2 - Params_a * x1 * x2)]  = 0
         q * [cg * (1 - Params_d * a * b * ag * bg) - (ag * bg - Params_a * b * a)] = 0
      *)
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:["1 + Params_d * a * b * ag * bg"]
          ~linear_coeffs:[minus_one]
          ~add_constant:(Scalar.add one one)
          ~name_result:"1 - Params_d * a * b * ag * bg"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:["1 - Params_d * a * b * ag * bg"; output]
          ~composition_gx:([0; 1], domain_size)
          ~name_result:"cg * (1 - Params_d * a * b * ag * bg)"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:[left; right]
          ~composition_gx:([1; 1], domain_size)
          ~name_result:"ag * bg"
          ()
      in
      let evaluations =
        Evaluations.mul_update_map
          ~evaluations
          ~poly_names:[left; right]
          ~name_result:"b * a"
          ()
      in

      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:["ag * bg"; "b * a"]
          ~linear_coeffs:[one; Scalar.negate a]
          ~name_result:"ag * bg - Params_a * b * a"
          ()
      in
      let evaluations =
        Evaluations.linear_update_map
          ~evaluations
          ~poly_names:
            [
              "cg * (1 - Params_d * a * b * ag * bg)";
              "ag * bg - Params_a * b * a";
            ]
          ~linear_coeffs:[one; minus_one]
          ~name_result:"second_identity"
          ()
      in
      let second_identity =
        Evaluations.mul ~evaluations ~poly_names:[q_label; "second_identity"] ()
      in

      let precomputed_polys =
        SMap.of_list
          [(q_label ^ ".0", first_identity); (q_label ^ ".1", second_identity)]
      in
      PP.{v_map = v_map ~prefix g; precomputed_polys}

    let verifier_query ~prefix ~generator ~size_domain:_ =
      let v_map = v_map ~prefix generator in
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree =
      SMap.of_list [(left, 6); (right, 6); (output, 6); (q_label, 6)]
  end

  module Public_gate : Gate_base_sig = struct
    let q_label = "qpub"

    let identity = (arith, 1)

    let equations ~q:_ ~a:_ ~b:_ ~c:_ ~ag:_ ~bg:_ ~cg:_ ?table:_ () =
      Scalar.[zero]

    let blinds = SMap.empty

    let identities prefix =
      SMap.singleton
        (prefix ^ arith ^ ".0")
        (MP.Polynomial.of_list [(monomial_of_list [prefix ^ "PI"], one)])

    let v_map = SMap.empty

    let compute_PI public_inputs domain evaluations =
      let size_domain = Domain.length domain in
      if size_domain = 0 then Evaluations.zero
      else
        let l = Array.length public_inputs in
        let scalars =
          Array.(
            append public_inputs (init (size_domain - l) (fun _ -> Scalar.zero)))
        in
        let pi =
          Poly.(opposite (Evaluations.interpolation_fft2 domain scalars))
        in
        let domain = Evaluations.get_domain evaluations in
        Evaluations.evaluation_fft domain pi

    let prover_query ~prefix:_ ~public_inputs ~domain ~evaluations =
      let pi_poly = compute_PI public_inputs domain evaluations in
      PP.{v_map; precomputed_polys = SMap.singleton (arith ^ ".0") pi_poly}

    let verifier_query ~prefix ~generator:_ ~size_domain:_ =
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree = SMap.empty
  end

  module X5_gate : Gate_base_sig = struct
    let q_label = "qx5"

    let identity = (arith, 1)

    let equations ~q ~a ~b:_ ~c:_ ~ag:_ ~bg:_ ~cg:_ ?table:_ () =
      Scalar.[q * pow a (Z.of_int 5)]

    let blinds = SMap.singleton left [|1; 0|]

    let identities prefix =
      let q_poly =
        MP.Polynomial.of_list [(monomial_of_list [prefix ^ q_label], one)]
      in
      let fl_poly =
        MP.Polynomial.of_list [(monomial_of_list [prefix ^ left], one)]
      in
      let fl2_poly = MPoly.mul fl_poly fl_poly in
      let fl4_poly = MPoly.mul fl2_poly fl2_poly in
      let fl5_poly = MPoly.mul fl4_poly fl_poly in
      let poly = MPoly.mul q_poly fl5_poly in
      SMap.singleton (prefix ^ arith ^ ".0") poly

    let v_map = SMap.empty

    let prover_query ~prefix:_ ~public_inputs:_ ~domain:_ ~evaluations =
      let poly =
        Evaluations.mul
          ~evaluations
          ~poly_names:[q_label; left]
          ~powers:[1; 5]
          ()
      in
      let precomputed_polys = SMap.singleton (arith ^ ".0") poly in
      PP.{v_map; precomputed_polys}

    let verifier_query ~prefix ~generator:_ ~size_domain:_ =
      PP.{v_map; identities = identities prefix; not_committed = SMap.empty}

    let polynomials_degree = SMap.of_list [(left, 6); (q_label, 6)]
  end

  module Gate_aggregator : sig
    val aggregate_blinds : module_list:(module Gate_base_sig) list -> int SMap.t

    val aggregate_prover_queries :
      ?prefix:string ->
      module_list:(module Gate_base_sig) list ->
      public_inputs:Scalar.t array ->
      domain:PP.PC.Polynomial.Domain.t ->
      evaluations:Evaluations.t SMap.t ->
      unit ->
      PP.prover_query

    val aggregate_verifier_queries :
      ?prefix:string ->
      module_list:(module Gate_base_sig) list ->
      generator:PP.PC.Scalar.t ->
      size_domain:int ->
      unit ->
      PP.verifier_query

    val aggregate_polynomials_degree :
      module_list:(module Gate_base_sig) list -> int SMap.t

    val add_public_inputs :
      prefix:string ->
      public_inputs:Scalar.t array ->
      generator:PP.PC.Scalar.t ->
      size_domain:int ->
      PP.verifier_query ->
      PP.verifier_query
  end = struct
    let get_blinds m =
      let module M = (val m : Gate_base_sig) in
      M.blinds

    let get_prover_query m =
      let module M = (val m : Gate_base_sig) in
      M.prover_query

    let get_verifier_query m =
      let module M = (val m : Gate_base_sig) in
      M.verifier_query

    let get_polynomials_degree m =
      let module M = (val m : Gate_base_sig) in
      M.polynomials_degree

    let empty_prover_query =
      PP.{v_map = SMap.empty; precomputed_polys = SMap.empty}

    let empty_verifier_query =
      PP.
        {
          v_map = SMap.empty;
          identities = SMap.empty;
          not_committed = SMap.empty;
        }

    let aggregate_blinds ~module_list =
      let f_union _key a1 a2 =
        if Array.length a1 <> Array.length a2 then
          raise (Invalid_argument "All blinds arrays must have the same size.")
        else Some Array.(init (length a1) (fun i -> max a1.(i) a2.(i)))
      in
      let blinds_array =
        SMap.(
          List.fold_left
            (fun acc_blinds gate -> union f_union acc_blinds (get_blinds gate))
            empty
            module_list)
      in
      let sum_array a = Array.fold_left ( + ) 0 a in
      SMap.map sum_array blinds_array

    let aggregate_prover_queries ?(prefix = "") ~module_list ~public_inputs
        ~domain ~evaluations () =
      List.fold_left
        (fun accumulated_query gate ->
          PP.sum_prover_queries
            accumulated_query
            (get_prover_query gate ~prefix ~public_inputs ~domain ~evaluations))
        empty_prover_query
        module_list

    let aggregate_verifier_queries ?(prefix = "") ~module_list ~generator
        ~size_domain () =
      List.fold_left
        (fun accumulated_query gate ->
          PP.sum_verifier_queries
            accumulated_query
            ((get_verifier_query gate) ~prefix ~generator ~size_domain))
        empty_verifier_query
        module_list

    let aggregate_polynomials_degree ~module_list =
      List.fold_left
        (fun accumulated_map gate ->
          let map = get_polynomials_degree gate in
          SMap.union
            (fun _key value_1 value_2 -> Some (max value_1 value_2))
            accumulated_map
            map)
        SMap.empty
        module_list

    (* returns PI(x) *)
    let compute_PIx public_inputs generator n x_ni =
      if n = 0 then Scalar.zero
      else
        let g = Scalar.inverse_exn generator in
        let f (acc, gi) wi =
          let deno = Scalar.((gi * x_ni.(0)) + negate one) in
          (Scalar.(acc + (wi / deno)), Scalar.mul g gi)
        in
        let (res, _) = Array.fold_left f Scalar.(zero, one) public_inputs in
        let xn_min_1_div_n =
          Scalar.((x_ni.(1) + negate one) / Fr_generation.fr_of_int_safe n)
        in
        Scalar.(negate (mul xn_min_1_div_n res))

    (* Add a [not_committed] variant to represent compute_PIx *)
    type PP.not_committed +=
      | ComputePublic of Evaluations.scalar array * Evaluations.scalar * int

    let () =
      let inner =
        let open Encodings in
        Data_encoding.(tup3 (array fr_encoding) fr_encoding int31)
      in
      let from = function
        | ComputePublic (a, b, c) -> Some (a, b, c)
        | _ -> None
      in
      let to' (a, b, c) = ComputePublic (a, b, c) in
      (* NB: do not change tag, it will break the encoding *)
      PP.register_nc_eval_and_encoding
        (function
          | ComputePublic (public_inputs, generator, n) ->
              Some (compute_PIx public_inputs generator n)
          | _ -> None)
        ~title:"public"
        ~tag:0
        inner
        from
        to'

    let add_public_inputs ~prefix ~public_inputs ~generator ~size_domain query =
      PP.
        {
          query with
          not_committed =
            SMap.add_unique
              (prefix ^ "PI")
              (ComputePublic (public_inputs, generator, size_domain))
              query.not_committed;
        }
  end
end

module Custom_gate (PP : Polynomial_protocol.Polynomial_protocol_sig) =
  Custom_gate_impl (PP)
