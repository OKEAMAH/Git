open Xtdlib
open Fmt
open Parser

let year_interval_separator = "-"

type printer = {
  print_line : 'a. ('a, Format.formatter, unit) format -> 'a;
  print_fill : unit -> unit;
}

let default_printer och =
  let f = Format.formatter_of_out_channel och in
  let print_line fmt = Format.fprintf f (fmt ^^ "\n") in
  let print_fill () = assert false in
  {print_line; print_fill}

let print_lines ~pf lines = Seq.iter (fun line -> pf.print_line "%s" line) lines

let pp_print_year f y = Format.pp_print_int f y

let pp_print_years f {y_beg; y_end} =
  if y_beg >= y_end then pp_print_year f y_beg
  else
    Format.fprintf
      f
      "%a%s%a"
      pp_print_year
      y_beg
      year_interval_separator
      pp_print_year
      y_end

let rec pp_print_line_element : type f. Format.formatter -> f F.line * f -> unit
    =
 fun f -> function
  | [], () -> ()
  | f_hd :: f_tl, (p_hd, p_tl) ->
      pp_print_line_element f (f_hd, p_hd) ;
      pp_print_line_element f (f_tl, p_tl)
  | Exact s, () -> Format.pp_print_string f s
  | Years, years -> pp_print_years f years
  | AnyText, s -> Format.pp_print_string f s
  | LMap {format; map = _; unmap}, x -> pp_print_line_element f (format, unmap x)

let print_line (type f) ~pf ~(format : f F.line) (parsed : f) =
  pf.print_line "%a" pp_print_line_element (format, parsed)

let print_repeat_line ~pf ~format parsed =
  List.iter (fun parsed -> print_line ~pf ~format parsed) parsed

let print_paragraph ~cc ~pf p =
  let print_rev_cur rev_cur =
    let line = String.concat " " (List.rev rev_cur) in
    pf.print_line "%s" line
  in
  let rec aux rev_cur rem_len ps =
    match ps with
    | [] -> print_rev_cur rev_cur
    | p :: ps ->
        let rem_len = rem_len - String.length p - 1 in
        if rem_len < 0 then (
          print_rev_cur rev_cur ;
          aux_init p ps)
        else aux (p :: rev_cur) rem_len ps
  and aux_init p ps = aux [p] (cc.comment_line_length - String.length p) ps in
  match String.split_on_char ' ' p with
  | [] -> failwith "Empty paragraph"
  | p :: ps ->
      aux_init p ps ;
      pf.print_line ""

let in_comments ~cc ~pf =
  let print_fill =
    let fill =
      lazy
        (let fill_len =
           cc.comment_line_length - String.length cc.start
           - String.length cc.end_
         in
         Format.sprintf "%s%s%s" cc.start (String.make fill_len cc.fill) cc.end_)
    in
    fun () -> pf.print_line "%s" (Lazy.force fill)
  in
  let prefix = cc.start ^ " " in
  let suffix = if cc.end_ = "" then "" else " " ^ cc.end_ in
  let comment_line_length =
    cc.comment_line_length - String.length prefix - String.length suffix
  in
  let print_line fmt =
    Format.kasprintf
      (fun s ->
        pf.print_line
          "%s%s%a%s"
          prefix
          s
          Format.pp_print_chars
          (' ', comment_line_length - String.length s)
          suffix)
      fmt
  in
  let cc =
    {comment_line_length; start = cc.start; end_ = cc.end_; fill = cc.fill}
  in
  let pf = {print_line; print_fill} in
  (cc, pf)

let rec print :
    type f c. cc:comment_config -> pf:printer -> (f, c) F.format -> f -> unit =
 fun ~cc ~pf format parsed ->
  match (format, parsed) with
  | [], () -> ()
  | f_hd :: f_tl, (p_hd, p_tl) ->
      print ~cc ~pf f_hd p_hd ;
      print ~cc ~pf f_tl p_tl
  | Copy _n, lines -> print_lines ~pf (List.to_seq lines)
  | CopyAll, lines -> print_lines ~pf lines
  | EndOfFile, () -> ()
  | CommentBlock format, parsed ->
      let cc, pf = in_comments ~cc ~pf in
      print ~cc ~pf format parsed
  | Fill, () -> pf.print_fill ()
  | Line format, parsed -> print_line ~pf ~format parsed
  | RepeatLine format, parsed -> print_repeat_line ~pf ~format parsed
  | Paragraph, p -> print_paragraph ~cc ~pf p
  | ExactParagraph p, () -> print_paragraph ~cc ~pf p
  | FMap {format; map = _; unmap}, parsed -> print ~cc ~pf format (unmap parsed)
  | OrSuggest f, () -> print ~cc ~pf f ()