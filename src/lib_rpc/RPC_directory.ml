(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

open Error_monad
include Resto_directory.Make (RPC_encoding)

let string_of_step = function
  | Static s -> s
  | Dynamic arg -> Format.sprintf "<%s>" arg.name
  | DynamicTail arg -> Format.sprintf "<%s...>" arg.name

let pp_confict_kind ppf = function
  | CDir -> Format.pp_print_string ppf "Dir conflict"
  | CBuilder -> Format.pp_print_string ppf "Builder conflict"
  | CTail -> Format.pp_print_string ppf "Tail conflict"
  | CService meth ->
      Format.fprintf ppf "Method conflict for %s" (Resto.string_of_meth meth)
  | CTypes (arg1, arg2) ->
      Format.fprintf
        ppf
        "Type conflict for argument %s with argument %s"
        arg1.name
        arg2.name
  | CType (arg, names) ->
      Format.fprintf
        ppf
        "Type conflict for %s with argument %s"
        (String.concat ", " names)
        arg.name

let pp_conflict ppf (steps, kind) =
  Format.fprintf
    ppf
    "%a in /%s"
    pp_confict_kind
    kind
    (String.concat "/" @@ List.map string_of_step steps)

let rec pp_path :
    type a b. Format.formatter -> (a, b) Resto.Internal.path -> unit =
 fun ppf -> function
  | Root -> ()
  | Static (p, s) -> Format.fprintf ppf "%a/%s" pp_path p s
  | Dynamic (p, arg) -> Format.fprintf ppf "%a/<%s>" pp_path p arg.descr.name
  | DynamicTail (p, arg) ->
      Format.fprintf ppf "%a/<%s...>" pp_path p arg.descr.name

(* TODO: https://gitlab.com/nomadic-labs/resto/-/issues/3
   Use printing from Resto when available.*)
let pp_service ppf service =
  let iservice = Service.Internal.to_service service in
  Format.fprintf
    ppf
    "%s %a (%s)"
    (Resto.string_of_meth iservice.meth)
    pp_path
    iservice.path
    (Option.value ~default:"" iservice.description)

let register dir service handler =
  try register dir service handler
  with Conflict (steps, conflict) as e ->
    Format.eprintf
      "@[<v 2>Error in registration of service %a:@ %a@]@."
      pp_service
      service
      pp_conflict
      (steps, conflict) ;
    raise e

let gen_register dir service handler =
  register dir service (fun p q i ->
      Lwt.catch
        (fun () -> handler p q i)
        (function
          | Not_found -> RPC_answer.not_found | exn -> RPC_answer.fail [Exn exn]))

let gen_register =
  (gen_register
    : _ -> _ -> (_ -> _ -> _ -> _ RPC_answer.t Lwt.t) -> _
    :> _ -> _ -> (_ -> _ -> _ -> [< _ RPC_answer.t] Lwt.t) -> _)

let register dir service handler =
  gen_register dir service (fun p q i ->
      let open Lwt_syntax in
      let* r = handler p q i in
      match r with Ok o -> RPC_answer.return o | Error e -> RPC_answer.fail e)

let register_chunked dir service handler =
  gen_register dir service (fun p q i ->
      let open Lwt_syntax in
      let* r = handler p q i in
      match r with
      | Ok o -> RPC_answer.return_chunked o
      | Error e -> RPC_answer.fail e)

let opt_register dir service handler =
  gen_register dir service (fun p q i ->
      let open Lwt_syntax in
      let* ro = handler p q i in
      match ro with
      | Ok (Some o) -> RPC_answer.return o
      | Ok None -> RPC_answer.not_found
      | Error e -> RPC_answer.fail e)

let lwt_register dir service handler =
  gen_register dir service (fun p q i ->
      let open Lwt_syntax in
      let* o = handler p q i in
      RPC_answer.return o)

open Curry

let register0 root s f = register root s (curry Z f)

let register0_chunked root s f = register_chunked root s (curry Z f)

let register1 root s f = register root s (curry (S Z) f)

let register2 root s f = register root s (curry (S (S Z)) f)

let register3 root s f = register root s (curry (S (S (S Z))) f)

let register4 root s f = register root s (curry (S (S (S (S Z)))) f)

let register5 root s f = register root s (curry (S (S (S (S (S Z))))) f)

let opt_register0 root s f = opt_register root s (curry Z f)

let opt_register1 root s f = opt_register root s (curry (S Z) f)

let opt_register2 root s f = opt_register root s (curry (S (S Z)) f)

let opt_register3 root s f = opt_register root s (curry (S (S (S Z))) f)

let opt_register4 root s f = opt_register root s (curry (S (S (S (S Z)))) f)

let opt_register5 root s f = opt_register root s (curry (S (S (S (S (S Z))))) f)

let gen_register0 root s f = gen_register root s (curry Z f)

let gen_register1 root s f = gen_register root s (curry (S Z) f)

let gen_register2 root s f = gen_register root s (curry (S (S Z)) f)

let gen_register3 root s f = gen_register root s (curry (S (S (S Z))) f)

let gen_register4 root s f = gen_register root s (curry (S (S (S (S Z)))) f)

let gen_register5 root s f = gen_register root s (curry (S (S (S (S (S Z))))) f)

let lwt_register0 root s f = lwt_register root s (curry Z f)

let lwt_register1 root s f = lwt_register root s (curry (S Z) f)

let lwt_register2 root s f = lwt_register root s (curry (S (S Z)) f)

let lwt_register3 root s f = lwt_register root s (curry (S (S (S Z))) f)

let lwt_register4 root s f = lwt_register root s (curry (S (S (S (S Z)))) f)

let lwt_register5 root s f = lwt_register root s (curry (S (S (S (S (S Z))))) f)
