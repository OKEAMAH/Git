let transaction_encodoing =
  Data_encoding.(
    obj3 (req "amount" string) (req "destination" string) (req "source" string))

let add_pending_operation :
    ( [`POST],
      unit,
      unit,
      unit,
      string * string * string,
      Injector.Inj_operation.hash )
    Tezos_rpc.Service.t =
  Tezos_rpc.Service.post_service
    ~description:"Add a pending operation to the injector queue"
    ~query:Tezos_rpc.Query.empty
    ~input:transaction_encodoing
    ~output:Injector.Inj_operation.Hash.encoding
    Tezos_rpc.Path.(root / "add_pending_operation")

type op_query = {op_hash : string}

let injector_op_query : op_query Tezos_rpc.Query.t =
  let open Tezos_rpc.Query in
  query (fun op_hash -> {op_hash})
  |+ field "op_hash" Tezos_rpc.Arg.string "" (fun t -> t.op_hash)
  |> seal

let operation_status :
    ([`GET], unit, unit, op_query, unit, string option) Tezos_rpc.Service.t =
  Tezos_rpc.Service.get_service
    ~description:"Query the status of an injector operation"
    ~query:injector_op_query
    ~output:Data_encoding.(option string)
    Tezos_rpc.Path.(root / "operation_status")

let inject : ([`GET], unit, unit, unit, unit, unit) Tezos_rpc.Service.t =
  Tezos_rpc.Service.get_service
    ~description:"Inject operations"
    ~query:Tezos_rpc.Query.empty
    ~output:Data_encoding.unit
    Tezos_rpc.Path.(root / "inject")
