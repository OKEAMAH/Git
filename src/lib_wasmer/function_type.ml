open Api
open Vectors

type (_, _) params =
  | End_param : (unit -> 'r, 'r) params
  | Cons_param : 'a Value_type.t * ('b, 'r) params -> ('a -> 'b, 'r) params

let num_params params =
  let rec go : type f r. (f, r) params -> Unsigned.size_t -> Unsigned.size_t =
   fun params num ->
    match params with
    | End_param -> num
    | Cons_param (_, params) -> go params (Unsigned.Size_t.succ num)
  in
  go params Unsigned.Size_t.zero

let param_types params =
  let inputs = Value_type_vector.uninitialized (num_params params) in
  let set_type index typ =
    Value_type_vector.set inputs index (Value_type.to_valtype typ)
  in
  let rec go : type f r. (f, r) params -> int -> unit =
   fun params index ->
    match params with
    | End_param -> ()
    | Cons_param (typ, params) ->
        set_type index typ ;
        go params (succ index)
  in
  go params 0 ;
  inputs

type _ results =
  | No_result : unit results
  | One_result : 'a Value_type.t -> 'a results
  | Cons_result : 'a Value_type.t * 'b results -> ('a * 'b) results

let num_results results =
  let rec go : type r. r results -> Unsigned.size_t -> Unsigned.size_t =
   fun results num ->
    match results with
    | No_result -> num
    | One_result _ -> Unsigned.Size_t.succ num
    | Cons_result (_, results) -> go results (Unsigned.Size_t.succ num)
  in
  go results Unsigned.Size_t.zero

let result_types results =
  let outputs = Value_type_vector.uninitialized (num_results results) in
  let set_type index typ =
    Value_type_vector.set outputs index (Value_type.to_valtype typ)
  in
  let rec go : type r. r results -> int -> unit =
   fun results index ->
    match results with
    | No_result -> ()
    | One_result typ -> set_type index typ
    | Cons_result (typ, results) ->
        set_type index typ ;
        go results (succ index)
  in
  go results 0 ;
  outputs

type 'f t = Function : ('f, 'r Lwt.t) params * 'r results -> 'f t

let to_owned (Function (params, results)) =
  let inputs = param_types params in
  let outputs = result_types results in
  (* Note, this consumes the elements in [inputs] and [outputs] but not the
     structures themselves. Ctypes will free the structures once they go out
     of scope. *)
  Functions.Functype.new_ (Ctypes.addr inputs) (Ctypes.addr outputs)

exception
  Wrong_number_of_params of {expected : Unsigned.size_t; got : Unsigned.size_t}

let () =
  Printexc.register_printer (function
      | Wrong_number_of_params {expected; got} ->
          Some
            (Printf.sprintf
               "Wrong number of parameters: expected %s, got %s"
               (Unsigned.Size_t.to_string expected)
               (Unsigned.Size_t.to_string got))
      | _ -> None)

let check_param_types params param_types =
  let expected = num_params params in
  let got = Value_type_vector.length param_types in
  if
    (* Fewer or more params than expected. *)
    not (Unsigned.Size_t.equal expected got)
  then raise (Wrong_number_of_params {got; expected}) ;
  let rec go : type f r. (f, r) params -> int -> unit =
   fun params index ->
    match params with
    | End_param -> ()
    | Cons_param (expected, params) ->
        Value_type_vector.get param_types index |> Value_type.check expected ;
        go params (succ index)
  in
  go params 0

exception
  Not_enough_results of {expected : Unsigned.size_t; got : Unsigned.size_t}

let () =
  Printexc.register_printer (function
      | Not_enough_results {expected; got} ->
          Some
            (Printf.sprintf
               "Not enough results: expected %s, got %s"
               (Unsigned.Size_t.to_string expected)
               (Unsigned.Size_t.to_string got))
      | _ -> None)

let check_result_types results result_types =
  let expected = num_results results in
  let got = Value_type_vector.length result_types in
  if (* Fewer resuls than expected. *)
     Unsigned.Size_t.compare got expected < 0
  then raise (Not_enough_results {got; expected}) ;
  let rec go : type r. r results -> int -> unit =
   fun results index ->
    match results with
    | No_result -> ()
    | One_result expected ->
        Value_type_vector.get result_types index |> Value_type.check expected
    | Cons_result (expected, results) ->
        Value_type_vector.get result_types index |> Value_type.check expected ;
        go results (succ index)
  in
  go results 0

exception Function_type_mismatch of {reason : exn}

let () =
  Printexc.register_printer (function
      | Function_type_mismatch {reason} ->
          Some
            (Printf.sprintf
               "Function type does not match: %s"
               (Printexc.to_string reason))
      | _ -> None)

let check_types (Function (params, results)) func_type =
  try
    let param_types = Functions.Functype.params func_type in
    check_param_types params Ctypes.(!@param_types) ;
    let result_types = Functions.Functype.results func_type in
    check_result_types results Ctypes.(!@result_types)
  with exn -> raise (Function_type_mismatch {reason = exn})
