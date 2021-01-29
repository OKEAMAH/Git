(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** [Error_monad]-aware replacements for parts of the Stdlib.

    This library aims to provide replacements to some parts of the Stdlib that:

    - do not raise exceptions (e.g., it shadows [Map.find] with [Map.find_opt]),
    - include traversal functions for Lwt (think [Lwt_list] for [List]),
      [tzresult], and the combined [tzresult]-Lwt monad (think the
      list-traversal functions from [Error_monad].

    The aim is to allow the use of the standard OCaml data-structures within the
    context of Lwt and the Error monad. This is already somewhat available for
    [List] through the combination of {!Stdlib.List} (for basic functionality),
    {!Lwt_list} (for the Lwt-aware traversals), and {!Error_monad} (for the
    error-aware and combined-error-lwt-aware traversal).

    More and more modules will be added to this Library. In particular [List]
    (to avoid splitting the functionality from three distinct libraries and to
    provide more consistent coverage) and [Array] will be made available.

*)

module Trace = Tezos_error_monad.Error_monad.TzTrace

module Monad : Traced_sigs.Monad.S with type 'error trace = 'error Trace.trace

module Hashtbl :
  Traced_sigs.Hashtbl.LWTRESLIB_TRACED_HASHTBL_S
    with type 'error trace := 'error Trace.trace

module List :
  Traced_sigs.List.LWTRESLIB_TRACED_LIST_S
    with type 'error trace := 'error Trace.trace

module Map :
  Traced_sigs.Map.LWTRESLIB_TRACED_MAP_S
    with type 'error trace := 'error Trace.trace

module Option : Traced_sigs.Option.S

module Result : Traced_sigs.Result.S

module Seq :
  Traced_sigs.Seq.LWTRESLIB_TRACED_SEQ_S
    with type 'error trace := 'error Trace.trace

module Set :
  Traced_sigs.Set.LWTRESLIB_TRACED_SET_S
    with type 'error trace := 'error Trace.trace

module WithExceptions : Traced_sigs.WithExceptions.S
