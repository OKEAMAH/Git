open Tezos_scoru_wasm
module Context = Tezos_context_memory.Context_binary

type Lazy_containers.Lazy_map.tree += Tree of Context.tree

module Tree = struct
  type tree = Context.tree

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

module Tree_encoding_runner = Tree_encoding.Runner.Make (Tree)
module Wasm = Wasm_pvm.Make (Tree)

let initial_boot_sector_from_kernel kernel =
  let open Lwt_syntax in
  let* index = Context.init "/tmp" in
  let context = Context.empty index in
  let tree = Context.Tree.empty context in
  let origination_message =
    Data_encoding.Binary.to_string_exn
      Gather_floppies.origination_message_encoding
    @@ Gather_floppies.Complete_kernel (String.to_bytes kernel)
  in
  let+ tree =
    Wasm.Internal_for_tests.initial_tree_from_boot_sector
      ~empty_tree:tree
      origination_message
  in
  (context, tree)

let run kernel k =
  let open Lwt_syntax in
  let* () =
    Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
        let* kernel = Lwt_io.read channel in
        k kernel)
  in
  return_unit

let () =
  let kernel = Sys.argv.(1) in
  Lwt_main.run
  @@ run kernel (fun kernel ->
         let open Lwt_syntax in
         let* _context, tree = initial_boot_sector_from_kernel kernel in
         let+ () =
           List.iter_s
             (fun () ->
               let+ _tree =
                 Wasm.Internal_for_tests.compute_step_many
                   ~max_steps:Int64.max_int
                   tree
               in
               ())
             (Stdlib.List.init (Sys.argv.(2) |> int_of_string) (fun _ -> ()))
         in
         ())
