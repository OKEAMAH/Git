open Tezos_lwt_result_stdlib.Lwtreslib.Bare
open Lwt.Syntax
open Sigs

module type S = sig
  type tree

  type key = string list

  type 'a t

  val run : 'a t -> tree -> 'a Lwt.t

  val raw : key -> bytes t

  val value : key -> 'a Data_encoding.t -> 'a t

  val tree : key -> 'a t -> 'a t

  val return : 'a -> 'a t

  val iterate : key -> (string -> 'a) t -> 'a list t

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t

  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t

  val ( and* ) : 'a t -> 'b t -> ('a * 'b) t
end

module Make (T : TreeS) : S with type tree = T.tree = struct
  module Tree = T

  type key = T.key

  type tree = T.tree

  exception KeyNotFound of Tree.key

  type 'a t = Tree.tree -> 'a Lwt.t

  let run = Fun.id

  let raw key tree =
    let+ value = Tree.find tree key in
    match value with Some value -> value | None -> raise (KeyNotFound key)

  let value key decoder tree =
    let+ value = Tree.find tree key in
    match value with
    | Some value -> Data_encoding.Binary.of_bytes_exn decoder value
    | None -> raise (KeyNotFound key)

  let tree key enc tree =
    let* tree = Tree.find_tree tree key in
    match tree with Some tree -> enc tree | None -> raise (KeyNotFound key)

  let return value _tree = Lwt.return value

  let iterate key inner tree =
    let* fields =
      (* XXX: This is not lazy! *)
      Tree.list tree key
    in
    List.map_s
      (fun (name, tree) ->
        let+ f = inner tree in
        f name)
      fields

  let ( let+ ) enc f tree = Lwt.map f (enc tree)

  let ( and+ ) lhs rhs tree = Lwt.Syntax.( and+ ) (lhs tree) (rhs tree)

  let ( let* ) enc f tree = Lwt.bind (enc tree) (fun x -> f x tree)

  let ( and* ) = ( and+ )
end
