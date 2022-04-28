let srs_root = Option.value (Sys.getenv_opt "SRS_DIR") ~default:"."

let srs_path srs = srs_root ^ "/" ^ srs

let rec repeat n f =
  if n < 0 then ()
  else (
    f () ;
    repeat (n - 1) f)

let must_fail f =
  let exception Local in
  try
    (try f () with _ -> raise Local) ;
    assert false
  with
  | Local -> ()
  | _ -> assert false

let time description f =
  let start = Unix.gettimeofday () in
  let res = f () in
  let stop = Unix.gettimeofday () in
  let time = Float.to_string ((stop -. start) *. 1_000.) in
  Printf.printf "Time %s: %s ms\n%!" description time ;
  res

module Make (Main : Plonk.Main_protocol.Main_protocol_sig) = struct
  open Plonk.Circuit

  (* generator must be n-th root of unity
     n must be in the form 2^i
     for k number of gates
     a_c, b_c, c_c, ql, qr, qo, qm, qc must be lists of length k
     x is an array of length m = 3+2(k-1)
     l between 0 and m-1, l first parameters will be taken as public inputs
     n = k+l
     valid_proof is true if the proof is expected valid, false if it must fail
     if verbose print run times when valid_proof is true
  *)
  let test_circuit ?(zero_knowledge = true) ?(valid_proof = true)
      ?(proof_exception = false) ?(lookup_exception = false) ?(verbose = false)
      ~nb_proofs circuit private_inputs srsfile =
    let time_if_verbose verbose description f =
      if verbose then time description f else f ()
    in
    let public_inputs = Array.sub private_inputs 0 circuit.public_input_size in
    let inputs = Main.{witness = private_inputs; public = public_inputs} in

    let ((pp_prover, pp_verifier), transcript) =
      time_if_verbose verbose "setup" (fun () ->
          Main.setup ~zero_knowledge circuit ~srsfile ~nb_proofs)
    in
    if valid_proof then
      let (proof, _transcript) =
        time_if_verbose verbose "prove" (fun () ->
            Main.prove ~zero_knowledge (pp_prover, transcript) ~inputs)
      in
      let v =
        time_if_verbose verbose "verify" (fun () ->
            Main.verify (pp_verifier, transcript) ~public_inputs proof)
      in
      assert v
    else
      assert (
        try
          let (proof, _) =
            Main.prove (pp_prover, transcript) ~zero_knowledge ~inputs
          in
          not (Main.verify (pp_verifier, transcript) ~public_inputs proof)
        with
        | Main.Rest_not_null _ ->
            if proof_exception then true
            else raise (Invalid_argument "Proving error: incorrect witness")
        | Main.Entry_not_in_table _ ->
            if lookup_exception then true
            else raise (Invalid_argument "Proving error: incorrect lookup")
        | _ -> raise (Invalid_argument "Proving error: unknown error"))

  let test_circuits ?(zero_knowledge = true) ?(valid_proof = true)
      ?(proof_exception = false) ?(lookup_exception = false) ?(verbose = false)
      circuit_map private_inputs srsfile =
    let time_if_verbose verbose description f =
      if verbose then time description f else f ()
    in
    let inputs =
      let get_pi pi_size =
        List.map (fun witness ->
            let public = Array.sub witness 0 pi_size in
            Main.{witness; public})
      in
      try
        Main.SMap.mapi
          (fun c_name witness ->
            get_pi
              (fst (Main.SMap.find c_name circuit_map)).public_input_size
              witness)
          private_inputs
      with _ ->
        failwith
          "Helpers.test_circuits : circuit_map must contain private_inputs' \
           keys."
    in
    let public_inputs =
      Main.SMap.map (List.map (fun i -> Main.(i.public))) inputs
    in
    let ((pp_prover, pp_verifier), transcript) =
      time_if_verbose verbose "setup" (fun () ->
          Main.setup_multi_circuits ~zero_knowledge circuit_map ~srsfile)
    in
    if valid_proof then
      let (proof, _transcript) =
        time_if_verbose verbose "prove" (fun () ->
            Main.prove_multi_circuits
              ~zero_knowledge
              (pp_prover, transcript)
              ~inputs)
      in

      let v =
        time_if_verbose verbose "verify" (fun () ->
            Main.verify_multi_circuits
              (pp_verifier, transcript)
              ~public_inputs
              proof)
      in
      assert v
    else
      assert (
        try
          let (proof, _) =
            Main.prove_multi_circuits
              (pp_prover, transcript)
              ~zero_knowledge
              ~inputs
          in
          not
            (Main.verify_multi_circuits
               (pp_verifier, transcript)
               ~public_inputs
               proof)
        with
        | Main.Rest_not_null _ ->
            if proof_exception then true
            else raise (Invalid_argument "Proving error: incorrect witness")
        | Main.Entry_not_in_table _ ->
            if lookup_exception then true
            else raise (Invalid_argument "Proving error: incorrect lookup")
        | _ -> raise (Invalid_argument "Proving error: unknown error"))
end
