(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

exception Exceeded_max_num_steps

type 'a t = Run of (int option -> ('a * int option) Lwt.t) [@@ocaml.unboxed]

let run ?max_num_steps (Run run) =
  match max_num_steps with
  | Some steps when steps < 0 -> Lwt.fail Exceeded_max_num_steps
  | _ -> Lwt.map fst @@ run max_num_steps

let return x = Run (fun n -> Lwt.return (x, n))

(* Decrement the remaining step budget if a budget exists. *)
let consume_step ?(steps = 1) = function
  | None -> None
  | Some n when n < steps -> raise Exceeded_max_num_steps
  | Some n -> Some (n - steps)

let map f (Run run) =
  Run
    (fun rem_steps ->
      Lwt.map
        (fun (x, rem_steps) -> (f x, consume_step rem_steps))
        (run rem_steps))

let bind (Run run) f =
  Run
    (fun rem_steps ->
      let open Lwt.Syntax in
      let* x, rem_steps = run rem_steps in
      let rem_steps = consume_step rem_steps in
      let (Run run) = f x in
      run rem_steps)

let weighted ~steps f =
  Run
    (fun rem_steps ->
      let open Lwt.Syntax in
      let (Run run) = f in
      let+ x, rem_steps = run rem_steps in
      (x, consume_step ~steps rem_steps))

let both m1 m2 = bind m1 (fun x -> bind m2 (fun y -> return (x, y)))

let of_lwt lwt = Run (fun rem_steps -> Lwt.map (fun x -> (x, rem_steps)) lwt)

let fail exn = Run (fun _rem_steps -> Lwt.fail exn)

let catch f handle =
  Run
    (fun rem_steps ->
      Lwt.catch
        (fun () ->
          let (Run run) = f () in
          run rem_steps)
        (fun exn ->
          let (Run run) = handle exn in
          run rem_steps))

module Syntax = struct
  let return = return

  let ( let+ ) m f = map f m

  let ( let* ) m f = bind m f

  let ( and+ ) m1 m2 = both m1 m2

  let ( and* ) m1 m2 = both m1 m2
end

let return_none = return None

let apply f x =
  Run
    (fun rem_steps ->
      Lwt.apply
        (fun x ->
          let (Run run) = f x in
          run rem_steps)
        x)

let return_unit = return ()

let return_nil = return []

let return_false = return false

module List = struct
  (** The implementation of these modules are taken from
      [src/lib_lwt_result_stdlib/bare/structs/list.ml] and adapted to the
      action monad, rather than lwt. *)

  let action_apply2 f x y = try f x y with exn -> fail exn

  let rev_map_s f l =
    let open Syntax in
    let rec aux ys = function
      | [] -> return ys
      | x :: xs ->
          let* y = f x in
          (aux [@ocaml.tailcall]) (y :: ys) xs
    in
    match l with
    | [] -> return []
    | x :: xs ->
        let* y = apply f x in
        aux [y] xs

  let map_s f l = rev_map_s f l |> map List.rev

  let iter_s f =
    let open Syntax in
    let rec aux f = function
      | [] -> return_unit
      | h :: t ->
          let* () = f h in
          (aux [@ocaml.tailcall]) f t
    in
    function
    | [] -> return_unit
    | h :: t ->
        let* () = apply f h in
        (aux [@ocaml.tailcall]) f t

  let rec fold_left_s f acc =
    let open Syntax in
    function
    | [] -> return acc
    | x :: xs ->
        let* acc = f acc x in
        (fold_left_s [@ocaml.tailcall]) f acc xs

  let fold_left_s f acc =
    let open Syntax in
    function
    | [] -> return acc
    | x :: xs ->
        let* acc = action_apply2 f acc x in
        fold_left_s f acc xs

  let rev_mapi_s f l =
    let open Syntax in
    let rec aux i ys = function
      | [] -> return ys
      | x :: xs ->
          let* y = f i x in
          (aux [@ocaml.tailcall]) (i + 1) (y :: ys) xs
    in
    match l with
    | [] -> return_nil
    | x :: xs ->
        let* y = action_apply2 f 0 x in
        aux 1 [y] xs

  let mapi_s f l = rev_mapi_s f l |> map List.rev

  let rev_concat_map_s f xs =
    let open Syntax in
    let rec aux f acc = function
      | [] -> return acc
      | x :: xs ->
          let* ys = f x in
          (aux [@ocaml.tailcall]) f (List.rev_append ys acc) xs
    in
    match xs with
    | [] -> return_nil
    | x :: xs ->
        let* ys = apply f x in
        (aux [@ocaml.tailcall]) f (List.rev ys) xs

  let concat_map_s f xs =
    let open Syntax in
    let+ ys = rev_concat_map_s f xs in
    List.rev ys

  let mapi_int32_s f xs =
    let rec mapi_s' f i =
      let open Syntax in
      function
      | [] -> return []
      | x :: xs ->
          let* v = f i x in
          let+ xs' = mapi_s' f (Int32.succ i) xs in
          v :: xs'
    in
    mapi_s' f 0l xs
end

let iter_range ~first_index ~last_index f =
  let open Syntax in
  let rec aux ix =
    if ix <= last_index then
      let* () = f ix in
      aux (ix + 1)
    else return_unit
  in
  aux first_index

module Internal_for_tests = struct
  let run (Run run) =
    let open Lwt.Syntax in
    let* x, rem_steps = run (Some max_int) in
    match rem_steps with
    | Some rem_steps -> Lwt.return (x, max_int - rem_steps)
    | None -> assert false
end
