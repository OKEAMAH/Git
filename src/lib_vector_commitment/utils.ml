module IntMap = Map.Make (Int)

(** Reads [len] bytes from descriptor [file_descr], storing them in
    byte sequence [buffer], starting at position [offset] in [file_descr].*)
let read_file file_descr buffer ~offset ~len =
  (* Printf.printf "\nroffset : %d\nrlen : %d\n" offset len ; *)
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.read file_descr buffer 0 len in
  (* Printf.printf "\ni = %d\n" i ; *)
  assert (i = len)

(** Writes [len] bytes to descriptor [file_descr], taking them from
        byte sequence [buffer], starting at position [offset] in [file_descr].*)
let write_file file_descr buffer ~offset ~len =
  (* Printf.printf "\nwoffset : %d\nwlen : %d\n" offset len ; *)
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.write file_descr buffer 0 len in
  assert (i = len)
