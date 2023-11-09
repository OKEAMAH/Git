open Bls
module IntMap = Map.Make (Int)

(*
root : G1
fst_lvl : array of array_size of FR
snd_lvl array_size array of array_size of FR
all of them are put in that order on disk
*)

let log_size = 8

let array_size = 1 lsl (log_size / 2)

let total_size = 1 lsl log_size

let snd_lvl_len = total_size * Scalar.size_in_bytes

let fst_lvl_len = array_size * Scalar.size_in_bytes

let snd_level_offset = G1.size_in_bytes + fst_lvl_len

let () = assert (log_size mod 2 = 0)

let trap_door = Scalar.random ()

let srs = Srs_g1.generate_insecure array_size trap_door

let domain = Domain.build array_size

let srs_c_array = G1_carray.init array_size (fun i -> Srs_g1.get srs i)

(*TODO : check*)
let srs_lagrange =
  let () = G1_carray.interpolation_ecfft_inplace ~domain ~points:srs_c_array in
  srs_c_array

let hash_ec_to_fr ec =
  let hash = Hacl_star.Hacl.Blake2b_32.hash (G1.to_bytes ec) 32 in
  Z.of_bits (Bytes.to_string hash) |> Scalar.of_z

let formula_snd fst snd =
  G1.size_in_bytes + fst_lvl_len
  + (fst * array_size * Scalar.size_in_bytes)
  + (snd * Scalar.size_in_bytes)

let formula_fst_level i = G1.size_in_bytes + (Scalar.size_in_bytes * i)

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
let create_storage ?(test = false) file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let random_vector () =
    let length = 1 lsl (log_size / 2) in
    Array.init length (fun i ->
        if test then Scalar.of_int i else Scalar.random ())
  in
  let nb_vectors = 1 lsl (log_size / 2) in
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
  write_file file_descr snd_lvl_bytes ~offset:snd_level_offset ~len:snd_lvl_len

let read_storage file_name =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  let buffer_fr_size = Scalar.size_in_bytes * array_size in
  let buffer_root = Bytes.create G1.size_in_bytes in
  let buffer_fst_lvl = Bytes.create buffer_fr_size in
  (* Read root *)
  let root =
    let () = read_file file_descr buffer_root ~offset:0 ~len:G1.size_in_bytes in
    G1.of_bytes_exn buffer_root
  in
  let () =
    read_file
      file_descr
      buffer_fst_lvl
      ~offset:G1.size_in_bytes
      ~len:buffer_fr_size
  in
  let fst_lvl =
    Array.init array_size (fun i ->
        let bytes_i =
          Bytes.sub
            buffer_fst_lvl
            (i * Scalar.size_in_bytes)
            Scalar.size_in_bytes
        in
        Scalar.of_bytes_exn bytes_i)
  in
  let buffer_snd_lvl = Bytes.create snd_lvl_len in
  let () =
    read_file
      file_descr
      buffer_snd_lvl
      ~offset:snd_level_offset
      ~len:snd_lvl_len
  in
  let snd_lvl =
    Array.init array_size (fun fst ->
        Array.init array_size (fun snd ->
            let bytes =
              Bytes.sub
                buffer_snd_lvl
                ((fst * array_size * Scalar.size_in_bytes)
                + (snd * Scalar.size_in_bytes))
                Scalar.size_in_bytes
            in
            Scalar.of_bytes_exn bytes))
  in
  (root, fst_lvl, snd_lvl)

let create_diff size =
  let init = IntMap.empty in
  let rec repeat f diff n = if n = 0 then diff else repeat f (f diff) (n - 1) in
  let rec my_update map_opt =
    let snd = Random.int array_size in
    match map_opt with
    | None -> Some (IntMap.singleton snd (Scalar.random ()))
    | Some map ->
        if IntMap.mem snd map then my_update map_opt
        else if IntMap.cardinal map = array_size then
          failwith "fix that function"
        else Some (IntMap.add snd (Scalar.random ()) map)
  in

  let f diff =
    let fst = Random.int array_size in
    IntMap.update fst my_update diff
  in
  repeat f init size

let map_to_array map =
  List.map snd (List.of_seq (IntMap.to_seq map)) |> Array.of_list

let update_storage file_name diff =
  let file_descr = Unix.openfile file_name [O_CREAT; O_RDWR] 0o640 in
  (*this function computes the EC diff to apply to the fst lvl from a snd lvl diff*)
  let update_i_fst_lvl snd_lvl_diff =
    let srs_lagrange_list = G1_carray.to_array srs_lagrange |> Array.to_list in
    let filtered_list =
      List.filteri (fun i _ -> IntMap.mem i snd_lvl_diff) srs_lagrange_list
    in
    let to_pippinger_ec = filtered_list |> Array.of_list in
    let to_pippinger_fr = map_to_array snd_lvl_diff in
    G1.pippenger to_pippinger_ec to_pippinger_fr
  in
  (*diff to apply to the fst lvl*)
  let fst_lvl_diff_ec = IntMap.map update_i_fst_lvl diff in

  let to_pippinger_fr_root =
    IntMap.mapi
      (fun i _ ->
        let buffer = Bytes.create Scalar.size_in_bytes in
        let () =
          read_file
            file_descr
            buffer
            ~offset:(formula_fst_level i)
            ~len:Scalar.size_in_bytes
        in
        let old_hash = buffer |> Scalar.of_bytes_exn in
        let new_hash = IntMap.find i fst_lvl_diff_ec |> hash_ec_to_fr in
        Scalar.(sub new_hash old_hash))
      diff
  in

  let srs_lagrange_list = G1_carray.to_array srs_lagrange |> Array.to_list in
  let filtered_list =
    List.filteri (fun i _ -> IntMap.mem i diff) srs_lagrange_list
  in
  let to_pippinger_ec_root = filtered_list |> Array.of_list in
  (*the diff to apply to the root*)
  let update_root =
    G1.pippenger to_pippinger_ec_root (map_to_array to_pippinger_fr_root)
  in
  let old_root = Bytes.create G1.size_in_bytes in
  let () = read_file file_descr old_root ~offset:0 ~len:G1.size_in_bytes in
  let root_to_write =
    G1.(add (of_bytes_exn old_root) update_root) |> G1.to_bytes
  in
  (*update sndlvl *)
  let fr_buffer = Bytes.create Scalar.size_in_bytes in
  let snd_lvl_map fst snd_lvl_diff =
    IntMap.mapi
      (fun snd diff ->
        let () =
          read_file
            file_descr
            fr_buffer
            ~offset:(formula_snd fst snd)
            ~len:Scalar.size_in_bytes
        in
        Scalar.(of_bytes_exn fr_buffer + diff))
      snd_lvl_diff
  in
  let to_write = IntMap.mapi snd_lvl_map diff in
  let snd_lvl_iter fst snd_lvl_to_write =
    IntMap.iter
      (fun snd to_write ->
        write_file
          file_descr
          (Scalar.to_bytes to_write)
          ~offset:(formula_snd fst snd)
          ~len:Scalar.size_in_bytes)
      snd_lvl_to_write
  in
  let () = IntMap.iter snd_lvl_iter to_write in
  (*update fst lvl*)
  let update_fst_lvl (to_pippinger_fr_root : Scalar.t IntMap.t) =
    let to_iter i scalar =
      let bytes = Scalar.to_bytes scalar in
      write_file
        file_descr
        bytes
        ~offset:(formula_fst_level i)
        ~len:Scalar.size_in_bytes
    in
    IntMap.iter to_iter to_pippinger_fr_root
  in
  let () = update_fst_lvl to_pippinger_fr_root in
  (*update_root*)
  write_file file_descr root_to_write ~offset:0 ~len:G1.size_in_bytes
