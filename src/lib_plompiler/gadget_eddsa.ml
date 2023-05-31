module Make
    (Curve : Mec.CurveSig.AffineEdwardsT) (H : sig
      module P : Hash_sig.P_HASH

      module V : Hash_sig.HASH
    end) =
(* : Signature.S *)
struct
  module Curve = Curve
  open Lang_core

  module P = struct
    module H = H.P

    (* S.t and Curve.t are the same but Curve.t is abstract *)
    let to_bls_scalar s = S.of_z (Curve.Base.to_z s)

    type sk = Curve.Scalar.t

    type pk = Curve.t

    type signature = {r : Curve.t; s : bool list}

    type msg = S.t

    type sign_parameters = sk * pk

    let neuterize sk = Curve.mul Curve.one sk

    let bls_scalar_to_curve_scalar s = Curve.Scalar.of_z (S.to_z s)

    (* TODO changer nb_bits_base *)
    let nb_bits_base = Z.numbits S.order
    (* /!\ hash output are scalar to respect the hash signature *)

    let sign ?(compressed = false) sk msg =
      ignore compressed ;
      let s, pk, prefix =
        let h =
          let sk = Curve.Scalar.to_z sk |> S.of_z in
          H.direct ~input_length:1 [|sk|] |> S.to_bytes
        in
        let h2 = Bytes.length h / 2 in
        let s = Curve.Scalar.of_bytes_exn (Bytes.sub h 0 h2) in
        let pk = neuterize s in
        let prefix = Bytes.sub h h2 h2 |> S.of_bytes_exn in
        (s, pk, prefix)
      in
      let r = H.direct [|prefix; msg|] |> bls_scalar_to_curve_scalar in
      let rg = Curve.mul Curve.one r in
      let k =
        let ur = Curve.get_u_coordinate rg |> to_bls_scalar in
        let vr = Curve.get_v_coordinate rg |> to_bls_scalar in
        let upk = Curve.get_u_coordinate pk |> to_bls_scalar in
        let vpk = Curve.get_v_coordinate pk |> to_bls_scalar in
        H.direct [|ur; vr; upk; vpk; msg|]
      in
      Printf.printf "\nk = %s" (S.string_of_scalar k) ;
      let k = k |> bls_scalar_to_curve_scalar in
      Printf.printf
        "\nk = %s"
        (S.string_of_scalar (Curve.Scalar.to_z k |> S.of_z)) ;
      let s =
        Curve.Scalar.(r + (k * s))
        |> Curve.Scalar.to_z
        |> Utils.bool_list_of_z ~nb_bits:nb_bits_base
      in
      (pk, {r = rg; s})

    (* todo do we need to multiply by cofactor ? *)
    (* The fact that s < l is enforced by the fact that s is a Curve.Scalar.t ; the fact that pk & r are on curve is enforced by the fact they are Curve.t *)
    let verify ?(compressed = false) ~msg ~pk ~signature () =
      ignore compressed ;
      ignore msg ;
      let k =
        let ur = Curve.get_u_coordinate signature.r |> to_bls_scalar in
        let vr = Curve.get_v_coordinate signature.r |> to_bls_scalar in
        let upk = Curve.get_u_coordinate pk |> to_bls_scalar in
        let vpk = Curve.get_v_coordinate pk |> to_bls_scalar in
        H.direct ~input_length:5 [|ur; vr; upk; vpk; msg|]
        |> bls_scalar_to_curve_scalar
      in
      let s = Curve.Scalar.of_z @@ Utils.bool_list_to_z signature.s in
      Curve.(eq (mul Curve.one s) (add signature.r (mul pk k)))
  end

  open Lang_stdlib
  open Gadget_edwards

  module V (L : LIB) = struct
    open L
    include MakeAffine (Curve) (L)

    open H.V (L)

    type pk = point

    type signature = {r : point repr; s : bool list repr}

    module Encoding = struct
      open Encoding.Encodings (L)

      type sig_encoding = (P.signature, signature, pk * bool list) encoding

      let point_encoding =
        let curve_base_to_s c = Lang_core.S.of_z @@ Curve.Base.to_z c in
        let curve_base_of_s c = Curve.Base.of_z @@ Lang_core.S.to_z c in
        with_implicit_bool_check is_on_curve
        @@ conv
             (fun r -> of_pair r)
             (fun (u, v) -> pair u v)
             (fun c ->
               ( curve_base_to_s @@ Curve.get_u_coordinate c,
                 curve_base_to_s @@ Curve.get_v_coordinate c ))
             (fun (u, v) ->
               Curve.from_coordinates_exn
                 ~u:(curve_base_of_s u)
                 ~v:(curve_base_of_s v))
             (obj2_encoding scalar_encoding scalar_encoding)

      let pk_encoding = point_encoding

      let signature_encoding =
        conv
          (fun {r; s} -> (r, s))
          (fun (r, s) -> {r; s})
          (fun ({r; s} : P.signature) -> (r, s))
          (fun (r, s) -> {r; s})
          (obj2_encoding point_encoding (atomic_list_encoding bool_encoding))
    end

    (* TODO: now msg is just one scalar, it will probably be a list of scalars *)
    (* assert s < Curve.Scalar.order *)
    (* reduce h modulo Curve.Scalar.order *)
    let verify ?(compressed = false) ~g ~msg ~pk ~signature () =
      ignore compressed ;
      with_label ~label:"EdDSA.verify"
      @@
      let {r; s} = signature in

      let* r_on_curve = is_on_curve r in
      let* pk_on_curve = is_on_curve pk in

      let* h =
        with_label ~label:"EdDSA.hash"
        @@
        let sig_r_u = get_u_coordinate r in
        let sig_r_v = get_v_coordinate r in
        let pk_u = get_u_coordinate pk in
        let pk_v = get_v_coordinate pk in
        digest @@ to_list [sig_r_u; sig_r_v; pk_u; pk_v; msg]
      in
      (* TODO how many bits ? *)
      let* h = bits_of_scalar ~nb_bits:(Z.numbits Curve.Scalar.order) h in
      with_label ~label:"Mul curve"
      (* It would be better to compute R = sg - h Pk using multiexp *)
      @@ let* sg = scalar_mul s g in
         let* hpk = scalar_mul h pk in
         let* rhpk = add r hpk in

         with_label ~label:"Checks" @@ Bool.assert_true r_on_curve
         >* Bool.assert_true pk_on_curve
         >* equal sg rhpk
  end
end
