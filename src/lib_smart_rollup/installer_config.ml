(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

type error +=
  | Installer_config_yaml_error of string
  | Installer_config_invalid
  | Installer_config_invalid_instruction of int

let () =
  register_error_kind
    `Permanent
    ~id:"installer_config.yaml_error"
    ~title:"The YAML file is illformed"
    ~description:"The YAML file is illformed"
    ~pp:(fun ppf -> Format.fprintf ppf "The given file is not a valid YAML: %s")
    Data_encoding.(obj1 (req "yaml_msg" Data_encoding.string))
    (function Installer_config_yaml_error msg -> Some msg | _ -> None)
    (fun msg -> Installer_config_yaml_error msg) ;
  register_error_kind
    `Permanent
    ~id:"installer_config.invalid_config"
    ~title:"The installer config is illformed"
    ~description:"The installer config is illformed"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "The installer config has not the right format.\n")
    Data_encoding.unit
    (function Installer_config_invalid -> Some () | _ -> None)
    (fun () -> Installer_config_invalid) ;
  register_error_kind
    `Permanent
    ~id:"installer_config.invalid_instruction"
    ~title:"The installer config is illformed"
    ~description:"The installer config is illformed with an invalid instruction"
    ~pp:(fun ppf -> Format.fprintf ppf "The %dth instruction is invalid.\n")
    Data_encoding.(obj1 (req "encoding_error" Data_encoding.int31))
    (function Installer_config_invalid_instruction i -> Some i | _ -> None)
    (fun i -> Installer_config_invalid_instruction i)

type instr = Set of {value : string; to_ : string}

type t = instr list

let instr_encoding : instr Data_encoding.t =
  let open Data_encoding in
  union
    [
      case
        ~title:"set"
        (Tag 0)
        (obj1
           (req "set" (obj2 (req "value" (option string)) (req "to" string))))
        (fun (Set {value; to_}) ->
          let (`Hex value) = Hex.of_string value in
          Some (Some value, to_))
        (fun (value, to_) ->
          let value = Option.value ~default:"" value in
          let value = Hex.to_string (`Hex value) |> Option.value ~default:"" in
          Set {value; to_});
    ]

let encoding =
  let open Data_encoding in
  obj1 (req "instructions" (list instr_encoding))

let pp_instr fmt (Set {value; to_}) =
  let open Format in
  fprintf fmt "Set %S to %S" Hex.(of_string value |> show) to_

let pp fmt config =
  let open Format in
  fprintf
    fmt
    "Instructions:@.%a"
    (pp_print_list ~pp_sep:pp_print_newline pp_instr)
    config

let map_yaml_err = function
  | Ok v -> Ok v
  | Error (`Msg err) -> Result_syntax.tzfail (Installer_config_yaml_error err)

let yaml_parse_instr i yaml =
  let open Result_syntax in
  (* By default, the library [Yaml] doesn't enforce implicite quote, we
     need to it manually. *)
  let rec enforce_scalars_quoted =
    let open Yaml in
    function
    | `Scalar scalar -> `Scalar {scalar with quoted_implicit = true}
    | `Alias a -> `Alias a
    | `A seq ->
        `A {seq with s_members = List.map enforce_scalars_quoted seq.s_members}
    | `O mapping ->
        `O
          {
            mapping with
            m_members =
              List.map
                (fun (y1, y2) ->
                  (enforce_scalars_quoted y1, enforce_scalars_quoted y2))
                mapping.m_members;
          }
  in
  match Yaml.to_json (enforce_scalars_quoted yaml) with
  | Error _ -> tzfail (Installer_config_invalid_instruction i)
  | Ok instr -> (
      try Ok (Data_encoding.Json.destruct instr_encoding instr)
      with _ -> tzfail (Installer_config_invalid_instruction i))

(* Note that the parsing is done manually on the Yaml representation rather than
   the JSON obtained with {Yaml.to_json}, as it tends to stack overflow on big
   configs (see https://github.com/avsm/ocaml-yaml/issues/70). *)
let yaml_parse_instrs =
  let open Result_syntax in
  function
  | `O
      Yaml.
        {
          m_members =
            [(`Scalar {value = "instructions"; _}, `A {s_members = instrs; _})];
          _;
        } ->
      let+ instrs = List.rev_mapi_e yaml_parse_instr instrs in
      List.rev instrs
  | _ -> tzfail Installer_config_invalid

let parse_yaml yaml =
  let open Result_syntax in
  let* yaml = Yaml.yaml_of_string yaml |> map_yaml_err in
  yaml_parse_instrs yaml
