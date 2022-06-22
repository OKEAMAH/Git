open Sigs
open Tezos_webassembly_interpreter

type key = string list

module type S = sig
  type tree

  module E : Tree_encoding.S with type tree = tree

  module D : Tree_decoding.S with type tree = tree

  type 'a t

  val conv : ('a -> 'b) -> ('b -> 'a) -> 'a t -> 'b t

  val conv_lwt : ('a -> 'b Lwt.t) -> ('b -> 'a Lwt.t) -> 'a t -> 'b t

  val prod : 'a t -> 'b t -> ('a * 'b) t

  val prod3 : 'a t -> 'b t -> 'c t -> ('a * 'b * 'c) t

  val encode : 'a t -> 'a -> tree -> tree Lwt.t

  val decode : 'a t -> tree -> 'a Lwt.t

  val raw : key -> bytes t

  val value : key -> 'a Data_encoding.t -> 'a t

  val tree : key -> 'a t -> 'a t

  module LazyMap (M : Lazy_map.S with type 'a effect = 'a Lwt.t) : sig
    type 'a map = 'a M.t

    val lazy_mapping : 'a t -> 'a map t
  end

  module LazyVector (V : Lazy_vector.S with type 'a effect = 'a Lwt.t) : sig
    type 'a vector = 'a V.t

    val lazy_vector : V.key t -> 'a t -> 'a vector t
  end

  type ('tag, 'a) case

  val case : 'tag -> 'b t -> ('a -> 'b option) -> ('b -> 'a) -> ('tag, 'a) case

  val tagged_union : 'tag t -> ('tag, 'a) case list -> 'a t
end

module Make (T : TreeS) : S with type tree = T.tree = struct
  module E = Tree_encoding.Make (T)
  module D = Tree_decoding.Make (T)

  type tree = T.tree

  type 'a t = {encode : 'a E.t; decode : 'a D.t}

  let conv d e {encode; decode} =
    {encode = E.contramap e encode; decode = D.map d decode}

  let conv_lwt d e {encode; decode} =
    {encode = E.contramap_lwt e encode; decode = D.map_lwt d decode}

  let prod lhs rhs =
    {
      encode = E.prod lhs.encode rhs.encode;
      decode = D.prod lhs.decode rhs.decode;
    }

  let prod3 one two three =
    conv
      (fun (a, (b, c)) -> (a, b, c))
      (fun (a, b, c) -> (a, (b, c)))
      (prod one (prod two three))

  let encode {encode; _} value tree = E.run encode value tree

  let decode {decode; _} tree = D.run decode tree

  let raw key = {encode = E.raw key; decode = D.raw key}

  let value key de = {encode = E.value key de; decode = D.value key de}

  let tree key {encode; decode} =
    {encode = E.tree key encode; decode = D.tree key decode}

  module LazyMap (M : Lazy_map.S with type 'a effect = 'a Lwt.t) = struct
    type 'a map = 'a M.t

    let lazy_mapping value =
      let to_key k = [M.Key.to_string k] in
      let encode =
        E.contramap M.__internal__bindings (E.lazy_mapping to_key value.encode)
      in
      let decode =
        D.map
          (fun produce_value -> M.create ~produce_value ())
          (D.lazy_mapping to_key value.decode)
      in
      {encode; decode}
  end

  module LazyVector (V : Lazy_vector.S with type 'a effect = 'a Lwt.t) = struct
    type 'a vector = 'a V.t

    let lazy_vector with_key value =
      let to_key k = [V.Key.to_string k] in
      let encode =
        E.contramap
          (fun vector ->
            ( V.__internal__bindings vector,
              V.num_elements vector,
              V.__internal__first vector ))
          (E.prod3
             (E.lazy_mapping to_key value.encode)
             (E.tree ["length"] with_key.encode)
             (E.tree ["head"] with_key.encode))
      in
      let decode =
        D.map
          (fun (produce_value, len, head) ->
            V.__internal__create ~produce_value head len)
          (D.prod3
             (D.lazy_mapping to_key value.decode)
             (D.tree ["length"] with_key.decode)
             (D.tree ["head"] with_key.decode))
      in
      {encode; decode}
  end

  type ('tag, 'a) case =
    | Case : {
        tag : 'tag;
        probe : 'a -> 'b option;
        extract : 'b -> 'a;
        delegate : 'b t;
      }
        -> ('tag, 'a) case

  let case tag delegate probe extract = Case {tag; delegate; probe; extract}

  let tagged_union tag cases =
    let to_encode_case (Case case) =
      E.case case.tag case.delegate.encode case.probe
    in
    let to_decode_case (Case case) =
      D.case case.tag case.delegate.decode case.extract
    in
    let encode = E.tagged_union tag.encode (List.map to_encode_case cases) in
    let decode = D.tagged_union tag.decode (List.map to_decode_case cases) in
    {encode; decode}
end
