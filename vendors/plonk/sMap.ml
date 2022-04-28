module StringMap = struct
  include Map.Make (String)

  let of_list l = of_seq (List.to_seq l)

  let encoding : 'a Data_encoding.t -> 'a t Data_encoding.t =
   fun inner_enc ->
    let to_list m = List.of_seq @@ to_seq m in
    Data_encoding.(conv to_list of_list (list (tup2 string inner_enc)))

  let to_bytes printer map =
    fold
      (fun key elt state ->
        Bytes.cat (Bytes.of_string key) (Bytes.cat (printer elt) state))
      map
      Bytes.empty

  (* Return the union of two maps. The keys of the maps have to be disjoint unless
     specifically stated in common_keys. In this case both key's values
     are asserted to be equal, with a given equality function.
     If no equal function is given the polymorphic euqality is used.*)
  let union_disjoint ?(common_keys_equal_elt = ([], ( = ))) x y =
    let (common_keys, equal_elt) = common_keys_equal_elt in
    union
      (fun key elt_1 elt_2 ->
        if not (List.mem key common_keys) then
          raise
            (Invalid_argument
               (Printf.sprintf
                  "the key %s appears in both union arguments and does not \
                   belong\n\
                  \                                 to common_keys."
                  key))
        else if not (equal_elt elt_1 elt_2) then
          raise
            (Invalid_argument
               (Printf.sprintf
                  "the key %s appears in both union argument with different \
                   values"
                  key))
        else Some elt_1)
      x
      y

  (* applies union_disjoint on a list of map*)
  let union_disjoint_list ?(common_keys_equal_elt = ([], ( = ))) map_list =
    List.fold_left (union_disjoint ~common_keys_equal_elt) empty map_list

  let add_unique k v m =
    if mem k m then
      raise
        (Invalid_argument (Printf.sprintf "key %s already present in map." k))
    else add k v m

  let pmap f m = Multicore.pmap (fun (k, v) -> (k, f v)) (bindings m) |> of_list

  let monomial_of_list l =
    let l_with_degree = List.map (fun p -> (p, 1)) l in
    of_list l_with_degree

  module Aggregation = struct
    (* separator between prefixes & name ; must be only one character *)
    let sep = "~"

    let nb_digits n =
      let rec aux nb i = if i = 0 then nb else aux (nb + 1) (i / 10) in
      if n = 0 then 1 else aux 0 n

    let int_to_string ~len_prefix i =
      let d_i = nb_digits i in
      let zeros_to_add =
        let nb_zeros_to_add = len_prefix - d_i in
        String.make nb_zeros_to_add '0'
      in
      zeros_to_add ^ string_of_int i ^ sep

    (* nb_proofs - 1 because indexes begin at 0 *)
    let compute_len_prefix ~nb_proofs = nb_digits (nb_proofs - 1)

    let prefix_map ~prefix str_map =
      if prefix = "" then str_map
      else fold (fun k v acc -> add (prefix ^ k) v acc) str_map empty

    (* rename the keys of the a string map by appending i to all of them
       except those in common_keys
       if an update_value is specified, the values are updated with this function ; by default, values remain the same and only keys are updated
    *)
    let rename ?(extra_prefix = "") ?(update_value = fun _prefix x -> x)
        ~len_prefix ~common_keys i map =
      let ffold key value new_map =
        let rename = not (List.mem key common_keys) in
        let (new_key, new_value) =
          let prefix = int_to_string ~len_prefix i ^ extra_prefix in
          if rename then (prefix ^ key, update_value prefix value)
          else (key, value)
        in
        add new_key new_value new_map
      in
      fold ffold map empty

    (*Takes a list of string map with the same set of keys,
      rename the keys that do not belong to common_keys
      of the i-th map by appending an i to it,
      and return the union_disjoint_list as defined in SMap.
    *)
    let merge_equal_set_of_keys ?(extra_prefix = "")
        ?(common_keys_equal_elt = ([], ( = ))) ~len_prefix list_map =
      let (common_keys, _equal_elt) = common_keys_equal_elt in
      (*assert the identifiers are the same*)
      assert (
        let keys = List.map fst (bindings (List.hd list_map)) in
        List.for_all
          (fun map -> List.map fst (bindings map) = keys)
          (List.tl list_map)) ;
      (* create unique identifiers in all map except common_keys*)
      let new_list_map =
        List.mapi (rename ~extra_prefix ~len_prefix ~common_keys) list_map
      in
      (* merge the modified map*)
      union_disjoint_list ~common_keys_equal_elt new_list_map
  end
end

module type StringMap_sig = sig
  include Map.S with type key = string

  val of_list : (string * 'a) list -> 'a t

  val union_disjoint :
    ?common_keys_equal_elt:string list * ('a -> 'a -> bool) ->
    'a t ->
    'a t ->
    'a t

  val union_disjoint_list :
    ?common_keys_equal_elt:string list * ('a -> 'a -> bool) -> 'a t list -> 'a t

  val add_unique : string -> 'a -> 'a t -> 'a t

  val pmap : ('a -> 'b) -> 'a t -> 'b t

  val to_bytes : ('a -> bytes) -> 'a t -> bytes
end

include StringMap
