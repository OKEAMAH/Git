(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

module IntMap = Map.Make (Int)

(*
  We use the following representation for the Merkle Tree:
  type tree = bytes array array
  tree: [log_nb_cells + 1]-size array of [level_size i]-size array of 32 bytes,
  where [level_size i] is the size of array for the i-th level.
          rt               root
         /   \
        0     1            fst_lvl
       / \   / \
      00 01 10 11          leaves
  
  The tree is stored in the file in the following order:
  [ rt | 0 | 1 | 00 | 01 | 10 | 11 ].
*)

module Make_Merkle_Tree : Vector_commitment_sig.Make_Vector_commitment =
functor
  (P : Vector_commitment_sig.Parameters)
  ->
  struct
    type leaves = bytes array

    (* the integer is the index of the leaves,
       the bytes are the new value. *)
    type update = bytes IntMap.t

    module Tree_Parameters = struct
      (** The parameters of Merkle Tree *)
      let log_nb_cells = P.log_nb_cells

      let nb_cells = 1 lsl log_nb_cells

      let digest_size = 32

      let cell_size = digest_size

      let level_size n =
        assert (n <= log_nb_cells) ;
        (1 lsl n) * cell_size

      let level_offset n =
        assert (n <= log_nb_cells) ;
        (1 lsl n) - 1

      let level_offset_file n = cell_size * level_offset n

      let hash input = Hacl_star.Hacl.Blake2b_32.hash input digest_size
    end

    open Tree_Parameters

    module Index = struct
      (* TODO: should we check that we can't call
         - a `_child` function for leaves and
         - a `parent` or `sibling` function for `root`? *)
      let level_from_index index = Z.log2 (Z.of_int (index + 1))

      (* [index] is the global index of the node in the tree
         (without considering the cell size) *)
      let left_child index =
        let lvl = level_from_index index in
        assert (lvl <= log_nb_cells) ;
        level_offset (lvl + 1) + ((index - level_offset lvl) * 2)

      let right_child index =
        let lvl = level_from_index index in
        assert (lvl <= log_nb_cells) ;
        level_offset (lvl + 1) + (((index - level_offset lvl) * 2) + 1)

      let parent index =
        let lvl = level_from_index index in
        assert (lvl <= log_nb_cells) ;
        level_offset (lvl - 1) + ((index - level_offset lvl) / 2)

      let is_left index = index mod 2 = 1

      let sibling index = if is_left index then index + 1 else index - 1
    end

    open Index

    module Internal_test = struct
      type tree = bytes array array

      type root = bytes

      let create_tree_memory leaves =
        let hash_lvl lvl =
          Array.init
            (Array.length lvl / 2)
            (fun i -> Bytes.cat lvl.(2 * i) lvl.((2 * i) + 1) |> hash)
        in
        (* all layers + root *)
        let tree = Array.init (log_nb_cells + 1) (Fun.const [||]) in
        tree.(log_nb_cells) <- leaves ;
        for current_level = log_nb_cells downto 1 do
          tree.(current_level - 1) <- hash_lvl tree.(current_level)
        done ;
        tree

      let apply_update_leaves leaves update =
        IntMap.iter (fun i v -> leaves.(i) <- v) update

      let read_root ~file_name =
        let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
        let buffer_root = Bytes.create cell_size in
        Utils.read_file file_descr buffer_root ~offset:0 ~len:cell_size ;
        buffer_root

      let read_root_memory tree = tree.(0).(0)

      (** Returns [[root]; [0; 1]; [00; 01; 10; 11]; …] in bytes. *)
      let read_tree ~file_name =
        let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in

        Array.init (log_nb_cells + 1) (fun i ->
            let offset = level_offset_file i in
            let len = level_size i in
            let buffer_lvl = Bytes.init len (Fun.const 'c') in
            Utils.read_file file_descr buffer_lvl ~offset ~len ;
            Array.init (len / cell_size) (fun i ->
                Bytes.sub buffer_lvl (i * cell_size) cell_size))

      let print_tree_memory tree =
        Array.iteri
          (fun i a ->
            Printf.printf
              "%d : [%s]\n"
              i
              (String.concat ", " Array.(to_list (map Utils.hex_of_bytes a))))
          tree

      let print_tree ~file_name =
        let storage = read_tree ~file_name in
        print_tree_memory storage

      let print_root root = Printf.printf "%s" (Utils.hex_of_bytes root)

      let equal_root = Bytes.equal
    end

    open Internal_test

    let random_bytes () = Kzg.Bls.Scalar.(random () |> to_bytes)

    let generate_leaves () =
      (* we could hash the fr elements if we want a different hash function *)
      Array.init nb_cells (fun _ -> random_bytes ())
    (* Array.init nb_cells (fun i -> Bls.Scalar.(of_int i |> to_bytes)) *)

    let generate_update ~size =
      IntMap.of_seq
        (Seq.init size (fun _ -> (Random.int nb_cells, random_bytes ())))
    (* IntMap.of_seq
       (Seq.init nb (fun i ->
            (i, Bls.(Scalar.of_int (nb_cells + 1) |> Scalar.to_bytes)))) *)

    let create_tree ~file_name (leaves : bytes array) =
      let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
      let tree = create_tree_memory leaves in
      let to_write =
        Bytes.(concat empty Array.(to_list (concat (to_list tree))))
      in
      Utils.write_file
        file_descr
        to_write
        ~offset:0
        ~len:(Bytes.length to_write)

    (* keep it for benchmarking *)
    let _apply_single_update ~file_name index new_value =
      let index = index + level_offset log_nb_cells in
      (* Printf.printf "\nlvl offset : %d" (level_offset log_nb_cells) ; *)
      (* Printf.printf "\nindex : %d\n" index ; *)
      let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
      let siblings = Array.init log_nb_cells (fun _ -> (true, Bytes.empty)) in
      (* Printf.printf "\nlen sibling = %d" (Array.length siblings) ; *)
      (* from the leaves to the root *)
      let _ =
        Array.fold_left
          (fun (lvl, node) _ ->
            (*             Printf.printf "\nlvl  : %d" lvl ; *)
            (*             Printf.printf "\nnode : %d" node ; *)
            (*             Printf.printf "\nsibl : %d\n" (sibling node) ; *)
            let buffer = Bytes.create cell_size in
            Utils.read_file
              file_descr
              buffer
              ~offset:(sibling node * cell_size)
              ~len:cell_size ;
            siblings.(log_nb_cells - lvl) <- (is_left node, buffer) ;
            (lvl - 1, parent node))
          (log_nb_cells, index)
          siblings
      in
      (* Printf.printf
         "\nsiblings = [%s]"
         (String.concat
            ", "
            Array.(
              to_list (Array.map (fun (_, x) -> Hex.(show (of_bytes x))) siblings))) ; *)
      let _write =
        let _write_new_value =
          Utils.write_file
            file_descr
            new_value
            ~offset:(index * cell_size)
            ~len:cell_size
        in
        Array.fold_left
          (fun (lvl, node_index, node_value) (is_left, sibling) ->
            let to_hash =
              if is_left then Bytes.cat node_value sibling
              else Bytes.cat sibling node_value
            in
            let parent_index = parent node_index in
            let parent_value = hash to_hash in
            (*             Printf.printf "\nis_left : %b" is_left ; *)
            (*             Printf.printf *)
            (*               "\nnode            : %s" *)
            (*               Hex.(show (of_bytes node_value)) ; *)
            (*             Printf.printf "\nsibling         : %s" Hex.(show (of_bytes sibling)) ; *)
            (*             Printf.printf "\nparent          : %d" (parent node_index) ; *)
            (*             Printf.printf *)
            (*               "\nhash_node_value : %s" *)
            (*               Hex.(show (of_bytes parent_value)) ; *)
            Utils.write_file
              file_descr
              parent_value
              ~offset:(parent_index * cell_size)
              ~len:cell_size ;
            (lvl - 1, parent_index, parent_value))
          (log_nb_cells, index, new_value)
          siblings
      in
      ()

    (* we want to handle indices in reverse order (to go from the leaves to the
       root) ; that’s why we use int in reverse order *)
    module IntSet = Set.Make (struct
      type t = int

      let compare x y = Int.compare y x
    end)

    let apply_update ~file_name (new_values : bytes IntMap.t) =
      if IntMap.is_empty new_values then ()
      else
        (* update the new_values (that have index in the leaves) with the index in the tree *)
        let new_values =
          IntMap.fold
            (fun k v acc -> IntMap.add (k + level_offset log_nb_cells) v acc)
            new_values
            IntMap.empty
        in
        let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
        let get_to_read_write index =
          let set_to_read = ref IntSet.empty in
          let set_to_write = ref IntSet.empty in
          let current_index = ref index in
          for _lvl = log_nb_cells downto 1 do
            set_to_read := IntSet.add (sibling !current_index) !set_to_read ;
            set_to_write := IntSet.add !current_index !set_to_write ;
            current_index := parent !current_index
          done ;
          (!set_to_read, !set_to_write)
        in
        let set_to_read = ref IntSet.empty in
        (* add the root to set_to_write *)
        let set_to_write = ref IntSet.(add 0 empty) in
        IntMap.iter
          (fun index _ ->
            let new_to_read, new_to_write = get_to_read_write index in
            set_to_read := IntSet.union !set_to_read new_to_read ;
            set_to_write := IntSet.union !set_to_write new_to_write)
          new_values ;
        let hashes = ref new_values in
        (* ref (IntMap.mapi (fun k v -> (v, is_left k)) new_values) in *)
        (* Remove what is updated from the set_to_read *)
        set_to_read := IntSet.diff !set_to_read !set_to_write ;
        (* Could be a fold on set_to_read *)
        IntSet.iter
          (fun i ->
            let buffer = Bytes.create cell_size in
            Utils.read_file
              file_descr
              buffer
              ~offset:(i * cell_size)
              ~len:cell_size ;
            hashes := IntMap.add i buffer !hashes)
          !set_to_read ;

        let write index =
          match IntMap.find_opt index new_values with
          | Some new_value ->
              hashes := IntMap.add index new_value !hashes ;
              Utils.write_file
                file_descr
                new_value
                ~offset:(index * cell_size)
                ~len:cell_size
          | None ->
              let left_child = IntMap.find (left_child index) !hashes in
              let right_child = IntMap.find (right_child index) !hashes in
              let to_write = hash (Bytes.cat left_child right_child) in
              (* Here it's important that we go from the bottom level to the top one.*)
              hashes := IntMap.add index to_write !hashes ;
              Utils.write_file
                file_descr
                to_write
                ~offset:(index * cell_size)
                ~len:cell_size
        in
        IntSet.iter write !set_to_write
  end
