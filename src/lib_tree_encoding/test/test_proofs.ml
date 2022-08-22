(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs  <contact@nomadic-labs.com>               *)
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

(** Testing
    -------
    Component:    Tree_encoding
    Invocation:   dune exec src/lib_tree_encoding/test/test_tree_encoding.exe \
                  -- test "^Proofs$"
    Subject:      Proof-related tests for the tree-encoding library
*)

open Tztest
open Lazy_containers
module Tree_encoding = Test_encoding.Tree_encoding
module Context = Test_encoding.Context
module Vector = Lazy_vector.IntVector

type t = int Vector.t * int Vector.t

let encoding =
  let open Tree_encoding in
  let int = value [] Data_encoding.int31 in
  tup3
    ~flatten:false
    (int_lazy_vector int int)
    (int_lazy_vector int int)
    (int_lazy_vector int int)

let test_move_subtrees () =
  let open Lwt_syntax in
  (* initializing large data *)
  let v1 =
    List.fold_left (fun v x -> Vector.set x x v) (Vector.create 1_000)
    @@ Stdlib.List.init 1_000 Fun.id
  in
  let v2 =
    List.fold_left (fun v x -> Vector.set x (x * 1000) v) (Vector.create 2_000)
    @@ Stdlib.List.init 2_000 Fun.id
  in
  let v3 =
    List.fold_left (fun v x -> Vector.set x (x + 20) v) (Vector.create 2_000)
    @@ Stdlib.List.init 500 Fun.id
  in
  let* index = Context.init "/tmp" in
  let context = Context.empty index in
  let tree = Context.Tree.empty context in
  (* encoding *)
  let* tree = Tree_encoding.encode encoding (v1, v2, v3) tree in
  (* commit tree *)
  let* context = Context.add_tree context [] tree in
  let* _hash = Context.commit ~time:Time.Protocol.epoch context in
  let index = Context.index context in
  (* produce a proof for the next steps *)
  let* res =
    match Context.Tree.kinded_key tree with
    | Some k ->
        let* p =
          Context.produce_tree_proof index k (fun tree ->
              (* decoding *)
              let* v1, v2, v3 = Tree_encoding.decode encoding tree in
              (* swap, encode *)
              let+ tree' = Tree_encoding.encode encoding (v3, v1, v2) tree in
              (tree', ()))
        in
        return (Some p)
    | None ->
        Stdlib.failwith "could not produce the inputs of produce_tree_proof"
  in
  let proof_size =
    match res with
    | Some (proof, ()) ->
        Data_encoding.Binary.length
          Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V1.Tree2
          .tree_proof_encoding
          proof
    | None -> Stdlib.failwith "could not produce proof"
  in
  (* This constant is set arbitrarily low. It’s basically a budget for
     a dozens of 32-byte hashes, which should be more than enough to read three
     lazy vectors in a tree. *)
  assert (proof_size < 400) ;
  Lwt.return_ok ()

let tests = [tztest "Move subtrees" `Quick test_move_subtrees]
