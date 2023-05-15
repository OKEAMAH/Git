type t = (string * string) list

let encoding = Data_encoding.(assoc string)

let initial = ref ([] : (string * string) list)

let non_empty () = match !initial with [] -> false | _ -> true

let add_error ~bench_name ~error = initial := (bench_name, error) :: !initial

let to_file () = Data_encoding.Json.construct encoding !initial
