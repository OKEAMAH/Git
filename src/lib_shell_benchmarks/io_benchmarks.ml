(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2021 Nomadic Labs. <contact@nomadic-labs.com>          *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

open Benchmarks_shell
module Context = Tezos_protocol_environment.Context
module Shell_monad = Tezos_error_monad.Error_monad
module Key_map = Io_helpers.Key_map

let purpose =
  Benchmark.Other_purpose "Measuring the time to access context file system"

let ns = Namespace.make Shell_namespace.ns "io"

let ns2 s1 s2 = Namespace.(cons (cons (Shell_namespace.ns "io") s1) s2)

let fv s1 s2 = Free_variable.of_namespace (ns2 s1 s2)

let read_model ~name =
  Model.bilinear_affine
    ~name:(ns2 name "read_model")
    ~intercept:(fv name "read_latency")
    ~coeff1:(fv name "depth")
    ~coeff2:(fv name "storage_bytes_read")

let write_model ~name =
  Model.bilinear_affine
    ~name:(ns2 name "write_model")
    ~intercept:(fv name "write_latency")
    ~coeff1:(fv name "keys_written")
    ~coeff2:(fv name "storage_bytes_write")

let write_model2 ~name =
  Model.bilinear_affine
    ~name:(ns2 name "write_model")
    ~intercept:(fv name "write_latency")
    ~coeff1:(fv name "depth")
    ~coeff2:(fv name "storage_bytes_write")

module Helpers = struct
  (* Samples keys in an alphabet of [card] elements. *)
  let sample_key ~card =
    assert (card > 0) ;
    let i = string_of_int (Random.int card) in
    "key" ^ i

  let random_key rng_state ~card ~depth =
    let depth = Base_samplers.sample_in_interval rng_state ~range:depth in
    Stdlib.List.init depth (fun _ -> sample_key ~card)

  (* Initializes a context by setting random bytes for each key in the
     given [key_set]. *)
  let random_contents rng_state base_dir index context key_set commit_batch_size
      =
    let open Lwt_syntax in
    let* index, context, _ =
      Key_map.fold_lwt
        (fun path size (index, context, current_commit_batch_size) ->
          let* context =
            Io_helpers.initialize_key rng_state context path size
          in
          if current_commit_batch_size < commit_batch_size then
            Lwt.return (index, context, current_commit_batch_size + 1)
          else
            (* save and proceed with fresh diff *)
            let* context, index =
              Io_helpers.commit_and_reload base_dir index context
            in
            Lwt.return (index, context, 0))
        key_set
        (index, context, 0)
    in
    Io_helpers.commit_and_reload base_dir index context

  let random_key_set rng_state ~depth ~key_card ~insertions =
    let rec loop remaining acc =
      if remaining = 0 then acc
      else
        let key = random_key rng_state ~card:key_card ~depth in
        match Key_map.does_not_collide key acc with
        | `Key_exists | `Key_has_prefix | `Key_has_suffix -> loop remaining acc
        | `Key_does_not_collide ->
            let size = 1000 in
            let acc = Key_map.insert key size acc in
            loop (remaining - 1) acc
    in
    let initial =
      let key = random_key rng_state ~card:key_card ~depth in
      let size = 1000 in
      Key_map.insert key size Key_map.empty
    in
    loop insertions initial

  let prepare_random_context rng_state base_dir commit_batch_size keys =
    let context_hash =
      Io_helpers.assert_ok ~msg:"Io_helpers.prepare_empty_context"
      @@ Lwt_main.run (Io_helpers.prepare_empty_context base_dir)
    in
    let context, index =
      Io_helpers.load_context_from_disk base_dir context_hash
    in
    Lwt_main.run
      (let open Lwt_syntax in
      let* context, index =
        random_contents rng_state base_dir index context keys commit_batch_size
      in
      Io_helpers.commit_and_reload base_dir index context)
end

module Context_size_dependent_shared = struct
  (* ----------------------------------------------------------------------- *)
  (* Config *)

  open Base_samplers

  type config = {
    depth : range;
    storage_chunk_bytes : int;
    storage_chunks : range;
    insertions : range;
    key_card : int;
    commit_batch_size : int;
    temp_dir : string option;
  }

  (* This config creates:
     - 1 target file of at most 1MB
     - At most 65536 files of 1KB

     - Files are scattered in directories of depth 10 to 1000
     - Commit for each 10_000 file additions

     In total, 66.5MB of max file contents. Produces a context file of 2GB.
  *)
  let default_config =
    {
      depth = {min = 10; max = 1000};
      storage_chunk_bytes = 1000;
      storage_chunks = {min = 10; max = 1000};
      insertions = {min = 100; max = 65536};
      key_card = 16;
      commit_batch_size = 10_000;
      temp_dir = None;
    }

  let config_encoding =
    let open Data_encoding in
    let int = int31 in
    conv
      (fun {
             depth;
             storage_chunk_bytes;
             storage_chunks;
             insertions;
             key_card;
             commit_batch_size;
             temp_dir;
           } ->
        ( depth,
          storage_chunk_bytes,
          storage_chunks,
          insertions,
          key_card,
          commit_batch_size,
          temp_dir ))
      (fun ( depth,
             storage_chunk_bytes,
             storage_chunks,
             insertions,
             key_card,
             commit_batch_size,
             temp_dir ) ->
        {
          depth;
          storage_chunk_bytes;
          storage_chunks;
          insertions;
          key_card;
          commit_batch_size;
          temp_dir;
        })
      (obj7
         (req "depth" range_encoding)
         (req "storage_chunk_bytes" int)
         (req "storage_chunks" range_encoding)
         (req "insertions" range_encoding)
         (req "key_card" int)
         (req "commit_batch_size" int)
         (opt "temp_dir" string))

  let rec sample_accessed_key rng_state cfg keys =
    let key =
      Helpers.random_key rng_state ~card:cfg.key_card ~depth:cfg.depth
    in
    match Key_map.does_not_collide key keys with
    | `Key_exists | `Key_has_prefix | `Key_has_suffix ->
        sample_accessed_key rng_state cfg keys
    | `Key_does_not_collide ->
        let size =
          Base_samplers.sample_in_interval rng_state ~range:cfg.storage_chunks
          * cfg.storage_chunk_bytes
        in
        (key, size)

  type workload =
    | Random_context_random_access of {
        depth : int;
        storage_bytes : int;
        context_size : int;
      }

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun (Random_context_random_access {depth; storage_bytes; context_size}) ->
        (depth, storage_bytes, context_size))
      (fun (depth, storage_bytes, context_size) ->
        Random_context_random_access {depth; storage_bytes; context_size})
      (tup3 int31 int31 int31)

  let workload_to_vector = function
    | Random_context_random_access {depth; storage_bytes; context_size} ->
        let keys =
          [
            ("depth", float_of_int depth);
            ("storage_bytes", float_of_int storage_bytes);
            ("context_size", float_of_int context_size);
          ]
        in
        Sparse_vec.String.of_list keys
end

module Context_size_dependent_read_bench = struct
  (* ----------------------------------------------------------------------- *)
  (* Benchmark def *)

  let name = ns "CONTEXT_SIZE_DEPENDENT_READ"

  let info =
    "Benchmarking the read accesses with contexts of various sizes (with fixed \
     storage size except for the accessed key)"

  let tags = ["io"]

  let module_filename = __FILE__

  let purpose = purpose

  include Context_size_dependent_shared

  let create_benchmark ~rng_state cfg =
    let insertions =
      Base_samplers.sample_in_interval rng_state ~range:cfg.insertions
    in
    let keys =
      Helpers.random_key_set
        rng_state
        ~depth:cfg.depth
        ~key_card:cfg.key_card
        ~insertions
    in
    let random_key, value_size = sample_accessed_key rng_state cfg keys in
    let keys = Key_map.insert random_key value_size keys in
    Format.eprintf "preparing bench: insertions = %d@." insertions ;
    let closure context =
      match
        Lwt_main.run
          (Tezos_protocol_environment.Context.find context random_key)
      with
      | Some _ -> ()
      | None ->
          let s = String.concat "/" random_key in
          Format.eprintf "key %s not found@." s ;
          exit 1
    in
    let workload =
      Random_context_random_access
        {
          depth = List.length random_key;
          storage_bytes = value_size;
          (* context_size !=  insertions, but there should
             be a linear relationship. *)
          context_size = insertions;
        }
    in
    let with_context f =
      let base_dir =
        Filename.temp_file ?temp_dir:cfg.temp_dir (Namespace.basename name) ""
      in
      Io_helpers.prepare_base_dir base_dir ;
      let context, index =
        Helpers.prepare_random_context
          rng_state
          base_dir
          cfg.commit_batch_size
          keys
      in
      let finalizer () =
        Gc.compact () ;
        Lwt_main.run
          (let open Lwt_syntax in
          let* () = Tezos_context.Context.close index in
          Tezos_stdlib_unix.Lwt_utils_unix.remove_dir base_dir)
      in
      let result =
        try f context
        with _ ->
          finalizer () ;
          exit 1
      in
      finalizer () ;
      result
    in
    Generator.With_context {workload; closure; with_context}

  let group = Benchmark.Group "io"

  let model =
    Model.make
      ~conv:(function
        | Random_context_random_access {depth; storage_bytes; _} ->
            (depth, (storage_bytes, ())))
      ~model:(read_model ~name:"context_dependent")
end

let () = Registration.register_simple (module Context_size_dependent_read_bench)

module Context_size_dependent_write_bench = struct
  include Context_size_dependent_shared

  (* ----------------------------------------------------------------------- *)
  (* Benchmark def *)

  let name = ns "CONTEXT_SIZE_DEPENDENT_WRITE"

  let info =
    "Benchmarking the write accesses with contexts of various sizes (with \
     fixed storage size except for the written key)"

  let module_filename = __FILE__

  let purpose = purpose

  let tags = ["io"]

  let write_storage context key bytes =
    Lwt_main.run (Tezos_protocol_environment.Context.add context key bytes)

  let group = Benchmark.Group "io"

  let model =
    Model.make
      ~conv:(function
        | Random_context_random_access {depth; storage_bytes; _} ->
            (depth, (storage_bytes, ())))
      ~model:(write_model ~name:"context_dependent")

  let create_benchmark ~rng_state cfg =
    let insertions =
      Base_samplers.sample_in_interval rng_state ~range:cfg.insertions
    in
    let keys =
      Helpers.random_key_set
        rng_state
        ~depth:cfg.depth
        ~key_card:cfg.key_card
        ~insertions
    in
    let random_key, value_size = sample_accessed_key rng_state cfg keys in
    Format.eprintf "preparing bench: insertions = %d@." insertions ;
    let closure context =
      Lwt_main.run
        (let open Lwt_syntax in
        let* _ = Io_helpers.commit context in
        Lwt.return_unit)
    in
    let workload =
      Random_context_random_access
        {
          depth = List.length random_key;
          storage_bytes = value_size;
          (* context_size !=  insertions, but there should
             be a linear relationship. *)
          context_size = insertions;
        }
    in
    let with_context f =
      let base_dir =
        Filename.temp_file ?temp_dir:cfg.temp_dir (Namespace.basename name) ""
      in
      Io_helpers.prepare_base_dir base_dir ;
      let context, index =
        Helpers.prepare_random_context
          rng_state
          base_dir
          cfg.commit_batch_size
          keys
      in
      let bytes = Base_samplers.uniform_bytes rng_state ~nbytes:value_size in
      let context = write_storage context random_key bytes in
      let finalizer () =
        Gc.compact () ;
        Lwt_main.run
          (let open Lwt_syntax in
          let* () = Tezos_context.Context.close index in
          Tezos_stdlib_unix.Lwt_utils_unix.remove_dir base_dir)
      in
      let result =
        try f context
        with _ ->
          finalizer () ;
          exit 1
      in
      finalizer () ;
      result
    in
    Generator.With_context {workload; closure; with_context}
end

let () =
  Registration.register_simple (module Context_size_dependent_write_bench)

module Irmin_pack_shared = struct
  open Base_samplers

  type config = {
    depth : range;
    insertions : range;
    key_card : int;
    irmin_pack_max_width : int;
    storage_chunk_bytes : int;
    storage_chunks : range;
    default_storage_bytes : int;
    commit_batch_size : int;
    temp_dir : string option;
  }

  let config_encoding =
    let open Data_encoding in
    let int = int31 in
    conv
      (fun {
             depth;
             insertions;
             key_card;
             irmin_pack_max_width;
             storage_chunk_bytes;
             storage_chunks;
             default_storage_bytes;
             commit_batch_size;
             temp_dir;
           } ->
        ( depth,
          insertions,
          key_card,
          irmin_pack_max_width,
          storage_chunk_bytes,
          storage_chunks,
          default_storage_bytes,
          commit_batch_size,
          temp_dir ))
      (fun ( depth,
             insertions,
             key_card,
             irmin_pack_max_width,
             storage_chunk_bytes,
             storage_chunks,
             default_storage_bytes,
             commit_batch_size,
             temp_dir ) ->
        {
          depth;
          insertions;
          key_card;
          irmin_pack_max_width;
          storage_chunk_bytes;
          storage_chunks;
          default_storage_bytes;
          commit_batch_size;
          temp_dir;
        })
      (obj9
         (req "depth" range_encoding)
         (req "insertions" range_encoding)
         (req "key_card" int)
         (req "irmin_pack_max_width" int)
         (req "storage_chunk_bytes" int)
         (req "storage_chunks" range_encoding)
         (req "default_storage_bytes" int)
         (req "commit_batch_size" int)
         (opt "temp_dir" string))

  (* This config creates:
     - 1 big directory with [256, 8192] items
       - 1 of the item of the big directory is the target file of at most 50KB
       - The other files in the big directory have 1KB each.
     - and at most 65536 files of 1KB each

     - Files and the big directory are scattered in directories of depth 3 to 30.
     - Commit for each 10_000 file additions

     In total, out 73.85MB of file contents. Produces a context file around 2.2GB.
  *)
  let default_config =
    {
      depth = {min = 3; max = 30};
      insertions = {min = 100; max = 65536};
      key_card = 64;
      irmin_pack_max_width = 8192;
      storage_chunk_bytes = 1000;
      storage_chunks = {min = 1; max = 50};
      default_storage_bytes = 1000;
      commit_batch_size = 10_000;
      temp_dir = None;
    }

  let rec sample_irmin_directory_key rng_state (cfg : config) keys =
    let key =
      Helpers.random_key rng_state ~card:cfg.key_card ~depth:cfg.depth
    in
    match Key_map.does_not_collide key keys with
    | `Key_exists | `Key_has_prefix | `Key_has_suffix ->
        sample_irmin_directory_key rng_state cfg keys
    | `Key_does_not_collide -> key

  let irmin_pack_key i = "pack_" ^ string_of_int i

  let sample_irmin_directory rng_state ~cfg ~key_set =
    if cfg.irmin_pack_max_width < 256 then
      Stdlib.failwith
        "Irmin_pack_read_bench: irmin_pack_max_width < 256, invalid \
         configuration"
    else
      let prefix = sample_irmin_directory_key rng_state cfg key_set in
      let dir_width =
        Base_samplers.sample_in_interval
          rng_state
          ~range:{min = 256; max = cfg.irmin_pack_max_width}
      in
      let files_under_big_directory =
        Array.init dir_width (fun i -> prefix @ [irmin_pack_key i])
      in
      (prefix, files_under_big_directory)
end

module Irmin_pack_read_bench = struct
  include Irmin_pack_shared

  let prepare_irmin_directory rng_state ~cfg ~key_set =
    if cfg.irmin_pack_max_width < 256 then
      Stdlib.failwith
        "Irmin_pack_read_bench: irmin_pack_max_width < 256, invalid \
         configuration"
    else
      let _prefix, files_under_big_directory =
        sample_irmin_directory rng_state ~cfg ~key_set
      in
      let dir_width = Array.length files_under_big_directory in
      let target_index = Random.int dir_width in
      let target_key = files_under_big_directory.(target_index) in
      let value_size =
        Base_samplers.sample_in_interval rng_state ~range:cfg.storage_chunks
        * cfg.storage_chunk_bytes
      in
      let key_set =
        let acc = ref key_set in
        Array.iteri
          (fun index key ->
            if index = target_index then
              acc := Key_map.insert key value_size !acc
            else acc := Key_map.insert key cfg.default_storage_bytes !acc)
          files_under_big_directory ;
        !acc
      in
      (target_key, value_size, key_set, files_under_big_directory)

  let name = ns "IRMIN_PACK_READ"

  let info = "Benchmarking read accesses in irmin-pack directories"

  let module_filename = __FILE__

  let purpose = purpose

  let tags = ["io"]

  type workload =
    | Irmin_pack_read of {
        depth : int;
        irmin_width : int;
        storage_bytes : int;
        context_size : int;
      }

  let workload_to_vector = function
    | Irmin_pack_read {depth; irmin_width; storage_bytes; context_size} ->
        let keys =
          [
            ("depth", float_of_int depth);
            ("irmin_width", float_of_int irmin_width);
            ("storage_bytes", float_of_int storage_bytes);
            ("context_size", float_of_int context_size);
          ]
        in
        Sparse_vec.String.of_list keys

  let model =
    Model.make
      ~conv:(function
        | Irmin_pack_read {depth; storage_bytes; _} ->
            (depth, (storage_bytes, ())))
      ~model:(read_model ~name:"irmin")

  let group = Benchmark.Group "io"

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun (Irmin_pack_read {depth; irmin_width; storage_bytes; context_size}) ->
        (depth, irmin_width, storage_bytes, context_size))
      (fun (depth, irmin_width, storage_bytes, context_size) ->
        Irmin_pack_read {depth; irmin_width; storage_bytes; context_size})
      (tup4 int31 int31 int31 int31)

  let create_benchmark ~rng_state (cfg : config) =
    let insertions =
      Base_samplers.sample_in_interval rng_state ~range:cfg.insertions
    in
    let keys =
      Helpers.random_key_set
        rng_state
        ~depth:cfg.depth
        ~key_card:cfg.key_card
        ~insertions
    in
    let target_key, value_size, keys, irmin_pack_paths =
      prepare_irmin_directory rng_state ~cfg ~key_set:keys
    in
    let irmin_width = Array.length irmin_pack_paths in
    let stats = Io_stats.tree_statistics keys in
    Format.eprintf
      "preparing bench: insertions = %d, stats = %a@."
      (insertions + irmin_width)
      Io_stats.pp
      stats ;
    let closure context =
      match Lwt_main.run (Context.find context target_key) with
      | Some _ -> ()
      | None ->
          let s = String.concat "/" target_key in
          Format.eprintf "key %s not found@." s ;
          exit 1
    in
    let workload =
      Irmin_pack_read
        {
          depth = List.length target_key;
          irmin_width;
          storage_bytes = value_size;
          context_size = stats.total;
        }
    in
    let with_context f =
      let base_dir =
        Filename.temp_file ?temp_dir:cfg.temp_dir (Namespace.basename name) ""
      in
      Io_helpers.prepare_base_dir base_dir ;
      let context, index =
        Helpers.prepare_random_context
          rng_state
          base_dir
          cfg.commit_batch_size
          keys
      in
      let finalizer () =
        Gc.compact () ;
        Lwt_main.run
          (let open Lwt_syntax in
          let* () = Tezos_context.Context.close index in
          Tezos_stdlib_unix.Lwt_utils_unix.remove_dir base_dir)
      in
      let result =
        try f context
        with _ ->
          finalizer () ;
          exit 1
      in
      finalizer () ;
      result
    in
    Generator.With_context {workload; closure; with_context}
end

let () = Registration.register_simple (module Irmin_pack_read_bench)

module Irmin_pack_write_bench = struct
  include Irmin_pack_shared

  let prepare_irmin_directory rng_state ~cfg ~key_set ~bench_init =
    if cfg.irmin_pack_max_width < 256 then
      Stdlib.failwith
        "Irmin_pack_read_bench: irmin_pack_max_width < 256, invalid \
         configuration"
    else
      let _prefix, directories =
        sample_irmin_directory rng_state ~cfg ~key_set
      in
      let total_keys_in_pack = Array.length directories in
      let number_of_keys_written = Random.int total_keys_in_pack in
      let keys_written_to, keys_not_written_to =
        Io_helpers.sample_without_replacement
          number_of_keys_written
          (Array.to_list directories)
      in
      let key_set =
        (* Initialize keys not written to with random bytes of fixed size *)
        List.fold_left
          (fun key_set key ->
            Key_map.insert key cfg.default_storage_bytes key_set)
          key_set
          keys_not_written_to
      in
      let key_set =
        if bench_init then
          (* If we wish to benchmark writing to fresh keys, we should not
             add the keys written to in the initial context *)
          key_set
        else
          (* Else, if we wish to benchmark overwriting existing keys,
             we initialize them to bytes of fixed size. *)
          List.fold_left
            (fun key_set key ->
              Key_map.insert key cfg.default_storage_bytes key_set)
            key_set
            keys_written_to
      in
      ( number_of_keys_written,
        keys_written_to,
        keys_not_written_to,
        key_set,
        total_keys_in_pack )

  let name = ns "IRMIN_PACK_WRITE"

  let info = "Benchmarking write accesses in irmin-pack directories"

  let module_filename = __FILE__

  let purpose = purpose

  let tags = ["io"]

  type workload =
    | Irmin_pack_write of {
        keys_written : int;
        irmin_width : int;
        storage_bytes : int;
        context_size : int;
      }

  let workload_encoding =
    let open Data_encoding in
    conv
      (fun (Irmin_pack_write
             {keys_written; irmin_width; storage_bytes; context_size}) ->
        (keys_written, irmin_width, storage_bytes, context_size))
      (fun (keys_written, irmin_width, storage_bytes, context_size) ->
        Irmin_pack_write
          {keys_written; irmin_width; storage_bytes; context_size})
      (tup4 int31 int31 int31 int31)

  let workload_to_vector = function
    | Irmin_pack_write {keys_written; irmin_width; storage_bytes; context_size}
      ->
        let keys =
          [
            ("keys_written", float_of_int keys_written);
            ("irmin_width", float_of_int irmin_width);
            ("storage_bytes", float_of_int storage_bytes);
            ("context_size", float_of_int context_size);
          ]
        in
        Sparse_vec.String.of_list keys

  let model =
    Model.make
      ~conv:(function
        | Irmin_pack_write {keys_written; storage_bytes; _} ->
            (keys_written, (storage_bytes, ())))
      ~model:(write_model ~name:"irmin")

  let group = Benchmark.Group "io"

  let write_storage context key bytes =
    Lwt_main.run (Context.add context key bytes)

  let create_benchmark ~rng_state (cfg : config) =
    let insertions =
      Base_samplers.sample_in_interval rng_state ~range:cfg.insertions
    in
    let keys =
      Helpers.random_key_set
        rng_state
        ~depth:cfg.depth
        ~key_card:cfg.key_card
        ~insertions
    in
    let ( number_of_keys_written,
          keys_written_to,
          _keys_not_written_to,
          key_set,
          total_keys_in_pack ) =
      prepare_irmin_directory rng_state ~cfg ~key_set:keys ~bench_init:true
    in
    let stats = Io_stats.tree_statistics keys in
    Format.eprintf
      "preparing bench: insertions = %d, stats = %a@."
      (insertions + total_keys_in_pack)
      Io_stats.pp
      stats ;
    let base_dir =
      Filename.temp_file ?temp_dir:cfg.temp_dir (Namespace.basename name) ""
    in
    let value_size =
      Base_samplers.sample_in_interval rng_state ~range:cfg.storage_chunks
      * cfg.storage_chunk_bytes
    in
    let with_context f =
      Io_helpers.prepare_base_dir base_dir ;
      let context, index =
        Helpers.prepare_random_context
          rng_state
          base_dir
          cfg.commit_batch_size
          key_set
      in
      let context =
        List.fold_left
          (fun context key ->
            let bytes =
              Base_samplers.uniform_bytes rng_state ~nbytes:value_size
            in
            write_storage context key bytes)
          context
          keys_written_to
      in
      let finalizer () =
        Gc.compact () ;
        Lwt_main.run
          (let open Lwt_syntax in
          let* () = Tezos_context.Context.close index in
          Tezos_stdlib_unix.Lwt_utils_unix.remove_dir base_dir)
      in
      let result =
        try f context
        with _ ->
          finalizer () ;
          exit 1
      in
      finalizer () ;
      result
    in
    let closure context =
      Lwt_main.run
        (let open Lwt_syntax in
        let* _ = Io_helpers.commit context in
        Lwt.return_unit)
    in
    let workload =
      Irmin_pack_write
        {
          keys_written = number_of_keys_written;
          irmin_width = total_keys_in_pack;
          storage_bytes = value_size;
          context_size = stats.total;
        }
    in
    Generator.With_context {workload; closure; with_context}
end

let () = Registration.register_simple (module Irmin_pack_write_bench)

module Read_random_key_bench = struct
  type config = {
    existing_context : string * Context_hash.t;
    subdirectory : string;
  }

  let default_config =
    {
      existing_context = ("/no/such/directory", Context_hash.zero);
      subdirectory = "/no/such/key";
    }

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {existing_context; subdirectory} -> (existing_context, subdirectory))
      (fun (existing_context, subdirectory) -> {existing_context; subdirectory})
      (obj2
         (req "existing_context" (tup2 string Context_hash.encoding))
         (req "subdirectory" string))

  let name = ns "READ_RANDOM_KEY"

  let info = "Benchmarking random read accesses in a subdirectory"

  let module_filename = __FILE__

  let purpose = purpose

  let tags = ["io"]

  type workload = Read_random_key of {depth : int; storage_bytes : int}

  let workload_encoding =
    let open Data_encoding in
    conv
      (function
        | Read_random_key {depth; storage_bytes} -> (depth, storage_bytes))
      (fun (depth, storage_bytes) -> Read_random_key {depth; storage_bytes})
      (tup2 int31 int31)

  let workload_to_vector = function
    | Read_random_key {depth; storage_bytes} ->
        let keys =
          [
            ("depth", float_of_int depth);
            ("storage_bytes", float_of_int storage_bytes);
          ]
        in
        Sparse_vec.String.of_list keys

  let group = Benchmark.Group "io"

  let model =
    Model.make
      ~conv:(function
        | Read_random_key {depth; storage_bytes} -> (depth, (storage_bytes, ())))
      ~model:(read_model ~name:"random")

  let make_bench rng_state config keys () =
    let card = Array.length keys in
    assert (card > 0) ;
    let key, value_size = keys.(Random.State.int rng_state card) in
    let with_context f =
      let context, index =
        let base_dir, context_hash = config.existing_context in
        Io_helpers.load_context_from_disk base_dir context_hash
      in
      let finalizer () =
        Gc.compact () ;
        Lwt_main.run (Tezos_context.Context.close index)
      in
      let result =
        try f context
        with _ ->
          finalizer () ;
          exit 1
      in
      finalizer () ;
      result
    in
    let closure context =
      match Lwt_main.run (Context.find context key) with
      | Some _ -> ()
      | None ->
          let s = String.concat "/" key in
          Format.eprintf "key %s not found@." s ;
          exit 1
    in
    let workload =
      Read_random_key {depth = List.length key; storage_bytes = value_size}
    in
    Generator.With_context {workload; closure; with_context}

  let create_benchmarks ~rng_state ~bench_num config =
    let base_dir, context_hash = config.existing_context in
    (* files under [config.subdirectory] *)
    let tree =
      Io_helpers.with_context ~base_dir ~context_hash (fun context ->
          Io_stats.load_tree context
          @@ Option.value_f ~default:(fun () ->
                 Stdlib.failwith
                   "io/READ_RANDOM_KEY: invalid config subdirectory")
          @@ Io_helpers.split_absolute_path config.subdirectory)
    in
    let keys = Array.of_seq @@ Io_helpers.Key_map.to_seq tree in
    List.repeat bench_num (make_bench rng_state config keys)
end

let () = Registration.register_simple_with_num (module Read_random_key_bench)

module Write_random_keys_bench = struct
  open Base_samplers

  type config = {
    existing_context : string * Context_hash.t;
    storage_chunk_bytes : int;
    storage_chunks : range;
    max_written_keys : int;
    temp_dir : string option;
    subdirectory : string;
  }

  let default_config =
    {
      existing_context = ("/no/such/directory", Context_hash.zero);
      storage_chunk_bytes = 1000;
      storage_chunks = {min = 1; max = 1000};
      max_written_keys = 10_000;
      temp_dir = None;
      subdirectory = "/no/such/key";
    }

  let config_encoding =
    let open Data_encoding in
    let int = int31 in
    conv
      (fun {
             existing_context;
             storage_chunk_bytes;
             storage_chunks;
             max_written_keys;
             temp_dir;
             subdirectory;
           } ->
        ( existing_context,
          storage_chunk_bytes,
          storage_chunks,
          max_written_keys,
          temp_dir,
          subdirectory ))
      (fun ( existing_context,
             storage_chunk_bytes,
             storage_chunks,
             max_written_keys,
             temp_dir,
             subdirectory ) ->
        {
          existing_context;
          storage_chunk_bytes;
          storage_chunks;
          max_written_keys;
          temp_dir;
          subdirectory;
        })
      (obj6
         (req "existing_context" (tup2 string Context_hash.encoding))
         (req "storage_chunk_bytes" int)
         (req "storage_chunks" range_encoding)
         (req "max_written_keys" int)
         (req "temp_dir" (option string))
         (req "subdirectory" string))

  let name = ns "WRITE_RANDOM_KEYS"

  let info = "Benchmarking random read accesses in a subdirectory"

  let module_filename = __FILE__

  let purpose = purpose

  let tags = ["io"]

  type workload =
    | Write_random_keys of {keys_written : int; storage_bytes : int}

  let workload_encoding =
    let open Data_encoding in
    conv
      (function
        | Write_random_keys {keys_written; storage_bytes} ->
            (keys_written, storage_bytes))
      (fun (keys_written, storage_bytes) ->
        Write_random_keys {keys_written; storage_bytes})
      (tup2 int31 int31)

  let workload_to_vector = function
    | Write_random_keys {keys_written; storage_bytes} ->
        let keys =
          [
            ("keys_written", float_of_int keys_written);
            ("storage_bytes", float_of_int storage_bytes);
          ]
        in
        Sparse_vec.String.of_list keys

  let group = Benchmark.Group "io"

  let model =
    Model.make
      ~conv:(function
        | Write_random_keys {keys_written; storage_bytes; _} ->
            (keys_written, (storage_bytes, ())))
      ~model:(write_model ~name:"random")

  let write_storage context key bytes =
    Lwt_main.run (Context.add context key bytes)

  let make_bench rng_state (cfg : config) (keys : (string list * int) list) () =
    let total_keys_under_directory = List.length keys in
    let number_of_keys_written =
      min
        total_keys_under_directory
        (Random.State.int rng_state cfg.max_written_keys)
    in
    let keys_written_to, _keys_not_written_to =
      Io_helpers.sample_without_replacement number_of_keys_written keys
    in
    let source_base_dir, context_hash = cfg.existing_context in
    let value_size =
      Base_samplers.sample_in_interval rng_state ~range:cfg.storage_chunks
      * cfg.storage_chunk_bytes
    in
    let with_context f =
      let target_base_dir =
        let temp_dir = Option.value cfg.temp_dir ~default:"/tmp" in
        Format.asprintf
          "%s/%s_%d"
          temp_dir
          (Namespace.basename name)
          (Random.int 65536)
      in
      (* copying the original context for EACH test *)
      Io_helpers.copy_rec source_base_dir target_base_dir ;
      Format.eprintf "Finished copying original context to %s@." target_base_dir ;
      let context, index =
        Io_helpers.load_context_from_disk target_base_dir context_hash
      in
      (* overwrite [keys_written_to].  The times of the writes are not measured. *)
      let context =
        List.fold_left
          (fun context (key, _) ->
            let bytes =
              Base_samplers.uniform_bytes rng_state ~nbytes:value_size
            in
            write_storage context key bytes)
          context
          keys_written_to
      in
      let finalizer () =
        Gc.compact () ;
        Lwt_main.run
          (let open Lwt_syntax in
          let* () = Tezos_context.Context.close index in
          Tezos_stdlib_unix.Lwt_utils_unix.remove_dir target_base_dir)
      in
      let result =
        try f context
        with _ ->
          finalizer () ;
          exit 1
      in
      finalizer () ;
      result
    in
    (* This only measure the time to commit *)
    let closure context =
      Lwt_main.run
        (let open Lwt_syntax in
        let* _context_hash = Io_helpers.commit context in
        Lwt.return_unit)
    in
    let workload =
      Write_random_keys
        {keys_written = number_of_keys_written; storage_bytes = value_size}
    in
    Generator.With_context {workload; closure; with_context}

  let create_benchmarks ~rng_state ~bench_num config =
    let base_dir, context_hash = config.existing_context in
    (* files under [config.subdirectory] *)
    let tree =
      Io_helpers.with_context ~base_dir ~context_hash (fun context ->
          Io_stats.load_tree context
          @@ Option.value_f ~default:(fun () ->
                 Stdlib.failwith
                   "io/WRITE_RANDOM_KEYS: invalid config subdirectory")
          @@ Io_helpers.split_absolute_path config.subdirectory)
    in
    let keys = List.of_seq @@ Io_helpers.Key_map.to_seq tree in
    List.repeat bench_num (make_bench rng_state config keys)
end

let () = Registration.register_simple_with_num (module Write_random_keys_bench)

(* To avoid long time (≒ 20mins) to traverse the tree, we have a cache file
   [<base_dir>/<context_hash>.txt] lodable in 3mins *)
let build_key_list base_dir context_hash =
  let open Lwt.Syntax in
  let fn_cache =
    Filename.concat
      base_dir
      (Format.asprintf "%a.txt" Context_hash.pp context_hash)
  in
  if Sys.file_exists fn_cache then Lwt.return fn_cache
  else
    let oc = open_out fn_cache in
    Format.eprintf "Loading the trees of %a@." Context_hash.pp context_hash ;
    let+ () =
      Io_stats.fold_tree base_dir context_hash [] () @@ fun () key tree ->
      let+ o = Context.Tree.to_value tree in
      match o with
      | Some bytes ->
          let len = Bytes.length bytes in
          output_string
            oc
            (Printf.sprintf "%s %d\n" (String.concat "/" key) len)
      | None -> ()
    in
    output_string oc "END OF LIST\n" ;
    close_out oc ;
    fn_cache

let fold_tree base_dir context_hash init f =
  let fn_cache = Lwt_main.run @@ build_key_list base_dir context_hash in
  Format.eprintf
    "Loading the cached trees of %a at %s@."
    Context_hash.pp
    context_hash
    fn_cache ;
  let tbl = Stdlib.Hashtbl.create 1024 in
  let ic = open_in fn_cache in
  let rec loop acc =
    match input_line ic with
    | "END OF LIST" ->
        close_in ic ;
        acc
    | l -> (
        match String.split ' ' ~limit:2 l with
        | [k; n] ->
            let ks =
              let ks = String.split '/' k in
              (* hashcons for shorter strings *)
              List.map
                (fun k ->
                  if String.length k > 12 then k
                  else
                    match Stdlib.Hashtbl.find_opt tbl k with
                    | Some k -> k
                    | None ->
                        Stdlib.Hashtbl.add tbl k k ;
                        k)
                ks
            in
            loop (f acc (ks, int_of_string n))
        | _ -> Stdlib.failwith (Printf.sprintf "Broken file list: %s" fn_cache))
  in
  loop init

(* Get 1_000_000+ random keys from the context.
   The files over 4096 bytes (= 1 disk block) are always listed. *)
let get_sample_keys ~rng base_dir context_hash =
  let depths_tbl = Stdlib.Hashtbl.create 101 in
  let blocks_tbl = Stdlib.Hashtbl.create 101 in
  let nkeys =
    fold_tree base_dir context_hash 0 (fun nkeys (key, size) ->
        let depth = List.length key in
        let n =
          Option.value ~default:0 @@ Stdlib.Hashtbl.find_opt depths_tbl depth
        in
        Stdlib.Hashtbl.replace depths_tbl depth (n + 1) ;

        let blocks = (size + 4095) / 4096 in
        let n =
          Option.value ~default:0 @@ Stdlib.Hashtbl.find_opt blocks_tbl blocks
        in
        Stdlib.Hashtbl.replace blocks_tbl blocks (n + 1) ;

        nkeys + 1)
  in
  Format.eprintf "Got %d keys@." nkeys ;

  List.iter (fun (depth, n) -> Format.eprintf "Depth %d: %d@." depth n)
  @@ List.sort (fun (k1, _) (k2, _) -> Int.compare k1 k2)
  @@ List.of_seq
  @@ Stdlib.Hashtbl.to_seq depths_tbl ;

  List.iter (fun (blocks, n) -> Format.eprintf "Blocks %d: %d@." blocks n)
  @@ List.sort (fun (k1, _) (k2, _) -> Int.compare k1 k2)
  @@ List.of_seq
  @@ Stdlib.Hashtbl.to_seq blocks_tbl ;

  let nsamples = 1_000_000 in

  let normals, rares =
    let normals, rares =
      fold_tree base_dir context_hash ([], []) (fun (acc, rares) (key, size) ->
          let depth = List.length key in
          if
            size > 4096 (* Big files are rare, so we keep all of them. *)
            || depth <= 3 (* Shallow files are rare, so we keep all of them. *)
          then (acc, (key, size) :: rares)
          else if Random.State.int rng nkeys < nsamples then
            ((key, size) :: acc, rares)
          else (acc, rares))
    in
    (Array.of_list normals, Array.of_list rares)
  in
  Format.eprintf
    "Got %d normal keys and %d rare)keys after filtering@."
    (Array.length normals)
    (Array.length rares) ;
  (normals, rares)

module Shared = struct
  let purpose = purpose

  let tags = ["io"]

  let group = Benchmark.Group "io"

  type config = {
    existing_context : string * Context_hash.t;
    subdirectory : string;
    memoryAvailable : float;
    runs : int;
  }

  let default_config =
    {
      existing_context = ("/no/such/directory", Context_hash.zero);
      subdirectory = "/no/such/key";
      memoryAvailable = 6.0;
      runs = 0;
    }

  let config_encoding =
    let open Data_encoding in
    conv
      (fun {existing_context; subdirectory; memoryAvailable; runs} ->
        (existing_context, subdirectory, memoryAvailable, runs))
      (fun (existing_context, subdirectory, memoryAvailable, runs) ->
        {existing_context; subdirectory; memoryAvailable; runs})
      (obj4
         (req "existing_context" (tup2 string Context_hash.encoding))
         (req "subdirectory" string)
         (req "memoryAvailable" float)
         (req "runs" int31))

  type workload = Key of {depth : int; storage_bytes : int}

  let workload_encoding =
    let open Data_encoding in
    conv
      (function Key {depth; storage_bytes} -> (depth, storage_bytes))
      (fun (depth, storage_bytes) -> Key {depth; storage_bytes})
      (tup2 int31 int31)

  let workload_to_vector = function
    | Key {depth; storage_bytes} ->
        let keys =
          [
            ("depth", float_of_int depth);
            ("storage_bytes", float_of_int storage_bytes);
          ]
        in
        Sparse_vec.String.of_list keys

  (* Load the measurements and build the data for [Measure] *)
  let recover_measurements fn =
    (* Recover the measurements *)
    let tbl = Stdlib.Hashtbl.create 1023 in

    let ic = open_in_bin fn in
    let rec loop () =
      match input_value ic with
      | exception End_of_file -> close_in ic
      | depth, value_size, nsecs ->
          let n = (value_size + 255) / 256 * 256 in
          (match Stdlib.Hashtbl.find_opt tbl (depth, n) with
          | None -> Stdlib.Hashtbl.replace tbl (depth, n) [nsecs]
          | Some nsecs_list ->
              Stdlib.Hashtbl.replace tbl (depth, n) (nsecs :: nsecs_list)) ;
          loop ()
    in
    loop () ;

    (* medians *)
    let median xs =
      let a = Array.of_list xs in
      Array.sort Float.compare a ;
      a.(Array.length a / 2)
    in

    Stdlib.Hashtbl.fold
      (fun (depth, n) nsecs_list acc ->
        let median = median nsecs_list in
        let workload = Key {depth; storage_bytes = n} in
        (fun () ->
          Generator.Calculated {workload; measure = (fun () -> median)})
        :: acc)
      tbl
      []
end

module Read_bench = struct
  include Shared

  let default_config = {default_config with runs = 200_000}

  let name = ns "READ"

  let info = "Benchmarking random read accesses"

  let module_filename = __FILE__

  let model =
    Model.make
      ~conv:(function
        | Key {depth; storage_bytes} ->
            (* Shift depth so that it starts from 0 *)
            (depth - 1, (storage_bytes, ())))
      ~model:(read_model ~name:"random_read")

  (* - Use existing context.  Mainnet context just before a GC is preferable.
     - Restrict the available memory about to 4 GiB, to emulate an 8 GiB machine
     - Random accesses to the context to use 3.5 GiB of the available memory for the disk cache.
     - Random accesses for the benchmark

     It ignores [bench_num].
  *)
  let create_benchmarks ~rng_state ~bench_num:_ config =
    let base_dir, context_hash = config.existing_context in

    (* We sample keys in the context ,since we cannot carry the all *)
    let normal_keys, rare_keys =
      get_sample_keys ~rng:rng_state base_dir context_hash
    in
    let n_normal_keys = Array.length normal_keys in
    let n_rare_keys = Array.length rare_keys in

    (* Actual benchmarks.  During benchmarking, we avoid new allocations
       as possible: the obtained measurements are stored in a temp file. *)
    let fn = Filename.temp_file "snoop_io_" ".data" in
    let oc = open_out_bin fn in

    (* Dummies must be kept until the end of the benchmark *)
    Io_helpers.with_memory_restriction
      config.memoryAvailable
      (fun restrict_memory ->
        restrict_memory () ;
        Io_helpers.purge_disk_cache () ;
        Io_helpers.with_context ~base_dir ~context_hash (fun context ->
            Io_helpers.fill_disk_cache
              ~rng:rng_state
              ~restrict_memory
              context
              [normal_keys; rare_keys]) ;
        restrict_memory () ;
        Lwt_main.run
          (let open Lwt.Syntax in
          let* context, index =
            Io_helpers.load_context_from_disk_lwt base_dir context_hash
          in
          let* () =
            let rec loop n =
              if n <= 0 then Lwt.return_unit
              else
                (* We need flush even for reading.
                   Otherwise the tree on memory grows forever *)
                let* context = Io_helpers.flush context in
                let key, value_size =
                  match Random.State.int rng_state 2 with
                  | 0 ->
                      let i = Random.State.int rng_state n_normal_keys in
                      normal_keys.(i)
                  | _ ->
                      let i = Random.State.int rng_state n_rare_keys in
                      rare_keys.(i)
                in
                let* nsecs, _ =
                  (* Using [Lwt_main.run] here slows down the benchmark *)
                  Measure.Time.measure_lwt (fun () -> Context.find context key)
                in
                output_value oc (List.length key, value_size, nsecs) ;
                if n mod 10000 = 0 then restrict_memory () ;
                loop (n - 1)
            in
            loop config.runs
          in
          Tezos_context.Context.close index)) ;
    close_out oc ;
    recover_measurements fn
end

let () = Registration.register_simple_with_num (module Read_bench)

module Write_bench = struct
  include Shared

  let default_config = {default_config with runs = 5_000}

  let name = ns "WRITE"

  let info = "Benchmarking random write accesses"

  let module_filename = __FILE__

  let model =
    Model.make
      ~conv:(function
        | Key {depth; storage_bytes} ->
            (* Shift depth so that it starts from 0 *)
            (depth - 1, (storage_bytes, ())))
      ~model:(write_model2 ~name:"random_write")

  (* - Use existing context.  Mainnet context just before a GC is preferable.
     - Restrict the available memory about to 4 GiB, to emulate an 8 GiB machine
     - Random accesses to the context to use 3.5 GiB of the available memory for the disk cache.
     - Random accesses for the benchmark

     It ignores [bench_num].
  *)
  let create_benchmarks ~rng_state ~bench_num:_ config =
    let open Lwt.Syntax in
    let source_base_dir, context_hash = config.existing_context in

    (* Copy the context dir *)
    let base_dir = source_base_dir ^ ".tmp" in
    let () =
      Lwt_main.run @@ Tezos_stdlib_unix.Lwt_utils_unix.remove_dir base_dir
    in
    Format.eprintf "Copying the data directory to %s@." base_dir ;
    Io_helpers.copy_rec source_base_dir base_dir ;

    let normal_keys, rare_keys =
      get_sample_keys ~rng:rng_state base_dir context_hash
    in
    let n_normal_keys = Array.length normal_keys in
    let n_rare_keys = Array.length rare_keys in

    (* Actual benchmarks.  During benchmarking, we avoid new allocations
       as possible: the obtained measurements are stored in a temp file. *)
    let fn = Filename.temp_file "snoop_io_" ".data" in
    let oc = open_out_bin fn in

    Io_helpers.with_memory_restriction
      config.memoryAvailable
      (fun restrict_memory ->
        restrict_memory () ;
        Io_helpers.purge_disk_cache () ;
        Io_helpers.with_context ~base_dir ~context_hash (fun context ->
            Io_helpers.fill_disk_cache
              ~rng:rng_state
              ~restrict_memory
              context
              [normal_keys; rare_keys]) ;
        restrict_memory () ;
        Lwt_main.run
          (let* index = Tezos_context.Context.init ~readonly:false base_dir in
           let rec loop context_hash n =
             if n <= 0 then Lwt.return_unit
             else
               let* context =
                 let+ context =
                   Tezos_context.Context.checkout index context_hash
                 in
                 match context with
                 | None -> assert false
                 | Some context ->
                     Tezos_shell_context.Shell_context.wrap_disk_context context
               in
               let key, _value_size =
                 match Random.State.int rng_state 2 with
                 | 0 ->
                     let i = Random.State.int rng_state n_normal_keys in
                     normal_keys.(i)
                 | _ ->
                     let i = Random.State.int rng_state n_rare_keys in
                     rare_keys.(i)
               in
               let random_bytes =
                 (* The biggest file we have is 368640B *)
                 Base_samplers.uniform_bytes rng_state ~nbytes:(4096 * 1000)
               in
               let value_size = Bytes.length random_bytes in

               let* nsecs, context_hash =
                 (* Using [Lwt_main.run] here slows down the benchmark *)
                 Measure.Time.measure_lwt (fun () ->
                     let* context = Context.add context key random_bytes in
                     let* context_hash = Io_helpers.commit context in
                     (* We need to call [flush] to finish the disk writing.
                        It is a sort of the worst case: in a real node,
                        it is rare to flush just after 1 write.
                     *)
                     let+ _context = Io_helpers.flush context in
                     context_hash)
               in
               output_value oc (List.length key, value_size, nsecs) ;
               if n mod 100 = 0 then restrict_memory () ;
               loop context_hash (n - 1)
           in
           let* () = loop context_hash config.runs in
           Tezos_context.Context.close index)) ;
    close_out oc ;
    recover_measurements fn
end

let () = Registration.register_simple_with_num (module Write_bench)
