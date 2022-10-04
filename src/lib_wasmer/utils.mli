(** [check_null_ptr exn ptr] raises [exn] if [ptr] is a null pointer. *)
val check_null_ptr : exn -> 'a Ctypes.ptr -> unit
