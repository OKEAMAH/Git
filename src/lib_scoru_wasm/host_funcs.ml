(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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
open Tezos_webassembly_interpreter
open Instance

module Error = struct
  type t =
    | Store_key_too_large
    | Store_invalid_key
    | Store_not_a_value
    | Store_invalid_access
    | Store_value_size_exceeded
    | Memory_invalid_access
    | Input_output_too_large
    | Generic_invalid_access
    | Store_readonly_value
    | Store_not_a_node
    | Full_outbox

  (** [code error] returns the error code associated to the error. *)
  let code = function
    | Store_key_too_large -> -1l
    | Store_invalid_key -> -2l
    | Store_not_a_value -> -3l
    | Store_invalid_access -> -4l
    | Store_value_size_exceeded -> -5l
    | Memory_invalid_access -> -6l
    | Input_output_too_large -> -7l
    | Generic_invalid_access -> -8l
    | Store_readonly_value -> -9l
    | Store_not_a_node -> -10l
    | Full_outbox -> -11l
end

module type Memory_access = sig
  type t

  (** TODO Use the same type for offsets & memory size *)

  type size := int

  type addr := int32

  val store_bytes : t -> addr -> string -> unit Lwt.t

  val load_bytes : t -> addr -> size -> string Lwt.t

  val store_num : t -> addr -> addr -> Values.num -> unit Lwt.t

  val bound : t -> int64

  val exn_to_error : default:Error.t -> exn -> Error.t
end

module Memory_access_interpreter :
  Memory_access with type t = Instance.memory_inst = struct
  include Memory

  let exn_to_error ~(default : Error.t) exn =
    match exn with Memory.Bounds -> Error.Memory_invalid_access | _ -> default
end

exception Bad_input

exception Key_too_large of int

let check_key_length key_length = key_length > Durable.max_key_length

let return_error e = Lwt.return (Error.code e)

let extract_error_code = function
  | Error error -> return_error error
  | Ok res -> Lwt.return res

let extract_error durable = function
  | Error error -> Lwt.return (durable, Error.code error)
  | Ok res -> Lwt.return res

let retrieve_memory memories =
  let crash_with msg = raise (Eval.Crash (Source.no_region, msg)) in
  match memories with
  | Host_funcs.No_memories_during_init ->
      crash_with "host functions must not access memory during initialisation"
  | Host_funcs.Available_memories memories
    when Vector.num_elements memories = 1l ->
      Vector.get 0l memories
  | Host_funcs.Available_memories _ ->
      crash_with "caller module must have exactly 1 memory instance"

type read_input_info = {level : int32; id : int32}

let read_input_info_encoding =
  let open Data_encoding in
  conv
    (function {level; id} -> (level, id))
    (fun (level, id) -> {level; id})
    (obj2
       (req "level" Data_encoding_utils.Little_endian.int32)
       (req "id" Data_encoding_utils.Little_endian.int32))

module Aux = struct
  module type S = sig
    type memory

    (** max size of intputs and outputs. *)
    val input_output_max_size : int

    (** [write_output ~output_buffer ~memory ~src ~num_bytes] reads
     num_bytes from the memory of module_inst starting at src and writes
     this to the output_buffer. It also checks that the input payload is
     no larger than `max_output`. It returns 0 for Ok. *)
    val write_output :
      output_buffer:Output_buffer.t ->
      memory:memory ->
      src:int32 ->
      num_bytes:int32 ->
      int32 Lwt.t

    (** [read_input ~input_buffer ~output_buffer ~memory ~level_offset
     ~id_offset ~dst ~max_bytes] reads `input_buffer` and writes its
     components to the memory based on the memory addreses offsets described.
     It also checks that the input payload is no larger than `max_input` and
     fails with `Input_output_too_large` otherwise. It returns the size of the
     payload. Note also that, if the level increases this function also updates
     the level of the output buffer and resets its id to zero. *)
    val read_input :
      input_buffer:Input_buffer.t ->
      memory:memory ->
      info_addr:int32 ->
      dst:int32 ->
      max_bytes:int32 ->
      int32 Lwt.t

    val store_has :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      int32 Lwt.t

    val store_delete :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      (Durable.t * int32) Lwt.t

    val store_copy :
      durable:Durable.t ->
      memory:memory ->
      from_key_offset:int32 ->
      from_key_length:int32 ->
      to_key_offset:int32 ->
      to_key_length:int32 ->
      (Durable.t * int32) Lwt.t

    val store_move :
      durable:Durable.t ->
      memory:memory ->
      from_key_offset:int32 ->
      from_key_length:int32 ->
      to_key_offset:int32 ->
      to_key_length:int32 ->
      (Durable.t * int32) Lwt.t

    val store_value_size :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      int32 Lwt.t

    val store_read :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      value_offset:int32 ->
      dest:int32 ->
      max_bytes:int32 ->
      int32 Lwt.t

    val store_write :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      value_offset:int32 ->
      src:int32 ->
      num_bytes:int32 ->
      (Durable.t * int32) Lwt.t

    val store_list_size :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      (Durable.t * int64) Lwt.t

    val store_get_nth_key :
      durable:Durable.t ->
      memory:memory ->
      key_offset:int32 ->
      key_length:int32 ->
      index:int64 ->
      dst:int32 ->
      max_size:int32 ->
      int32 Lwt.t

    val reveal :
      memory:memory ->
      dst:int32 ->
      max_bytes:int32 ->
      payload:bytes ->
      int32 Lwt.t

    val read_mem : memory:memory -> src:int32 -> num_bytes:int32 -> string Lwt.t
  end

  module Make (M : Memory_access) : S with type memory = M.t = struct
    type memory = M.t

    let input_output_max_size = 4096

    let guard func =
      let open Lwt_result_syntax in
      Lwt.catch
        (fun () ->
          let*! res = func () in
          return res)
        (function
          | Durable.Out_of_bounds _ -> fail Error.Store_invalid_access
          | Durable.Readonly_value -> fail Error.Store_readonly_value
          | Durable.Invalid_key _ -> fail Error.Store_invalid_key
          | Durable.Value_not_found -> fail Error.Store_not_a_value
          | Durable.Tree_not_found -> fail Error.Store_not_a_node
          | Output_buffer.Full_outbox -> fail Error.Full_outbox
          | exn ->
              fail @@ M.exn_to_error ~default:Error.Generic_invalid_access exn)

    module M = struct
      include M

      let load_bytes mem addr size =
        guard @@ fun () -> M.load_bytes mem addr size

      let store_bytes mem addr data =
        guard @@ fun () -> M.store_bytes mem addr data
    end

    let load_key_from_memory key_offset key_length memory =
      let open Lwt_result_syntax in
      let key_length = Int32.to_int key_length in
      if check_key_length key_length then fail Error.Store_key_too_large
      else
        let* key = M.load_bytes memory key_offset key_length in
        guard (fun () -> Lwt.return (Durable.key_of_string_exn key))

    let read_input ~input_buffer ~memory ~info_addr ~dst ~max_bytes =
      let open Lwt_result_syntax in
      let*! res =
        Lwt.catch
          (fun () ->
            let*! {raw_level; message_counter; payload} =
              Input_buffer.dequeue input_buffer
            in
            let input_size = Bytes.length payload in
            let* () =
              if input_size > input_output_max_size then
                fail Error.Input_output_too_large
              else return_unit
            in
            let payload =
              Bytes.sub payload 0 @@ min input_size (Int32.to_int max_bytes)
            in
            let* () = M.store_bytes memory dst (Bytes.to_string payload) in
            let* () =
              M.store_bytes
                memory
                info_addr
                (Data_encoding.Binary.to_string_exn
                   read_input_info_encoding
                   {level = raw_level; id = Z.to_int32 message_counter})
            in
            return (Int32.of_int input_size))
          (fun exn ->
            match exn with
            | Input_buffer.Dequeue_from_empty_queue -> return 0l
            | _ -> return Error.(code Generic_invalid_access))
      in
      extract_error_code res

    let write_output ~output_buffer ~memory ~src ~num_bytes =
      let open Lwt_result_syntax in
      let*! res =
        if num_bytes > Int32.of_int input_output_max_size then
          fail Error.Input_output_too_large
        else
          let num_bytes = Int32.to_int num_bytes in
          let* payload = M.load_bytes memory src num_bytes in
          let* Output_buffer.{outbox_level = _; message_index = _} =
            guard (fun () ->
                Output_buffer.push_message
                  output_buffer
                  (Bytes.of_string payload))
          in
          return 0l
      in
      extract_error_code res

    let store_has_unknown_key = 0l

    let store_has_value_only = 1l

    let store_has_subtrees_only = 2l

    let store_has_value_and_subtrees = 3l

    let store_has ~durable ~memory ~key_offset ~key_length =
      let open Lwt_result_syntax in
      let*! res =
        let* key = load_key_from_memory key_offset key_length memory in
        let*! value_opt = Durable.find_value durable key in
        let*! num_subtrees = Durable.count_subtrees durable key in
        match (value_opt, num_subtrees) with
        | None, 0 -> return store_has_unknown_key
        | Some _, 1 -> return store_has_value_only
        | None, _ -> return store_has_subtrees_only
        | _ -> return store_has_value_and_subtrees
      in
      extract_error_code res

    let store_delete ~durable ~memory ~key_offset ~key_length =
      let open Lwt_result_syntax in
      let*! res =
        let* key = load_key_from_memory key_offset key_length memory in
        let+ durable = guard (fun () -> Durable.delete durable key) in
        (durable, 0l)
      in
      extract_error durable res

    let store_list_size ~durable ~memory ~key_offset ~key_length =
      let open Lwt_result_syntax in
      let*! res =
        let* key = load_key_from_memory key_offset key_length memory in
        let+ num_subtrees =
          guard (fun () -> Durable.count_subtrees durable key)
        in
        (durable, I64.of_int_s num_subtrees)
      in
      match res with
      | Error error -> Lwt.return (durable, Int64.of_int32 (Error.code error))
      | Ok res -> Lwt.return res

    let store_copy ~durable ~memory ~from_key_offset ~from_key_length
        ~to_key_offset ~to_key_length =
      let open Lwt_result_syntax in
      let*! res =
        let* from_key =
          load_key_from_memory from_key_offset from_key_length memory
        in
        let* to_key = load_key_from_memory to_key_offset to_key_length memory in
        let+ durable =
          guard (fun () -> Durable.copy_tree_exn durable from_key to_key)
        in
        (durable, 0l)
      in
      extract_error durable res

    let store_move ~durable ~memory ~from_key_offset ~from_key_length
        ~to_key_offset ~to_key_length =
      let open Lwt_result_syntax in
      let*! res =
        let* from_key =
          load_key_from_memory from_key_offset from_key_length memory
        in
        let* to_key = load_key_from_memory to_key_offset to_key_length memory in
        let+ durable =
          guard (fun () -> Durable.move_tree_exn durable from_key to_key)
        in
        (durable, 0l)
      in
      extract_error durable res

    let store_value_size_aux ~durable ~key =
      let open Lwt_result_syntax in
      let* bytes = guard (fun () -> Durable.find_value durable key) in
      match bytes with
      | Some bytes ->
          let size = Tezos_lazy_containers.Chunked_byte_vector.length bytes in
          return (Int64.to_int32 size)
      | None -> fail Error.Store_not_a_value

    let store_value_size ~durable ~memory ~key_offset ~key_length =
      let open Lwt_result_syntax in
      let*! res =
        let* key = load_key_from_memory key_offset key_length memory in
        store_value_size_aux ~durable ~key
      in
      extract_error_code res

    let store_read ~durable ~memory ~key_offset ~key_length ~value_offset ~dest
        ~max_bytes =
      let open Lwt_result_syntax in
      let*! res =
        let* key = load_key_from_memory key_offset key_length memory in
        let value_offset = Int64.of_int32 value_offset in
        let max_bytes = Int64.of_int32 max_bytes in
        let* value =
          guard (fun () ->
              Durable.read_value_exn durable key value_offset max_bytes)
        in
        let* () = M.store_bytes memory dest value in
        return (Int32.of_int (String.length value))
      in
      extract_error_code res

    let chunk_max_size = 4096l

    let store_write ~durable ~memory ~key_offset ~key_length ~value_offset ~src
        ~num_bytes =
      let open Lwt_result_syntax in
      let*! res =
        if num_bytes > chunk_max_size then fail Error.Input_output_too_large
        else
          let* key = load_key_from_memory key_offset key_length memory in
          let*! value_size_err = store_value_size_aux ~durable ~key in
          let* value_size =
            match value_size_err with
            | Ok s -> return s
            | Error Error.Store_not_a_value -> return 0l
            | Error e -> fail e
          in
          let* () =
            (* Checks for overflow. *)
            if value_size > Int32.add value_size num_bytes then
              fail Error.Store_value_size_exceeded
            else return ()
          in
          let value_offset = Int64.of_int32 value_offset in
          let num_bytes = Int32.to_int num_bytes in
          let* payload = M.load_bytes memory src num_bytes in
          let+ durable =
            guard (fun () ->
                Durable.write_value_exn durable key value_offset payload)
          in
          (durable, 0l)
      in
      extract_error durable res

    let store_get_nth_key ~durable ~memory ~key_offset ~key_length ~index ~dst
        ~max_size =
      let open Lwt_result_syntax in
      let*! res =
        let index = Int64.to_int index in
        let* key = load_key_from_memory key_offset key_length memory in
        let* result =
          guard (fun () -> Durable.subtree_name_at durable key index)
        in
        let result_size = String.length result in
        let max_size = Int32.to_int max_size in
        let result =
          if max_size < result_size then String.sub result 0 max_size
          else result
        in
        let+ () =
          if result <> "" then M.store_bytes memory dst result else return_unit
        in
        Int32.of_int @@ String.length result
      in
      extract_error_code res

    let reveal ~memory ~dst ~max_bytes ~payload =
      let open Lwt_syntax in
      let* res =
        let open Lwt_result_syntax in
        let payload_size = Bytes.length payload in
        let revealed_bytes = min payload_size (Int32.to_int max_bytes) in
        let payload = Bytes.sub payload 0 revealed_bytes in
        let+ () = M.store_bytes memory dst (Bytes.to_string payload) in
        Int32.of_int revealed_bytes
      in
      extract_error_code res

    let read_mem ~memory ~src ~num_bytes =
      let open Lwt.Syntax in
      let mem_size = I32.of_int_s @@ I64.to_int_s @@ M.bound memory in
      let get_error_message = function
        | err -> Printf.sprintf "Error code: %ld" @@ Error.code err
      in
      let+ result =
        if src < mem_size then
          let truncated =
            Int32.(src |> sub (min (add src num_bytes) mem_size))
          in
          let int_len =
            assert (num_bytes > 0l) ;
            assert (num_bytes < Int32.max_int) ;
            Int32.to_int truncated
          in
          M.load_bytes memory src int_len
        else Lwt_result.return ""
      in
      Result.fold ~ok:Fun.id ~error:get_error_message result
  end

  include Make (Memory_access_interpreter)
end

let value i = Values.(Num (I32 i))

let read_input_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Types.[NumType I32Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

let read_input_name = "tezos_read_input"

let read_input =
  Host_funcs.Host_func
    (fun input_buffer _output_buffer durable memories inputs ->
      let open Lwt.Syntax in
      match inputs with
      | [
       Values.(Num (I32 info_addr));
       Values.(Num (I32 dst));
       Values.(Num (I32 max_bytes));
      ] ->
          let* memory = retrieve_memory memories in
          let* x =
            Aux.read_input ~input_buffer ~memory ~info_addr ~dst ~max_bytes
          in
          Lwt.return (durable, [value x])
      | _ -> raise Bad_input)

let write_output_name = "tezos_write_output"

let write_output_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Types.[NumType I32Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

let write_output =
  Host_funcs.Host_func
    (fun _input_buffer output_buffer durable memories inputs ->
      let open Lwt.Syntax in
      match inputs with
      | [Values.(Num (I32 src)); Values.(Num (I32 num_bytes))] ->
          let* memory = retrieve_memory memories in
          let* x = Aux.write_output ~output_buffer ~memory ~src ~num_bytes in
          Lwt.return (durable, [value x])
      | _ -> raise Bad_input)

let write_debug_name = "tezos_write_debug"

let write_debug_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Vector.empty () in
  Types.FuncType (input_types, output_types)

(** [write_debug] is a noop.
  Switch manually to _alternative_write_debug_impl for printing de debug info
  *)
let write_debug_impl durable _memories _src _num_bytes = Lwt.return (durable, [])

(* [alternate_write_debug_impl] may be used to replace the default
   [write_debug_impl] implementation when debugging the PVM/kernel, and
   prints the debug message.

   NB this does slightly change the semantics of 'write_debug', as it may
   load the memory pointed to by [src] & [num_bytes].
*)
let _alternate_write_debug_impl durable memories src num_bytes =
  let open Lwt.Syntax in
  let* memory = retrieve_memory memories in
  let* result = Aux.read_mem ~memory ~src ~num_bytes in
  Printf.printf "DEBUG: %s\n" result ;
  Lwt.return (durable, [])

(* [write_debug] accepts a pointer to the start of a sequence of
   bytes, and a length.

   The PVM, however, does not check that these are valid: from its
   point of view, [write_debug] is a no-op. *)
let write_debug =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      match inputs with
      | [Values.(Num (I32 src)); Values.(Num (I32 num_bytes))] ->
          write_debug_impl durable memories src num_bytes
      | _ -> raise Bad_input)

let store_has_name = "tezos_store_has"

let store_has_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Types.[NumType I32Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

let store_has =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      let open Lwt.Syntax in
      match inputs with
      | [Values.(Num (I32 key_offset)); Values.(Num (I32 key_length))] ->
          let* memory = retrieve_memory memories in
          let+ r =
            Aux.store_has
              ~durable:(Durable.of_storage_exn durable)
              ~memory
              ~key_offset
              ~key_length
          in
          (durable, [value r])
      | _ -> raise Bad_input)

let store_delete_name = "tezos_store_delete"

let store_delete_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Vector.of_list [Types.NumType I32Type] in
  Types.FuncType (input_types, output_types)

let store_delete =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      match inputs with
      | [Values.(Num (I32 key_offset)); Values.(Num (I32 key_length))] ->
          let open Lwt.Syntax in
          let* memory = retrieve_memory memories in
          let+ durable, code =
            Aux.store_delete
              ~durable:(Durable.of_storage_exn durable)
              ~memory
              ~key_offset
              ~key_length
          in
          (Durable.to_storage durable, [value code])
      | _ -> raise Bad_input)

let store_value_size_name = "tezos_store_value_size"

let store_value_size_type =
  let open Instance in
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Vector.of_list Types.[NumType I32Type] in
  Types.FuncType (input_types, output_types)

let store_value_size =
  let open Lwt_syntax in
  let open Values in
  Host_funcs.Host_func
    (fun _input _output durable memories inputs ->
      match inputs with
      | [Num (I32 key_offset); Num (I32 key_length)] ->
          let* memory = retrieve_memory memories in
          let+ res =
            Aux.store_value_size
              ~durable:(Durable.of_storage_exn durable)
              ~memory
              ~key_offset
              ~key_length
          in
          (durable, [value res])
      | _ -> raise Bad_input)

let store_list_size_name = "tezos_store_list_size"

let store_list_size_type =
  let open Instance in
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Types.[NumType I64Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

let store_list_size =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      let open Lwt.Syntax in
      match inputs with
      | [Values.(Num (I32 key_offset)); Values.(Num (I32 key_length))] ->
          let* memory = retrieve_memory memories in
          let+ durable, result =
            Aux.store_list_size
              ~durable:(Durable.of_storage_exn durable)
              ~memory
              ~key_offset
              ~key_length
          in
          (Durable.to_storage durable, [Values.(Num (I64 result))])
      | _ -> raise Bad_input)

let store_get_nth_key_name = "tezos_store_get_nth_key_list"

let store_get_nth_key_type =
  let input_types =
    Types.
      [
        NumType I32Type;
        NumType I32Type;
        NumType I64Type;
        NumType I32Type;
        NumType I32Type;
      ]
    |> Vector.of_list
  in
  let output_types = Types.[NumType I32Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

let store_get_nth_key =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      let open Lwt.Syntax in
      match inputs with
      | Values.
          [
            Num (I32 key_offset);
            Num (I32 key_length);
            Num (I64 index);
            Num (I32 dst);
            Num (I32 max_size);
          ] ->
          let* memory = retrieve_memory memories in
          let+ result =
            Aux.store_get_nth_key
              ~durable:(Durable.of_storage_exn durable)
              ~memory
              ~key_offset
              ~key_length
              ~index
              ~dst
              ~max_size
          in
          (durable, [value result])
      | _ -> raise Bad_input)

let store_copy_name = "tezos_store_copy"

let store_copy_type =
  let open Instance in
  let input_types =
    Types.[NumType I32Type; NumType I32Type; NumType I32Type; NumType I32Type]
    |> Vector.of_list
  in
  let output_types = Vector.of_list Types.[NumType I32Type] in
  Types.FuncType (input_types, output_types)

let store_copy =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      match inputs with
      | [
       Values.(Num (I32 from_key_offset));
       Values.(Num (I32 from_key_length));
       Values.(Num (I32 to_key_offset));
       Values.(Num (I32 to_key_length));
      ] ->
          let open Lwt.Syntax in
          let* memory = retrieve_memory memories in
          let durable = Durable.of_storage_exn durable in
          let+ durable, code =
            Aux.store_copy
              ~durable
              ~memory
              ~from_key_offset
              ~from_key_length
              ~to_key_offset
              ~to_key_length
          in
          (Durable.to_storage durable, [value code])
      | _ -> raise Bad_input)

let store_move_name = "tezos_store_move"

let store_move_type =
  let open Instance in
  let input_types =
    Types.[NumType I32Type; NumType I32Type; NumType I32Type; NumType I32Type]
    |> Vector.of_list
  in
  let output_types = Vector.of_list Types.[NumType I32Type] in
  Types.FuncType (input_types, output_types)

let store_move =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      match inputs with
      | [
       Values.(Num (I32 from_key_offset));
       Values.(Num (I32 from_key_length));
       Values.(Num (I32 to_key_offset));
       Values.(Num (I32 to_key_length));
      ] ->
          let open Lwt.Syntax in
          let* memory = retrieve_memory memories in
          let durable = Durable.of_storage_exn durable in
          let+ durable, code =
            Aux.store_move
              ~durable
              ~memory
              ~from_key_offset
              ~from_key_length
              ~to_key_offset
              ~to_key_length
          in
          (Durable.to_storage durable, [value code])
      | _ -> raise Bad_input)

let store_read_name = "tezos_store_read"

let store_read_type =
  let input_types =
    Types.
      [
        NumType I32Type;
        NumType I32Type;
        NumType I32Type;
        NumType I32Type;
        NumType I32Type;
      ]
    |> Vector.of_list
  in
  let output_types = Vector.of_list Types.[NumType I32Type] in
  Types.FuncType (input_types, output_types)

let store_read =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      match inputs with
      | [
       Values.(Num (I32 key_offset));
       Values.(Num (I32 key_length));
       Values.(Num (I32 value_offset));
       Values.(Num (I32 dest));
       Values.(Num (I32 max_bytes));
      ] ->
          let open Lwt.Syntax in
          let* memory = retrieve_memory memories in
          let+ len =
            Aux.store_read
              ~durable:(Durable.of_storage_exn durable)
              ~memory
              ~key_offset
              ~key_length
              ~value_offset
              ~dest
              ~max_bytes
          in
          (durable, [value len])
      | _ -> raise Bad_input)

let reveal_preimage_name = "tezos_reveal_preimage"

let reveal_preimage_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type; NumType I32Type; NumType I32Type]
    |> Vector.of_list
  in
  let output_types = Types.[NumType I32Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

let reveal_preimage_parse_args memories args =
  match args with
  | Values.
      [
        Num (I32 hash_addr);
        Num (I32 hash_size);
        Num (I32 base);
        Num (I32 max_bytes);
      ] ->
      let open Lwt_result_syntax in
      let*! memory = retrieve_memory memories in
      let hash_size = Int32.to_int hash_size in
      if hash_size > Aux.input_output_max_size then
        fail (Error.code Input_output_too_large)
      else
        let*! hash =
          Memory_access_interpreter.load_bytes memory hash_addr hash_size
        in
        Lwt_result.return
          (Host_funcs.(Reveal_raw_data hash), Host_funcs.{base; max_bytes})
  | _ -> raise Bad_input

let reveal_preimage = Host_funcs.Reveal_func reveal_preimage_parse_args

let reveal_metadata_name = "tezos_reveal_metadata"

let reveal_metadata_type =
  let input_types =
    Types.[NumType I32Type; NumType I32Type] |> Vector.of_list
  in
  let output_types = Types.[NumType I32Type] |> Vector.of_list in
  Types.FuncType (input_types, output_types)

(* The rollup address is a 20-byte hash. The origination level is
   a 4-byte (32bit) integer. *)
let metadata_size = Int32.add 20l 4l

let reveal_metadata_parse_args _memories args =
  match args with
  | Values.[Num (I32 base); Num (I32 max_bytes)] ->
      Lwt.return (Ok (Host_funcs.Reveal_metadata, Host_funcs.{base; max_bytes}))
  | _ -> raise Bad_input

let reveal_metadata = Host_funcs.Reveal_func reveal_metadata_parse_args

let store_write_name = "tezos_write_read"

let store_write_type =
  let input_types =
    Types.
      [
        NumType I32Type;
        NumType I32Type;
        NumType I32Type;
        NumType I32Type;
        NumType I32Type;
      ]
    |> Vector.of_list
  in
  let output_types = Vector.of_list Types.[NumType I32Type] in
  Types.FuncType (input_types, output_types)

let store_write =
  Host_funcs.Host_func
    (fun _input_buffer _output_buffer durable memories inputs ->
      match inputs with
      | [
       Values.(Num (I32 key_offset));
       Values.(Num (I32 key_length));
       Values.(Num (I32 value_offset));
       Values.(Num (I32 src));
       Values.(Num (I32 num_bytes));
      ] ->
          let open Lwt.Syntax in
          let* memory = retrieve_memory memories in
          let durable = Durable.of_storage_exn durable in
          let+ durable, code =
            Aux.store_write
              ~durable
              ~memory
              ~key_offset
              ~key_length
              ~value_offset
              ~src
              ~num_bytes
          in
          (Durable.to_storage durable, [value code])
      | _ -> raise Bad_input)

let lookup_opt name =
  match name with
  | "read_input" ->
      Some (ExternFunc (HostFunc (read_input_type, read_input_name)))
  | "write_output" ->
      Some (ExternFunc (HostFunc (write_output_type, write_output_name)))
  | "write_debug" ->
      Some (ExternFunc (HostFunc (write_debug_type, write_debug_name)))
  | "store_has" -> Some (ExternFunc (HostFunc (store_has_type, store_has_name)))
  | "store_list_size" ->
      Some (ExternFunc (HostFunc (store_list_size_type, store_list_size_name)))
  | "store_get_nth_key" ->
      Some
        (ExternFunc (HostFunc (store_get_nth_key_type, store_get_nth_key_name)))
  | "store_delete" ->
      Some (ExternFunc (HostFunc (store_delete_type, store_delete_name)))
  | "store_copy" ->
      Some (ExternFunc (HostFunc (store_copy_type, store_copy_name)))
  | "store_move" ->
      Some (ExternFunc (HostFunc (store_move_type, store_move_name)))
  | "store_value_size" ->
      Some
        (ExternFunc (HostFunc (store_value_size_type, store_value_size_name)))
  | "reveal_preimage" ->
      Some (ExternFunc (HostFunc (reveal_preimage_type, reveal_preimage_name)))
  | "reveal_metadata" ->
      Some (ExternFunc (HostFunc (reveal_metadata_type, reveal_metadata_name)))
  | "store_read" ->
      Some (ExternFunc (HostFunc (store_read_type, store_read_name)))
  | "store_write" ->
      Some (ExternFunc (HostFunc (store_write_type, store_write_name)))
  | _ -> None

let lookup name =
  match lookup_opt name with Some f -> f | None -> raise Not_found

let register_host_funcs registry =
  List.fold_left
    (fun _acc (global_name, host_function) ->
      Host_funcs.register ~global_name host_function registry)
    ()
    [
      (read_input_name, read_input);
      (write_output_name, write_output);
      (write_debug_name, write_debug);
      (store_has_name, store_has);
      (store_list_size_name, store_list_size);
      (store_get_nth_key_name, store_get_nth_key);
      (store_delete_name, store_delete);
      (store_copy_name, store_copy);
      (store_move_name, store_move);
      (store_value_size_name, store_value_size);
      (reveal_preimage_name, reveal_preimage);
      (reveal_metadata_name, reveal_metadata);
      (store_read_name, store_read);
      (store_write_name, store_write);
    ]

let all =
  let registry = Host_funcs.empty () in
  register_host_funcs registry ;
  registry

module Internal_for_tests = struct
  let metadata_size = Int32.to_int metadata_size

  let write_output = Func.HostFunc (write_output_type, write_output_name)

  let read_input = Func.HostFunc (read_input_type, read_input_name)

  let store_has = Func.HostFunc (store_has_type, store_has_name)

  let store_delete = Func.HostFunc (store_delete_type, store_delete_name)

  let store_copy = Func.HostFunc (store_copy_type, store_copy_name)

  let store_move = Func.HostFunc (store_move_type, store_move_name)

  let store_read = Func.HostFunc (store_read_type, store_read_name)

  let store_write = Func.HostFunc (store_write_type, store_write_name)

  let store_value_size =
    Func.HostFunc (store_value_size_type, store_value_size_name)

  let store_list_size =
    Func.HostFunc (store_list_size_type, store_list_size_name)

  let store_get_nth_key =
    Func.HostFunc (store_get_nth_key_type, store_get_nth_key_name)
end
