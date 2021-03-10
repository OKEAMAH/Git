open Client_entrypoint

let versions = Protocol_hash.Table.create 1

let get_versions () = Protocol_hash.Table.to_seq versions

type network = [`Mainnet | `Testnet]

type entry = Client_context.full Client_entrypoint.entry

exception Version_not_found

exception No_such_entrypoint

let register name entrypoints =
  let previous =
    Option.value ~default:(fun (_network : network option) ->
        ([] : entry list))
    @@ Protocol_hash.Table.find versions name
  in
  Protocol_hash.Table.replace versions name (fun (network : network option) ->
      entrypoints network @ previous network)

let entrypoints_for_version version =
  WithExceptions.Option.to_exn ~none:Version_not_found
  @@ Protocol_hash.Table.find versions version

let entrypoints () : entry list =
  [ entrypoint
      ~path:"helpers.compute-chain-id"
      ~desc:"Computes the chain-id."
      ~input:string
      ~output:string
      ~cases:[]
      (fun seed_str (_ : Client_context.full) ->
        let chain_id =
          Tezos_crypto.Chain_id.hash_bytes [Bytes.of_string seed_str]
        in
        return_ok @@ Format.asprintf "%a" Tezos_crypto.Chain_id.pp chain_id) ]

let entrypoints = entrypoints () @ Client_keys_entrypoints.entrypoints ()

let apply_entry entry input cctxt =
  match entry with
  | Entry {input_enc; output_enc; f; conv; _} -> (
      let input = Json.destruct input_enc input in
      f input (conv cctxt)
      >>= function
      | Ok' res ->
          Lwt.return @@ construct_ok output_enc res
      | OkErr err ->
          Lwt.return @@ construct_error Error_monad.error_encoding err.error )
  | EntryPassword {input_enc; output_enc; f; conv; _} -> (
      let input = Json.destruct input_enc input in
      f input (conv cctxt)
      >>= function
      | Ok' res ->
          Lwt.return @@ construct_ok output_enc res
      | OkErr err ->
          Lwt.return @@ construct_error Error_monad.error_encoding err.error )

let call_method req_path value cctxt _version _network =
  (* let proto_entries =
    match version with
    | None ->
        []
    | Some v ->
        entrypoints_for_version v network
  in *)
  let entrypoints = entrypoints in
  (* let entrypoints = entrypoints @ Client_keys_entrypoints.entrypoints () in *)
  (* let entrypoints = entrypoints @ proto_entries in *)
  let find_f = function
    | Entry {path; _} ->
        path = req_path
    | EntryPassword {path; _} ->
        path = req_path
  in
  match List.find find_f entrypoints with
  | Some entry ->
      apply_entry entry value cctxt
  | None ->
      raise No_such_entrypoint
