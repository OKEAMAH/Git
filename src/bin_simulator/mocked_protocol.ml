open Tezos_rpc
open Environment_context

(** [Mocking_parameters] contains values and samplers accounting
    for the processing time of the operations of the [Mocked] protocol. *)
module type Mocking_parameters = sig
  (** Time to check a signature. Does not account for hashing messages. *)
  val signature_check_time : float

  (** Hashing time, in nanoseconds/byte. *)
  val hashing_time : float

  (** Time taken to process endorsement, not including signature check.
      This should be close to deterministic but we allow for randomness. *)
  val endorsement_processing_time : unit -> float

  (** Operations have random sizes (in bytes).
      Must return a value consistent with the protocol parameters. *)
  val operation_size : unit -> int

  (** The gas <-> time conversion is axiomatically set to 1ns per milligas.
      We allow it to deviate by a (strictly positive) multiplicative scaling. *)
  val gas_deviation : unit -> float
end

module Env =
  Tezos_protocol_environment.MakeV6
    (struct
      let name = "V6"
    end)
    ()

module Make (P : Mocking_parameters) : Env.Updater.PROTOCOL = struct
  let max_block_length =
    (* TODO? *)
    let fake_shell =
      {
        Block_header.level = 0l;
        proto_level = 0;
        predecessor = Block_hash.zero;
        timestamp = Time.Protocol.of_seconds 0L;
        validation_passes = 0;
        operations_hash = Operation_list_list_hash.zero;
        fitness = [Data_encoding.(Binary.to_bytes_exn int32 0l)];
        context = Context_hash.zero;
      }
    in
    Data_encoding.Binary.length Block_header.shell_header_encoding fake_shell

  let max_operation_data_length = 32 * 1024 (* 32kB *)

  let validation_passes =
    Environment_context.
      [
        (* 2048 endorsements *)
        {max_size = 2048 * 2048; max_op = Some 2048};
        (* 32k of voting operations *)
        {max_size = 32 * 1024; max_op = None};
        (* revelations, wallet activations and denunciations *)
        {max_size = 132 * 1024; max_op = Some 132};
        (* 512kB *)
        {max_size = 512 * 1024; max_op = None};
      ]

  type block_header_data = unit

  let block_header_data_encoding = Data_encoding.unit

  type block_header = {
    shell : Block_header.shell_header;
    protocol_data : block_header_data;
  }

  type block_header_metadata = unit

  let block_header_metadata_encoding = Data_encoding.unit

  type operation_data =
    | Mocked_endorsement of {dummy_payload : Bytes.t}
    | Mocked_manager of {gas : int; dummy_payload : Bytes.t}

  type operation_receipt = unit

  type operation = {
    shell : Operation.shell_header;
    protocol_data : operation_data;
  }

  let operation_data_encoding : operation_data Data_encoding.t =
    let open Data_encoding in
    union
      [
        case
          ~title:"Mocked_endorsement"
          (Tag 0)
          bytes
          (function
            | Mocked_endorsement {dummy_payload} -> Some dummy_payload
            | _ -> None)
          (fun dummy_payload -> Mocked_endorsement {dummy_payload});
        case
          ~title:"Mocked_manager"
          (Tag 1)
          (tup2 int31 bytes)
          (function
            | Mocked_manager {gas; dummy_payload} -> Some (gas, dummy_payload)
            | _ -> None)
          (fun (gas, dummy_payload) -> Mocked_manager {gas; dummy_payload});
      ]

  let operation_receipt_encoding = Data_encoding.unit

  let operation_data_and_receipt_encoding =
    Data_encoding.tup2 operation_data_encoding operation_receipt_encoding

  let acceptable_passes {shell = _; protocol_data} =
    match protocol_data with
    | Mocked_endorsement _ -> [0]
    | Mocked_manager _ -> [3]

  let relative_position_within_block op1 op2 =
    match (op1.protocol_data, op2.protocol_data) with
    | Mocked_endorsement _, Mocked_endorsement _
    | Mocked_manager _, Mocked_manager _ ->
        0
    | Mocked_endorsement _, _ -> -1
    | _ -> 1

  type validation_state = {
    context : Context.t;
    level : int32;
    remaining_gas : int;
  }

  type Env.Error_monad.error += Operation_quota_exceeded

  let error e : 'a Env.Error_monad.tzresult Lwt.t =
    Lwt.return (Env.Error_monad.error e)

  let () =
    Env.Error_monad.register_error_kind
      `Temporary
      ~id:"gas_exhausted.operation"
      ~title:"Gas quota exceeded for the operation"
      ~description:
        "A script or one of its callee took more time than the operation said \
         it would"
      Data_encoding.empty
      (function Operation_quota_exceeded -> Some () | _ -> None)
      (fun () -> Operation_quota_exceeded)

  let sigcheck_time bytes =
    let hash = P.hashing_time *. float_of_int (Bytes.length bytes) in
    hash +. P.signature_check_time

  let apply_operation :
      validation_state ->
      operation ->
      (validation_state * operation_receipt) Env.Error_monad.tzresult Lwt.t =
   fun ({context = _; level = _; remaining_gas} as vs) op ->
    let open Lwt_result_syntax in
    match op.protocol_data with
    | Mocked_endorsement {dummy_payload} ->
        let sigcheck = sigcheck_time dummy_payload in
        let processing = P.endorsement_processing_time () in
        let*! () = Lwt_unix.sleep (sigcheck +. processing) in
        return (vs, ())
    | Mocked_manager {gas; dummy_payload} ->
        let remaining = remaining_gas - gas in
        let* () =
          if remaining < 0 then error Operation_quota_exceeded else return ()
        in
        let sigcheck = sigcheck_time dummy_payload in
        let gas_dev = P.gas_deviation () in
        let processing = gas_dev *. float_of_int gas in
        let*! () = Lwt_unix.sleep (sigcheck +. processing) in
        return (vs, ())

  let rpc_services = RPC_directory.empty

  let init context shell_header =
    let open Lwt_result_syntax in
    let level = shell_header.Block_header.level in
    return
      {
        context;
        fitness = [Data_encoding.(Binary.to_bytes_exn int32 level)];
        message = None;
        max_operations_ttl = 120;
        last_allowed_fork_level = 2l;
      }

  let value_of_key ~chain_id:_ ~predecessor_context:_ ~predecessor_timestamp:_
      ~predecessor_level:_ ~predecessor_fitness:_ ~predecessor:_ ~timestamp:_ =
    let open Lwt_result_syntax in
    return (fun _cache_key -> assert false)

  let begin_partial_application ~chain_id:_ ~ancestor_context
      ~predecessor_timestamp:_ ~predecessor_fitness:_
      (block_header : block_header) =
    let open Lwt_result_syntax in
    let level = block_header.shell.level in
    return {context = ancestor_context; level; remaining_gas = 5_200_000_000}

  let begin_application ~chain_id:_ ~predecessor_context
      ~predecessor_timestamp:_ ~predecessor_fitness:_
      (block_header : block_header) =
    let open Lwt_result_syntax in
    let level = block_header.shell.level in
    return {context = predecessor_context; level; remaining_gas = 5_200_000_000}

  let begin_construction ~chain_id:_ ~predecessor_context
      ~predecessor_timestamp:_ ~predecessor_level ~predecessor_fitness:_
      ~predecessor:_ ~timestamp:_ ?protocol_data:_ () =
    let open Lwt_result_syntax in
    let level = Int32.succ predecessor_level in
    return {context = predecessor_context; level; remaining_gas = 5_200_000_000}

  let finalize_block validation_state _shell_header_opt =
    let open Lwt_result_syntax in
    return
      ( {
          context = validation_state.context;
          fitness =
            [Data_encoding.(Binary.to_bytes_exn int32 validation_state.level)];
          message = None;
          max_operations_ttl = 120;
          last_allowed_fork_level = 2l;
        },
        () )
end
