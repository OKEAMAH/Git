open Bls
module IntMap = Map.Make (Int)

(*
root : G1
fst_lvl : array of array_size of FR
snd_lvl array_size array of array_size of FR
all of them are put in that order on disk
*)

module Parameters = struct
  (** The parameters of Verkle Tree *)
  let log_nb_cells = 24

  (* the square root should be a power of two  *)
  let () = assert (log_nb_cells mod 2 = 0)

  (* We want the same arity of the fst and snd levels *)
  let arity = 1 lsl (log_nb_cells / 2)

  let nb_cells = 1 lsl log_nb_cells

  let root_size = G1.size_in_bytes

  let cell_size = Scalar.size_in_bytes

  let fst_lvl_cell_size = G1.size_in_bytes

  let vector_size = arity * cell_size

  let fst_lvl_size = arity * fst_lvl_cell_size

  let snd_lvl_size = nb_cells * cell_size

  (* We store the tree in the following order: [root; fst_lvl; snd_lvl] *)
  let fst_lvl_offset = root_size

  let snd_lvl_offset = fst_lvl_offset + fst_lvl_size
end

open Parameters

module Preprocess = struct
  (** The parameters of KZG *)
  let trap_door = Scalar.random ()

  let srs = Srs_g1.generate_insecure arity trap_door

  let domain = Domain.build arity

  (* SRS in Lagrange form *)
  let srs_lagrange =
    let srs_c_array = G1_carray.init arity (fun i -> Srs_g1.get srs i) in
    let () =
      G1_carray.interpolation_ecfft_inplace ~domain ~points:srs_c_array
    in
    Array.to_list @@ G1_carray.to_array srs_c_array
end

open Preprocess

let hash_ec_to_fr ec =
  let hash = Hacl_star.Hacl.Blake2b_32.hash (G1.to_bytes ec) 32 in
  Z.of_bits (Bytes.to_string hash) |> Scalar.of_z

(* Get the i-th element of the first level *)
let get_offset_fst_lvl i = fst_lvl_offset + (i * fst_lvl_cell_size)

(* Get the j-th element from the second level of the i-th element of the first level *)
let get_offset_snd_lvl i j = snd_lvl_offset + (i * vector_size) + (j * cell_size)

(** Reads [len] bytes from descriptor [file_descr], storing them in
    byte sequence [buffer], starting at position [offset] in [file_descr].*)
let read_file file_descr buffer ~offset ~len =
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.read file_descr buffer 0 len in
  assert (i = len) ;
  let i = Unix.lseek file_descr 0 Unix.SEEK_SET in
  assert (i = 0)

(** Writes [len] bytes to descriptor [file_descr], taking them from
    byte sequence [buffer], starting at position [offset] in [file_descr].*)
let write_file file_descr buffer ~offset ~len =
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.write file_descr buffer 0 len in
  assert (i = len) ;
  let i = Unix.lseek file_descr 0 Unix.SEEK_SET in
  assert (i = 0)

let commit snd_lvl =
  let fst_lvl =
    Array.map
      (fun eval ->
        let poly = Evaluations.interpolation_fft2 domain eval in
        Commitment.commit_single srs poly)
      snd_lvl
  in
  let fst_lvl_cmt = Array.map hash_ec_to_fr fst_lvl in
  let root =
    Commitment.commit_single
      srs
      (Evaluations.interpolation_fft2 domain fst_lvl_cmt)
  in
  (root, fst_lvl)

let serialize_snd_lvl snd_lvl =
  let array_array = Array.map (Array.map Scalar.to_bytes) snd_lvl in
  let list_list = Array.map Array.to_list array_array |> Array.to_list in
  Bytes.concat Bytes.empty (List.flatten list_list)

let serialize_fst_lvl fst_lvl =
  Bytes.concat Bytes.empty (Array.to_list (fst_lvl |> Array.map G1.to_bytes))

let serialize_root root = G1.to_bytes root

let generate_snd_lvl () =
  let random_vector () = Array.init arity (fun _i -> Scalar.random ()) in
  Array.init arity (fun _ -> random_vector ())

(** Writes in the file [root; fst_lvl; snd_level] in bytes. *)
let commit_storage file_name snd_lvl =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let root, fst_lvl = commit snd_lvl in

  let root_bytes = serialize_root root in
  let fst_lvl_bytes = serialize_fst_lvl fst_lvl in
  let snd_lvl_bytes = serialize_snd_lvl snd_lvl in

  write_file file_descr root_bytes ~offset:0 ~len:root_size ;
  write_file file_descr fst_lvl_bytes ~offset:fst_lvl_offset ~len:fst_lvl_size ;
  write_file file_descr snd_lvl_bytes ~offset:snd_lvl_offset ~len:snd_lvl_size

let read_root file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let buffer_root = Bytes.create root_size in
  read_file file_descr buffer_root ~offset:0 ~len:root_size ;
  G1.of_bytes_exn buffer_root

(** Returns [root; fst_lvl; snd_level] not in bytes. *)
let read_storage file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in

  let buffer_root = Bytes.create root_size in
  let buffer_fst_lvl = Bytes.create fst_lvl_size in
  let buffer_snd_lvl = Bytes.create snd_lvl_size in

  read_file file_descr buffer_root ~offset:0 ~len:root_size ;
  read_file file_descr buffer_fst_lvl ~offset:fst_lvl_offset ~len:fst_lvl_size ;
  read_file file_descr buffer_snd_lvl ~offset:snd_lvl_offset ~len:snd_lvl_size ;

  let root = G1.of_bytes_exn buffer_root in
  let fst_lvl =
    Array.init arity (fun i ->
        let bytes_i =
          Bytes.sub buffer_fst_lvl (i * fst_lvl_cell_size) fst_lvl_cell_size
        in
        G1.of_bytes_exn bytes_i)
  in
  let snd_lvl =
    Array.init arity (fun fst ->
        Array.init arity (fun snd ->
            let bytes =
              Bytes.sub
                buffer_snd_lvl
                ((fst * vector_size) + (snd * cell_size))
                cell_size
            in
            Scalar.of_bytes_exn bytes))
  in
  (root, fst_lvl, snd_lvl)

(** Generates a random diff for [nb] elements *)
let create_diff nb =
  (* Gets a random index that does not belong to the diff *)
  let rec random_index diff =
    let ij = Random.int nb_cells in
    let i, j = (Int.div ij arity, ij mod arity) in
    if IntMap.mem i diff && IntMap.mem j (IntMap.find i diff) then
      random_index diff
    else (i, j)
  in

  let rec repeat f diff n = if n = 0 then diff else repeat f (f diff) (n - 1) in
  let add diff =
    let i, j = random_index diff in
    if IntMap.mem i diff then
      let new_i = IntMap.add j (Scalar.random ()) (IntMap.find i diff) in
      IntMap.add i new_i diff
    else IntMap.add i (IntMap.singleton j (Scalar.random ())) diff
  in
  repeat add IntMap.empty nb

let map_to_array map =
  List.map snd (List.of_seq (IntMap.to_seq map)) |> Array.of_list

let update_storage (diff : scalar IntMap.t IntMap.t)
    (snd_lvl : scalar array array) =
  IntMap.iter
    (fun i snd_lvl_diff ->
      (IntMap.iter (fun j diff ->
           snd_lvl.(i).(j) <- Scalar.(snd_lvl.(i).(j) + diff)))
        snd_lvl_diff)
    diff

(** Modifies the storage and recomputes the commitment according to [diff]. *)
let update_commit file_name diff =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in

  let ec_of_diff diff =
    let filtered_list =
      List.filteri (fun i _ -> IntMap.mem i diff) srs_lagrange
    in
    let to_pippinger_ec = filtered_list |> Array.of_list in
    let to_pippinger_fr = map_to_array diff in
    G1.pippenger to_pippinger_ec to_pippinger_fr
  in
  (* Compute the EC diff for the fst lvl *)
  let fst_lvl_diff_ec = IntMap.map ec_of_diff diff in

  (* Compute the Fr diff for the root *)
  let root_diff_fr =
    IntMap.mapi
      (fun i _ ->
        let buffer = Bytes.create fst_lvl_cell_size in
        read_file
          file_descr
          buffer
          ~offset:(get_offset_fst_lvl i)
          ~len:fst_lvl_cell_size ;
        let old_ec = G1.of_bytes_exn buffer in
        let old_hash = hash_ec_to_fr old_ec in
        let new_hash =
          G1.add (IntMap.find i fst_lvl_diff_ec) old_ec |> hash_ec_to_fr
        in
        Scalar.sub new_hash old_hash)
      diff
  in
  (* Compute the EC diff for the root *)
  let root_diff = ec_of_diff root_diff_fr in

  (* Compute the new root *)
  let new_root =
    let old_root = Bytes.create root_size in
    read_file file_descr old_root ~offset:0 ~len:root_size ;
    G1.(add (of_bytes_exn old_root) root_diff) |> G1.to_bytes
  in

  (* Compute the new first level *)
  let new_fst_lvl =
    let ec_buffer = Bytes.create fst_lvl_cell_size in
    IntMap.mapi
      (fun i ec_point ->
        read_file
          file_descr
          ec_buffer
          ~offset:(get_offset_fst_lvl i)
          ~len:fst_lvl_cell_size ;
        G1.(to_bytes (add (of_bytes_exn ec_buffer) ec_point)))
      fst_lvl_diff_ec
  in

  (* Compute the new second level *)
  let new_snd_lvl =
    let fr_buffer = Bytes.create cell_size in
    let snd_lvl_map fst snd_lvl_diff =
      IntMap.mapi
        (fun snd diff ->
          let () =
            read_file
              file_descr
              fr_buffer
              ~offset:(get_offset_snd_lvl fst snd)
              ~len:cell_size
          in
          Scalar.(to_bytes (of_bytes_exn fr_buffer + diff)))
        snd_lvl_diff
    in
    IntMap.mapi snd_lvl_map diff
  in

  (* Write the new root *)
  write_file file_descr new_root ~offset:0 ~len:root_size ;

  (* Write the new first level into file *)
  let to_iter i bytes =
    write_file
      file_descr
      bytes
      ~offset:(get_offset_fst_lvl i)
      ~len:fst_lvl_cell_size
  in
  IntMap.iter to_iter new_fst_lvl ;

  (* Write the new second level into file *)
  let snd_lvl_iter fst snd_lvl_to_write =
    IntMap.iter
      (fun snd to_write ->
        write_file
          file_descr
          to_write
          ~offset:(get_offset_snd_lvl fst snd)
          ~len:cell_size)
      snd_lvl_to_write
  in
  IntMap.iter snd_lvl_iter new_snd_lvl
