(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

module type STORED_DATA = sig
  type key

  type value

  val key_encoding : key Data_encoding.t

  val value_encoding : value Data_encoding.t
end

module type STORAGE = sig
  type t

  type key

  type value

  val get_data_dir : t -> string

  type key_value = {key : key; value : value}

  type subpath = string

  (** [init ~max_mutexes path] initiates a value storage at [path]. A maximum of
      [max_fdopen] files can be written or read simultaneously. *)
  val init : max_mutexes:int -> string -> t tzresult Lwt.t

  (** [write_values store commitment values] stores the set [values] on
      [store] associated with [commitment]. In case of IO error, [Io_error] is
      returned. *)
  val write_values :
    t -> subpath:subpath -> (key * value) Seq.t -> unit tzresult Lwt.t

  (** [read_values ~value_size dal_constants store commitment] fetches the
      set of values associated with [commitment] in [store]. The expected size
      of values is given by [dal_constants]. In case of IO error, [Io_error]
      is returned. *)
  val read_values :
    value_size:int -> t -> subpath -> key_value list tzresult Lwt.t

  (** [read_value ~value_size store commitment value_id] fetches the
      value associated to [commitment] in [store] with id [value_id]. In
      case of IO error, [Io_error] is returned.*)
  val read_value :
    value_size:int -> t -> subpath:subpath -> key -> key_value tzresult Lwt.t

  (** [read_values_subset] has the same behavior as [read_value] but fetches
      multiple value. *)
  val read_values_subset :
    value_size:int ->
    t ->
    subpath:subpath ->
    key list ->
    key_value list tzresult Lwt.t
end
