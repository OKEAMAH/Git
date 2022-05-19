module Genesis = Tezos_protocol_genesis.Protocol
module Alpha = Tezos_protocol_alpha.Protocol

let get_genesis node =
  let open Tezos_store in
  let store = Node.Internal_for_tests.store node in
  let chain_store = Store.main_chain_store store in
  Store.Chain.block_of_identifier chain_store `Genesis

let activator_sk =
  Signature.Secret_key.of_b58check_exn
    "edsk31vznjHSSpGExDMHYASz45VZqXN4DPxvsa4hAyY8dHM28cZzp6"

let inject_block_proto_genesis node predecessor timestamp command =
  let open Tezos_store in
  let open Lwt_result_syntax in
  let store = Node.Internal_for_tests.store node in
  let chain_store = Store.main_chain_store store in
  let block_validator =
    Block_validator.running_worker (Node.Internal_for_tests.internal_id node)
  in
  let protocol_data : Genesis.block_header_data =
    {command; signature = Signature.zero}
  in
  let protocol_data =
    Data_encoding.Binary.to_bytes_exn
      Genesis.block_header_data_encoding
      protocol_data
  in
  let* shell_header, _ =
    Block_validator.preapply
      block_validator
      chain_store
      ~predecessor
      ~timestamp
      ~protocol_data
      []
  in
  let blk = Genesis.Data.Command.forge shell_header command in
  let chain_id = Store.Chain.chain_id chain_store in
  let watermark = Signature.Block_header chain_id in
  let signature = Signature.sign ~watermark activator_sk blk in
  let signed_blk = Signature.concat blk signature in
  let validator = Node.Internal_for_tests.validator node in
  let* hash, block = Validator.validate_block validator signed_blk [] in
  let*! res = block in
  match res with
  | Ok () -> return hash
  | Error trace -> Lwt.return (Error trace)

let fitness_from_int64 fitness =
  (* definition taken from src/proto_alpha/lib_protocol/src/constants_repr.ml *)
  let version_number = "\000" in
  (* definitions taken from src/proto_alpha/lib_protocol/src/fitness_repr.ml *)
  let int64_to_bytes i =
    let b = Bytes.create 8 in
    TzEndian.set_int64 b 0 i ;
    b
  in
  [Bytes.of_string version_number; int64_to_bytes fitness]

let activate_alpha node =
  let open Lwt_result_syntax in
  let* genesis = get_genesis node in
  let fitness = fitness_from_int64 1L in
  let tstamp = Time.System.(to_protocol (Time.System.now ())) in

  let protocol_parameters =
    let open Tezos_protocol_alpha_parameters in
    let constants = Default_parameters.constants_sandbox in
    let params = Default_parameters.parameters_of_constants constants in
    let json = Default_parameters.json_of_parameters params in
    Data_encoding.Binary.to_bytes_exn Data_encoding.json json
  in

  let protocol = Alpha.hash in

  inject_block_proto_genesis
    node
    genesis
    tstamp
    (Activate {protocol; fitness; protocol_parameters})
