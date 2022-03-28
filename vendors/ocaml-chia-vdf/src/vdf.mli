val form_size_bytes : int

type discriminant

type challenge = Bytes.t

type difficulty = Unsigned.UInt64.t

type proof

type result

(** [generate_discriminant ?seed size] *)
val generate_discriminant : ?seed:Bytes.t -> int -> discriminant

(** [prove_vdf discriminant challenge difficulty] *)
val prove_vdf : discriminant -> challenge -> difficulty -> result * proof

(** [verify_vdf discriminant challenge difficulty result proof] *)
val verify_vdf :
  discriminant -> challenge -> difficulty -> result -> proof -> bool
