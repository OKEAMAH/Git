
(** Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                 -- --file test_datatype_size.ml
*)

open Protocol

let _print_maximum_length enc =
  Printf.printf "\n%s\n\n%!" @@
  match Data_encoding.Binary.maximum_length enc with
    | None -> "no max length"
    | Some l -> "max length = " ^ string_of_int l

let length enc =
  Option.value_f ~default:(fun () -> Stdlib.failwith "maximum_length") @@
  Data_encoding.Binary.maximum_length enc
let assert_length enc l = assert (length enc = l)

let test_size enc size () =
  assert_length enc size ;
  Lwt_result_syntax.return_unit

type box = Box : (string * _ Data_encoding.t * int) -> box

let encs =
  [
    Box ("Public_key_hash", Signature.Public_key_hash.encoding, 21) ;
    Box ("Staking_parameters", Staking_parameters_repr.encoding, 8) ;
    Box ("Cycle", Cycle_repr.encoding, 4) ;
    Box ("Tez", Tez_repr.encoding, 10) ;
    Box ("uint8", Data_encoding.uint8, 1) ;
    Box ("Deposits", Deposits_repr.encoding, 20) ;
    Box ("Staking_pseudotokens", Staking_pseudotoken_repr.encoding, 10) ;
  ]

let tests =
  List.map
    (fun (Box (name, enc, size)) ->
       Tztest.tztest name `Quick (test_size enc size))
    encs

let () =
  Alcotest_lwt.run ~__FILE__ Protocol.name [("datatype size", tests)]
  |> Lwt_main.run
