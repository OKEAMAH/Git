(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

let id = "tez"

let name = "mutez"

type repr = Uint63.t

type t = Tez_tag of repr [@@ocaml.unboxed]

let wrap t = Tez_tag t [@@ocaml.inline always]

type error +=
  | Addition_overflow of t * t (* `Temporary *)
  | Subtraction_underflow of t * t (* `Temporary *)
  | Multiplication_overflow of t * Uint63.t (* `Temporary *)
  | Negative_multiplicator of t * int64 (* `Temporary *)
  | Invalid_divisor of t * int64

(* `Temporary *)

let zero = Tez_tag Uint63.zero

(* all other constant are defined from the value of one micro tez *)
let one_mutez = Tez_tag Uint63.one

let max_mutez = Tez_tag Uint63.max_int

let mul_int (Tez_tag tez) i = Tez_tag (Uint63.With_exceptions.mul tez i)

let one_cent = mul_int one_mutez Uint63.ten_thousand

let fifty_cents = mul_int one_cent Uint63.fifty

(* 1 tez = 100 cents = 1_000_000 mutez *)
let one = mul_int one_cent Uint63.one_hundred

let of_string s =
  let triplets = function
    | hd :: tl ->
        let len = String.length hd in
        Compare.Int.(
          len <= 3 && len > 0 && List.for_all (fun s -> String.length s = 3) tl)
    | [] -> false
  in
  let integers s = triplets (String.split_on_char ',' s) in
  let decimals s =
    let l = String.split_on_char ',' s in
    if Compare.List_length_with.(l > 2) then false else triplets (List.rev l)
  in
  let parse left right =
    let remove_commas s = String.concat "" (String.split_on_char ',' s) in
    let pad_to_six s =
      let len = String.length s in
      String.init 6 (fun i -> if Compare.Int.(i < len) then s.[i] else '0')
    in
    let prepared = remove_commas left ^ pad_to_six (remove_commas right) in
    Option.map wrap (Uint63.of_string_opt prepared)
  in
  match String.split_on_char '.' s with
  | [left; right] ->
      if String.contains s ',' then
        if integers left && decimals right then parse left right else None
      else if
        Compare.Int.(String.length right > 0)
        && Compare.Int.(String.length right <= 6)
      then parse left right
      else None
  | [left] ->
      if (not (String.contains s ',')) || integers left then parse left ""
      else None
  | _ -> None

let pp ppf (Tez_tag amount) =
  let mult_int = 1_000_000L in
  let rec left ppf amount =
    let d, r = (Int64.div amount 1000L, Int64.rem amount 1000L) in
    if Compare.Int64.(d > 0L) then Format.fprintf ppf "%a%03Ld" left d r
    else Format.fprintf ppf "%Ld" r
  in
  let right ppf amount =
    let triplet ppf v =
      if Compare.Int.(v mod 10 > 0) then Format.fprintf ppf "%03d" v
      else if Compare.Int.(v mod 100 > 0) then Format.fprintf ppf "%02d" (v / 10)
      else Format.fprintf ppf "%d" (v / 100)
    in
    let hi, lo = (amount / 1000, amount mod 1000) in
    if Compare.Int.(lo = 0) then Format.fprintf ppf "%a" triplet hi
    else Format.fprintf ppf "%03d%a" hi triplet lo
  in
  let amount = (amount :> Int64.t) in
  let ints, decs =
    (Int64.div amount mult_int, Int64.(to_int (rem amount mult_int)))
  in
  left ppf ints ;
  if Compare.Int.(decs > 0) then Format.fprintf ppf ".%a" right decs

let to_string t = Format.asprintf "%a" pp t

let ( -? ) tez1 tez2 =
  let open Result_syntax in
  let (Tez_tag t1) = tez1 in
  let (Tez_tag t2) = tez2 in
  match Uint63.sub t1 t2 with
  | Some res -> return (Tez_tag res)
  | None -> tzfail (Subtraction_underflow (tez1, tez2))

let sub_opt (Tez_tag t1) (Tez_tag t2) = Uint63.sub t1 t2 |> Option.map wrap

let ( +? ) tez1 tez2 =
  let open Result_syntax in
  let (Tez_tag t1) = tez1 in
  let (Tez_tag t2) = tez2 in
  match Uint63.add t1 t2 with
  | None -> tzfail (Addition_overflow (tez1, tez2))
  | Some t -> return (Tez_tag t)

let ( *!? ) tez m =
  let open Result_syntax in
  let (Tez_tag t) = tez in
  match Uint63.mul t m with
  | None -> tzfail (Multiplication_overflow (tez, m))
  | Some res -> return (Tez_tag res)

let ( *? ) tez m =
  let open Result_syntax in
  match Uint63.of_int64 m with
  | None -> tzfail (Negative_multiplicator (tez, m))
  | Some m -> tez *!? m

let ( /! ) (Tez_tag t) d = Tez_tag (Uint63.div t d)

let div2 tez = tez /! Uint63.Div_safe.two

let rem (Tez_tag t) d = Tez_tag (Uint63.rem t d)

let ( *?? ) t m ~default =
  match t *? Int64.of_int m with Ok v -> v | Error _ -> default

let mul_exn t m =
  match t *? Int64.of_int m with Ok v -> v | Error _ -> invalid_arg "mul_exn"

let mul_ratio ~rounding tez ~num ~den =
  let open Result_syntax in
  let (Tez_tag t) = tez in
  match Uint63.of_int64 num with
  | None -> tzfail (Negative_multiplicator (tez, num))
  | Some num -> (
      match Uint63.Div_safe.of_int64 den with
      | None -> tzfail (Invalid_divisor (tez, den))
      | Some den -> (
          match Uint63.mul_ratio ~rounding t ~num ~den with
          | Some res -> return (Tez_tag res)
          | None -> tzfail (Multiplication_overflow (tez, num))))

let mul_percentage ~rounding (Tez_tag t) percentage =
  Tez_tag (Uint63.mul_percentage ~rounding t percentage)

let of_mutez t = Uint63.of_int64 t |> Option.map wrap

let of_mutez_exn x =
  match of_mutez x with None -> invalid_arg "Tez.of_mutez" | Some v -> v

let to_mutez' (Tez_tag t) = t

let to_mutez tez = (to_mutez' tez :> Int64.t)

let encoding =
  let open Data_encoding in
  let decode (Tez_tag t) = Z.of_int64 (t :> Int64.t) in
  let encode =
    Json.wrap_error (fun z ->
        match Uint63.of_int64 (Z.to_int64 z) with
        | None -> Error "Non-negative integer expected"
        | Some i -> Ok (Tez_tag i))
  in
  Data_encoding.def name (check_size 10 (conv_with_guard decode encode n))

let balance_update_encoding =
  let open Data_encoding in
  conv
    (function
      | `Credited v -> (to_mutez v :> Int64.t)
      | `Debited v -> Int64.neg (to_mutez v :> Int64.t))
    ( Json.wrap_error @@ fun v ->
      match Uint63.abs_of_int64 v with
      | `Neg v -> `Debited (Tez_tag v)
      | `Pos v -> `Credited (Tez_tag v) )
    int64

let () =
  let open Data_encoding in
  register_error_kind
    `Temporary
    ~id:(id ^ ".addition_overflow")
    ~title:("Overflowing " ^ id ^ " addition")
    ~pp:(fun ppf (opa, opb) ->
      Format.fprintf
        ppf
        "Overflowing addition of %a %s and %a %s"
        pp
        opa
        id
        pp
        opb
        id)
    ~description:("An addition of two " ^ id ^ " amounts overflowed")
    (obj1 (req "amounts" (tup2 encoding encoding)))
    (function Addition_overflow (a, b) -> Some (a, b) | _ -> None)
    (fun (a, b) -> Addition_overflow (a, b)) ;
  register_error_kind
    `Temporary
    ~id:(id ^ ".subtraction_underflow")
    ~title:("Underflowing " ^ id ^ " subtraction")
    ~pp:(fun ppf (opa, opb) ->
      Format.fprintf
        ppf
        "Underflowing subtraction of %a %s and %a %s"
        pp
        opa
        id
        pp
        opb
        id)
    ~description:
      ("A subtraction of two " ^ id
     ^ " amounts underflowed (i.e., would have led to a negative amount)")
    (obj1 (req "amounts" (tup2 encoding encoding)))
    (function Subtraction_underflow (a, b) -> Some (a, b) | _ -> None)
    (fun (a, b) -> Subtraction_underflow (a, b)) ;
  register_error_kind
    `Temporary
    ~id:(id ^ ".multiplication_overflow")
    ~title:("Overflowing " ^ id ^ " multiplication")
    ~pp:(fun ppf (opa, opb) ->
      Format.fprintf
        ppf
        "Overflowing multiplication of %a %s and %a"
        pp
        opa
        id
        Uint63.pp
        opb)
    ~description:
      ("A multiplication of a " ^ id ^ " amount by an integer overflowed")
    (obj2 (req "amount" encoding) (req "multiplicator" Uint63.encoding))
    (function Multiplication_overflow (a, b) -> Some (a, b) | _ -> None)
    (fun (a, b) -> Multiplication_overflow (a, b)) ;
  register_error_kind
    `Temporary
    ~id:(id ^ ".negative_multiplicator")
    ~title:("Negative " ^ id ^ " multiplicator")
    ~pp:(fun ppf (opa, opb) ->
      Format.fprintf
        ppf
        "Multiplication of %a %s by negative integer %Ld"
        pp
        opa
        id
        opb)
    ~description:("Multiplication of a " ^ id ^ " amount by a negative integer")
    (obj2 (req "amount" encoding) (req "multiplicator" int64))
    (function Negative_multiplicator (a, b) -> Some (a, b) | _ -> None)
    (fun (a, b) -> Negative_multiplicator (a, b)) ;
  register_error_kind
    `Temporary
    ~id:(id ^ ".invalid_divisor")
    ~title:("Invalid " ^ id ^ " divisor")
    ~pp:(fun ppf (opa, opb) ->
      Format.fprintf
        ppf
        "Division of %a %s by non positive integer %Ld"
        pp
        opa
        id
        opb)
    ~description:
      ("Multiplication of a " ^ id ^ " amount by a non positive integer")
    (obj2 (req "amount" encoding) (req "divisor" int64))
    (function Invalid_divisor (a, b) -> Some (a, b) | _ -> None)
    (fun (a, b) -> Invalid_divisor (a, b))

let compare (Tez_tag x) (Tez_tag y) = Uint63.compare x y

let ( = ) (Tez_tag x) (Tez_tag y) = Uint63.(x = y)

let ( <> ) (Tez_tag x) (Tez_tag y) = Uint63.(x <> y)

let ( < ) (Tez_tag x) (Tez_tag y) = Uint63.(x < y)

let ( > ) (Tez_tag x) (Tez_tag y) = Uint63.(x > y)

let ( <= ) (Tez_tag x) (Tez_tag y) = Uint63.(x <= y)

let ( >= ) (Tez_tag x) (Tez_tag y) = Uint63.(x >= y)

let equal (Tez_tag x) (Tez_tag y) = Uint63.equal x y

let max (Tez_tag x) (Tez_tag y) = Tez_tag (Uint63.max x y)

let min (Tez_tag x) (Tez_tag y) = Tez_tag (Uint63.min x y)
