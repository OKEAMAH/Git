(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.com>                        *)
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

open Protocol

let assert_ok_lwt x =
  match Lwt_main.run x with Ok x -> x | Error _ -> assert false

(** A benchmark for estimating the gas cost of
    {!Sc_rollup_costs.Constants.cost_update_num_and_size_of_messages}. This
    value is used to consume the gas cost internally in
    [Sc_rollup_storage.add_external_messages], when computing the number of
    messages and their total size in bytes to be added to an inbox.
*)

module Sc_rollup_update_num_and_size_of_messages_benchmark = struct
  let name = "Sc_rollup_update_num_and_size_of_messages"

  let info =
    "Estimating the cost of updating the number and total size of messages \
     when adding a message to a sc_rollup inbox"

  let tags = ["scoru"]

  type config = {
    max_num_messages : int;
    max_messages_size : int;
    max_new_message_size : int;
  }

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {max_num_messages; max_messages_size; max_new_message_size} ->
        (max_num_messages, max_messages_size, max_new_message_size))
      (fun (max_num_messages, max_messages_size, max_new_message_size) ->
        {max_num_messages; max_messages_size; max_new_message_size})
      (obj3
         (req "max_num_of_messages" int31)
         (req "max_messages_size" int31)
         (req "max_new_message_size" int31))

  let default_config =
    {
      max_num_messages = 100;
      max_messages_size = 1000;
      max_new_message_size = 100;
    }

  type workload = unit

  let workload_encoding = Data_encoding.unit

  let workload_to_vector () = Sparse_vec.String.of_list []

  let cost_update_num_and_size_ofmessages_model =
    Model.make
      ~conv:(fun () -> ())
      ~model:
        (Model.unknown_const2
           ~const1:Builtin_benchmarks.timer_variable
           ~const2:
             (Free_variable.of_string "cost_update_num_and_size_of_messages"))

  let models = [("scoru", cost_update_num_and_size_ofmessages_model)]

  let benchmark rng_state conf () =
    let num_messages =
      Base_samplers.sample_in_interval
        ~range:{min = 0; max = conf.max_num_messages}
        rng_state
    in
    let total_messages_size =
      Base_samplers.sample_in_interval
        ~range:{min = 0; max = conf.max_messages_size}
        rng_state
    in
    let new_message_size =
      Base_samplers.sample_in_interval
        ~range:{min = 0; max = conf.max_new_message_size}
        rng_state
    in
    let new_external_message =
      Base_samplers.uniform_string ~nbytes:new_message_size rng_state
    in
    let new_message =
      WithExceptions.Result.get_ok ~loc:__LOC__
      @@ Sc_rollup_inbox_message_repr.(
           serialize @@ External new_external_message)
    in
    let workload = () in
    let closure () =
      ignore
        (Sc_rollup_inbox_storage.Internal_for_tests
         .update_num_and_size_of_messages
           ~num_messages
           ~total_messages_size
           new_message)
    in
    Generator.Plain {workload; closure}

  let create_benchmarks ~rng_state ~bench_num config =
    List.repeat bench_num (benchmark rng_state config)

  let () =
    Registration.register_for_codegen
      name
      (Model.For_codegen cost_update_num_and_size_ofmessages_model)
end

(** A benchmark for estimating the gas cost of
    {!Sc_rollup.Inbox.add_external_messages}.

    We assume that the cost (in gas) [cost(n, l)] of adding a message of size
    [n] bytes, at level [l] since the origination of the rollup, satisfies the
    equation [cost(n) = c_0 + c_1 * n + c_2 * log(l)], where [c_0], [c_1] and
    [c_2] are the values to be benchmarked. We also assume that the cost of
    adding messages [m_0, ..., m_k] to a rollup inbox is
    [\sum_{i=0}^{k} cost(|m_i|, l)]. Thus, it suffices to estimate the cost of
    adding a single message to the inbox.
*)

module Sc_rollup_add_external_messages_benchmark = struct
  let name = "Sc_rollup_inbox_add_external_message"

  let info = "Estimating the costs of adding a single message to a rollup inbox"

  let tags = ["scoru"]

  type config = {max_length : int; max_level : int}

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {max_length; max_level} -> (max_length, max_level))
      (fun (max_length, max_level) -> {max_length; max_level})
      (obj2 (req "max_bytes" int31) (req "max_level" int31))

  let default_config = {max_length = 1 lsl 16; max_level = 255}

  type workload = {message_length : int; level : int}

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun {message_length; level} -> (message_length, level))
      (fun (message_length, level) -> {message_length; level})
      (obj2 (req "message_length" int31) (req "inbox_level" int31))

  let workload_to_vector {message_length; level} =
    Sparse_vec.String.of_list
      [
        ("message_length", float_of_int message_length);
        ("inbox_level", float_of_int level);
      ]

  let add_message_model =
    Model.make
      ~conv:(fun {message_length; level} -> (message_length, (level, ())))
      ~model:
        (Model.n_plus_logm
           ~intercept:(Free_variable.of_string "cost_add_message_intercept")
           ~linear_coeff:(Free_variable.of_string "cost_add_message_per_byte")
           ~log_coeff:(Free_variable.of_string "cost_add_message_per_level"))

  let models = [("scoru", add_message_model)]

  let benchmark rng_state conf () =
    let external_message =
      Base_samplers.string rng_state ~size:{min = 1; max = conf.max_length}
    in
    let message =
      WithExceptions.Result.get_ok ~loc:__LOC__
      @@ Sc_rollup_inbox_message_repr.(serialize @@ External external_message)
    in
    let last_level_int =
      Base_samplers.sample_in_interval
        ~range:{min = 1; max = conf.max_level}
        rng_state
    in
    let last_level =
      Raw_level_repr.of_int32_exn (Int32.of_int last_level_int)
    in
    let message_length = String.length (message :> string) in

    let new_ctxt =
      let open Lwt_result_syntax in
      let* block, _ = Context.init1 () in
      let+ b = Incremental.begin_construction block in
      let state = Incremental.validation_state b in
      let ctxt = state.ctxt in
      (* Necessary to originate rollups. *)
      let ctxt =
        Alpha_context.Origination_nonce.init ctxt Operation_hash.zero
      in
      Alpha_context.Internal_for_tests.to_raw ctxt
    in

    let ctxt_with_rollup =
      let open Lwt_result_syntax in
      let* ctxt = new_ctxt in
      let {Michelson_v1_parser.expanded; _}, _ =
        Michelson_v1_parser.parse_expression "unit"
      in
      let parameters_ty = Alpha_context.Script.lazy_expr expanded in
      let boot_sector = "" in
      let kind = Sc_rollups.Kind.Example_arith in
      let*! genesis_commitment =
        Sc_rollup_helpers.genesis_commitment_raw
          ~boot_sector
          ~origination_level:(Raw_context.current_level ctxt).level
          kind
      in
      let+ rollup, _size, _genesis_hash, ctxt =
        Lwt.map Environment.wrap_tzresult
        @@ Sc_rollup_storage.originate
             ctxt
             ~kind
             ~boot_sector
             ~parameters_ty
             ~genesis_commitment
      in
      (rollup, ctxt)
    in

    let add_message_and_increment_level ctxt rollup =
      let open Lwt_result_syntax in
      let+ inbox, _, ctxt =
        Lwt.map Environment.wrap_tzresult
        @@ Sc_rollup_inbox_storage.add_external_messages
             ctxt
             rollup
             ["CAFEBABE"]
      in
      let ctxt = Raw_context.Internal_for_tests.add_level ctxt 1 in
      (inbox, ctxt)
    in

    let prepare_benchmark_scenario () =
      let open Lwt_result_syntax in
      let rec add_messages_for_level ctxt inbox rollup =
        if Raw_level_repr.((Raw_context.current_level ctxt).level > last_level)
        then return (inbox, ctxt)
        else
          let* inbox, ctxt = add_message_and_increment_level ctxt rollup in
          add_messages_for_level ctxt inbox rollup
      in
      let* rollup, ctxt = ctxt_with_rollup in
      let*! inbox =
        Sc_rollup_inbox_repr.empty
          (Raw_context.recover ctxt)
          rollup
          (Raw_context.current_level ctxt).level
      in
      let* inbox, ctxt = add_messages_for_level ctxt inbox rollup in
      let+ messages, _ctxt =
        Lwt.return @@ Environment.wrap_tzresult
        @@ Raw_context.Sc_rollup_in_memory_inbox.current_messages ctxt rollup
      in
      (inbox, ctxt, messages)
    in

    let inbox, ctxt, current_messages =
      match Lwt_main.run @@ prepare_benchmark_scenario () with
      | Ok result -> result
      | Error _ -> assert false
    in

    let workload = {message_length; level = last_level_int} in
    let closure () =
      ignore
        (Sc_rollup_inbox_repr.add_messages_no_history
           (Raw_context.recover ctxt)
           inbox
           last_level
           [message]
           current_messages)
    in
    Generator.Plain {workload; closure}

  let create_benchmarks ~rng_state ~bench_num config =
    List.repeat bench_num (benchmark rng_state config)

  let () =
    Registration.register_for_codegen name (Model.For_codegen add_message_model)
end

(* A model to estimate [Sc_rollup_inbox_repr.hash_skip_list_cell]. *)
module Sc_rollup_inbox_repr_hash_skip_list_cell = struct
  let name = "Sc_rollup_inbox_hash_skip_list_cell"

  let info = "Estimating the costs of hashing a skip list cell"

  let tags = ["scoru"]

  open Sc_rollup_inbox_repr.Internal_for_snoop
  module Hash = Sc_rollup_inbox_repr.Hash

  type config = {max_index : int}

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {max_index} -> max_index)
      (fun max_index -> {max_index})
      (obj1 (req "max_index" int31))

  let default_config = {max_index = 1_000_000}

  type workload = {max_nb_backpointers : int}

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun {max_nb_backpointers} -> max_nb_backpointers)
      (fun max_nb_backpointers -> {max_nb_backpointers})
      (obj1 (req "max_nb_backpointers" int31))

  let workload_to_vector {max_nb_backpointers} =
    Sparse_vec.String.of_list
      [("max_nb_backpointers", float_of_int max_nb_backpointers)]

  let hash_skip_list_cell_model =
    Model.make
      ~conv:(fun {max_nb_backpointers} -> (max_nb_backpointers, ()))
      ~model:
        (Model.affine
           ~intercept:(Free_variable.of_string "cost_hash_skip_list_cell")
           ~coeff:(Free_variable.of_string "cost_hash_skip_list_cell_coef"))

  let models = [("scoru", hash_skip_list_cell_model)]

  let benchmark rng_state conf () =
    let skip_list_len =
      Base_samplers.sample_in_interval
        ~range:{min = 1; max = conf.max_index}
        rng_state
    in
    let random_hash () =
      Hash.hash_string
        [Base_samplers.string ~size:{min = 1; max = 25} rng_state]
    in
    let cell =
      let rec repeat n cell =
        if n = 0 then cell
        else
          let prev_cell = cell and prev_cell_ptr = hash_skip_list_cell cell in
          repeat
            (n - 1)
            (Skip_list.next ~prev_cell ~prev_cell_ptr (random_hash ()))
      in
      repeat skip_list_len (Skip_list.genesis (random_hash ()))
    in
    let max_nb_backpointers = Skip_list.number_of_back_pointers cell in
    let workload = {max_nb_backpointers} in
    let closure () = ignore (hash_skip_list_cell cell) in
    Generator.Plain {workload; closure}

  let create_benchmarks ~rng_state ~bench_num config =
    List.repeat bench_num (benchmark rng_state config)

  let () =
    Registration.register_for_codegen
      name
      (Model.For_codegen hash_skip_list_cell_model)
end

(* A model to estimate [Skip_list_valid_back_path ~equal_ptr:Hash.equal]
   as used in [Sc_rollup_inbox_repr]. *)
module Skip_list_valid_back_path_hash_equal = struct
  let name = "Skip_list_valid_back_path_hash_equal"

  let info =
    "Estimating the costs of validating a path in a merkelized skip list"

  let tags = ["scoru"]

  open Sc_rollup_inbox_repr.Internal_for_snoop
  module Hash = Sc_rollup_inbox_repr.Hash

  type config = {max_index : int}

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {max_index} -> max_index)
      (fun max_index -> {max_index})
      (obj1 (req "max_index" int31))

  let default_config = {max_index = 18}

  type workload = {path_len : int}

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun {path_len} -> path_len)
      (fun path_len -> {path_len})
      (obj1 (req "path_len" int31))

  let workload_to_vector {path_len} =
    Sparse_vec.String.of_list [("path_len", float_of_int path_len)]

  let skip_list_valid_back_path_hash_equal_model =
    Model.make
      ~conv:(fun {path_len; _} -> (path_len, ()))
      ~model:
        (Model.nlogn
           ~intercept:
             (Free_variable.of_string
                "cost_skip_list_valid_back_path_hash_equal")
           ~coeff:
             (Free_variable.of_string
                "cost_skip_list_valid_back_path_hash_equal_coeff"))

  let models = [("scoru", skip_list_valid_back_path_hash_equal_model)]

  let benchmark rng_state conf () =
    let skip_list_len =
      1
      lsl Base_samplers.sample_in_interval
            ~range:{min = 1; max = conf.max_index}
            rng_state
      - 1
    in
    let random_hash () =
      Hash.hash_string
        [Base_samplers.string ~size:{min = 1; max = 25} rng_state]
    in
    let genesis_cell = Skip_list.genesis (random_hash ()) in
    let cell, map =
      let rec repeat n (cell, map) =
        if n = 0 then (cell, map)
        else
          let prev_cell = cell and prev_cell_ptr = hash_skip_list_cell cell in
          let map = (prev_cell_ptr, prev_cell) :: map in
          let cell =
            Skip_list.next ~prev_cell ~prev_cell_ptr (random_hash ())
          in
          repeat (n - 1) (cell, map)
      in
      repeat skip_list_len (genesis_cell, [])
    in
    let cell_ptr = hash_skip_list_cell cell in
    let deref_of_map map =
      let map = Hash.Map.of_seq (List.to_seq @@ ((cell_ptr, cell) :: map)) in
      fun k -> Hash.Map.find k map
    in
    let deref = deref_of_map map in
    let target_index = 0 in
    let equal_ptr = Hash.equal in
    let target_ptr = hash_skip_list_cell genesis_cell in
    let path_opt = Skip_list.back_path ~deref ~cell_ptr ~target_index in
    let path =
      match path_opt with
      | None ->
          (* Absurd by construction of [cell]. *)
          assert false
      | Some path -> path
    in
    let deref =
      deref_of_map
      @@ List.map
           (fun h ->
             match deref h with
             | None ->
                 (* Impossible because the path is taken in the reachable cells from [deref]. *)
                 assert false
             | Some c -> (h, c))
           path
    in
    let workload = {path_len = 1 + List.length path} in
    let closure () =
      let open Skip_list in
      ignore (valid_back_path ~equal_ptr ~deref ~cell_ptr ~target_ptr path)
    in
    Generator.Plain {workload; closure}

  let create_benchmarks ~rng_state ~bench_num config =
    List.repeat bench_num (benchmark rng_state config)

  let () =
    Registration.register_for_codegen
      name
      (Model.For_codegen skip_list_valid_back_path_hash_equal_model)
end

(* A model to estimate [verify_proof_about_payload_and_level] as used
   in [Sc_rollup_inbox_repr]. *)
module Sc_rollup_verify_proof_about_payload_and_level = struct
  let name = "Sc_rollup_verify_proof_about_payload_and_level"

  let info =
    "Estimating the costs of verifying a proof about level tree contents"

  let tags = ["scoru"]

  module Hash = Sc_rollup_inbox_repr.Hash

  module Tree = struct
    open Tezos_context_memory.Context

    type nonrec t = t

    type nonrec tree = tree

    module Tree = struct
      include Tezos_context_memory.Context.Tree

      type nonrec t = t

      type nonrec tree = tree

      type key = string list

      type value = bytes
    end

    let commit_tree context key tree =
      let open Lwt_syntax in
      let* ctxt = Tezos_context_memory.Context.add_tree context key tree in
      let* _ = commit ~time:Time.Protocol.epoch ~message:"" ctxt in
      return ()

    let lookup_tree context hash =
      let open Lwt_syntax in
      let* _, tree =
        produce_tree_proof
          (index context)
          (`Node (Hash.to_context_hash hash))
          (fun x -> Lwt.return (x, x))
      in
      return (Some tree)

    type proof = Proof.tree Proof.t

    let verify_proof proof f =
      Lwt.map Result.to_option (verify_tree_proof proof f)

    let produce_proof context tree f =
      let open Lwt_syntax in
      let* proof =
        produce_tree_proof (index context) (`Node (Tree.hash tree)) f
      in
      return (Some proof)

    let kinded_hash_to_inbox_hash = function
      | `Value hash | `Node hash -> Hash.of_context_hash hash

    let proof_before proof = kinded_hash_to_inbox_hash proof.Proof.before

    let proof_encoding =
      Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V2.Tree32
      .tree_proof_encoding
  end

  module Op = Sc_rollup_inbox_repr.Make_hashing_scheme (Tree)
  open Op.Internal_MerkelizedOperations_for_snoop

  type config = {max_number_of_messages : int}

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {max_number_of_messages} -> max_number_of_messages)
      (fun max_number_of_messages -> {max_number_of_messages})
      (obj1 (req "max_number_of_messages" int31))

  let default_config = {max_number_of_messages = (1 lsl 16) - 1}

  type workload = {number_of_messages : int; proof : Op.P.proof; index : Z.t}

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun {number_of_messages; proof; index} ->
        (number_of_messages, proof, index))
      (fun (number_of_messages, proof, index) ->
        {number_of_messages; proof; index})
      (obj3
         (req "number_of_messages" int31)
         (req "proof" Op.P.proof_encoding)
         (req "index" Data_encoding.z))

  let workload_to_vector {number_of_messages; proof = _; index = _} =
    Sparse_vec.String.of_list
      [("number_of_messages", float_of_int number_of_messages)]

  let verify_proof_about_payload_and_level_model =
    Model.make
      ~conv:(fun {number_of_messages; _} -> (number_of_messages, ()))
      ~model:
        (Model.logn
         (* ~intercept:
          *   (Free_variable.of_string
          *      "cost_verify_proof_about_payload_and_level") *)
           ~coeff:
             (Free_variable.of_string
                "cost_verify_proof_about_payload_and_level_coeff"))

  let models = [("scoru", verify_proof_about_payload_and_level_model)]

  let benchmark rng_state conf () =
    let number_of_messages =
      Base_samplers.sample_in_interval
        ~range:{min = 1; max = conf.max_number_of_messages}
        rng_state
    in
    let ctxt =
      let open Lwt_syntax in
      Lwt_main.run
      @@ let* index = Tezos_context_memory.Context.init "foo" in
         return @@ Tezos_context_memory.Context.empty index
    in
    let index =
      Z.of_int
        (Base_samplers.sample_in_interval
           ~range:{min = 0; max = number_of_messages - 1}
           rng_state)
    in
    let proof =
      Lwt_main.run
      @@ produce_proof_about_payload_and_level ctxt number_of_messages index
      |> function
      | None -> assert false
      | Some proof -> proof
    in
    let workload = {number_of_messages; proof; index} in
    let closure () =
      Lwt_main.run @@ verify_proof_about_payload_and_level proof index
      |> fun b -> assert b
    in
    Generator.Plain {workload; closure}

  let create_benchmarks ~rng_state ~bench_num config =
    List.repeat bench_num (benchmark rng_state config)

  let () =
    Registration.register_for_codegen
      name
      (Model.For_codegen verify_proof_about_payload_and_level_model)
end

let () =
  Registration_helpers.register
    (module Sc_rollup_add_external_messages_benchmark)

let () =
  Registration_helpers.register
    (module Sc_rollup_update_num_and_size_of_messages_benchmark)

let () =
  Registration_helpers.register
    (module Sc_rollup_inbox_repr_hash_skip_list_cell)

let () =
  Registration_helpers.register (module Skip_list_valid_back_path_hash_equal)

let () =
  Registration_helpers.register
    (module Sc_rollup_verify_proof_about_payload_and_level)
