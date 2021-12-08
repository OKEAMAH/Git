(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

module type ROLLUP_MONITOR = sig
  module Proto : Registered_protocol.T

  type rollup_address

  type t

  val encoding : t Data_encoding.t

  module S : sig
    (* Services for distinct protocols should have distinct paths! *)
    val monitor_rollup :
      ( [`GET],
        unit,
        (unit * Chain_services.chain) * rollup_address,
        unit,
        unit,
        t trace )
      RPC_service.t
  end

  val filter : rollup_address -> op:Operation.t -> metadata:Bytes.t -> t list
end

let process_block :
    type a b.
    Store.chain_store ->
    (module ROLLUP_MONITOR with type t = a and type rollup_address = b) ->
    Store.Block.t ->
    b ->
    a list tzresult Lwt.t =
  fun (type a b)
      chain_store
      (module Monitor : ROLLUP_MONITOR
        with type t = a
         and type rollup_address = b)
      (head : Store.Block.t)
      rollup_address ->
   Store.Block.get_block_metadata chain_store head >>=? fun metadata ->
   let operations = Store.Block.operations head in
   (* get manager ops & their receipts *)
   let manager =
     match List.nth operations 3 with None -> assert false | Some ops -> ops
   in
   let receipts =
     match List.nth metadata.operations_metadata 3 with
     | None -> assert false
     | Some receipts -> receipts
   in
   let filtered =
     List.fold_right2
       ~when_different_lengths:()
       (fun op metadata acc ->
         let res = Monitor.filter rollup_address ~op ~metadata in
         res @ acc)
       manager
       receipts
       []
   in
   match filtered with
   | Error () ->
       failwith
         "Rollup_monitoring: list of operations and metadata have inconsistent \
          length"
   | Ok outcome -> return outcome

let service :
    type a b.
    Validator.t ->
    Store.t ->
    (module ROLLUP_MONITOR with type t = a and type rollup_address = b) ->
    Chain_services.chain ->
    b ->
    unit ->
    unit ->
    a list RPC_answer.t Lwt.t =
  fun (type a b)
      validator
      store
      (module Monitor : ROLLUP_MONITOR
        with type t = a
         and type rollup_address = b)
      chain
      rollup_addr
      ()
      () ->
   Chain_directory.get_chain_store_exn store chain >>= fun chain_store ->
   match Validator.get validator (Store.Chain.chain_id chain_store) with
   | Error _ -> Lwt.fail Not_found
   | Ok chain_validator ->
       let (block_stream, stopper) =
         Chain_validator.new_head_watcher chain_validator
       in
       Store.Chain.current_head chain_store >>= fun head ->
       let shutdown () = Lwt_watcher.shutdown stopper in
       let in_protocol block =
         Store.Block.context_exn chain_store block >>= fun context ->
         Context.get_protocol context >>= fun next_protocol ->
         Lwt.return (Protocol_hash.equal Monitor.Proto.hash next_protocol)
       in
       let stream =
         Lwt_stream.filter_map_s
           (fun block ->
             in_protocol block >>= fun in_protocol ->
             if in_protocol then
               process_block chain_store (module Monitor) block rollup_addr
               >>= function
               | Error _ ->
                   (* TODO: Inelegant. Log some info at least. *)
                   Lwt.return_none
               | Ok data -> Lwt.return_some data
             else Lwt.return_none)
           block_stream
       in
       in_protocol head >>= fun first_block_is_in_protocol ->
       let first_call =
         (* Skip the first block if this is false *)
         ref first_block_is_in_protocol
       in
       let next () =
         if !first_call then (
           first_call := false ;
           process_block chain_store (module Monitor) head rollup_addr
           >>= function
           | Error _ ->
               (* TODO: Inelegant. Log some info at least. *)
               Lwt_stream.get stream
           | Ok data -> Lwt.return_some data)
         else Lwt_stream.get stream
       in
       RPC_answer.return_stream {next; shutdown}

let table : (module ROLLUP_MONITOR) Protocol_hash.Table.t =
  Protocol_hash.Table.create 5

let register (module Monitor : ROLLUP_MONITOR) =
  assert (not (Protocol_hash.Table.mem table Monitor.Proto.hash)) ;
  Protocol_hash.Table.add table Monitor.Proto.hash (module Monitor)

let find = Protocol_hash.Table.find table

let iter f = Protocol_hash.Table.iter f table
