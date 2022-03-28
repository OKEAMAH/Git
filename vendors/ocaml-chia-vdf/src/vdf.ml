module Stubs = struct
  external create_discriminant : Bytes.t -> int -> int -> Bytes.t -> unit
    = "caml_create_discriminant_stubs"

  external prove :
    Bytes.t ->
    Unsigned.Size_t.t ->
    Bytes.t ->
    Unsigned.UInt64.t ->
    Bytes.t ->
    Bytes.t ->
    unit = "caml_prove_bytecode_stubs" "caml_prove_stubs"

  external verify :
    Bytes.t ->
    Unsigned.Size_t.t ->
    Bytes.t ->
    Bytes.t ->
    Bytes.t ->
    Unsigned.UInt64.t ->
    bool = "caml_verify_bytecode_stubs" "caml_verify_stubs"
end

module Integer = struct
  type t = Bytes.t
end

(* Serialisation of a type form. A quadratic form is a tuple (a, b, c) \in Z
   with the relation discriminant: D = b^2 - 4 a c/

   The form serialisation only uses parameters a and b as c can be recomputed
   with the discriminant. *)
module Form = struct
  type t = Bytes.t
end

module Vdf = struct
  (* Constraint from Chia's cpp code *)
  let form_size_bytes = 100

  type discriminant = Integer.t

  type challenge = Form.t

  type difficulty = Unsigned.UInt64.t

  type proof = Form.t

  type result = Form.t

  let generate_discriminant ?(seed = Bytes.empty) size_in_bytes =
    let result = Bytes.create size_in_bytes in
    Stubs.create_discriminant seed (Bytes.length seed) size_in_bytes result ;
    result

  let prove_vdf discriminant challenge difficulty =
    let discriminant_size =
      Unsigned.Size_t.of_int (Bytes.length discriminant)
    in
    let result = Bytes.create form_size_bytes in
    let proof = Bytes.create form_size_bytes in
    Stubs.prove discriminant discriminant_size challenge difficulty result proof ;
    (result, proof)

  let verify_vdf discriminant challenge difficulty result proof =
    let discriminant_size =
      Unsigned.Size_t.of_int (Bytes.length discriminant)
    in
    Stubs.verify
      discriminant
      discriminant_size
      challenge
      result
      proof
      difficulty
end

include Vdf
