module TzStdLib = Tezos_lwt_result_stdlib.Lwtreslib.Bare
open Sigs

type key = string list

module type S = sig
  type tree

  type -'a t

  val contramap : ('a -> 'b) -> 'b t -> 'a t

  val contramap_lwt : ('a -> 'b Lwt.t) -> 'b t -> 'a t

  val prod : 'a t -> 'b t -> ('a * 'b) t

  val prod3 : 'a t -> 'b t -> 'c t -> ('a * 'b * 'c) t

  val run : 'a t -> 'a -> tree -> tree Lwt.t

  val raw : key -> bytes t

  val value : key -> 'a Data_encoding.t -> 'a t

  val tree : key -> 'a t -> 'a t

  val lazy_mapping : ('k -> key) -> 'v t -> ('k * 'v) list t

  type ('tag, 'a) case

  val case : 'tag -> 'b t -> ('a -> 'b option) -> ('tag, 'a) case

  val tagged_union : 'tag t -> ('tag, 'a) case list -> 'a t

  val of_lwt : 'a t -> 'a Lwt.t t
end

module Make (T : TreeS) : S with type tree = T.tree = struct
  (** Given the tail key, construct a full key. *)
  type prefix_key = key -> key

  (** [of_key key] constructs a [prefix_key] where [key] is the prefix. *)
  let of_key key tail =
    let rec go = function [] -> tail | x :: xs -> x :: go xs in
    go key

  (** [append_key prefix key] append [key] to [prefix] in order to create a new
      [prefix_key]. *)
  let append_key prefix key tail = prefix (of_key key tail)

  type tree = T.tree

  type -'a t = 'a -> prefix_key -> tree -> tree Lwt.t

  let of_lwt enc value prefix tree =
    Lwt.bind value (fun value -> enc value prefix tree)

  let contramap f enc value = enc (f value)

  let contramap_lwt f enc value prefix tree =
    Lwt.bind (f value) (fun value -> enc value prefix tree)

  let prod lhs rhs (l, r) prefix tree =
    let open Lwt.Syntax in
    let* tree = lhs l prefix tree in
    rhs r prefix tree

  let prod3 encode_a encode_b encode_c (a, b, c) prefix tree =
    let open Lwt.Syntax in
    let* tree = encode_a a prefix tree in
    let* tree = encode_b b prefix tree in
    encode_c c prefix tree

  let run dec value tree = dec value Fun.id tree

  let raw suffix bytes prefix tree = T.add tree (prefix suffix) bytes

  let value suffix enc =
    contramap (Data_encoding.Binary.to_bytes_exn enc) (raw suffix)

  let tree key enc value prefix tree = enc value (append_key prefix key) tree

  let lazy_mapping to_key enc_value bindings prefix tree =
    TzStdLib.List.fold_left_s
      (fun tree (k, v) ->
        let key = append_key prefix (to_key k) in
        enc_value v key tree)
      tree
      bindings

  type ('tag, 'a) case =
    | Case : {
        tag : 'tag;
        probe : 'a -> 'b option;
        encode : 'b t;
      }
        -> ('tag, 'a) case

  let case tag encode probe = Case {tag; encode; probe}

  let tagged_union encode_tag cases value prefix target_tree =
    let open Lwt.Syntax in
    let encode_tag = tree ["tag"] encode_tag in
    let rec find_case cases =
      match cases with
      | [] -> failwith "None of the cases matched!"
      | Case case :: cases -> (
          match case.probe value with
          | Some value ->
              let* target_tree = encode_tag case.tag prefix target_tree in
              tree ["value"] case.encode value prefix target_tree
          | None -> find_case cases)
    in
    find_case cases
end
