(* rt| 0 | 1 |00 |01 |10 | 11*)
module IntMap = Map.Make (Int)

module Parameters = struct
  (** The parameters of Merkle Tree *)
  let log_nb_cells = 4

  let nb_cells = 1 lsl log_nb_cells

  let cell_size = 32

  let level_size n =
    assert (n <= log_nb_cells) ;
    (1 lsl n) * cell_size

  let level_offset_file n =
    assert (n <= log_nb_cells) ;
    ((1 lsl n) - 1) * cell_size

  let level_offset n =
    assert (n <= log_nb_cells) ;
    (1 lsl n) - 1

  let hash input = Hacl_star.Hacl.Blake2b_32.hash input cell_size
end

open Parameters

(* [index] is the index of the considerated node in the array (not considering the cell size)
   [lvl] is the layer where the considerated node is *)
let left_child ~lvl index =
  assert (lvl <= log_nb_cells) ;
  level_offset (lvl + 1) + ((index - level_offset lvl) * 2)

let right_child ~lvl index =
  assert (lvl <= log_nb_cells) ;
  level_offset (lvl + 1) + (((index - level_offset lvl) * 2) + 1)

let parent ~lvl index =
  assert (lvl <= log_nb_cells) ;
  level_offset (lvl - 1) + ((index - level_offset lvl) / 2)

let is_left index = index mod 2 = 1

let sibling ~lvl index =
  assert (lvl <= log_nb_cells) ;
  if is_left index then index + 1 else index - 1

(** Reads [len] bytes from descriptor [file_descr], storing them in
    byte sequence [buffer], starting at position [offset] in [file_descr].*)
let read_file file_descr buffer ~offset ~len =
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.read file_descr buffer 0 len in
  assert (i = len)

(** Writes [len] bytes to descriptor [file_descr], taking them from
    byte sequence [buffer], starting at position [offset] in [file_descr].*)
let write_file file_descr buffer ~offset ~len =
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.write file_descr buffer 0 len in
  assert (i = len)

let write_level file_descr data lvl =
  let offset = level_offset lvl in
  let len = Array.length data * cell_size in
  let bytes_data = Bytes.concat Bytes.empty (Array.to_list data) in
  write_file file_descr bytes_data ~offset ~len

(* the integer is the index of the leaf,
   the bytes are the new value. *)
type update = bytes IntMap.t

(** Writes in the file [root; fst_lvl; snd_level] in bytes. *)
let commit_storage file_name (state : bytes array) =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let hash_lvl lvl =
    Array.init
      (Array.length lvl / 2)
      (fun i -> Bytes.cat lvl.(2 * i) lvl.((2 * i) + 1) |> hash)
  in
  let tree = Array.init log_nb_cells (Fun.const [||]) in
  tree.(log_nb_cells - 1) <- state ;
  let rec hash_all_lvls current_level =
    if current_level = 0 then ()
    else
      let () = tree.(current_level - 1) <- hash_lvl tree.(current_level) in
      hash_all_lvls (current_level - 1)
  in
  hash_all_lvls (log_nb_cells - 1) ;
  Array.iteri (fun i lvl -> write_level file_descr lvl i) tree

(** Returns [root; fst_lvl; snd_level] not in bytes. *)
let read_storage _file_name = assert false

let read_root file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let buffer_root = Bytes.create cell_size in
  read_file file_descr buffer_root ~offset:0 ~len:cell_size ;
  buffer_root

(** Generates a random diff for [nb] elements *)
let create_diff _nb = assert false

let update_one file_name index new_value =
  let index = index + level_offset log_nb_cells in
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let siblings = Array.init log_nb_cells (fun _ -> (true, Bytes.empty)) in
  let buffer = Bytes.create cell_size in
  (* from the leaves to the root *)
  let _ =
    Array.fold_left
      (fun (lvl, node) _ ->
        read_file
          file_descr
          buffer
          ~offset:(sibling ~lvl node * cell_size)
          ~len:cell_size ;
        siblings.(log_nb_cells - lvl) <- (is_left node, buffer) ;
        (lvl - 1, parent ~lvl node))
      (log_nb_cells, index)
      siblings
  in
  let _write =
    Array.fold_left
      (fun (lvl, node_index, node_value) (is_left, sibling) ->
        let to_hash =
          if is_left then Bytes.cat node_value sibling
          else Bytes.cat sibling node_value
        in
        let hash_node_value = hash to_hash in
        write_file
          file_descr
          hash_node_value
          ~offset:(node_index * cell_size)
          ~len:cell_size ;
        (lvl - 1, parent ~lvl node_index, hash_node_value))
      (log_nb_cells, index, new_value)
      siblings
  in
  ()

let update_storage (_diff : scalar IntMap.t IntMap.t)
    (_snd_lvl : scalar array array) =
  assert false

(** Modifies the storage and recomputes the commitment according to [diff]. *)
let update_commit _file_name _diff = assert false

(* generates array for the leaves *)
let generate_leaves () =
  (* we could hash the fr elements if we want a different hash function *)
  Array.init nb_cells (fun _ -> Bls.Scalar.(random () |> to_bytes))
