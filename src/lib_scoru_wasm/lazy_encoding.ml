open Tezos_webassembly_interpreter

let chunked_byte_vector : Chunked_byte_vector.Buffer.t Data_encoding.t =
  let open Data_encoding in
  let open Chunked_byte_vector.Buffer in
  conv to_string_unstable of_string string
