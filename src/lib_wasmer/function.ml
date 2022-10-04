open Api
open Vectors

type owned = (* TODO: Might need to keep store alive. *)
  Types.Func.t Ctypes.ptr

let call_with_inputs params f inputs =
  let rec go : type f r. (f, r) Function_type.params -> f -> int -> r =
   fun params f index ->
    match params with
    | Function_type.End_param -> f
    | Trigger_param params -> go params (f ()) index
    | Cons_param (typ, params) ->
        let value =
          Value_vector.get Ctypes.(!@inputs) index |> Value.unpack typ
        in
        go params (f value) (succ index)
  in
  go params f 0

let pack_outputs results r outputs =
  Value_vector.init_uninitialized outputs (Function_type.num_results results) ;
  let rec go : type r. r Function_type.results -> r -> int -> unit =
   fun results value index ->
    match results with
    | Function_type.No_result -> ()
    | Function_type.One_result typ ->
        let value = Value.pack typ value in
        Value_vector.set Ctypes.(!@outputs) index value
    | Function_type.Cons_result (typ, results) ->
        let x, xs = value in
        let value = Value.pack typ x in
        Value_vector.set Ctypes.(!@outputs) index value ;
        go results xs (succ index)
  in
  go results r 0

let create : type f. Store.t -> f Function_type.t -> f -> owned =
 fun store typ f ->
  let func_type = Function_type.to_owned typ in
  let (Function_type.Function (params, results)) = typ in
  let run inputs outputs =
    let result =
      Lwt_preemptive.run_in_main (fun () -> call_with_inputs params f inputs)
    in
    pack_outputs results result outputs
  in
  let try_run inputs outputs =
    try
      let () = run inputs outputs in
      Trap.none
    with exn -> Trap.from_string store (Printexc.to_string exn)
  in
  Functions.Func.new_ store func_type try_run

let call_raw func inputs =
  let open Lwt.Syntax in
  let outputs = Value_vector.uninitialized (Functions.Func.result_arity func) in
  let+ trap =
    Lwt_preemptive.detach
      (fun (inputs, outputs) ->
        Functions.Func.call func (Ctypes.addr inputs) (Ctypes.addr outputs))
      (inputs, outputs)
  in
  Trap.check trap ;
  outputs

let pack_inputs (type x r) (params : (x, r Lwt.t) Function_type.params) func
    (unpack : Value_vector.t -> r) =
  let open Lwt.Syntax in
  let inputs = Value_vector.uninitialized (Function_type.num_params params) in
  let rec go_params : type f. (f, r Lwt.t) Function_type.params -> int -> f =
   fun params index ->
    match params with
    | Function_type.End_param ->
        let+ outputs = call_raw func inputs in
        unpack outputs
    | Trigger_param params -> fun () -> go_params params index
    | Cons_param (typ, params) ->
        fun x ->
          Value_vector.set inputs index (Value.pack typ x) ;
          go_params params (succ index)
  in
  go_params params 0

exception
  Not_enough_outputs of {expected : Unsigned.size_t; got : Unsigned.size_t}

let () =
  Printexc.register_printer (function
      | Not_enough_outputs {got; expected} ->
          Some
            (Printf.sprintf
               "Function did return less values (%s) than expected (%s)"
               (Unsigned.Size_t.to_string got)
               (Unsigned.Size_t.to_string got))
      | _ -> None)

let unpack_outputs results outputs =
  let got = Value_vector.length outputs in
  let expected = Function_type.num_results results in
  if (* Fewer outputs than expected. *)
     Unsigned.Size_t.compare got expected < 0
  then raise (Not_enough_outputs {got; expected}) ;
  let rec go : type r x. r Function_type.results -> int -> (r -> x) -> x =
   fun params index k ->
    match params with
    | Function_type.No_result -> k ()
    | Function_type.One_result typ ->
        Value_vector.get outputs index |> Value.unpack typ |> k
    | Function_type.Cons_result (typ, results) ->
        let x = Value_vector.get outputs index |> Value.unpack typ in
        go results (succ index) (fun xs -> k (x, xs))
  in
  go results 0 Fun.id

let call func typ =
  Function_type.check_types typ (Functions.Func.type_ func) ;
  let (Function_type.Function (params, results)) = typ in
  pack_inputs params func (unpack_outputs results)
