(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Yaml
open Yaml.Util
open Types

(* Helpers *)

let opt name f = function Some v -> [(name, f v)] | None -> []

let obj_flatten fs = `O (List.concat fs)

let key name f v : (string * value) list = [(name, f v)]

let array f v = `A (List.map f v)

let strings ss : value = array string ss

(* Translation elements *)

let enc_if expr = string @@ If.encode expr

let enc_variables (vars : variables) : value =
  `O (List.map (fun (name, value) -> (name, `String value)) vars)

let enc_rule_aux : ('a -> value) -> 'a rule -> value =
 fun enc_when rule ->
  match rule with
  | {changes; if_; variables = vars; when_} ->
      obj_flatten
        [
          opt "changes" strings changes;
          opt "if" enc_if if_;
          opt "variables" enc_variables vars;
          key "when" enc_when when_;
        ]

let enc_when : when_ -> value = function
  | Always -> `String "always"
  | Never -> `String "never"
  | On_success -> `String "on_success"
  | Manual -> `String "manual"

let enc_when_workflow : when_workflow -> value = function
  | Always -> `String "always"
  | Never -> `String "never"

let enc_rules rules = array (enc_rule_aux enc_when) rules

let enc_workflow_rules : when_workflow rule list -> value =
  array (enc_rule_aux enc_when_workflow)

let enc_workflow : workflow -> value = function
  | {name; rules} ->
      obj_flatten [opt "name" string name; key "rules" enc_workflow_rules rules]

let enc_stages st : value = strings st

let enc_image (Image i) = string i

let enc_default ({image; interruptible} : default) : value =
  obj_flatten
    [opt "image" enc_image image; opt "interruptible" bool interruptible]

let enc_report : reports -> value =
 fun {dotenv; junit} ->
  obj_flatten [opt "dotenv" string dotenv; opt "junit" string junit]

let enc_artifacts : artifacts -> value =
 fun {expire_in; paths; reports; when_; expose_as} ->
  obj_flatten
    [
      key "expire_in" string expire_in;
      key "paths" strings paths;
      key "reports" enc_report reports;
      key "when" string when_;
      opt "expose_as" string expose_as;
    ]

let enc_cache : cache -> value =
 fun {key = k; paths} ->
  obj_flatten [key "key" string k; key "paths" strings paths]

let enc_service ({name} : service) : value =
  obj_flatten [key "name" string name]

let enc_services (ss : service list) : value = array enc_service ss

let enc_interval interval =
  `String
    (match interval with
    | Seconds x -> string_of_int x ^ " seconds"
    | Minutes x -> string_of_int x ^ " minutes"
    | Hours x -> string_of_int x ^ " hours"
    | Days x -> string_of_int x ^ " days"
    | Weeks x -> string_of_int x ^ " weeks"
    | Months x -> string_of_int x ^ " months"
    | Years x -> string_of_int x ^ " years")

let enc_job : job -> value =
 fun {
       name = _;
       after_script;
       allow_failure;
       artifacts;
       before_script;
       cache;
       image;
       interruptible;
       needs;
       depends;
       rules;
       script;
       services;
       stage;
       variables;
       timeout;
       tags;
     } ->
  obj_flatten
    [
      opt "image" enc_image image;
      opt "stage" string stage;
      opt "tags" (array string) tags;
      opt "rules" enc_rules rules;
      opt "needs" strings depends;
      opt "depends" strings needs;
      opt "allow_failure" bool allow_failure;
      opt "timeout" enc_interval timeout;
      opt "cache" enc_cache cache;
      opt "interruptible" bool interruptible;
      opt "script" strings script;
      opt "after_script" strings after_script;
      opt "before_script" strings before_script;
      opt "services" enc_services services;
      opt "variables" enc_variables variables;
      opt "artifacts" enc_artifacts artifacts;
    ]

let enc_includes : include_ list -> value =
 fun includes ->
  let enc_includes ({local; rules} : include_) =
    match rules with
    | [] -> `String local
    | _ :: _ ->
        `O [("local", `String local); ("rules", enc_workflow_rules rules)]
  in
  match includes with
  | [] -> failwith "empty includes"
  | [{local; rules = []}] -> `String local
  | inc -> array enc_includes inc

let config_element : config_element -> string * value = function
  | Workflow wf -> ("workflow", enc_workflow wf)
  | Stages ss -> ("stages", enc_stages ss)
  | Variables vars -> ("variables", enc_variables vars)
  | Default def -> ("default", enc_default def)
  | Job j -> (j.name, enc_job j)
  | Include i -> ("include", enc_includes i)

let to_yaml (config : config) : value = `O (List.map config_element config)

let to_file ?header ~filename config =
  Base.write_yaml ?header filename (to_yaml config)
