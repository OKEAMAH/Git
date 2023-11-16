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

(* rt| 0 | 1 |00 |01 |10 | 11*)
module IntMap = Map.Make (Int)

module Make_Merkle_Tree : Vector_commitment_sig.Make_Vector_commitment =
functor
  (P : Vector_commitment_sig.Parameters)
  ->
  struct
    type leaves = bytes array

    (* the integer is the index of the leaf,
       the bytes are the new value. *)
    type update = bytes IntMap.t

    module Tree_Parameters = struct
      (** The parameters of Merkle Tree *)
      let log_nb_cells = P.log_nb_leaves

      let nb_cells = 1 lsl log_nb_cells

      let cell_size = 32

      (*       let level_size n = *)
      (*         assert (n <= log_nb_cells) ; *)
      (*         (1 lsl n) * cell_size *)

      let level_offset n =
        assert (n <= log_nb_cells) ;
        (1 lsl n) - 1

      let level_offset_file n = cell_size * level_offset n

      let hash input = Hacl_star.Hacl.Blake2b_32.hash input cell_size
    end

    open Tree_Parameters

    module Index = struct
      let lvl_from_index index =
        if index = 0 then 0 else Z.log2 (Z.of_int (index + 1))

      (* [index] is the index of the considerated node in the array
         (not considering the cell size)
         [lvl] is the layer where the considerated node is *)
      let left_child index =
        let lvl = lvl_from_index index in
        assert (lvl <= log_nb_cells) ;
        level_offset (lvl + 1) + ((index - level_offset lvl) * 2)

      let right_child index =
        let lvl = lvl_from_index index in
        assert (lvl <= log_nb_cells) ;
        level_offset (lvl + 1) + (((index - level_offset lvl) * 2) + 1)

      let parent index =
        let lvl = lvl_from_index index in
        assert (lvl <= log_nb_cells) ;
        level_offset (lvl - 1) + ((index - level_offset lvl) / 2)

      let is_left index = index mod 2 = 1

      let sibling index = if is_left index then index + 1 else index - 1
    end

    open Index

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

    let create_tree_internal (leaves : bytes array) =
      let hash_lvl lvl =
        Array.init
          (Array.length lvl / 2)
          (fun i -> Bytes.cat lvl.(2 * i) lvl.((2 * i) + 1) |> hash)
      in
      (* all layers + root *)
      let tree = Array.init (log_nb_cells + 1) (Fun.const [||]) in
      tree.(log_nb_cells) <- leaves ;
      let rec hash_all_lvls current_level =
        if current_level = 0 then ()
        else
          let () = tree.(current_level - 1) <- hash_lvl tree.(current_level) in
          hash_all_lvls (current_level - 1)
      in
      hash_all_lvls log_nb_cells ;
      tree

    let create_tree ~file_name (leaves : bytes array) =
      let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
      let tree = create_tree_internal leaves in
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

    module Internal_test = struct
      type tree = bytes array array

      type root = bytes

      let create_tree_memory = create_tree_internal

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
        let buffer_lvls =
          Array.init (log_nb_cells + 1) (fun i ->
              ( level_offset_file i,
                (1 lsl i) * cell_size,
                Bytes.init (cell_size * (1 lsl i)) (Fun.const 'c') ))
        in
        Array.map
          (fun (offset, len, buffer_lvl) ->
            let b =
              Utils.read_file file_descr buffer_lvl ~offset ~len ;
              buffer_lvl
            in
            Array.init (len / cell_size) (fun i ->
                Bytes.sub b (i * cell_size) cell_size))
          buffer_lvls

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

      (*       let write_level file_descr data lvl = *)
      (*         let offset = level_offset lvl in *)
      (*         let len = Array.length data * cell_size in *)
      (*         let bytes_data = Bytes.concat Bytes.empty (Array.to_list data) in *)
      (*         Utils.write_file file_descr bytes_data ~offset ~len *)

      let print_root root = Printf.printf "%s" (Utils.hex_of_bytes root)

      let equal_root = Bytes.equal
    end
  end
