type 'a t = {first : int32; last : int32; dict : (int32, 'a) Lazy_dict.t}

let create ?origin ?produce_value num_elements =
  let produce_value =
    match produce_value with
    | Some produce_value ->
        Some (fun tree key -> produce_value tree (Int32.of_string key))
    | None -> None
  in
  {
    first = 0l;
    last = num_elements;
    dict = Lazy_dict.create ?origin ?produce_value Int32.to_string;
  }

let num_elements {first; last; _} = Int32.sub last first

let assert_boundaries i vec =
  if not (0l <= i && i < num_elements vec) then raise Exn.Bounds

let get i vec =
  assert_boundaries i vec ;
  Lazy_dict.get (Int32.add i vec.first) vec.dict

let set i v vec =
  assert_boundaries i vec ;
  {vec with dict = Lazy_dict.set (Int32.add i vec.first) v vec.dict}

let empty () = create 0l

let grow ?default size vec =
  let len = num_elements vec in
  let new_len = Int32.add len size in
  let new_len_i = Int32.to_int new_len in
  let res_vec = ref {vec with last = Int32.add vec.last size} in
  (match default with
  | Some default ->
      for i = Int32.to_int len to new_len_i - 1 do
        res_vec := set (Int32.of_int i) default !res_vec
      done
  | None -> ()) ;
  !res_vec

let alloc ?default size = empty () |> grow ?default size

let append v vec =
  let l = num_elements vec in
  (grow ~default:v 1l vec, l)

let singleton v = create 1l |> set 0l v

let loaded_bindings vec =
  Lazy_dict.loaded_bindings vec.dict
  |> List.sort (fun x y ->
         let x = Int32.of_string (fst x) in
         let y = Int32.of_string (fst y) in
         compare x y)

let of_list l =
  let vec = create 0l in
  List.fold_left (fun vec x -> append x vec |> fst) vec l

let cons v vec =
  let vec = {vec with first = Int32.pred vec.first} in
  set 0l v vec

(** We assume the [values] are always complete, that is, no decode-encode loop *)
module Unsafe_for_tick = struct
  let fetch_all vec =
    let open Lwt.Syntax in
    let len = num_elements vec in
    let rec aux i =
      if len <= i then Lwt.return ()
      else
        let* _ = get i vec and* () = aux (Int32.succ i) in
        Lwt.return ()
    in
    aux 0l

  let to_list vec = loaded_bindings vec |> List.map snd

  let fetch_to_list vec =
    let open Lwt.Syntax in
    let+ () = fetch_all vec in
    to_list vec

  let concat v1 v2 = of_list (to_list v1 @ to_list v2)
end

let pp pp_elem fmt v =
  Format.(
    fprintf
      fmt
      "[%a]"
      (pp_print_list ~pp_sep:(fun fmt () -> pp_print_string fmt "; ") pp_elem))
    (Unsafe_for_tick.to_list v)
