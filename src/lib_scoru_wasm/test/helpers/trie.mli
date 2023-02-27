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

(* In-memory trie implementation.
   It's needed for three reasons:
    1. To generated initialy decoded irmin tree.
    2. To keep track of tree structure in order to generate keys and offsets
       for stress-tests operations properly.
       During stress-testing we would like to maintain a requested
       percent of valid operations: it's why we need this tree.
    3. In order to have all operations on the trie pure and, hence,
       be able to use it in QCheck.Gen.
*)

module Map : module type of Map.Make (String)

(* Support subtree sizes in order to generate keys evenly *)
type 'a t = {
  value : 'a option;
  children : 'a t Map.t;
  keys_count : int;
  nodes_count : int; (* including empty one *)
}

val empty : 'a t

val set_value : edit_readonly:bool -> string -> 'a -> 'a t -> 'a t option

val get_value : string -> 'a t -> 'a option

val lookup : string -> 'a t -> 'a t option

val subtrees_size : string -> 'a t -> int

val copy_tree : edit_readonly:bool -> string -> string -> 'a t -> 'a t option

val move_tree : string -> string -> 'a t -> 'a t option

val delete : edit_readonly:bool -> string -> 'a t -> 'a t option
