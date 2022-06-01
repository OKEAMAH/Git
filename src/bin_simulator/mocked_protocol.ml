open Tezos_rpc
open Tezos_event_logging
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

  (** Operations have random sizes. Automatically truncated to correct interval. *)
  val operation_size : unit -> int

  (** The gas <-> time conversion is axiomatically set to 1ns per milligas.
      We allow it to deviate by a (strictly positive) multiplicative scaling. *)
  val gas_deviation : unit -> float
end

(* Size of an encoded endorsement, in bytes *)
let endorsement_size = 48

module Mocked (P : Mocking_parameters) : sig
  val max_block_length : int

  val max_operation_data_length : int

  val validation_passes : quota trace

  type block_header_data

  val block_header_data_encoding : block_header_data Data_encoding.t

  type block_header = {
    shell : Block_header.shell_header;
    protocol_data : block_header_data;
  }

  type block_header_metadata

  val block_header_metadata_encoding : block_header_metadata Data_encoding.t

  type operation_data

  type operation_receipt

  type operation = {
    shell : Operation.shell_header;
    protocol_data : operation_data;
  }

  val operation_data_encoding : operation_data Data_encoding.t

  val operation_receipt_encoding : operation_receipt Data_encoding.t

  val operation_data_and_receipt_encoding :
    (operation_data * operation_receipt) Data_encoding.t

  val acceptable_passes : operation -> int trace

  val relative_position_within_block : operation -> operation -> int

  type validation_state

  val apply_operation :
    validation_state ->
    operation ->
    (validation_state * operation_receipt) Error_monad.tzresult Lwt.t

  val rpc_services : rpc_context RPC_directory.t

  val init :
    Context.t ->
    Block_header.shell_header ->
    validation_result Error_monad.tzresult Lwt.t

  val value_of_key :
    chain_id:Chain_id.t ->
    predecessor_context:Context.t ->
    predecessor_timestamp:Time.Protocol.t ->
    predecessor_level:int32 ->
    predecessor_fitness:Fitness.t ->
    predecessor:Block_hash.t ->
    timestamp:Time.Protocol.t ->
    (Context.cache_key -> Context.cache_value Error_monad.tzresult Lwt.t)
    Error_monad.tzresult
    Lwt.t

  val set_log_message_consumer :
    (Internal_event.level -> string -> unit) -> unit

  val environment_version : Protocol.env_version

  val begin_partial_application :
    chain_id:Chain_id.t ->
    ancestor_context:Context.t ->
    predecessor:Block_header.t ->
    predecessor_hash:Block_hash.t ->
    cache:Context.source_of_cache ->
    block_header ->
    (validation_state, tztrace) result Lwt.t

  val begin_application :
    chain_id:Chain_id.t ->
    predecessor_context:Context.t ->
    predecessor_timestamp:Time.Protocol.t ->
    predecessor_fitness:Fitness.t ->
    cache:Context.source_of_cache ->
    block_header ->
    validation_state Error_monad.tzresult Lwt.t

  val begin_construction :
    chain_id:Chain_id.t ->
    predecessor_context:Context.t ->
    predecessor_timestamp:Time.Protocol.t ->
    predecessor_level:int32 ->
    predecessor_fitness:Fitness.t ->
    predecessor:Block_hash.t ->
    timestamp:Time.Protocol.t ->
    ?protocol_data:block_header_data ->
    cache:Context.source_of_cache ->
    unit ->
    validation_state Error_monad.tzresult Lwt.t

  val finalize_block :
    validation_state ->
    Block_header.shell_header option ->
    (validation_result * block_header_metadata) tzresult Lwt.t
end = struct
  let max_block_length =
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
    | Mocked_endorsement
    | Mocked_manager_list of
        int list (* each mgr op is abstracted by its gas consumption *)

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
          unit
          (function Mocked_endorsement -> Some () | _ -> None)
          (fun () -> Mocked_endorsement);
        case
          ~title:"Mocked_manager"
          (Tag 1)
          (list int31)
          (function Mocked_manager_list gasses -> Some gasses | _ -> None)
          (fun gasses -> Mocked_manager_list gasses);
      ]

  let operation_receipt_encoding = Data_encoding.unit

  let operation_data_and_receipt_encoding =
    Data_encoding.tup2 operation_data_encoding operation_receipt_encoding

  let acceptable_passes {shell = _; protocol_data} =
    match protocol_data with
    | Mocked_endorsement -> [0]
    | Mocked_manager_list _ -> [3]

  let relative_position_within_block op1 op2 =
    match (op1.protocol_data, op2.protocol_data) with
    | Mocked_endorsement, Mocked_endorsement
    | Mocked_manager_list _, Mocked_manager_list _ ->
        0
    | Mocked_endorsement, _ -> -1
    | _ -> 1

  type validation_state = {
    context : Context.t;
    level : int32;
    remaining_gas : int;
  }

  type error += Operation_quota_exceeded

  let error e = Lwt_result_syntax.fail (TzTrace.make e)

  let () =
    register_error_kind
      `Temporary
      ~id:"gas_exhausted.operation"
      ~title:"Gas quota exceeded for the operation"
      ~description:
        "A script or one of its callee took more time than the operation said \
         it would"
      Data_encoding.empty
      (function Operation_quota_exceeded -> Some () | _ -> None)
      (fun () -> Operation_quota_exceeded)

  let apply_operation :
      validation_state ->
      operation ->
      (validation_state * operation_receipt) tzresult Lwt.t =
   fun ({context = _; level = _; remaining_gas} as vs) op ->
    let open Lwt_result_syntax in
    match op.protocol_data with
    | Mocked_endorsement ->
        let t = P.endorsement_processing_time () in
        let h = float_of_int endorsement_size *. P.hashing_time in
        let*! () = Lwt_unix.sleep (P.signature_check_time +. h +. t) in
        return (vs, ())
    | Mocked_manager_list gasses ->
        let t, total_gas =
          List.fold_left
            (fun (time, total_gas) gas ->
              let time = time +. manager_op_processing_time gas in
              let total_gas = total_gas + gas in
              (time, total_gas))
            (0.0, 0)
            gasses
        in
        let remaining = remaining_gas - total_gas in
        if remaining < 0 then error Operation_quota_exceeded
        else
          let*! () = Lwt_unix.sleep t in
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

  let set_log_message_consumer _consumer = ()

  let environment_version = Protocol.V6

  let begin_partial_application ~chain_id:_ ~ancestor_context ~predecessor
      ~predecessor_hash:_ ~cache:_ _block_header =
    let open Lwt_result_syntax in
    let predecessor_level = predecessor.Block_header.shell.level in
    return
      {
        context = ancestor_context;
        level = Int32.succ predecessor_level;
        remaining_gas = 5_200_000_000;
      }

  let begin_application ~chain_id:_ ~predecessor_context
      ~predecessor_timestamp:_ ~predecessor_fitness:_ ~cache:_
      (block_header : block_header) =
    let open Lwt_result_syntax in
    let level = block_header.shell.level in
    return {context = predecessor_context; level; remaining_gas = 5_200_000_000}

  let begin_construction ~chain_id:_ ~predecessor_context
      ~predecessor_timestamp:_ ~predecessor_level ~predecessor_fitness:_
      ~predecessor:_ ~timestamp:_ ?protocol_data:_ ~cache:_ () =
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
