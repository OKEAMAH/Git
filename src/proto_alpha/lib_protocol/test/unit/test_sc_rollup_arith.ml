(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(** Testing
    -------
    Component:  Protocol (saturated arithmetic)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                -- test "^\[Unit\] sc rollup arith$"
    Subject:    Basic testing of the arithmetic rollup example
*)

open Protocol
module Context_binary = Tezos_context_memory.Context_binary

(* We first instantiate an arithmetic PVM capable of generating proofs. *)
module Tree :
  Environment.Context.TREE
    with type t = Context_binary.t
     and type tree = Context_binary.tree
     and type key = string list
     and type value = bytes = struct
  type t = Context_binary.t

  type tree = Context_binary.tree

  type key = Context_binary.key

  type value = Context_binary.value

  include Context_binary.Tree
end

module Arith_Context = struct
  module Tree = Tree

  type tree = Tree.tree

  let hash_tree tree =
    Sc_rollup_repr.State_hash.context_hash_to_state_hash (Tree.hash tree)

  type proof = Context_binary.Proof.tree Context_binary.Proof.t

  let proof_encoding =
    Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V2.Tree2
    .tree_proof_encoding

  let kinded_hash_to_state_hash = function
    | `Value hash | `Node hash ->
        Sc_rollup_repr.State_hash.context_hash_to_state_hash hash

  let proof_before proof =
    kinded_hash_to_state_hash proof.Context_binary.Proof.before

  let proof_after proof =
    kinded_hash_to_state_hash proof.Context_binary.Proof.after

  let produce_proof context tree step =
    let open Lwt_syntax in
    (* FIXME: With on-disk context, we cannot commit the empty
       context. Is it also true in our case? *)
    let* context = Context_binary.add_tree context [] tree in
    let* _hash = Context_binary.commit ~time:Time.Protocol.epoch context in
    let index = Context_binary.index context in
    match Context_binary.Tree.kinded_key tree with
    | Some k ->
        let* p = Context_binary.produce_tree_proof index k step in
        return (Some p)
    | None -> return None

  let verify_proof proof step =
    let open Lwt_syntax in
    let* result = Context_binary.verify_tree_proof proof step in
    match result with
    | Ok v -> return (Some v)
    | Error _ ->
        (* We skip the error analysis here since proof verification is not a
           job for the rollup node. *)
        return None
end

module FullArithPVM = Sc_rollup_arith.Make (Arith_Context)
open FullArithPVM

let setup boot_sector f =
  let open Lwt_syntax in
  let* index = Context_binary.init "/tmp" in
  let ctxt = Context_binary.empty index in
  let* state = initial_state ctxt in
  let* state = install_boot_sector state boot_sector in
  f ctxt state

let pre_boot boot_sector f =
  parse_boot_sector boot_sector |> function
  | None -> failwith "Invalid boot sector"
  | Some boot_sector -> setup boot_sector @@ f

let test_preboot () =
  [""; "1"; "1 2 +"]
  |> List.iter_es (fun boot_sector ->
         pre_boot boot_sector @@ fun _ctxt _state -> return ())

let boot boot_sector f =
  pre_boot boot_sector @@ fun ctxt state -> eval state >>= f ctxt

let test_boot () =
  let open Sc_rollup_PVM_sem in
  boot "" @@ fun _ctxt state ->
  is_input_state state >>= function
  | Initial -> return ()
  | First_after _ ->
      failwith
        "After booting, the machine should be waiting for the initial input."
  | No_input_required ->
      failwith "After booting, the machine must be waiting for input."

let make_external_inbox_message str =
  WithExceptions.Result.get_ok
    ~loc:__LOC__
    Sc_rollup_inbox_message_repr.(External str |> serialize)

let make_inbox_input message_counter payload =
  Sc_rollup_PVM_sem.{message_counter; payload}

let make_page slot_index page_index =
  let open Dal_slot_repr.Page in
  {slot_index; page_index}

let make_dal_input content page ~last_page =
  Sc_rollup_PVM_sem.{content; page; last_page}

(* [input_is_partial] should be set to true when providing DAL pages of a slot
   that are not the last one. *)
let test_input_message ?(input_is_partial = false) state raw_input =
  let open Sc_rollup_PVM_sem in
  let open Lwt_result_syntax in
  let input = {inbox_level = Raw_level_repr.root; raw_input} in
  set_input input state >>= fun state ->
  is_input_state state >>= fun input_request ->
  if input_is_partial then
    (* If [input_is_partial] is true:
       - We don't expect the state to be [No_input_required],
       - We don't call eval yet. *)
    match input_request with
    | No_input_required ->
        failwith
          "After (partially) setting an input, the rollup must still be \
           waiting for the rest of input."
    | Initial | First_after _ -> return state
  else
    (* If [input_is_partial] is false:
       - We expect the state to be [No_input_required],
       - We call eval, as the full input is supplied. *)
    match input_request with
    | Initial | First_after _ ->
        failwith
          "After setting a full input, the rollup must not be waiting for \
           input."
    | No_input_required -> (
        eval state >>= fun state ->
        is_input_state state >>= function
        | Initial | First_after _ ->
            failwith
              "After receiving a message, the rollup must not be waiting for \
               input."
        | No_input_required -> return state)

let test_inbox_input_message () =
  let open Lwt_result_syntax in
  let open Sc_rollup_PVM_sem in
  boot "" @@ fun _ctxt state ->
  let m = make_external_inbox_message "MESSAGE" in
  let* state =
    test_input_message state @@ Inbox_input (make_inbox_input Z.one m)
  in
  (* The PVM doesn't check that the message counter is in increasing order *)
  let* _state =
    test_input_message state @@ Inbox_input (make_inbox_input Z.zero m)
  in
  return ()

let test_dal_input_message () =
  let open Lwt_result_syntax in
  let open Sc_rollup_PVM_sem in
  let open Dal_slot_repr in
  boot "" @@ fun _ctxt state ->
  let i =
    make_dal_input Bytes.empty (make_page Index.zero 0) ~last_page:false
  in
  let* state = test_input_message ~input_is_partial:true state @@ Dal_input i in
  (* The PVM doesn't check that the pages positions are in increasing order *)
  let i = make_dal_input Bytes.empty (make_page Index.zero 0) ~last_page:true in
  let* _state = test_input_message state @@ Dal_input i in
  return ()

let go ~max_steps target_status state =
  let rec aux i state =
    pp state >>= fun pp ->
    Format.eprintf "%a" pp () ;
    if i > max_steps then
      failwith "Maximum number of steps reached before target status."
    else
      get_status state >>= fun current_status ->
      if target_status = current_status then return state
      else eval state >>= aux (i + 1)
  in
  aux 0 state

(* This function allows to call set_input on a list of raw_inputs. It's
   mainly usefull to feed a list of DL pages composing a slot to the PVM. *)
let set_raw_inputs state inbox_level input =
  let open Sc_rollup_PVM_sem in
  match input with
  | `Inbox i -> set_input {inbox_level; raw_input = Inbox_input i} state
  | `Slot pages ->
      let rec aux state pages =
        match pages with
        | [] -> Lwt.return state
        | p :: l ->
            set_input {inbox_level; raw_input = Dal_input p} state
            >>= fun state -> aux state l
      in
      aux state pages

let test_parsing_message ~valid make_raw_inputs (source, expected_code) =
  boot "" @@ fun _ctxt state ->
  let inputs_list = make_raw_inputs source in
  set_raw_inputs state Raw_level_repr.root inputs_list >>= fun state ->
  eval state >>= fun state ->
  go ~max_steps:10000 Evaluating state >>=? fun state ->
  get_parsing_result state >>= fun result ->
  Assert.equal
    ~loc:__LOC__
    (Option.equal Bool.equal)
    "Unexpected parsing resutlt"
    (fun fmt r ->
      Format.fprintf
        fmt
        (match r with
        | None -> "No parsing running"
        | Some true -> "Syntax correct"
        | Some false -> "Syntax error"))
    (Some valid)
    result
  >>=? fun () ->
  if valid then
    get_code state >>= fun code ->
    Assert.equal
      ~loc:__LOC__
      (List.equal equal_instruction)
      "The parsed code is not what we expected: "
      (Format.pp_print_list pp_instruction)
      expected_code
      code
  else return ()

let syntactically_valid_messages =
  List.map
    (fun nums ->
      ( String.concat " " (List.map string_of_int nums),
        List.map (fun x -> IPush x) nums ))
    [[0]; [42]; [373]; [0; 1]; [0; 123; 42; 73; 34; 13; 31]]
  @ [
      ("1 2 +", [IPush 1; IPush 2; IAdd]);
      ( "1 2 3 +    + 3 +",
        [IPush 1; IPush 2; IPush 3; IAdd; IAdd; IPush 3; IAdd] );
      ("1 2+", [IPush 1; IPush 2; IAdd]);
      ("1 2 3++3+", [IPush 1; IPush 2; IPush 3; IAdd; IAdd; IPush 3; IAdd]);
      ("", []);
      ("1 a", [IPush 1; IStore "a"]);
    ]

let syntactically_invalid_messages =
  List.map
    (fun s -> (s, []))
    ["@"; "  @"; "  @  "; "---"; "12 +++ --"; "1a"; "a1"]

let test_parsing_messages make_raw_inputs =
  List.iter_es
    (test_parsing_message make_raw_inputs ~valid:true)
    syntactically_valid_messages
  >>=? fun () ->
  List.iter_es
    (test_parsing_message make_raw_inputs ~valid:false)
    syntactically_invalid_messages

let split_string f source =
  let len = String.length source in
  let half = len / 2 in
  let c0 = String.sub source 0 half in
  let c1 = String.sub source half (len - half) in
  (f c0, f c1)

let string_as_inbox_input source =
  `Inbox (make_inbox_input Z.zero (make_external_inbox_message source))

let string_as_two_inbox_messages ?(misorder_pages = false) source =
  let c0, c1 = split_string make_external_inbox_message source in
  let l =
    [`Inbox (make_inbox_input Z.zero c0); `Inbox (make_inbox_input Z.zero c1)]
  in
  if misorder_pages then List.rev l else l

let string_as_two_dal_pages ?(misorder_pages = false) source =
  let open Sc_rollup_PVM_sem in
  let open Dal_slot_repr in
  let c0, c1 = split_string Bytes.of_string source in
  let i0 = make_dal_input c0 (make_page Index.zero 0) ~last_page:false in
  let i1 = make_dal_input c1 (make_page Index.zero 1) ~last_page:false in
  let i0, i1 = if misorder_pages then (i1, i0) else (i0, i1) in
  let i1 = {i1 with last_page = true} in
  `Slot [i0; i1]

let string_as_two_dal_slots ?(misorder_pages = false) source =
  let open Dal_slot_repr in
  let c0, c1 = split_string Bytes.of_string source in
  let i0 = make_dal_input c0 (make_page Index.zero 0) ~last_page:true in
  let i1 = make_dal_input c1 (make_page Index.zero 0) ~last_page:true in
  let i0, i1 = if misorder_pages then (i1, i0) else (i0, i1) in
  [`Slot [i0]; `Slot [i1]]

let test_parsing_inbox_messages () = test_parsing_messages string_as_inbox_input

let test_parsing_dal_messages () = test_parsing_messages string_as_two_dal_pages

let test_parsing_misordered_dal_data () =
  let open Lwt_result_syntax in
  let message =
    ( "1 2 3++3+",
      (* This is the valid parsed AST of the message above:  *)
      [IPush 1; IPush 2; IPush 3; IAdd; IAdd; IPush 3; IAdd],
      (* But instructions are expected to be re-ordered as follows because of
         the DAL pages flip. *)
      [
        (* The supposed content of the second page (out of 2) comes first *)
        IPush 3;
        IAdd;
        IAdd;
        IPush 3;
        IAdd;
        (* The supposed content of the first page (out of 2) comes last *)
        IPush 1;
        IPush 2;
      ] )
  in
  let string_message, valid_ast, flipped_ast = message in
  let* () =
    test_parsing_message
      string_as_two_dal_pages
      ~valid:true
      (string_message, valid_ast)
  in
  test_parsing_message
    (string_as_two_dal_pages ~misorder_pages:true)
    ~valid:true
    (string_message, flipped_ast)

(* This function allows to evaluate a list of messages  at a given level.
   Each message can be an inbox message or a DAL slot (i.e. list of pages) *)
let rec eval_messages state inbox_level messages =
  match messages with
  | [] -> return state
  | m :: l ->
      set_raw_inputs state inbox_level m >>= fun state ->
      eval state >>= fun state ->
      go ~max_steps:10000 Waiting_for_input_message state >>=? fun state ->
      eval_messages state inbox_level l

let test_evaluation_message ~valid make_raw_inputs
    (boot_sector, source, expected_stack, expected_vars) =
  boot boot_sector @@ fun _ctxt state ->
  let messages = make_raw_inputs source in
  eval_messages state Raw_level_repr.root messages >>=? fun state ->
  if valid then
    get_stack state >>= fun stack ->
    Assert.equal
      ~loc:__LOC__
      (List.equal Compare.Int.equal)
      "The stack is not what we expected: "
      Format.(pp_print_list (fun fmt -> fprintf fmt "%d;@;"))
      expected_stack
      stack
    >>=? fun () ->
    List.iter_es
      (fun (x, v) ->
        get_var state x >>= function
        | None -> failwith "The variable %s cannot be found." x
        | Some v' ->
            Assert.equal
              ~loc:__LOC__
              Compare.Int.equal
              (Printf.sprintf "The variable %s has not the right value: " x)
              (fun fmt x -> Format.fprintf fmt "%d" x)
              v
              v')
      expected_vars
  else
    get_evaluation_result state >>= function
    | Some true -> failwith "This code should lead to an evaluation error."
    | None -> failwith "We should have reached the evaluation end."
    | Some false -> return ()

let valid_messages =
  [
    ("", "0", [0], []);
    ("", "1 2", [2; 1], []);
    ("", "1 2 +", [3], []);
    ("", "1 2 + 3 +", [6], []);
    ("", "1 2 + 3 + 1 1 + +", [8], []);
    ("0 ", "", [0], []);
    ("1 ", "2", [2; 1], []);
    ("1 2 ", "+", [3], []);
    ("1 2 + ", "3 +", [6], []);
    ("1 2 + ", "3 + 1 1 + +", [8], []);
    ("", "1 a", [1], [("a", 1)]);
    ("", "1 a 2 + b 3 +", [6], [("a", 1); ("b", 3)]);
    ("", "1 a 2 + b 3 + result", [6], [("a", 1); ("b", 3); ("result", 6)]);
    ("1 a ", "2 b", [2; 1], [("a", 1); ("b", 2)]);
    ("1 a ", "2 a", [2; 1], [("a", 2)]);
    ("", "1 a 2 a + a", [3], [("a", 3)]);
    ("", "1 a b", [1], [("a", 1); ("b", 1)]);
    ("1 a", "", [1], [("a", 1)]);
    ("", "1 a 2 a", [2; 1], [("a", 2)]);
  ]

let invalid_messages =
  List.map
    (fun s -> ("", s, [], []))
    ["+"; "1 +"; "1 1 + +"; "1 1 + 1 1 + + +"; "a"]

let test_evaluation_messages make_raw_inputs =
  List.iter_es
    (test_evaluation_message make_raw_inputs ~valid:true)
    valid_messages
  >>=? fun () ->
  List.iter_es
    (test_evaluation_message make_raw_inputs ~valid:false)
    invalid_messages

let test_evaluation_inbox_messages () =
  test_evaluation_messages (fun s -> [string_as_inbox_input s])

let test_evaluation_dal_messages () =
  test_evaluation_messages (fun s -> [string_as_two_dal_pages s])

let test_evaluation_misordered_dal_data () =
  (* The following test considers the state of the PVM (content of the stack
     and of saved variables) after evaluating of two examples "1 2 3 b " and
     "1 a 2 a "
     A - When these examples are provided as atomic messages (case `Inbox_message)
     B - When these examples are split into two DAL pages (case `Pages)

     -> In these two cases, we observe the same final PVM state

     C - When these examples are split into two DAL slots (case `Slots). In this case,
     D - When these examples are split into two DAL slots (case `Slots). In this case,

     -> In these two cases, we observe the same final PVM state, but the stack is
     reset when evaluating the second message/slot (following the PVM's code)

     E - When these examples are split into two DAL flipped pages
          (case `Flipped_pages)
     F - When these examples are split into two DAL flipped slots
          (case `Flipped_slots)
     G - When these examples are split into two flipped inbox messages
          (case `Flipped_inbox_messages)

     -> In these three cases, the stack is re-ordered differently, and the
        content of variables may be affected. Moreover, in case F and G
        (which are simular), the content of the stack is reset after the
        evaluation of the first slot/message.
  *)
  let messages =
    [
      ( "",
        "1 2 3 b ",
        [
          `Inbox_message ([3; 2; 1], [("b", 3)]);
          `Pages ([3; 2; 1], [("b", 3)]);
          `Inbox_messages ([3], [("b", 3)]);
          `Slots ([3], [("b", 3)]);
          `Flipped_pages ([2; 1; 3], [("b", 3)]);
          `Flipped_slots ([2; 1], [("b", 3)]);
          `Flipped_inbox_messages ([2; 1], [("b", 3)]);
        ] );
      ( "",
        "1 a 2 a ",
        [
          `Inbox_message ([2; 1], [("a", 2)]);
          `Pages ([2; 1], [("a", 2)]);
          `Inbox_messages ([2], [("a", 2)]);
          `Slots ([2], [("a", 2)]);
          `Flipped_pages ([1; 2], [("a", 1)]);
          `Flipped_slots ([1], [("a", 1)]);
          `Flipped_inbox_messages ([1], [("a", 1)]);
        ] );
    ]
  in
  let mk_test boot msg case =
    let (stack, vars), mk_messages =
      match case with
      | `Inbox_message expected -> (expected, fun s -> [string_as_inbox_input s])
      | `Inbox_messages expected ->
          (expected, fun s -> string_as_two_inbox_messages s)
      | `Pages expected -> (expected, fun s -> [string_as_two_dal_pages s])
      | `Slots expected -> (expected, fun s -> string_as_two_dal_slots s)
      | `Flipped_pages expected ->
          (expected, fun s -> [string_as_two_dal_pages ~misorder_pages:true s])
      | `Flipped_slots expected ->
          (expected, string_as_two_dal_slots ~misorder_pages:true)
      | `Flipped_inbox_messages expected ->
          (expected, string_as_two_inbox_messages ~misorder_pages:true)
    in
    test_evaluation_message mk_messages ~valid:true (boot, msg, stack, vars)
  in
  List.iter_es
    (fun (boot, msg, test_cases) -> List.iter_es (mk_test boot msg) test_cases)
    messages

let test_output_messages_proofs ~valid ~inbox_level make_raw_inputs
    (source, expected_outputs) =
  let open Lwt_result_syntax in
  boot "" @@ fun ctxt state ->
  let inputs_list = make_raw_inputs source in
  let inbox_level = Raw_level_repr.of_int32_exn (Int32.of_int inbox_level) in
  set_raw_inputs state inbox_level inputs_list >>= fun state ->
  let*! state = eval state in
  let* state = go ~max_steps:10000 Waiting_for_input_message state in
  let check_output output =
    let*! result = produce_output_proof ctxt state output in
    if valid then
      match result with
      | Ok proof ->
          let*! valid = verify_output_proof proof in
          fail_unless valid (Exn (Failure "An output proof is not valid."))
      | Error _ -> failwith "Error during proof generation"
    else
      match result with
      | Ok proof ->
          let*! proof_is_valid = verify_output_proof proof in
          fail_when
            proof_is_valid
            (Exn
               (Failure
                  (Format.asprintf
                     "A wrong output proof is valid: %s -> %a"
                     source
                     Sc_rollup_PVM_sem.pp_output
                     output)))
      | Error _ -> return ()
  in
  List.iter_es check_output expected_outputs

let make_output ~outbox_level ~message_index n =
  let open Sc_rollup_outbox_message_repr in
  let unparsed_parameters =
    Micheline.(Int (dummy_location, Z.of_int n) |> strip_locations)
  in
  let destination = Contract_hash.zero in
  let entrypoint = Entrypoint_repr.default in
  let transaction = {unparsed_parameters; destination; entrypoint} in
  let transactions = [transaction] in
  let message_index = Z.of_int message_index in
  let outbox_level = Raw_level_repr.of_int32_exn (Int32.of_int outbox_level) in
  let message = Atomic_transaction_batch {transactions} in
  Sc_rollup_PVM_sem.{outbox_level; message_index; message}

let test_valid_output_messages make_raw_inputs =
  let test inbox_level =
    let outbox_level = inbox_level in
    [
      ("1", []);
      ("1 out", [make_output ~outbox_level ~message_index:0 1]);
      ( "1 out 2 out",
        [
          make_output ~outbox_level ~message_index:0 1;
          make_output ~outbox_level ~message_index:1 2;
        ] );
      ( "1 out 1 1 + out",
        [
          make_output ~outbox_level ~message_index:0 1;
          make_output ~outbox_level ~message_index:1 2;
        ] );
      ( "1 out 1 1 + out out",
        [
          make_output ~outbox_level ~message_index:0 1;
          make_output ~outbox_level ~message_index:1 2;
          make_output ~outbox_level ~message_index:2 2;
        ] );
    ]
    |> List.iter_es
         (test_output_messages_proofs ~valid:true ~inbox_level make_raw_inputs)
  in
  (* Test for different inbox/outbox levels. *)
  List.iter_es test [0; 1; 2345]

let test_valid_inbox_output_messages () =
  test_valid_output_messages string_as_inbox_input

let test_valid_dal_output_messages () =
  test_valid_output_messages string_as_two_dal_pages

let test_invalid_output_messages make_raw_inputs =
  let inbox_level = 0 in
  let outbox_level = inbox_level in
  [
    ("1", [make_output ~outbox_level ~message_index:0 1]);
    ("1 out", [make_output ~outbox_level ~message_index:1 1]);
    ( "1 out 1 1 + out",
      [
        make_output ~outbox_level ~message_index:0 0;
        make_output ~outbox_level ~message_index:3 2;
      ] );
    ( "1 out 1 1 + out out",
      [
        make_output ~outbox_level ~message_index:0 42;
        make_output ~outbox_level ~message_index:1 32;
        make_output ~outbox_level ~message_index:2 13;
      ] );
  ]
  |> List.iter_es
       (test_output_messages_proofs ~valid:false ~inbox_level make_raw_inputs)

let test_invalid_inbox_output_messages () =
  test_invalid_output_messages string_as_inbox_input

let test_invalid_dal_output_messages () =
  test_invalid_output_messages string_as_two_dal_pages

let test_invalid_outbox_level make_raw_inputs =
  let inbox_level = 42 in
  let outbox_level = inbox_level - 1 in
  [
    ("1", []);
    ("1 out", [make_output ~outbox_level ~message_index:0 1]);
    ( "1 out 2 out",
      [
        make_output ~outbox_level ~message_index:0 1;
        make_output ~outbox_level ~message_index:1 2;
      ] );
  ]
  |> List.iter_es
       (test_output_messages_proofs ~valid:false ~inbox_level make_raw_inputs)

let test_invalid_inbox_outbox_level () =
  test_invalid_outbox_level string_as_inbox_input

let test_invalid_dal_outbox_level () =
  test_invalid_outbox_level string_as_two_dal_pages

let test_initial_state_hash_arith_pvm () =
  let open Alpha_context in
  let open Lwt_result_syntax in
  let context = Tezos_context_memory.make_empty_context () in
  let*! state = Sc_rollup_helpers.Arith_pvm.initial_state context in
  let*! hash = Sc_rollup_helpers.Arith_pvm.state_hash state in
  let expected = Sc_rollup.ArithPVM.reference_initial_state_hash in
  if Sc_rollup.State_hash.(hash = expected) then return_unit
  else
    failwith
      "incorrect hash, expected %a, got %a"
      Sc_rollup.State_hash.pp
      expected
      Sc_rollup.State_hash.pp
      hash

let tests =
  [
    Tztest.tztest "PreBoot" `Quick test_preboot;
    Tztest.tztest "Boot" `Quick test_boot;
    Tztest.tztest "Inbox input message" `Quick test_inbox_input_message;
    Tztest.tztest "Dal input message" `Quick test_dal_input_message;
    Tztest.tztest "Parsing Inbox message" `Quick test_parsing_inbox_messages;
    Tztest.tztest "Parsing Dal message" `Quick test_parsing_dal_messages;
    Tztest.tztest
      "Parsing misordered Dal data"
      `Quick
      test_parsing_misordered_dal_data;
    Tztest.tztest
      "Evaluating inbox message"
      `Quick
      test_evaluation_inbox_messages;
    Tztest.tztest "Evaluating Dal message" `Quick test_evaluation_dal_messages;
    Tztest.tztest
      "Evaluating misordered Dal data"
      `Quick
      test_evaluation_misordered_dal_data;
    Tztest.tztest
      "Valid inbox output messages"
      `Quick
      test_valid_inbox_output_messages;
    Tztest.tztest
      "Valid Dal output messages"
      `Quick
      test_valid_dal_output_messages;
    Tztest.tztest
      "Invalid inbox output messages"
      `Quick
      test_invalid_inbox_output_messages;
    Tztest.tztest
      "Invalid Dal output messages"
      `Quick
      test_invalid_dal_output_messages;
    Tztest.tztest
      "Invalid inbox outbox level"
      `Quick
      test_invalid_inbox_outbox_level;
    Tztest.tztest
      "Invalid Dal outbox level"
      `Quick
      test_invalid_dal_outbox_level;
    Tztest.tztest
      "Initial state hash for Arith"
      `Quick
      test_initial_state_hash_arith_pvm;
  ]
