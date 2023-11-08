open Bls

let log_size = 8

let array_size = 1 lsl (log_size / 2)

let total_size = 1 lsl log_size

let snd_lvl_len = total_size * Scalar.size_in_bytes

let fst_lvl_len = array_size * Scalar.size_in_bytes

let snd_level_offset = G1.size_in_bytes + fst_lvl_len

let () = assert (log_size mod 2 = 0)

let trap_door = Scalar.random ()

let srs = Srs_g1.generate_insecure (1 lsl log_size) trap_door

let hash_ec_to_fr ec =
  let hash = Hacl_star.Hacl.Blake2b_32.hash (G1.to_bytes ec) 32 in
  Z.of_bits (Bytes.to_string hash) |> Scalar.of_z

let read_file file_descr buffer ~offset ~len =
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.read file_descr buffer 0 len in
  assert (i = len) ;
  let i = Unix.lseek file_descr 0 Unix.SEEK_SET in
  assert (i = 0)

let write_file file_descr buffer ~offset ~len =
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.write file_descr buffer 0 len in
  assert (i = len) ;
  let i = Unix.lseek file_descr 0 Unix.SEEK_SET in
  assert (i = 0)

(*2^(square_root_log*2)= size of the storage*)
let create_storage file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let random_vector () =
    let length = 1 lsl (log_size / 2) in
    Array.init length (fun _ -> Scalar.random ())
  in
  let nb_vectors = 1 lsl (log_size / 2) in
  let domain = Domain.build (1 lsl (log_size / 2)) in
  let snd_lvl = Array.init nb_vectors (fun _ -> random_vector ()) in
  let fst_lvl =
    Array.map
      (fun eval ->
        let poly = Evaluations.interpolation_fft2 domain eval in
        Commitment.commit_single srs poly |> hash_ec_to_fr)
      snd_lvl
  in
  let root =
    Commitment.commit_single srs (Evaluations.interpolation_fft2 domain fst_lvl)
  in
  let root_bytes = G1.to_bytes root in
  let fst_lvl_bytes =
    Bytes.concat
      Bytes.empty
      (Array.to_list (fst_lvl |> Array.map Scalar.to_bytes))
  in
  let () = write_file file_descr root_bytes ~offset:0 ~len:G1.size_in_bytes in
  let () =
    write_file
      file_descr
      fst_lvl_bytes
      ~offset:G1.size_in_bytes
      ~len:(Bytes.length fst_lvl_bytes)
  in
  let snd_lvl_bytes =
    let array_array = Array.map (Array.map Scalar.to_bytes) snd_lvl in
    let list_list = Array.map Array.to_list array_array |> Array.to_list in
    Bytes.concat Bytes.empty (List.flatten list_list)
  in
  let snd_lvl_len = total_size * Scalar.size_in_bytes in
  write_file file_descr snd_lvl_bytes ~offset:snd_level_offset ~len:snd_lvl_len ;
  snd_lvl_bytes

let read_storage file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let buffer_fr_size = Scalar.size_in_bytes * array_size in
  let buffer_root = Bytes.create G1.size_in_bytes in
  let buffer_fr = Bytes.create buffer_fr_size in
  (* Read root *)
  let _root =
    let () = read_file file_descr buffer_root ~offset:0 ~len:G1.size_in_bytes in
    G1.of_bytes_exn buffer_root
  in
  let () =
    read_file file_descr buffer_fr ~offset:G1.size_in_bytes ~len:buffer_fr_size
  in
  let buffer_snd_lvl = Bytes.create snd_lvl_len in
  let () =
    read_file
      file_descr
      buffer_snd_lvl
      ~offset:snd_level_offset
      ~len:snd_lvl_len
  in
  buffer_snd_lvl
