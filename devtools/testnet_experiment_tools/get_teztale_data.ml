(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

(* TODO: fail nicely in case canonical_chain table was not created in advance *)
(* TODO: Add printing for reorganised_blocks command *)
(* TODO: Add documentation for functions *)
(* TODO: Refactor more *)

(* Teztale querying tool
   ------------------------
   Invocation:
   1. ./_build/default/devtools/testnet_experiment_tools/get_teztale_data.exe \
     canonical_chain_query \
     --db-path <db-path>
     [ --print ]
   2. ./_build/default/devtools/testnet_experiment_tools/get_teztale_data.exe \
     reorganised_blocks_query \
     --db-path <db-path>
   Requirements:
     <db-path> - path to the teztale database
     [<print>] - if this flag is set, we print the result of the query
   Description:
     This file contains the tool for querying the teztale database.
     The queries that it provides are:
     - canonical_chain_query : get table (id, block_id, predecessor) of block ids in the
     increasing order as they appear in the canonical chain from the db;
     - reorganised_blocks_query : get table (id, block_id, level, round) of block ids
     which are not part of the canonical chain, together with more detailed info.
*)

open Tezos_clic
open Teztale_sql_queries
module Query_Map = Map.Make (Int)

let group = {name = "devtools"; title = "Command for querying the teztale db"}

(* Errors. *)

type error +=
  | Db_path of string
  | Caqti_database_connection of string
  | Canonical_chain_query of string
  | Reorganised_blocks_query of string
  | Canonical_chain_head of string

let () =
  register_error_kind
    `Permanent
    ~id:"get_teztale_data.db_path"
    ~title:"Teztale database path provided was invalid"
    ~description:"Teztale database path must be valid"
    ~pp:(fun ppf s ->
      Format.fprintf ppf "Expected valid path to teztale db, got %s" s)
    Data_encoding.(obj1 (req "arg" string))
    (function Db_path s -> Some s | _ -> None)
    (fun s -> Db_path s) ;
  register_error_kind
    `Permanent
    ~id:"get_teztale_data.caqti_database_connection"
    ~title:"Connection to teztale db failed"
    ~description:"Connection to teztale db must be achieved"
    ~pp:(fun ppf s ->
      Format.fprintf ppf "Expected to connect to teztale db: %s" s)
    Data_encoding.(obj1 (req "arg" string))
    (function Caqti_database_connection s -> Some s | _ -> None)
    (fun s -> Caqti_database_connection s) ;
  register_error_kind
    `Permanent
    ~id:"get_teztale_data.canonical_chain_query"
    ~title:"Failed to create canonical_chain table"
    ~description:"canonical_chain table must be created"
    ~pp:(fun ppf s -> Format.fprintf ppf "Expected canonical_chain table: %s" s)
    Data_encoding.(obj1 (req "arg" string))
    (function Canonical_chain_query s -> Some s | _ -> None)
    (fun s -> Canonical_chain_query s) ;
  register_error_kind
    `Permanent
    ~id:"get_teztale_data.reorganised_blocks_query"
    ~title:"Failed to create reorganised_blocks table"
    ~description:"reorganised_blocks table must be created"
    ~pp:(fun ppf s ->
      Format.fprintf ppf "Expected reorganised_blocks table: %s" s)
    Data_encoding.(obj1 (req "arg" string))
    (function Reorganised_blocks_query s -> Some s | _ -> None)
    (fun s -> Reorganised_blocks_query s) ;
  register_error_kind
    `Permanent
    ~id:"get_tezale_data.canonical_chain_head"
    ~title:"Failed to obtain the head of the canonical chain"
    ~description:"Canonical chain head is required"
    ~pp:(fun ppf s -> Format.fprintf ppf "Expected canonical chain head: %s" s)
    Data_encoding.(obj1 (req "arg" string))
    (function Canonical_chain_head s -> Some s | _ -> None)
    (fun s -> Canonical_chain_head s)

(* Aggregators. *)

let add_canonical_chain_row (id, predecessor) acc =
  Query_Map.add id predecessor acc

let add_reorganised_blocks_row (id, level, round) acc =
  Query_Map.add id (level, round) acc

let add_head_id id acc =
  acc := Some id ;
  acc

let get_head_id db_pool =
  let open Lwt_result_syntax in
  let*! head_id_ref =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.fold get_canonical_chain_head_id_query add_head_id () (ref None))
      db_pool
  in
  match head_id_ref with
  | Error e -> tzfail (Canonical_chain_head (Caqti_error.show e))
  | Ok head_id_ref -> return !head_id_ref

let get_entries db_pool query add_to_map empty_map head_id query_error =
  let open Lwt_result_syntax in
  let*! map =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.fold query add_to_map head_id empty_map)
      db_pool
  in
  match map with
  | Error e -> tzfail (query_error (Caqti_error.show e))
  | Ok map -> return map

let create_table db_pool create_table_query query_error =
  let open Lwt_result_syntax in
  let*! result =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) -> Db.exec create_table_query ())
      db_pool
  in
  match result with
  | Error e -> tzfail (query_error (Caqti_error.show e))
  | Ok () -> return_unit

let insert_entry db_pool query entry query_error =
  let open Lwt_result_syntax in
  let*! result =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) -> Db.exec query entry)
      db_pool
  in
  match result with
  | Error e -> tzfail (query_error (Caqti_error.show e))
  | Ok () -> return_unit

(* Printing. *)

let print_canonical_chain map =
  let find_key_by_value map x =
    Query_Map.filter (fun _ value -> value = x) map
    |> Query_Map.to_seq |> List.of_seq
    |> fun lst -> List.nth lst 0 |> Option.map fst
  in

  let rec process_block current_block =
    match find_key_by_value map (Some current_block) with
    | None -> ()
    | Some next_block ->
        Format.printf " --> %s@," (string_of_int next_block) ;
        process_block next_block
  in

  match find_key_by_value map None with
  | None -> Format.printf "No canonical chain found"
  | Some first_block ->
      Format.printf "%s" (string_of_int first_block) ;
      process_block first_block

(* Commands. *)

let connect_db db_path =
  let open Lwt_result_syntax in
  let db_uri = Uri.of_string ("sqlite3:" ^ db_path) in
  match Caqti_lwt.connect_pool db_uri with
  | Error e -> tzfail (Caqti_database_connection (Caqti_error.show e))
  | Ok db_pool -> return db_pool

let canonical_chain_command db_path print_result =
  let open Lwt_result_syntax in
  let* db_pool = connect_db db_path in
  (* 1. Create canonical_chain table in teztale db *)
  let* () =
    create_table db_pool create_canonical_chain_table_query (fun e ->
        Canonical_chain_query e)
  in

  (* 2. Obtain the head id of the canonical chain *)
  let* head_id = get_head_id db_pool in

  (* 3. Retrieve the entries which form the canonical chain *)
  let* map =
    get_entries
      db_pool
      get_canonical_chain_entries_query
      add_canonical_chain_row
      Query_Map.empty
      (Option.value ~default:0 head_id)
      (fun e -> Canonical_chain_query e)
  in

  (* 4. Populate the canonical_chain table *)
  let counter = ref 0 in
  if print_result then print_canonical_chain map ;
  Query_Map.iter_es
    (fun id predecessor ->
      counter := !counter + 1 ;
      insert_entry
        db_pool
        insert_canonical_chain_entry_query
        (!counter, id, Option.value ~default:(-1) predecessor)
        (fun e -> Canonical_chain_query e))
    map

let reorganised_blocks_command db_path =
  let open Lwt_result_syntax in
  let* db_pool = connect_db db_path in
  (* 1. Create reorganised_blocks table in teztale db *)
  let* () =
    create_table db_pool create_reorganised_blocks_table_query (fun e ->
        Reorganised_blocks_query e)
  in

  (* 2. Obtain the head id of the canonical chain *)
  let* head_id = get_head_id db_pool in

  (* 3. Retrieve the entries which form the reorganised blocks *)
  let* map =
    get_entries
      db_pool
      get_reorganised_blocks_entries_query
      add_reorganised_blocks_row
      Query_Map.empty
      (Option.value ~default:0 head_id)
      (fun e -> Reorganised_blocks_query e)
  in

  (* 4. Populate the reorganised_blocks table *)
  let counter = ref 0 in
  Query_Map.iter_es
    (fun id (level, round) ->
      counter := !counter + 1 ;
      insert_entry
        db_pool
        insert_reorganised_blocks_entry_query
        (!counter, id, level, round)
        (fun e -> Reorganised_blocks_query e))
    map

(* Arguments. *)

let db_arg =
  let open Lwt_result_syntax in
  arg
    ~doc:"Teztale db path"
    ~long:"db-path"
    ~placeholder:"db-path"
    ( parameter @@ fun _ctxt db_path ->
      if Sys.file_exists db_path then return db_path
      else tzfail (Db_path db_path) )

let print_arg =
  Tezos_clic.switch
    ~short:'p'
    ~long:"print"
    ~doc:"If print flag is set, the result of the query will be printed."
    ()

let commands =
  let open Lwt_result_syntax in
  [
    command
      ~group
      ~desc:"Canonical chain query."
      (args2 db_arg print_arg)
      (fixed ["canonical_chain_query"])
      (fun (db_path, print_result) _cctxt ->
        match db_path with
        | Some db_path -> canonical_chain_command db_path print_result
        | None -> tzfail (Db_path ""));
    command
      ~group
      ~desc:"Reorganised blocks query."
      (args1 db_arg)
      (fixed ["reorganised_blocks_query"])
      (fun db_path _cctxt ->
        match db_path with
        | Some db_path -> reorganised_blocks_command db_path
        | None -> tzfail (Db_path ""));
  ]

module Custom_client_config : Client_main_run.M = struct
  type t = unit

  let default_base_dir = "/tmp"

  let global_options () = args1 @@ constant ()

  let parse_config_args ctx argv =
    let open Lwt_result_syntax in
    let* (), remaining =
      Tezos_clic.parse_global_options (global_options ()) ctx argv
    in
    let open Client_config in
    return (default_parsed_config_args, remaining)

  let default_chain = `Main

  let default_block = `Head 0

  let default_daily_logs_path = None

  let default_media_type = Tezos_rpc_http.Media_type.Command_line.Binary

  let other_registrations = None

  let clic_commands ~base_dir:_ ~config_commands:_ ~builtin_commands:_
      ~other_commands:_ ~require_auth:_ =
    commands

  let logger = None
end

let () =
  let open Lwt_result_syntax in
  let select_commands _ctx _ = return commands in
  Client_main_run.run (module Custom_client_config) ~select_commands
