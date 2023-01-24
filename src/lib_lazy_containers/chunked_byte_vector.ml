(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech  <contact@trili.tech>                        *)
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

exception Bounds

exception SizeOverflow

let reraise = function
  | Lazy_vector.Bounds -> raise Bounds
  | Lazy_vector.SizeOverflow -> raise SizeOverflow
  | exn -> raise exn

module Chunk = struct
  type t = bytes

  (** Number of bits in an address for the chunk offset *)
  let offset_bits = 9

  (** Size of a chunk in bytes - with 9 bits of address space the
      chunk is 512 bytes *)
  let size = Int64.shift_left 1L offset_bits

  (** The same size but of it, for internal usage. *)
  let size_int : int = Int.shift_left 1 offset_bits

  (** Get the chunk index for an address. *)
  let index address = Int64.shift_right address offset_bits

  (** Get the offset within its chunk for a given address. *)
  let offset address = Int64.(logand address (sub size 1L))

  (** Get the address from a page index and an offset. *)
  let address ~index ~offset = Int64.(add (shift_left index offset_bits) offset)

  let alloc () = Bytes.make size_int (Char.chr 0)

  let of_bytes bytes =
    let fresh_chunk = alloc () in
    Bytes.blit bytes 0 fresh_chunk 0 (Int.min size_int (Bytes.length bytes)) ;
    fresh_chunk

  let to_bytes = Bytes.copy

  let num_needed length =
    if Int64.compare length 0L > 0 then
      (* [pred length] is used to cover the edge cases where [length] is an exact
          multiple of [Chunk.size]. For example [div Chunk.size Chunk.size] is 1
          but would allocate 2 chunks without a [pred] applied to the first
          argument. *)
      Int64.(div (pred length) size |> succ)
    else 0L

  (* Return left and right addresses of a chunk *)
  let inclusive_boundaries chunk_id =
    ( address ~index:chunk_id ~offset:0L,
      address ~index:chunk_id ~offset:(Int64.sub size 1L) )
end

module Vector = Lazy_vector.Mutable.Int64Vector

type t = {mutable length : int64; chunks : Chunk.t Vector.t}

let def_get_chunk _ = Lwt.return (Chunk.alloc ())

let create ?origin ?get_chunk length =
  let chunks =
    Vector.create ?origin ?produce_value:get_chunk (Chunk.num_needed length)
  in
  {length; chunks}

let origin vector = Vector.origin vector.chunks

let grow vector size_delta =
  if 0L < size_delta then (
    let new_size = Int64.add vector.length size_delta in
    let new_chunks = Chunk.num_needed new_size in
    let current_chunks = Vector.num_elements vector.chunks in
    let chunk_count_delta = Int64.sub new_chunks current_chunks in
    if Int64.compare chunk_count_delta 0L > 0 then
      (* We cannot make any assumption on the previous value of
         [produce_value]. In particular, it may very well raise an
         error in case of absent value (which is the case when
         growing the chunked byte vector requires to allocate new
         chunks). *)
      Vector.grow chunk_count_delta vector.chunks ;
    vector.length <- new_size)

let allocate length =
  let res = create 0L in
  grow res length ;
  res

let length vector = vector.length

let get_chunk index {chunks; _} =
  Lwt.catch
    (fun () -> Vector.get index chunks)
    (function
      | Lazy_vector.Bounds as exn -> reraise exn | _ -> def_get_chunk ())

let set_chunk index chunk {chunks; _} =
  try Vector.set index chunk chunks with exn -> reraise exn

let load_byte vector address =
  let open Lwt.Syntax in
  if Int64.compare address vector.length >= 0 then raise Bounds ;
  let+ chunk = get_chunk (Chunk.index address) vector in
  Bytes.get chunk (Int64.to_int @@ Chunk.offset address) |> Char.code

let load_bytes vector offset length =
  let open Lwt.Syntax in
  let end_offset = Int64.pred @@ Int64.add offset length in
  (* Ensure [offset] and [end_offset] are valid indeces in the vector.

     Once we ensure the vector can be contained in a string, we can safely
     convert everything to int, since the size of the vector is contained in
     a `nativeint`. See {!of_string} comment. *)
  if
    offset < 0L || length < 0L
    || end_offset >= vector.length
    || vector.length > Int64.of_int Sys.max_string_length
  then raise Bounds ;

  let rec list_chunks (pos : int64) (acc : bytes list) =
    if pos > end_offset then Lwt.return (List.rev acc)
    else
      let chunk_id = Chunk.index pos in
      let left, right = Chunk.inclusive_boundaries chunk_id in
      let* chunk = get_chunk chunk_id vector in
      let sub_chunk =
        (* Chunk fully lies in the requested boundaries, hence we don't need to copy it*)
        if left == pos && right <= end_offset then chunk
        else
          let l_offset_chunk = Chunk.offset @@ Int64.max left pos in
          let r_offset_chunk = Chunk.offset @@ Int64.min right end_offset in
          Bytes.sub
            chunk
            (Int64.to_int l_offset_chunk)
            (Int64.to_int
            @@ Int64.add (Int64.sub r_offset_chunk l_offset_chunk) 1L)
      in
      (list_chunks [@tailcall])
        (Int64.add pos @@ Int64.of_int @@ Bytes.length sub_chunk)
        (sub_chunk :: acc)
  in
  let+ chunks = list_chunks offset [] in
  Bytes.concat Bytes.empty chunks

let store_byte vector address byte =
  let open Lwt.Syntax in
  if Int64.compare address vector.length >= 0 then raise Bounds ;
  let+ chunk = get_chunk (Chunk.index address) vector in
  Bytes.set chunk (Int64.to_int @@ Chunk.offset address) (Char.chr byte) ;
  (* This is necessary because [get_chunk] might provide a default
     value without loading any data. *)
  Vector.set (Chunk.index address) chunk vector.chunks

let store_bytes vector offset bytes =
  let open Lwt.Syntax in
  let length = Int64.of_int @@ Bytes.length bytes in
  let end_offset = Int64.pred @@ Int64.add offset length in
  if
    offset < 0L
    || end_offset >= vector.length
    || vector.length > Int64.of_int Sys.max_string_length
  then raise Bounds ;

  let rec set_chunks (pos : int64) =
    if pos >= length then Lwt.return_unit
    else
      let offseted_pos = Int64.add offset pos in
      let chunk_id = Chunk.index offseted_pos in
      let _, chunk_right = Chunk.inclusive_boundaries chunk_id in
      let* chunk = get_chunk chunk_id vector in
      (* [l_range; r_range] in the chunk which has to be rewritten *)
      let l_range = Chunk.offset offseted_pos in
      let r_range =
        if end_offset >= chunk_right then Int64.sub Chunk.size 1L
        else Chunk.offset end_offset
      in
      let len_range = Int64.add (Int64.sub r_range l_range) 1L in
      Bytes.blit
        bytes
        (Int64.to_int pos)
        chunk
        (Int64.to_int l_range)
        (Int64.to_int len_range) ;
      set_chunk chunk_id chunk vector ;
      (set_chunks [@tailcall]) (Int64.add pos len_range)
  in
  set_chunks 0L

let of_bytes bytes =
  let length = Int64.of_int (Bytes.length bytes) in
  let vector = allocate length in
  let rec set_chunks (chunk_id : int64) =
    let chunk_left, chunk_right = Chunk.inclusive_boundaries chunk_id in
    if chunk_left >= length then ()
    else
      let chunk =
        if chunk_right < length then
          (* Full chunk *)
          Bytes.sub bytes (Int64.to_int chunk_left) (Int64.to_int Chunk.size)
        else
          (* Chunk consisted of bytes suffix + padding of zeros *)
          let fresh_chunk = Chunk.alloc () in
          Bytes.blit
            bytes
            (Int64.to_int chunk_left)
            fresh_chunk
            0
            (Int64.to_int @@ Int64.sub length chunk_left) ;
          fresh_chunk
      in
      set_chunk chunk_id chunk vector ;
      (set_chunks [@tailcall]) (Int64.add chunk_id 1L)
  in
  set_chunks 0L ;
  vector

let of_string str =
  (* Strings are limited in size and contained in `nativeint` (either int31 or
     int63 depending of the architecture). The maximum size of strings in
     OCaml is limited by {!Sys.max_string_length} which is lesser than
     `Int64.max_int` (and even Int.max_int). As such conversions from / to
     Int64 to manipulate the vector is safe since the size of the
     Chunked_byte_vector from a string can be contained in an `int`.

       Moreover, WASM strings are limited to max_uint32 in size for data
       segments, which is the primary usage of this function in the text
       parser. *)
  of_bytes @@ Bytes.of_string str

let to_bytes vector = load_bytes vector 0L vector.length

let to_string vector =
  let open Lwt.Syntax in
  let+ buffer = to_bytes vector in
  Bytes.to_string buffer

let loaded_chunks vector =
  Vector.Vector.loaded_bindings (Vector.snapshot vector.chunks)
