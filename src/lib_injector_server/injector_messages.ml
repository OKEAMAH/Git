let transaction_encodoing =
  Data_encoding.(
    obj3 (req "amount" string) (req "destination" string) (req "source" string))

let inject :
    ( [`POST],
      unit,
      unit,
      unit,
      string * string * string,
      Injector.Inj_operation.hash )
    Tezos_rpc.Service.t =
  Tezos_rpc.Service.post_service
    ~description:"Inject an operation"
    ~query:Tezos_rpc.Query.empty
    ~input:transaction_encodoing
    ~output:Injector.Inj_operation.Hash.encoding
    Tezos_rpc.Path.(root / "inject")
