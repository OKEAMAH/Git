module Request : sig
  type t = Operation of unit

  val encoding : t Data_encoding.t
end = struct
  type t = Operation of unit

  let encoding =
    let open Data_encoding in
    def "injector.request"
    @@ union
         [
           case
             (Tag 0)
             ~title:"Operation"
             unit
             (function Operation () -> Some ())
             (fun () -> Operation ());
         ]
end

let inject :
    ( [`POST],
      unit,
      unit,
      unit,
      bytes,
      Injector.Inj_operation.hash )
    Tezos_rpc.Service.t =
  Tezos_rpc.Service.post_service
    ~description:"Inject an operation"
    ~query:Tezos_rpc.Query.empty
    ~input:Data_encoding.bytes
    ~output:Injector.Inj_operation.Hash.encoding
    Tezos_rpc.Path.(root / "inject")
