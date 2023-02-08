module type RPC = sig
  val rpc_services :
    reveal_data_dir:string ->
    #Client_context.wallet ->
    Tezos_crypto.Aggregate_signature.public_key option list ->
    Client_keys.aggregate_sk_uri option list ->
    int ->
    unit Tezos_rpc.Directory.directory
end

module Make (P : Node_plugin.S) = struct
  module M = P.Reveal_hash_mapper

  let store_preimage_request_encoding =
    Data_encoding.(
      obj2
        (req "payload" Data_encoding.(bytes' Hex))
        (req "pagination_scheme" (string' Plain)))

  (* A variant of [Sc_rollup_reveal_hash.encoding] that prefers hex
     encoding over b58check encoding for JSON. *)
  let root_hash_encoding =
    let binary = M.encoding in
    Data_encoding.(
      splitted
        ~binary
        ~json:
          (conv_with_guard
             M.to_hex
             (fun str ->
               Result.of_option ~error:"Not a valid hash" (M.of_hex str))
             (string' Plain)))

  let store_preimage_response_encoding =
    Data_encoding.(
      obj2
        (req "root_hash" root_hash_encoding)
        (req "external_message" (bytes' Hex)))

  let dac_store_preimage =
    Tezos_rpc.Service.put_service
      ~description:"Split DAC reveal data"
      ~query:Tezos_rpc.Query.empty
      ~input:store_preimage_request_encoding
      ~output:store_preimage_response_encoding
      Tezos_rpc.Path.(open_root / "store_preimage")

  let register_serialize_dac_store_preimage cctxt dac_sk_uris reveal_data_dir
      dir =
    Tezos_rpc.Directory.register dir dac_store_preimage (fun () () input ->
        let open Lwt_result_syntax in
        let+ proto_hash, message =
          P.serialize_payload cctxt dac_sk_uris reveal_data_dir input
        in
        (M.of_reveal_hash proto_hash, message))

  let register reveal_data_dir cctxt _dac_public_keys_opt dac_sk_uris =
    (Tezos_rpc.Directory.empty : unit Tezos_rpc.Directory.t)
    |> register_serialize_dac_store_preimage cctxt dac_sk_uris reveal_data_dir

  let rpc_services ~reveal_data_dir cctxt dac_public_keys_opt dac_sk_uris
      _threshold =
    register reveal_data_dir cctxt dac_public_keys_opt dac_sk_uris
end
