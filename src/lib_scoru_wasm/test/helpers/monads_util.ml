(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech  <contact@trili.tech>                        *)
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

open QCheck2
open Tezos_test_helpers.Qcheck_extra
module RS = Random.State

module type State = sig
  type t
end

module Monad_ops (M : Monad.S) = struct
  let rec fold_left ~(f : 'a -> 'b -> 'a M.t) (z : 'a) (l : 'b list) : 'a M.t =
    match l with
    | [] -> M.return z
    | x :: rest -> M.bind (f z x) (fun res -> fold_left ~f res rest)

  let rec repeat_n ~(f : unit M.t) (n : int) : unit M.t =
    if n <= 0 then M.return () else M.bind f (fun _ -> repeat_n ~f (n - 1))

  let rec iter_n ~(f : 'a -> 'a M.t) (z : 'a) (n : int) : 'a M.t =
    if n <= 0 then M.return z
    else M.bind (f z) (fun res -> iter_n ~f res (n - 1))

  let rec traverse_seq (xs: 'a M.t Seq.t): 'a Seq.t M.t =
    (* HERE: I actually have to evaluate lazy valuees of Seq *)
    match Seq.uncons xs with
      | None -> M.return Seq.empty
      | Some (x, rest) -> M.bind x (fun x -> M.map (Seq.cons x) @@ traverse_seq rest)
end

(* Lwt.t which has some state, satisfies Monad.S *)
module Lwt_state (S : State) = struct
  type 'a t = S.t -> ('a * S.t) Lwt.t

  let return (x : 'a) : 'a t = fun s -> Lwt.return (x, s)

  let bind a f s =
    let open Lwt_syntax in
    let* r_a, s_1 = a s in
    f r_a s_1

  let ( let* ) = bind

  let map f a s = Lwt.map (fun (x, s) -> (f x, s)) @@ a s

  let product a b = bind a @@ fun a -> map (fun b -> (a, b)) b

  let map2 f a b s =
    let open Lwt_syntax in
    let* r_a, s_1 = a s in
    let+ r_b, s_2 = b s_1 in
    (f r_a r_b, s_2)

  let join f = bind f Fun.id

  let get_state s = Lwt.return (s, s)

  let set_state s _ = Lwt.return ((), s)

  let lift_lwt lwt s = Lwt.map (fun a -> (a, s)) lwt
end

(* This is a monad transofrmer,
   which stacks Gen monad over another one.
   Satisfies Monad.S
*)
module Gen_m (M : Monad.S) = struct
  let unpack_tree t = (Tree.root t, Tree.children t)

  (* This is basically Gen2.t but with tree_m and returned type wrapped with M.t. *)
  type 'a t = RS.t -> 'a Tree.t M.t

  (* Adapted version of QCheck2.Tree.bind *)
  let bind (m : 'a t) (f : 'a -> 'b t) : 'b t =
   fun g ->
    let open Monad.Syntax (M) in
    let rec bind_tree (ta : 'a Tree.t) (f : 'a -> 'b Tree.t M.t) :
        'b Tree.t M.t =
      let open Monad_ops(M) in
      let x, xs = unpack_tree ta in
      let* (y, ys_of_x) = M.map unpack_tree @@ f x in
      let ys_of_xs_m =
        Seq.map (fun tree -> bind_tree tree f) xs
      in
      (* HERE: in traverse_seq I have to traverse lazy Seq and
      essentially evaluate all of them, which will cause recursive invocation of
      bind_tree, which is also eagerly evaluate tree recursively.
      Which will effectively lead to eager evaluation of the whole tree.
      *)
      let* ys_of_xs = traverse_seq ys_of_xs_m in
      let ys = Seq.append ys_of_x ys_of_xs in
      (** HERE: I can't construct a tree *)
      M.return @@ Tree.make (y, ys)
    in
    let* m = m g in
    bind_tree m (fun x -> f x g)

  let map f x g = M.map f (x g)

  let return x _ = M.return x

  let ( let* ) = bind

  let map2 f x y g = M.map2 f (x g) (y g)

  let join x =
    let* y = x in
    y

  let product x y = map2 (fun x y -> (x, y)) x y

  let ( and+ ) = product

  let ( let+ ) x f = map f x

  let lift_gen (gen : 'a Gen.t) : 'a t =
   fun g -> M.return @@ Gen.generate1 ~rand:g gen

  let lift_m (m : 'a M.t) : 'a t = fun _ -> m

  (* ? here stands for an "uncertain" value provided by Gen *)
  let ( let*? ) (a : 'a Gen.t) (f : 'a -> 'b t) : 'b t = bind (lift_gen a) f

  let ( let*! ) (a : 'a M.t) (f : 'a -> 'b t) : 'b t = bind (lift_m a) f
end

(* QCheck.Gen with product to satisfy Monad.Syntax *)
module Gen_syntax = Monad.Syntax (struct
  include QCheck.Gen

  let bind = ( >>= )

  let product x y = map2 (fun x y -> (x, y)) x y
end)

(* This monad:
   1. allows to use Gen.t methods
   2. keeps track of some state
   3. allows running Lwt actions
*)
module Gen_lwt (S : State) = struct
  module Lwt_state = Lwt_state (S)
  include Gen_m (Lwt_state)

  let get_state : S.t t = fun _ -> Lwt_state.get_state

  let set_state (s : S.t) : unit t = fun _ -> Lwt_state.set_state s

  let modify_state (f : S.t -> S.t) : unit t =
    let* s = get_state in
    set_state (f s)

  let lift_lwt (lwt : 'a Lwt.t) : 'a t = fun _ -> Lwt_state.lift_lwt lwt
end

module Gen_substate (S1 : State) (S2 : State) = struct
  module S = struct
    type t = S1.t * S2.t
  end

  let lift (act : 'a Gen_lwt(S1).t) : 'a Gen_lwt(S).t =
   fun g (s1, s2) -> Lwt.map (fun (a, s1_new) -> (a, (s1_new, s2))) (act g s1)
end

(* This is a syntax for Gen_lwt *)
module Gen_lwt_syntax (S : State) = struct
  module Gen_lwt = Gen_lwt (S)
  include Monad.Syntax (Gen_lwt)

  let ( let*? ) = Gen_lwt.( let*? )

  let ( let*! ) (lwt : 'a Lwt.t) f = Gen_lwt.bind (Gen_lwt.lift_lwt lwt) f
end
