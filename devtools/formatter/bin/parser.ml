open Xtdlib
open Fmt

type comment_config = {
  comment_line_length : int;
  start : string;
  end_ : string;
  fill : char;
}

module Fail = struct
  exception Parse_error of string

  let fail fmt = Format.kasprintf (fun s -> raise (Parse_error s)) fmt

  let get_ln lines =
    Option.map
      (fun ({ln; offset = _; line = _}, _rest) -> ln)
      (Seq.uncons lines)

  let pp_ln f = function
    | None -> Format.pp_print_string f "eof"
    | Some ln -> Format.pp_print_int f ln

  let line_char ~ln ~offset i fmt =
    fail ("Line %d, char %d: " ^^ fmt) ln (offset + i)

  let line_chars ~ln ~offset i1 i2 fmt =
    fail ("Line %d, chars %d-%d: " ^^ fmt) ln (offset + i1) (offset + i2)

  let line lines fmt = fail ("Line %a: " ^^ fmt) pp_ln (get_ln lines)

  let lines lines1 lines2 fmt =
    fail ("Lines %a-%a: " ^^ fmt) pp_ln (get_ln lines1) pp_ln (get_ln lines2)
end

let eat_exact_from ~ln ~offset ~prefix s i =
  for j = 0 to String.length prefix - 1 do
    if s.[i + j] <> prefix.[j] then
      Fail.line_char
        ~ln
        ~offset
        (i + j)
        "expected '%c', got '%c'."
        prefix.[j]
        s.[i + j]
  done

let eat_nat_from ~ln ~offset s i ~min ~max =
  let i0 = i in
  let rec aux acc i =
    if acc < 0 then
      Fail.line_chars ~ln ~offset i0 i "overflow while reading natural number."
    else if i >= String.length s then (acc, i)
    else
      let c = s.[i] in
      if c >= '0' && c <= '9' then
        aux ((acc * 10) + Char.code c - Char.code '0') (i + 1)
      else (acc, i)
  in
  if i >= String.length s then
    Fail.line_char ~ln ~offset i "expected number, got end of line." ;
  let c = s.[i] in
  if c < '0' || c > '9' then Fail.line_char ~ln ~offset i "number expected."
  else
    let res = aux (Char.code c - Char.code '0') (i + 1) in
    let n, i = res in
    if n <= min || n >= max then
      Fail.line_chars
        ~ln
        ~offset
        i0
        i
        "expected number in range %d-%d, got %d."
        min
        max
        n ;
    res

let eat_year_from ~ln ~offset s i =
  eat_nat_from ~ln ~offset s i ~min:1970 ~max:2050

let eat_years_from ~ln ~offset s i =
  let i0 = i in
  let y_beg, i = eat_year_from ~ln ~offset s i in
  if i < String.length s && s.[i] = '-' then
    let i = i + 1 in
    let i = if i < String.length s && s.[i] = '-' then i + 1 else i in
    let y_end, i = eat_year_from ~ln ~offset s i in
    if y_beg >= y_end then
      Fail.line_chars ~ln ~offset i0 i "bad interval %d >= %d" y_beg y_end
    else ({y_beg; y_end}, i)
  else ({y_beg; y_end = y_beg}, i)

let eat_rest_from ~ln ~offset s i =
  let rec aux j =
    if j < i then Fail.line_char ~ln ~offset i "token expected"
    else if s.[j] = ' ' then aux (j - 1)
    else String.sub s i (j - i + 1)
  in
  let last = String.length s - 1 in
  (aux last, last + 1)

let rec eat_fline_format_from :
    type f. format:f F.line -> ln:int -> offset:int -> string -> int -> f * int
    =
 fun ~format ~ln ~offset s i ->
  match format with
  | [] -> ((), i)
  | hd :: tl ->
      let hd, i = eat_fline_format_from ~format:hd ~ln ~offset s i in
      let tl, i = eat_fline_format_from ~format:tl ~ln ~offset s i in
      ((hd, tl), i)
  | Exact prefix ->
      (eat_exact_from ~ln ~offset ~prefix s i, i + String.length prefix)
  | Years -> eat_years_from ~ln ~offset s i
  | AnyText -> eat_rest_from ~ln ~offset s i
  | LMap {format; map; unmap = _} ->
      let x, i = eat_fline_format_from ~format ~ln ~offset s i in
      (map x, i)

let parse_fline (type f) ~(format : f F.line) ~ln ~offset s : f =
  let res, i = eat_fline_format_from ~format ~ln ~offset s 0 in
  for j = i to String.length s - 1 do
    if s.[j] <> ' ' then
      Fail.line_char
        ~ln
        ~offset
        j
        "after format %a, expected space, got '%c'."
        F.pp_line
        format
        s.[j]
  done ;
  res

let parse_line (type f) (eat : ln:int -> offset:int -> string -> f) lines :
    f * line Seq.t =
  match Seq.uncons lines with
  | None -> Fail.fail "Unexpected end of file."
  | Some ({ln; offset; line}, lines) -> (eat ~ln ~offset line, lines)

let trim_comment ~cc {ln; offset; line} =
  let prefix_len = String.length cc.start in
  let suffix_len = String.length cc.end_ in
  let line_len = String.length line in
  if
    line_len >= prefix_len + suffix_len
    && String.starts_with ~prefix:cc.start line
    && String.ends_with ~suffix:cc.end_ line
  then
    let start =
      if String.length line >= prefix_len && line.[prefix_len] = ' ' then
        prefix_len + 1
      else prefix_len
    in
    let len =
      let last_possible_space = line_len - suffix_len - 1 in
      line_len - start
      -
      if
        String.length line >= last_possible_space
        && line.[last_possible_space] = ' '
      then suffix_len + 1
      else suffix_len
    in
    let offset = offset + start in
    let line = String.sub line start len in
    Some {ln; offset; line}
  else None

let parse_fill ~cc ~ln ~offset line =
  String.iteri
    (fun i c ->
      if c <> cc.fill then
        Fail.line_char
          ~ln
          ~offset
          i
          "expected fill character '%c' got '%c'."
          cc.fill
          c)
    line

let parse_repeat_line (type f) (eat : ln:int -> offset:int -> string -> f) lines
    : f list * line Seq.t =
  let rec aux lines =
    match parse_line eat lines with
    | first, lines ->
        let rest, last_error, lines = aux lines in
        (first :: rest, last_error, lines)
    | exception Fail.Parse_error e -> ([], e, lines)
  in
  match aux lines with
  | [], last_error, _ -> (
      match Seq.uncons lines with
      | None -> Fail.fail "Expected at least one remaining line; %s" last_error
      | Some ({ln; offset; line = _}, _) ->
          Fail.line_char
            ~ln
            ~offset
            0
            "expected at least one line match pattern; %s"
            last_error)
  | res, _last_error, lines -> (res, lines)

let parse_paragraph lines =
  let p_lines, lines = parse_repeat_line (parse_fline ~format:AnyText) lines in
  let p = String.concat " " p_lines in
  let (), lines = parse_line (parse_fline ~format:[]) lines in
  (p, lines)

let match_exact_paragraph p lines =
  let lines0 = lines in
  let actual_p, lines = parse_paragraph lines in
  if p <> actual_p then
    Fail.lines
      lines0
      lines
      "paragraph mismatch, expected\n%s\ngot\n%s"
      p
      actual_p ;
  ((), lines)

let copy_n_lines n lines =
  let lines0 = lines in
  let rec aux n lines =
    if n <= 0 then ([], lines)
    else
      match Seq.uncons lines with
      | None ->
          Fail.line lines0 "at least %d more lines expected at end of file." n
      | Some ({ln = _; offset = _; line}, lines) ->
          let res, lines = aux (n - 1) lines in
          (line :: res, lines)
  in
  aux n lines

let copy_all_lines lines =
  (Seq.map (fun {ln = _; offset = _; line} -> line) lines, Seq.empty)

let expect_end ~of_ lines =
  if Option.is_some (Seq.uncons lines) then
    Fail.line lines "expected end of %s." of_

let rec parse :
    type f c.
    cc:comment_config -> format:(f, c) F.format -> line Seq.t -> f * line Seq.t
    =
 fun ~cc ~format lines ->
  match format with
  | [] -> ((), lines)
  | OrSuggest f :: tl -> (
      match parse ~cc ~format:(f :: tl) lines with
      | res_lines -> res_lines
      | exception (Fail.Parse_error _ as original_error) -> (
          match parse ~cc ~format:tl lines with
          | res, lines -> (((), res), lines)
          | exception Fail.Parse_error _ -> raise original_error))
  | OrSuggest f -> (
      match parse ~cc ~format:f lines with
      | res_lines -> res_lines
      | exception (Fail.Parse_error _ as original_error) -> (
          match parse ~cc ~format:[] lines with
          | (), lines -> ((), lines)
          | exception Fail.Parse_error _ -> raise original_error))
  | hd :: tl ->
      let hd, lines = parse ~cc ~format:hd lines in
      let tl, lines = parse ~cc ~format:tl lines in
      ((hd, tl), lines)
  | Copy n -> copy_n_lines n lines
  | CopyAll -> copy_all_lines lines
  | EndOfFile ->
      expect_end ~of_:"file" lines ;
      ((), Seq.empty)
  | CommentBlock format ->
      let comment_lines, other_lines = Seq.split_map (trim_comment ~cc) lines in
      let res, rem_comment_lines = parse ~cc ~format comment_lines in
      expect_end ~of_:"comment block" rem_comment_lines ;
      (res, other_lines)
  | Fill -> parse_line (parse_fill ~cc) lines
  | Line format -> parse_line (parse_fline ~format) lines
  | RepeatLine format -> parse_repeat_line (parse_fline ~format) lines
  | Paragraph -> parse_paragraph lines
  | ExactParagraph p -> match_exact_paragraph p lines
  | FMap {format; map; unmap = _} ->
      let x, lines = parse ~cc ~format lines in
      (map x, lines)
