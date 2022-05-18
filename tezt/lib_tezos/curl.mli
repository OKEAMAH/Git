(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** [get ()] returns [Some curl] where [curl ~url] returns the raw response
    obtained by curl when requesting [url]. Returns [None] if [curl] cannot be
    found. *)
val get : unit -> (url:string -> JSON.t Lwt.t) option Lwt.t

(** [post data] returns [Some curl] where [curl ~url data] returns the raw
    response obtained by curl when posting the data to [url]. Returns [None] if
    [curl] cannot be found. *)
val post : unit -> (url:string -> JSON.t -> JSON.t Lwt.t) option Lwt.t

(** [stream ()] returns [Some (f, close)] where [f ~url] returns a stream
    containing the JSON items of the response and [close] is a callback function
    to close the connection (by terminating the curl process). Note that the
    streaming RPC must be produce one JSON value per line. Returns [None] if
    [curl] cannot be found. *)
val stream :
  unit -> (url:string -> JSON.t Lwt_stream.t * (unit -> unit)) option Lwt.t
