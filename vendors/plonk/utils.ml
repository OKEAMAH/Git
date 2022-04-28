let build_array init next len =
  let xi = ref init in
  Array.init len (fun _ ->
      let i = !xi in
      xi := next !xi ;
      i)

(* The second vector w may be shorter than v *)
let inner_product ~add ~mul v w =
  let rec aux acc = function
    | (_, []) -> acc
    | (a :: v', b :: w') -> aux (add acc (mul a b)) (v', w')
    | _ -> failwith "inner_product: first is shorter than second"
  in
  aux List.(mul (hd v) (hd w)) List.(tl v, tl w)

let read_vector a_size a_of_bytes len file =
  let read_element ic bytes_buf =
    Stdlib.really_input ic bytes_buf 0 a_size ;
    a_of_bytes bytes_buf
  in
  let ic = open_in file in
  try
    if in_channel_length ic < len * a_size then
      failwith "Buffer is smaller than requested vector length" ;

    let bytes_buf = Bytes.create a_size in
    let vector = List.init len (fun _ -> read_element ic bytes_buf) in
    close_in ic ;
    vector
  with error ->
    close_in ic ;
    raise error

let export_vector a_to_bytes vector file =
  let oc = open_out_bin file in
  List.iter (fun a -> output_bytes oc (a_to_bytes a)) vector ;
  close_out oc
