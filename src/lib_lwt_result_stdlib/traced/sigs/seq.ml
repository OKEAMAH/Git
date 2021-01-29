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

module type LWTRESLIB_TRACED_SEQ_S = sig
  include Bare_sigs.Seq.S

  type 'error trace

  (** Similar to {!iter} but wraps the iteration in [result Lwt.t]. All the
      steps of the iteration are started concurrently. The promise [iter_ep]
      resolves once all the promises of the traversal resolve. At this point it
      either:
      - is rejected if at least one of the promises is, otherwise
      - is fulfilled with [Error _] if at least one of the promises is,
        otherwise
      - is fulfilled with [Ok ()] if all the promises are. *)
  val iter_ep :
    ('a -> (unit, 'error trace) result Lwt.t) ->
    'a t ->
    (unit, 'error trace) result Lwt.t

  (** Similar to {!map} but wraps the transformation in [result Lwt]. All the
      transformations are done concurrently. The promise [map_p f s] resolves
      once all the promises of the traversal resolve. At this point it is
      rejected if any of the promises are, and otherwise it is resolved with
      [Error _] if any of the promises are, and otherwise it is fulfilled (if
      all the promises are).

      Note that, unlike {!map}, [map_ep] is not lazy: it applies the
      transformation eagerly to all the elements of the sequence and does not
      terminate on infinite sequences. Moreover [map_p] is not tail-recursive.
  *)
  val map_ep :
    ('a -> ('b, 'error trace) result Lwt.t) ->
    'a t ->
    ('b t, 'error trace) result Lwt.t
end
