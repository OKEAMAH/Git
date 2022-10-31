open Xtdlib
open Fmt

(** Helper functions for the configuration. *)

(** Generic regular expressions. *)
type gen_re =
  | G of string  (** Glob. *)
  | Gs of string list  (** Alternative of globs. *)
  | Re of Re.t  (** Re. *)

(** Get a [Re.t] from a [gen_re]. *)
let re_of_gen_re = function
  | G glob -> Re.Glob.glob glob
  | Gs globs -> List.rev_map Re.Glob.glob globs |> Re.alt
  | Re re -> re

(** Create a mapping [file -> v] from a list of bindings [(re, v)].
    The first matching value is returned.
    Regular expressions are tried in the same order. *)
let mk ~name ?default gre_v =
  let compiled_re_v =
    List.map (fun (gre, v) -> (Re.compile (re_of_gen_re gre), v)) gre_v
  in
  fun file ->
    match
      List.find_map
        (fun (re, v) -> if Re.execp re file then Some v else None)
        compiled_re_v
    with
    | Some v -> v
    | None -> (
        match default with
        | Some v -> v
        | None -> Format.ksprintf failwith "Cannot find a %s for %s" name file)

(** Create a set [file -> bool] from a list of regular expressions. *)
let mk_set gres =
  let compiled_re = List.rev_map re_of_gen_re gres |> Re.alt |> Re.compile in
  fun file -> Re.execp compiled_re file

(** Create a set [file -> bool] from a [.gitignore] file. *)
let mk_git_ignore path =
  let ich = open_in path in
  let globs =
    ich |> Seq.of_in_channel
    |> Seq.filter (fun s -> s <> "" && not (String.starts_with ~prefix:"#" s))
    |> List.of_seq
  in
  close_in ich ;
  mk_set [Gs globs]

(** Gives a score to how well an author match a known author. *)
let author_score =
  let substring_score f a b =
    let l = f a b in
    if l >= String.length a then if l >= String.length b then 2000 else 1000
    else if l >= String.length b then 1000
    else l
  in
  fun who known_author ->
    let known, _y_beg, _y_end = known_author in
    let prefix_score =
      max 0 (substring_score String.common_prefix_length who known - 5)
    in
    let suffix_score =
      max 0 (substring_score String.common_suffix_length who known - 5)
    in
    let max_score = max prefix_score suffix_score in
    if max_score > 0 then
      Some (max_score, prefix_score + suffix_score, known_author)
    else None

(** Try to fix typos in author name and check author is known and was active at
    the given time. *)
let fix_copyright known_authors years who =
  match List.max (author_score who) known_authors with
  | None -> Format.kasprintf failwith "Unknown author '%s'" who
  | Some (author, author_y_beg, author_y_end) ->
      let {y_beg; y_end} = years in
      if y_beg < author_y_beg then
        Format.kasprintf
          failwith
          "'%s' didn\'t authored before %d, found %d."
          author
          author_y_beg
          y_beg ;
      if y_end > author_y_end then
        Format.kasprintf
          failwith
          "'%s' didn\'t authored after %d, found %d."
          author
          author_y_end
          y_end ;
      (years, author)
