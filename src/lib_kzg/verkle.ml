open Bls

let log_size = 8

let array_size = 1 lsl (log_size / 2)

let () = assert (log_size mod 2 = 0)

let trap_door = Scalar.random ()

let srs = Srs_g1.generate_insecure (1 lsl log_size) trap_door

let hash_ec_to_fr ec =
  let hash = Hacl_star.Hacl.Blake2b_32.hash (G1.to_bytes ec) 32 in
  Z.of_bits (Bytes.to_string hash) |> Scalar.of_z

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
      (root_bytes :: Array.to_list (fst_lvl |> Array.map Scalar.to_bytes))
  in
  let _ = Unix.write file_descr fst_lvl_bytes 0 (Bytes.length fst_lvl_bytes) in

  ()

let read_storage file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let buffer_fr_size = Scalar.size_in_bytes * array_size in
  let buffer_root = Bytes.create G1.size_in_bytes in
  let buffer_fr = Bytes.create buffer_fr_size in
  (* Read root *)
  let _ = Unix.read file_descr buffer_root 0 G1.size_in_bytes in
  let _ec = G1.of_bytes_exn buffer_root in
  (* Moving cursor at the end of root *)
  let _ = Unix.lseek file_descr G1.size_in_bytes Unix.SEEK_SET in
  (* Read the rest *)
  let _ = Unix.read file_descr buffer_fr 0 buffer_fr_size in
  (* Puting pointer in the file at the begining *)
  let _ = Unix.lseek file_descr 0 Unix.SEEK_SET in
  ()
