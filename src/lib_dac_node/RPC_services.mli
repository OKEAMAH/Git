module type RPC = sig
  val rpc_services :
    reveal_data_dir:string ->
    #Client_context.wallet ->
    Tezos_crypto.Aggregate_signature.public_key option list ->
    Client_keys.aggregate_sk_uri option list ->
    int ->
    unit Tezos_rpc.Directory.directory
end

module Make (P : Node_plugin.S) : RPC
