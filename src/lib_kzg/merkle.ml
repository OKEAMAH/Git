(* rt| 0 | 1 |00 |01 |10 | 11*)
module IntMap = Map.Make (Int)

module Parameters = struct
  (** The parameters of Merkle Tree *)
  let log_nb_cells = 24

  let nb_cells = 1 lsl log_nb_cells

  let cell_size = 32

  let level_size n =
    assert (n <= log_nb_cells) ;
    (1 lsl n) * cell_size

  let level_offset n =
    assert (n <= log_nb_cells) ;
    ((1 lsl n) - 1) * cell_size
end

open Parameters

let left_child index lvl =
  assert (lvl <= log_nb_cells) ;
  level_offset (lvl + 1) + ((index - lvl_offset lvl) * 2)

let right_child index lvl =
  assert (lvl <= log_nb_cells) ;
  level_offset (lvl + 1) + (((index - lvl_offset lvl) * 2) + 1)

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

let write_level fd data lvl =
  let offset = level_offset lvl in
  let len = Array.length data in
  let bytes_data = Bytes.concat Bytes.empty (Array.to_list data) in
  write_file fd bytes_data ~offset ~len

(* the integer is the index of the leaf,
   the bytes are the new value. *)
type update = bytes IntMap.t

(** Writes in the file [root; fst_lvl; snd_level] in bytes. *)
let commit_storage file_name (state : bytes array) = assert false

(** Returns [root; fst_lvl; snd_level] not in bytes. *)
let read_storage file_name = assert false

let read_root file_name = assert false

(** Generates a random diff for [nb] elements *)
let create_diff nb = assert false

let update_storage (diff : scalar IntMap.t IntMap.t)
    (snd_lvl : scalar array array) =
  assert false

(** Modifies the storage and recomputes the commitment according to [diff]. *)
let update_commit file_name diff = assert false

let generate_snd_lvl () =
  let random_vector () = Array.init arity (fun _i -> Scalar.random ()) in
  Array.init arity (fun _ -> random_vector ())
