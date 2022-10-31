module String = struct
  include String

  let common_prefix_length a b =
    let rec aux i =
      if i < length a && i < length b && a.[i] = b.[i] then aux (i + 1) else i
    in
    aux 0

  let common_suffix_length a b =
    let rec aux i =
      if
        i < length a
        && i < length b
        && a.[length a - i - 1] = b.[length b - i - 1]
      then aux (i + 1)
      else i
    in
    aux 0
end

module List = struct
  include List

  let rec max_non_empty score cur_score cur = function
    | [] -> cur
    | x :: xs -> (
        match score x with
        | Some x_score when x_score > cur_score ->
            max_non_empty score x_score x xs
        | _ -> max_non_empty score cur_score cur xs)

  let rec max score = function
    | [] -> None
    | x :: xs -> (
        match score x with
        | None -> max score xs
        | Some x_score -> Some (max_non_empty score x_score x xs))
end

type line = {ln : int; offset : int; line : string}

module Seq = struct
  include Seq

  (** [split_map f xs] is [ys, zs] such that
      [ys = map Option.get (take_while Option.is_some (map f xs))]
      and [zs = drop_while (fun x -> Option.is_none (f x)) xs] *)
  let split_map f xs =
    let last_known = ref (-1, xs) in
    let rest =
      ref (fun () ->
          let _, xs = !last_known in
          let xs = drop_while (fun x -> Option.is_some (f x)) xs in
          xs ())
    in
    let rec aux_head i xs () =
      match xs () with
      | Nil ->
          (rest := fun () -> Nil) ;
          Nil
      | Cons (x, xs) as xs0 -> (
          match f x with
          | None ->
              (rest := fun () -> xs0) ;
              Nil
          | Some y ->
              let cur_last_known_i, _ = !last_known in
              if i > cur_last_known_i then last_known := (i, xs) ;
              Cons (y, aux_head (i + 1) xs))
    in
    (aux_head 0 xs, fun () -> !rest ())

  let of_in_channel ich =
    memoize
      (of_dispenser (fun () ->
           match input_line ich with
           | exception End_of_file -> None
           | line -> Some line))

  let of_in_channel_with_ln_and_offset ich =
    mapi (fun i line -> {ln = i + 1; offset = 1; line}) (of_in_channel ich)

  let rec readdir_recursive ~mk_rec_ignore ~ignore path =
    let is_dir = Sys.is_directory path in
    if ignore (if is_dir then path ^ Filename.dir_sep else path) then Seq.empty
    else if is_dir then
      let files = Sys.readdir path in
      let ignore = mk_rec_ignore ~ignore path files in
      Array.to_seq files
      |> Seq.concat_map (fun name ->
             if name = "." || name = ".." then Seq.empty
             else
               readdir_recursive
                 ~mk_rec_ignore
                 ~ignore
                 (Filename.concat path name))
    else Seq.cons path Seq.empty
end

module Format = struct
  include Format

  let pp_print_chars f (c, n) =
    assert (n >= 0) ;
    for _i = 0 to n - 1 do
      pp_print_char f c
    done
end
