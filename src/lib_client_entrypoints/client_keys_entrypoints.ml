open Client_entrypoint

(* Transforms a tzresult into an entry_result.
    A tzresult is needed as each entrypoint documents
    exactly which errors it can return. In order to do that,
    the message of some generic errors needs to be parsed.
    `string_errors`, the first parameter, is an association list.
    The first element is the string that needs to match, and the second
    is the function that transforms the message into the correct error type.
    The second argument - `retval` - is the tzerror value returned by the entrypoint. *)
(* let wrap string_errors retval =
    match retval with
    | Ok v ->
        return_ok v
    | Error (Exn (Failure msg) :: _) -> (
        List.fold_left
          (fun err (str, to_error) ->
            match err with
            | Some _ ->
                err
            | None ->
                if contains ~str ~into:msg then Some (to_error msg) else None)
          None
          string_errors
        |> function
        | None ->
            print_endline "Generic error" ;
            return_err @@ `GenericError msg
        | Some err ->
            return_err err )
    | Error (err :: _) -> (
        let info = Error_monad.find_info_of_error err in
        match info.id with
        | "alias.already.exists" ->
            (* let schema = Data_encoding.Json.construct Data_encoding.Json. in *)
            return_err @@ `GenericError "Alias already exists."
        | _ ->
            return_err @@ `GenericError "UnhandledError." )
    | _ ->
        return_err @@ `GenericError "UnhandledError." *)

let gen_keys_encoding =
  obj4
    (dft "force" bool false)
    (req "algo" string)
    (req "name" string)
    (req "password" string)

let force_switch = opt "force" bool

let generic_error = (`GenericError, "generic.error")

let unknown_sig_algorithm =
  (`UnknownSignatureAlgorithm, "unknown.sig.algorithm")

let pk_uri_scheme_needed = (`PkUriSchemeNeeded, "pk.uri.scheme.needed")

let sk_uri_scheme_needed = (`SkUriSchemeNeeded, "sk.uri.scheme.needed")

let aliased_as_another = (`AliasedAsAnother, "aliased.as.another")

let alias_already_exists = (`AliasAlreadyExists, "alias.already.exists")

let existing_key = (`ExistingKey, "existing.key")

let fresh_name_errors = [aliased_as_another; alias_already_exists]

let gen_keys_errors =
  fresh_name_errors
  @ [ generic_error;
      unknown_sig_algorithm
      (* pk_uri_scheme_needed; *)
      (* sk_uri_scheme_needed; *)
     ]

let list_known_addresses_errors = [generic_error]

let rename_aliases_errors = generic_error :: fresh_name_errors

let add_address_errors = generic_error :: fresh_name_errors

let forget_address_errors = [generic_error; existing_key]

let current_level_errors = [generic_error]

let import_keys_from_mnemonics_errors = generic_error :: fresh_name_errors

let import_secret_key_errors = generic_error :: fresh_name_errors

let fail_if_already_registered cctxt force pk_uri name =
  Tezos_client_base.Client_keys.Public_key.find_opt cctxt name
  >>=? function
  | None ->
      return_unit
  | Some (pk_uri_found, _) ->
      fail_unless
        (pk_uri = pk_uri_found || force)
        (failure
           "public and secret keys '%s' don't correspond, please don't use \
            --force"
           name)

let entrypoints () =
  [ entrypoint
      ~desc:"Return the current level."
      ~path:"current-level"
      ~cases:current_level_errors
      ~input:unit
      ~output:int32
      (fun () cctxt ->
        Block_services.Empty.Header.shell_header cctxt ()
        >>=? (fun b -> Tezos_base.Block_header.(return b.level))
        >>= wrap current_level_errors);
    entrypoint
      ~path:"gen-keys"
      ~desc:"Generate a pair of keys."
      ~input:gen_keys_encoding
      ~output:unit (* wallet#load and wallet#write not handled *)
      ~cases:gen_keys_errors
      (fun (force, algo, name, password) cctxt ->
        Parsers.algo algo
        >>=? (fun algo ->
               Tezos_client_base.Client_keys.Secret_key.fresh name
               >>=? fun name ->
               let password = Bytes.of_string password in
               Tezos_client_mid.Client_keys.generate_encrypted_keys
                 force
                 algo
                 name
                 cctxt
                 password)
        >>= wrap gen_keys_errors);
    entrypoint
      ~path:"list-known-addresses"
      ~desc:"List all addresses and associated keys."
      ~input:unit
      ~cases:list_known_addresses_errors
      ~output:
        (list
           (obj4
              (req "alias" string)
              (req "pkh" Signature.Public_key_hash.encoding)
              (opt "sk_known" bool)
              (opt "pk_known" bool)))
      (fun () cctxt ->
        Tezos_client_base.Client_keys.list_keys cctxt
        >>=? (fun l ->
               List.map_es
                 (fun (name, pkh, pk, sk) ->
                   let sk_known = Option.map (fun _ -> true) sk in
                   let pk_known = Option.map (fun _ -> true) pk in
                   return (name, pkh, sk_known, pk_known))
                 l)
        >>= wrap list_known_addresses_errors);
    entrypoint
      ~desc:
        {| Rename all aliases with the given old name in public keys, secret keys
         and public_key_hashes |}
      ~path:"rename-aliases"
      ~input:(obj2 (req "old_name" string) (req "new_name" string))
      ~output:unit
      ~cases:rename_aliases_errors
      (fun (old, new_name) cctxt ->
        (let open Tezos_client_base.Client_keys in
        Public_key.fresh new_name
        >>=? fun fresh_pk ->
        Public_key.of_fresh cctxt false fresh_pk
        >>=? fun pk ->
        Public_key_hash.fresh new_name
        >>=? fun fresh_pkh ->
        Public_key_hash.of_fresh cctxt false fresh_pkh
        >>=? fun pkh ->
        Secret_key.fresh new_name
        >>=? fun fresh_sk ->
        Secret_key.of_fresh cctxt false fresh_sk
        >>=? fun sk ->
        Public_key.rename cctxt ~old pk
        >>=? fun () ->
        Secret_key.rename cctxt ~old sk
        >>=? fun () -> Public_key_hash.rename cctxt ~old pkh)
        >>= wrap rename_aliases_errors);
    entrypoint
      ~path:"add-address"
      ~desc:"Add an address to the wallet."
      ~input:(obj3 (req "alias" string) (req "pkh" string) force_switch)
      ~output:unit
      ~cases:add_address_errors
      (fun (alias, pkh, force) cctxt ->
        (let force = (function Some true -> true | _ -> false) force in
         let open Tezos_client_base.Client_keys in
         Public_key_hash.fresh alias
         >>=? fun name ->
         Lwt.return @@ Signature.Public_key_hash.of_b58check pkh
         >>=? fun hash ->
         Tezos_client_base.Client_keys.Public_key_hash.of_fresh
           cctxt
           force
           name
         >>=? fun name ->
         Tezos_client_base.Client_keys.Public_key_hash.add
           ~force
           cctxt
           name
           hash)
        >>= wrap add_address_errors);
    entrypoint
      ~path:"forget-address"
      ~desc:"Forget one address."
      ~input:(obj2 (req "force" bool) (req "name" string))
      ~output:unit
      ~cases:forget_address_errors
      (fun (force, name) cctxt ->
        Tezos_client_mid.Client_keys.forget_key force name cctxt
        >>= wrap forget_address_errors);
    entrypoint
      ~path:"import-keys-from-mnemonics"
      ~desc:"Import a pair of keys to the wallet from a mnemonic phrase."
      ~cases:import_keys_from_mnemonics_errors
      ~input:
        (obj4
           (req "name" string)
           (req "encrypt" bool)
           (req "mnemonics" string)
           force_switch)
      ~output:unit
      (fun (name, encrypt, mnemonics, force) cctxt ->
        (let open Tezos_client_base.Client_keys in
        let force = Option.value force ~default:false in
        Secret_key.fresh name
        >>=? fun name ->
        Secret_key.of_fresh cctxt force name
        >>=? fun name ->
        let mnemonics = String.trim mnemonics |> String.split_on_char ' ' in
        match Bip39.of_words mnemonics with
        | None ->
            failwith "mnemonic failure"
        | Some t ->
            (cctxt :> Client_context.full)#prompt_password
              "Enter your passphrase: "
            >>=? fun passphrase ->
            Tezos_client_mid.Client_keys.import_from_mnemonics
              ~encrypt
              ~force
              fail_if_already_registered
              name
              passphrase
              t
              cctxt)
        >>= wrap import_keys_from_mnemonics_errors);
    entrypoint
      ~path:"import-secret-key"
      ~desc:"Add a secret key to the wallet."
      ~cases:import_secret_key_errors
      ~input:(obj3 (req "name" string) (req "sk_uri" string) force_switch)
      ~output:unit
      (fun (name, sk_uri, force) cctxt ->
        (let force = Option.value force ~default:false in
         let open Tezos_client_base in
         Client_keys.Secret_key.fresh name
         >>=? fun name ->
         Client_keys.make_sk_uri @@ Uri.of_string sk_uri
         >>=? fun sk_uri ->
         Tezos_client_mid.Client_keys.import_secret_key
           fail_if_already_registered
           force
           name
           sk_uri
           cctxt)
        >>= wrap import_secret_key_errors);
    entrypoint
      ~path:"chain-id"
      ~desc:"get chain-id"
      ~input:unit
      ~output:string
      ~cases:([(`GenericError, "generic.error")] : [`GenericError] errs)
      (fun () (cctxt : Client_context.full) ->
        Chain_services.chain_id cctxt ()
        >>= (function
              | Ok (v : Chain_id.t) ->
                  Data_encoding.Json.construct Chain_id.encoding v
                  |> Data_encoding.Json.to_string |> return
              | Error e ->
                  print_endline
                  @@ Format.asprintf "%a" Error_monad.pp_print_error e ;
                  failwith "chain_id_test failed")
        >>= wrap []) ]

(* entrypoint
      ~path:"generate-nonce-hash"
      ~desc:"Compute deterministic nonce hash."
      ~input:(obj2 (req "alias" string) (req "data" string))
      ~output:string
      (fun (name, data) cctxt ->
        Tezos_client_mid.Client_keys.generate_nonce_hash ~name ~data cctxt
        >>=? fun nonce_hash ->
        return @@ Format.asprintf "%a" Hex.pp (Hex.of_bytes nonce_hash));
    entrypoint
      ~path:"generate-nonce"
      ~desc:"Compute deterministic nonce hash."
      ~input:(obj2 (req "alias" string) (req "data" string))
      ~output:string
      (fun (name, data) cctxt ->
        Tezos_client_mid.Client_keys.generate_nonce_hash ~name ~data cctxt
        >>=? fun nonce_hash ->
        return @@ Format.asprintf "%a" Hex.pp (Hex.of_bytes nonce_hash));
    entrypoint
      ~path:"forget-all-keys"
      ~desc:"Forget the entire wallet of keys."
      ~input:unit
      ~output:unit
      (fun () cctxt -> Tezos_client_mid.Client_keys.forget_all_keys cctxt);
    entrypoint
      ~path:"show-address"
      ~desc:"Show the keys associated with an implicit account."
      ~input:(obj2 (opt "show_private" bool) (req "name" string))
      ~output:
        (obj3
           (req "pkh" Signature.Public_key_hash.encoding)
           (opt "pk" Signature.Public_key.encoding)
           (opt "sk" string))
      (fun (show_private, name) cctxt ->
        Tezos_client_mid.Client_keys.get_keys name cctxt
        >>=? function
        | None ->
            failwith "No keys found for address %s" name
        | Some (pkh, pk, sk) -> (
          match show_private with
          | None | Some false ->
              return (pkh, pk, None)
          | Some true ->
              return (pkh, pk, sk) ));
*)
