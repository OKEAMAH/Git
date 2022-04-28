exception Random_from_list_empty_input

exception Random_from_list_overflowed_choice of Q.t list

exception Random_qt_non_positive_interval of Q.t

module StringMap = struct
  include Map.Make (String)

  let to_bytes f m =
    Bytes.concat Bytes.empty (List.rev (fold (fun _k v acc -> f v :: acc) m []))

  let of_list l = of_seq (List.to_seq l)

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

  let pmap f m =
    let open Domainslib in
    match Task.lookup_pool "pool" with
    | None -> failwith "pmap: task pool not initialized"
    | Some pool ->
        let promises =
          fold
            (fun k v acc ->
              let promise = Task.async pool (fun _ -> f v) in
              (k, promise) :: acc)
            m
            []
        in
        List.fold_left
          (fun acc (k, p) ->
            let v = Task.await pool p in
            add k v acc)
          empty
          promises

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

module StringPairs = struct
  type t = string * string

  let compare (x0, y0) (x1, y1) =
    match Stdlib.compare x0 x1 with 0 -> Stdlib.compare y0 y1 | c -> c
end

module StringMatrix = Map.Make (StringPairs)

let monomial_of_list l =
  let l_with_degree = List.map (fun p -> (p, 1)) l in
  StringMap.of_list l_with_degree

(* RANDOM FUNCTIONS ON Q.t *)

(* Random Z.t between 0 and a positive [max] (both included)
   Samples by rejection. Expectancy of number of rejections:
   Worst case : 1 rejection
   Best case : 0 rejection
   Average case : ln(2) - 1/2 (approx. 0.19314718056)
   TODO test that
 *)
let random_z max state =
  let rec random_bits acc size =
    if size <= 0 then acc
    else random_bits (Random.State.bool state :: acc) (size - 1)
  in
  let rec z_of_bits acc = function
    | [] -> acc
    | b :: t ->
        if b then z_of_bits Z.(succ (shift_left acc 1)) t
        else z_of_bits (Z.shift_left acc 1) t
  in
  let n = Z.numbits max in
  let rec aux () =
    let res = z_of_bits Z.zero (random_bits [] n) in
    if Z.leq res max then res else aux ()
  in
  aux ()

(*
(* Random Q.t between 0 and 1
   [precision] is the number of calls to Random.State.float
   so the precision of the algorithm is actually 1/2^(60*[precision])
 *)
let random_qt_raw state precision =
  let precision = max 1 precision in
  let rec aux acc prec =
    if prec <= 0 then acc
    else
      aux
        (Q.add (Q.div_2exp acc 60) (Q.of_float (Random.State.float state 1.)))
        (prec - 1)
  in
  aux Q.zero precision
 *)

let random_qt interval state =
  if interval <= Q.zero then raise (Random_qt_non_positive_interval interval)
  else
    (* Compute to a precision at least 2^30 smaller than the given [interval] *)
    let k = Z.shift_left (Q.to_bigint (Q.inv interval)) 30 in
    let num = random_z k state in
    Q.make num k

let random_from_list (l : (Q.t * 'a) list) state : 'a =
  if l = [] then raise Random_from_list_empty_input
  else
    (* (* suspicious line below. TODO : investigate why Micheline has negative weights *)
       let l = List.filter (fun (x, _) -> Q.gt x Q.zero) l in *)
    let sum = List.fold_left (fun s (q, _) -> Q.add s q) Q.zero l in
    let l = List.rev_map (fun (q, i) -> (Q.div q sum, i)) l in
    let min = List.fold_left (fun m (q, _) -> Q.min m q) sum l in
    let rec aux x = function
      | [] -> raise (Random_from_list_overflowed_choice (List.rev_map fst l))
      | (q, i) :: t -> if Q.leq x q then i else aux (Q.sub x q) t
    in
    aux (random_qt min state) l

let random_bern x state =
  if Q.geq x Q.one then true
  else
    let intvl = Q.min x (Q.sub Q.one x) in
    let d = random_qt intvl state in
    if Q.lt d x then true else false

let pp_tree (a : string) (ls : string list list) : string list =
  let rec aux_intern l =
    match l with [] -> [] | h :: t -> ("│   " ^ h) :: aux_intern t
  in
  let rec aux_extern l =
    match l with [] -> [] | h :: t -> ("    " ^ h) :: aux_extern t
  in
  let rec aux_main l =
    match l with
    | [] -> []
    | [h] -> (
        match h with
        | [] -> []
        | hh :: ht -> ("└── " ^ hh) :: aux_extern ht)
    | h :: i :: t -> (
        match h with
        | [] -> aux_main (i :: t)
        | hh :: ht -> ("├── " ^ hh) :: aux_intern ht @ aux_main (i :: t))
  in
  a :: aux_main ls

let pp_string_list =
  Format.pp_print_list ~pp_sep:Format.pp_print_newline Format.pp_print_string
