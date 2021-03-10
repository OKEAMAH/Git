type error += UnknownSignatureAlgorithm of string

let _ =
  register_error_kind
    `Permanent
    ~id:"unknown.sig.algorithm"
    ~title:"Unknown Signature Algorithm"
    ~description:"Specified algorithm is unknown."
    ~pp:(fun ppf algo ->
      Format.fprintf
        ppf
        "Unknown signature algorithm (%s). Available: 'ed25519', 'secp256k1' \
         or 'p256'"
        algo)
    Data_encoding.(obj1 (req "algo" string))
    (function UnknownSignatureAlgorithm algo -> Some algo | _ -> None)
    (fun algo -> UnknownSignatureAlgorithm algo)

let algo name =
  match name with
  | "ed25519" ->
      return Signature.Ed25519
  | "secp256k1" ->
      return Signature.Secp256k1
  | "p256" ->
      return Signature.P256
  | name ->
      fail @@ UnknownSignatureAlgorithm name
