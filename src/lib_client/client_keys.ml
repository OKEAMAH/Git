open Tezos_client_base.Client_keys

type error += ExistingKey of string

let () =
  register_error_kind
    `Temporary
    ~id:"existing.key"
    ~title:"Existing key"
    ~description:"secret or public key present for the targeted key"
    ~pp:(fun ppf name ->
      Format.fprintf
        ppf
        "secret or public key present for %s, use --force to delete"
        name)
    Data_encoding.(obj1 (req "key" string))
    (function ExistingKey name -> Some name | _ -> None)
    (fun name -> ExistingKey name)

let generate_encrypted_keys force algo name cctxt password =
  Secret_key.of_fresh cctxt force name
  >>=? fun name ->
  let (pkh, pk, sk) = Signature.generate_key ~algo () in
  Tezos_signer_backends.Unencrypted.make_pk pk
  >>=? fun pk_uri ->
  Tezos_signer_backends.Encrypted.encrypt sk password
  >>=? fun sk_uri -> register_key cctxt ~force (pkh, pk_uri, sk_uri) name

let forget_key force name cctxt =
  Secret_key.mem cctxt name
  >>=? fun has_secret_key ->
  Public_key.mem cctxt name
  >>=? fun has_public_key ->
  fail_when
    ((not force) && (has_secret_key || has_public_key))
    (ExistingKey name)
  >>=? fun () ->
  Secret_key.del cctxt name
  >>=? fun () ->
  Public_key.del cctxt name >>=? fun () -> Public_key_hash.del cctxt name

let forget_all_keys cctxt =
  Public_key.set cctxt []
  >>=? fun () ->
  Secret_key.set cctxt [] >>=? fun () -> Public_key_hash.set cctxt []

let generate_nonce ~name ~data cctxt =
  let data = Bytes.of_string data in
  Secret_key.mem cctxt name
  >>=? fun sk_present ->
  fail_unless sk_present (failure "secret key not present for %s" name)
  >>=? fun () ->
  Secret_key.find cctxt name
  >>=? fun sk_uri -> deterministic_nonce_hash sk_uri data

let generate_nonce_hash ~name ~data cctxt =
  let data = Bytes.of_string data in
  Secret_key.mem cctxt name
  >>=? fun sk_present ->
  fail_unless sk_present (failure "secret key not present for %s" name)
  >>=? fun () ->
  Secret_key.find cctxt name
  >>=? fun sk_uri -> deterministic_nonce_hash sk_uri data

let get_keys name cctxt =
  alias_keys cctxt name
  >>=? fun key_info ->
  match key_info with
  | None ->
      return None
  | Some (pkh, pk, skloc) ->
      ( match skloc with
      | None ->
          return None
      | Some sk ->
          Secret_key.to_source sk >>=? fun sk -> return @@ Some sk )
      >>=? fun sk -> return @@ Some (pkh, pk, sk)

let import_from_mnemonics ~encrypt ~force fail_if_already_registered name
    passphrase secret cctxt =
  let sk = Bip39.to_seed ~passphrase secret in
  let sk = Bytes.sub sk 0 32 in
  let sk : Signature.Secret_key.t =
    Ed25519 (Data_encoding.Binary.of_bytes_exn Ed25519.Secret_key.encoding sk)
  in
  Tezos_signer_backends.Unencrypted.make_sk sk
  >>=? fun unencrypted_sk_uri ->
  ( match encrypt with
  | true ->
      Tezos_signer_backends.Encrypted.read_password cctxt
      >>=? fun password -> Tezos_signer_backends.Encrypted.encrypt sk password
  | false ->
      return unencrypted_sk_uri )
  >>=? fun sk_uri ->
  neuterize unencrypted_sk_uri
  >>=? fun pk_uri ->
  fail_if_already_registered cctxt force pk_uri name
  >>=? fun () ->
  import_secret_key ~io:(cctxt :> Client_context.io_wallet) pk_uri
  >>=? fun (pkh, public_key) ->
  register_key cctxt ~force (pkh, pk_uri, sk_uri) ?public_key name
  >>=? fun () ->
  cctxt#message "Tezos address added: %a" Signature.Public_key_hash.pp pkh
  >>= fun () -> return_unit

let import_secret_key fail_if_already_registered force name sk_uri cctxt =
  Secret_key.of_fresh cctxt force name
  >>=? fun name ->
  neuterize sk_uri
  >>=? fun pk_uri ->
  fail_if_already_registered cctxt force pk_uri name
  >>=? fun () ->
  import_secret_key ~io:(cctxt :> Client_context.io_wallet) pk_uri
  >>=? fun (pkh, public_key) ->
  cctxt#message "Tezos address added: %a" Signature.Public_key_hash.pp pkh
  >>= fun () ->
  register_key cctxt ~force (pkh, pk_uri, sk_uri) ?public_key name
