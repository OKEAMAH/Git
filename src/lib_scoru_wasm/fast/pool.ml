(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
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

open Stdlib_ext

module type Policy = sig
  type 'a cell

  (** [remove key_cell_pairs] is called when the pool is full and needs to accomodate 
  a new element. It extracts from the [key_cell_pairs] the pair to be removed and
  returns a tuple containing the remaining key-cell pairs.

  If [key_cell_pairs] is empty it returns the empty Seq.t
  *)
  val remove : (string * 'a cell) Seq.t -> (string * 'a cell) Seq.t

  (** [make_cell value] creates a cell with the given [value] *)
  val make_cell : 'a -> 'a cell

  (** [get_content cell] is the data stored in the [cell] *)
  val get_content : 'a cell -> 'a

  (** [use cell f] Applies [f] to the [cell] content and returns a promise of the
   new cell value and the result *)
  val use : 'a cell -> ('a -> 'r) -> 'a cell * 'r
end

module type S = sig
  (** A pool which identifies the pool elements by key. It allows multiple concurent
      uses of the same resource as long as the users requested the same key
      *)
  type 'a t

  type resource_id = string

  module Policy : Policy

  (** [init pool_size] creates a pool of [pool_size].
  *)
  val init : int -> 'a t

  (** [use key ctor f pool] 
    Looks up the [key] in the [pool]. 
    
    If the [key] is found then a pair containing then [f] is called with the 
    corresponding element is returned. 
    
    If the [key] is NOT found then a new element is created by calling [ctor] and 
    it's added to the pool, then [f] is called.

    If the pool size is reached, one element is picked for removal using the given 

    In case of concurrent uses of the same key, the callers 
    [Policy].
    *)
  val use : resource_id -> (unit -> 'a) -> ('a -> 'r Lwt.t) -> 'a t -> 'r Lwt.t
end

module Make (P : Policy) : S = struct
  module M = Map.Make (String)

  type resource_id = string

  module Policy = P

  type 'a t = {
    store : 'a P.cell Lwt_mvar.t M.t Lwt_mvar.t;
    max_size : int;
    size : int;
  }

  let init max_size = {store = Lwt_mvar.create M.empty; max_size; size = 0}

  let use (type a b) key (ctor : unit -> a) (f : a -> b Lwt.t) (pool : a t) :
      b Lwt.t =
    let lookup_or_insert (map_content : a P.cell Lwt_mvar.t M.t) =
      let open Lwt.Syntax in
      let map_content =
        M.update
          key
          (fun maybe_cell ->
            Option.either_f maybe_cell @@ fun () ->
            let new_cell = Lwt_mvar.create @@ P.make_cell @@ ctor () in
            Some new_cell)
          map_content
      in
      (* We need to keep the pool.size <= pool.max_size. The above M.update might
          have grown the pool above the limit. If that's the case we have to
         remove the extra items
      *)
      let* map_content =
        if pool.size > pool.max_size then
          let get_cell (key, cell_mvar) =
            Lwt_mvar.use cell_mvar @@ fun cell -> Lwt.return (cell, (key, cell))
          in
          let key_cell_seq = Lwt_seq.of_seq @@ M.to_seq map_content in
          let+ key_content_list =
            Lwt_seq.to_list @@ Lwt_seq.map_s get_cell key_cell_seq
          in
          M.of_seq
          @@ Seq.map (fun (key, cell) -> (key, Lwt_mvar.create cell))
          @@ List.to_seq key_content_list
        else Lwt.return map_content
      in

      (* We need to do a second lookup because M.update above doesn't return the
         freshly created cell
      *)
      let new_cell =
        Option.value_f ~default:(fun () ->
            (* It must be found because it was either present before or
               inserted in the M.update call*)
            assert false)
        @@ M.find key map_content
      in
      Lwt.return (map_content, new_cell)
    in

    let open Lwt.Syntax in
    let* cell_mvar = Lwt_mvar.use pool.store lookup_or_insert in

    Lwt_mvar.use cell_mvar @@ fun cell ->
    let cell, result_promise = P.use cell f in
    let+ result = result_promise in
    (cell, result)
end

module LeastRecentlyUsed : Policy = struct
  type 'a cell = {value : 'a; last_usage_time : float}

  (** Removes the least recently used (LRU) from [key_cell_pairs].

      Asserts that the input is never empty i.e. a minimum can always be found. 
      Although we could return an empty list, such a situation would definitely
      signal a bug in the code so it's better to assert instead of continuing silently.
  *)
  let remove key_cell_pairs : (string * 'a cell) Seq.t =
    (* lru = least recently used *)
    let remove_lru (lru_key, _lru) =
      Seq.filter (fun (k, _) -> k != lru_key) key_cell_pairs
    in
    let lru_pair =
      Seq.min_by
        (fun (_key_a, a) (_key_b, b) -> a.last_usage_time > b.last_usage_time)
        key_cell_pairs
    in
    lru_pair |> Option.map remove_lru
    |> Option.value_f ~default:(fun () -> assert false)

  let use cell f =
    let r = f cell.value in
    let cell = {value = cell.value; last_usage_time = Unix.time ()} in
    (cell, r)

  let make_cell value = {value; last_usage_time = Unix.time ()}

  let get_content cell = cell.value
end
