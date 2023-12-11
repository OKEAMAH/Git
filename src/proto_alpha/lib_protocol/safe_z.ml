type error += Conversion_to_bounded_integer of Z.t * string

let () =
  register_error_kind
    `Permanent
    ~id:"z.conversion_error"
    ~title:"Error in conversion to bounded integer"
    ~description:
      "An overflow occured during an integer conversion from \
       arbitrary-precision to bounded"
    ~pp:(fun fmt (z, s) ->
      Format.fprintf
        fmt
        "An overflow occured while attempting to convert integer %a from \
         arbitrary-precision to %s."
        Z.pp_print
        z
        s)
    Data_encoding.(obj2 (req "input" z) (req "target" (string Plain)))
    (function Conversion_to_bounded_integer (z, s) -> Some (z, s) | _ -> None)
    (fun (z, s) -> Conversion_to_bounded_integer (z, s))

let to_int x =
  let open Result_syntax in
  match Z.to_int x with
  | Ok _ as res -> res
  | Error `Overflow -> tzfail (Conversion_to_bounded_integer (x, "int"))

let to_int64 x =
  let open Result_syntax in
  match Z.to_int64 x with
  | Ok _ as res -> res
  | Error `Overflow -> tzfail (Conversion_to_bounded_integer (x, "int64"))
