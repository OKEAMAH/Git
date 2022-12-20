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

(* This LRU aims to contains ['value Store.t] which handles the
   persistent storage for this value. [Store.t] allows to keep in
   memory the content of the file. However, because there could be
   numerous values to store, we use an LRU to avoid memory leaks. *)
module LRU =
  Aches_lwt.Lache.Make_result
    (Aches.Rache.Transfer
       (Aches.Rache.LRU)
       (struct
         type t = string

         let equal = String.equal

         let hash = Hashtbl.hash
       end))

type ('key, 'value) t =
  | E : {
      file_of : 'key -> ('filename, 'value) File.t;
          (* Map a [key] to the file containing the corresponding [value]. *)
      lru : ('value Store.t, tztrace) LRU.t;
          (* LRU which keeps in memory the last [values] stored. *)
      pool : unit Lwt_pool.t option;
          (* An optional pool to ensure that gives an upper bound of the number of file descriptors opened by this store. *)
    }
      -> ('key, 'value) t

let with_pool pool f =
  match pool with None -> f () | Some pool -> Lwt_pool.use pool f

let init ?pool ~lru_size file_of =
  let lru = LRU.create lru_size in
  E {file_of; lru; pool}

let read_value (E {lru; file_of; pool}) key =
  let open Lwt_result_syntax in
  let file = file_of key in
  LRU.bind_or_put
    lru
    file.path
    (fun _path -> with_pool pool (fun () -> Store.load file))
    (function
      | Error err -> fail err
      | Ok store ->
          let*! value = Store.get store in
          Lwt.return_ok value)

let write_value (type value) (E {lru; file_of; pool} as t) key (value : value) =
  let open Lwt_result_syntax in
  let file = file_of key in
  (* If the value is already cached there is nothing to store. If the
     value is not cached, the underlying store will fail because the
     file does not exists. In both, this should be easy to check.

     If we do not read a value, there could be a race condition where
     concurrently there is a [read/write] for the same key. If the
     [read] failed first, the [write] will fail too. To prevent that,
     we first [read] the value.

     This may induce a slight over head. This could be increased later
     on if we realise this is too slow. *)
  let*! result = read_value t key in
  match result with
  | Ok _value -> return_unit
  | Error _ ->
      (* The read failed, we store the value. *)
      ignore (LRU.take lru file.path) ;
      LRU.bind_or_put
        lru
        file.path
        (fun _path ->
          with_pool pool (fun () ->
              let open Tezos_stdlib_unix.Lwt_utils_unix in
              let*! result = create_parent file.path in
              match result with
              | Ok () -> Store.init file ~initial_data:value
              | Error err -> Lwt.return (tzfail_of_io_error err)))
        (function
          | Error err -> fail err
          | Ok store ->
              Store.update_with store (fun (_ : value) -> Lwt.return value))

let write_values t seq =
  Seq.iter_es (fun (key, value) -> write_value t key value) seq

let read_values t seq =
  let open Lwt_syntax in
  Seq_s.of_seq seq
  |> Seq_s.map_s (fun key ->
         let* maybe_value = read_value t key in
         return (key, maybe_value))
