(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Protocol_client_context
module Events = Baking_events.Liquidity_baking

let default_vote_json_filename = "per_block_votes.json"

let vote_file_content_encoding =
  let open Data_encoding in
  def
    (String.concat "." [Protocol.name; "vote_file_content"])
    (obj1
       (req
          "liquidity_baking_toggle_vote"
          Protocol.Alpha_context.Liquidity_baking
          .liquidity_baking_toggle_vote_encoding))

type error += Block_vote_file_not_found of string

type error += Block_vote_file_invalid of string

type error += Block_vote_file_wrong_content of string

type error += Block_vote_file_missing_liquidity_baking_toggle_vote of string

type error += Missing_vote_on_startup

let () =
  register_error_kind
    `Permanent
    ~id:"liquidity_baking_vote.block_vote_file_not_found"
    ~title:
      "The provided block vote file path does not point to an existing file."
    ~description:
      "A block vote file path was provided on the command line but the path \
       does not point to an existing file."
    ~pp:(fun ppf file_path ->
      Format.fprintf
        ppf
        "@[The provided block vote file path \"%s\" does not point to an \
         existing file.@]"
        file_path)
    Data_encoding.(obj1 (req "file_path" string))
    (function
      | Block_vote_file_not_found file_path -> Some file_path | _ -> None)
    (fun file_path -> Block_vote_file_not_found file_path) ;
  register_error_kind
    `Permanent
    ~id:"liquidity_baking_vote.block_vote_file_invalid"
    ~title:
      "The provided block vote file path does not point to a valid JSON file."
    ~description:
      "A block vote file path was provided on the command line but the path \
       does not point to a valid JSON file."
    ~pp:(fun ppf file_path ->
      Format.fprintf
        ppf
        "@[The provided block vote file path \"%s\" does not point to a valid \
         JSON file. The file exists but its content is not valid JSON.@]"
        file_path)
    Data_encoding.(obj1 (req "file_path" string))
    (function Block_vote_file_invalid file_path -> Some file_path | _ -> None)
    (fun file_path -> Block_vote_file_invalid file_path) ;
  register_error_kind
    `Permanent
    ~id:"liquidity_baking_vote.block_vote_file_wrong_content"
    ~title:"The content of the provided block vote file is unexpected."
    ~description:
      "The block vote file is valid JSON but its content is not the expected \
       one."
    ~pp:(fun ppf file_path ->
      Format.fprintf
        ppf
        "@[The provided block vote file \"%s\" is a valid JSON file but its \
         content is unexpected. Expecting a JSON file containing either \
         '{\"liquidity_baking_toggle_vote\": \"on\"}', or \
         '{\"liquidity_baking_toggle_vote\": \"off\"}', or \
         '{\"liquidity_baking_toggle_vote\": \"pass\"}'.@]"
        file_path)
    Data_encoding.(obj1 (req "file_path" string))
    (function
      | Block_vote_file_wrong_content file_path -> Some file_path | _ -> None)
    (fun file_path -> Block_vote_file_wrong_content file_path) ;
  register_error_kind
    `Permanent
    ~id:
      "liquidity_baking_vote.block_vote_file_missing_liquidity_baking_toggle_vote"
    ~title:
      "In the provided block vote file, no entry for liquidity baking toggle \
       vote was found"
    ~description:
      "In the provided block vote file, no entry for liquidity baking toggle \
       vote was found."
    ~pp:(fun ppf file_path ->
      Format.fprintf
        ppf
        "@[In the provided block vote file \"%s\", the \
         \"liquidity_baking_toggle_vote\" boolean field is missing. Expecting \
         a JSON file containing either '{\"liquidity_baking_toggle_vote\": \
         \"on\"}', or '{\"liquidity_baking_toggle_vote\": \"off\"}', or \
         '{\"liquidity_baking_toggle_vote\": \"pass\"}'.@]"
        file_path)
    Data_encoding.(obj1 (req "file_path" string))
    (function
      | Block_vote_file_missing_liquidity_baking_toggle_vote file_path ->
          Some file_path
      | _ -> None)
    (fun file_path ->
      Block_vote_file_missing_liquidity_baking_toggle_vote file_path) ;
  register_error_kind
    `Permanent
    ~id:"liquidity_baking_vote.missing_vote_on_startup"
    ~title:"Missing vote on startup"
    ~description:
      "No CLI flag, file path, or vote file in default location provided on \
       startup"
    ~pp:(fun fmt () ->
      Format.fprintf
        fmt
        "Missing liquidity baking toggle vote, please use either the \
         --liquidity-baking-toggle-vote or --votefile option or a vote file in \
         the default location: per_block_votes.json in the current working \
         directory or in the baker directory.")
    Data_encoding.empty
    (function Missing_vote_on_startup -> Some () | _ -> None)
    (fun () -> Missing_vote_on_startup)

let check_file_exists file =
  let open Lwt_result_syntax in
  let*! file_exists =
    Lwt.catch (fun () -> Lwt_unix.file_exists file) (fun _ -> Lwt.return_false)
  in
  if file_exists then return_unit else tzfail (Block_vote_file_not_found file)

let read_liquidity_baking_toggle_vote ~per_block_vote_file : 'a tzresult Lwt.t =
  let open Lwt_result_syntax in
  let*! () = Events.(emit reading_per_block) per_block_vote_file in
  let* () = check_file_exists per_block_vote_file in
  let* votes_json =
    trace
      (Block_vote_file_invalid per_block_vote_file)
      (Lwt_utils_unix.Json.read_file per_block_vote_file)
  in
  let* liquidity_baking_toggle_vote =
    trace
      (Block_vote_file_wrong_content per_block_vote_file)
      (protect (fun () ->
           return
             (Data_encoding.Json.destruct vote_file_content_encoding votes_json)))
  in
  return liquidity_baking_toggle_vote

let read_liquidity_baking_toggle_vote_no_fail ~default_liquidity_baking_vote
    ~per_block_vote_file =
  read_liquidity_baking_toggle_vote ~per_block_vote_file >>= function
  | Ok vote -> Lwt.return vote
  | Error errs ->
      Events.(emit per_block_vote_file_fail) errs >>= fun () ->
      Lwt.return default_liquidity_baking_vote

let load_liquidity_baking_config ~per_block_vote_file_arg
    ~(toggle_vote_arg :
       Protocol.Alpha_context.Liquidity_baking.liquidity_baking_toggle_vote
       option) : Baking_configuration.liquidity_baking_config tzresult Lwt.t =
  let open Lwt_result_syntax in
  (* If a vote file is given, it takes priority. Otherwise, we expect
     a toggle vote argument to be passed. *)
  let* config =
    match (per_block_vote_file_arg, toggle_vote_arg) with
    | None, None -> tzfail Missing_vote_on_startup
    | None, Some vote ->
        return
          {Baking_configuration.vote_file = None; liquidity_baking_vote = vote}
    | Some per_block_vote_file, _ -> (
        let*! (res : _ tzresult) =
          read_liquidity_baking_toggle_vote ~per_block_vote_file
        in
        match res with
        | Ok vote ->
            return
              {
                Baking_configuration.vote_file = Some per_block_vote_file;
                liquidity_baking_vote = vote;
              }
        | Error errs ->
            Events.(emit per_block_vote_file_fail) errs >>= fun () ->
            tzfail Missing_vote_on_startup)
  in
  let*! () =
    Events.(emit liquidity_baking_toggle_vote) config.liquidity_baking_vote
  in
  return config
