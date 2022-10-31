(** Format description. *)

(** Year interval. *)
type years = {y_beg : int; y_end : int}

module F = struct
  (** Single-line format. *)
  type _ line =
    | [] : unit line  (** Empty line or spaces. *)
    | ( :: ) : 'a line * 'b line -> ('a * 'b) line
        (** Concat two line formats. *)
    | Exact : string -> unit line  (** The exact given string. *)
    | Years : years line  (** Years as a single year or years intervals. *)
    | AnyText : string line  (** Any, non-empty, text. *)
    | LMap : {format : 'a line; map : 'a -> 'b; unmap : 'b -> 'a} -> 'b line
        (** Match the same content but map the result. *)

  type in_comment

  type not_in_comment

  (** File format. *)
  type (_, _) format =
    | [] : (unit, _) format  (** Nothing. *)
    | ( :: ) : ('a, 'c) format * ('b, 'c) format -> ('a * 'b, 'c) format
        (** Concat two file formats. *)
    | Copy : int -> (string list, not_in_comment) format
        (** Copy the given number of lines. *)
    | CopyAll : (string Seq.t, not_in_comment) format
        (** Copy the rest of the file. *)
    | EndOfFile : (unit, not_in_comment) format  (** Match the end of file. *)
    | CommentBlock : ('a, in_comment) format -> ('a, not_in_comment) format
        (** Match the given format in a comment block. The following line must not be in the comment block. *)
    | Fill : (unit, in_comment) format
        (** A comment line filled with the last character of the comment prefix. *)
    | Line : 'a line -> ('a, _) format
        (** Match a single line with the given format. *)
    | RepeatLine : 'a line -> ('a list, _) format
        (** Match one or more lines with the given format. *)
    | Paragraph : (string, _) format
        (** Match a non-empty text that can spread over several lines, followed by an empty line. *)
    | ExactParagraph : string -> (unit, _) format
        (** Match the exact given non-empty text that can spread over several lines, followed by an empty line. *)
    | FMap : {
        format : ('a, 'c) format;
        map : 'a -> 'b;
        unmap : 'b -> 'a;
      }
        -> ('b, 'c) format  (** Match the same content but map the result. *)
    | OrSuggest : (unit, 'c) format -> (unit, 'c) format
        (** Match the parameter or nothing. If nothing, suggest to add it. *)

  (** Pretty-print a line format element. *)
  let rec pp_line_content : type a. Format.formatter -> a line -> unit =
   fun f -> function
    | [] -> ()
    | [a] -> pp_line_content f a
    | a :: b -> Format.fprintf f "%a,%a" pp_line_content a pp_line_content b
    | Exact s -> Format.fprintf f "%S" s
    | Years -> Format.pp_print_string f "years"
    | AnyText -> Format.pp_print_string f "any"
    | LMap {format; map = _; unmap = _} -> pp_line_content f format

  (** Pretty-print a line format. *)
  let pp_line : type a. Format.formatter -> a line -> unit =
   fun f -> function
    | [] -> Format.pp_print_string f "[empty]"
    | line -> Format.fprintf f "[%a]" pp_line_content line
end

(** Whole-file format. *)
type ex_format =
  | Format_header : (_, F.not_in_comment) F.format -> ex_format
  | Ignore
