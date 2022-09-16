let check_null_ptr exn ptr = if Ctypes.is_null ptr then raise exn else ()
