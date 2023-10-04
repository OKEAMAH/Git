(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

(* Teztale querying tool
   ------------------------
   Invocation:
     ./_build/default/devtools/testnet_experiment_tools/get_teztale_data.exe \
     canonical_chain_query \
     --db-path <db-path>
   Requirements:
     <db-path> - path to the teztale database
   Description:
     This file contains the tool for querying the teztale database.
     The queries that it provides are:
     - get_canonical_chain : get table (id, predecessor) of block ids in the
     increasing order as they appear in the canonical chain from the db.
*)

open Tezos_clic

let block_finality = 2

(* Data Structures *)

module Canonical_Chain_Map = Map.Make (Int)

(* Errors *)

type error +=
  | Caqti_database_connection of Caqti_error.load
  | Canonical_chain_creation of Caqti_error.t
  | Canonical_chain_retrieval of Caqti_error.t
  | Canonical_chain_insertion of Caqti_error.t
  | Canonical_chain_head of Caqti_error.t

(* Aggregators *)

let add_canonical_chain_row (id, predecessor) acc =
  Canonical_Chain_Map.add id predecessor acc

let add_max_level level acc =
  acc := Some level ;
  acc

(* Queries *)

let get_canonical_chain db_pool max_level =
  let open Lwt_result_syntax in
  let query =
    {| WITH canonical_chain AS (
          SELECT id, predecessor
          FROM blocks
          WHERE level = ?

          UNION ALL

          SELECT b.id, b.predecessor
          FROM canonical_chain c
          JOIN blocks b ON c.predecessor = b.id
       )

       SELECT id, predecessor
       FROM canonical_chain
       ORDER BY id ASC |}
  in
  let canonical_chain_request =
    Caqti_request.Infix.(Caqti_type.int ->* Caqti_type.(tup2 int (option int)))
      query
  in
  let*! map =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.fold
          canonical_chain_request
          add_canonical_chain_row
          max_level
          Canonical_Chain_Map.empty)
      db_pool
  in
  match map with
  | Error e -> tzfail (Canonical_chain_retrieval e)
  | Ok map -> return map

let create_canonical_chain_table db_pool =
  let open Lwt_result_syntax in
  let query =
    Caqti_request.Infix.(Caqti_type.(unit ->. unit))
      {| CREATE TABLE IF NOT EXISTS canonical_chain(
         id INTEGER PRIMARY KEY,
         predecessor INTEGER ) |}
  in
  let*! result =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) -> Db.exec query ())
      db_pool
  in
  match result with
  | Error e -> tzfail (Canonical_chain_creation e)
  | Ok () -> return_unit

let insert_canonical_chain_entry db_pool id predecessor =
  let open Lwt_result_syntax in
  let query =
    Caqti_request.Infix.(Caqti_type.(tup2 string string ->. unit))
      {| INSERT INTO canonical_chain(id, predecessor) 
         VALUES ($1, $2) ON CONFLICT DO NOTHING |}
  in
  let*! result =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.exec query (id, predecessor))
      db_pool
  in
  match result with
  | Error e -> tzfail (Canonical_chain_insertion e)
  | Ok () -> return_unit

let get_head_level db_pool =
  let open Lwt_result_syntax in
  let query = {| SELECT MAX(level)
                 FROM blocks |} in
  let get_head_level_request =
    Caqti_request.Infix.(Caqti_type.unit ->* Caqti_type.int) query
  in
  let*! head_level_ref =
    Caqti_lwt.Pool.use
      (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.fold get_head_level_request add_max_level () (ref None))
      db_pool
  in
  match head_level_ref with
  | Error e -> tzfail (Canonical_chain_head e)
  | Ok head_level_ref -> return !head_level_ref

(* Commands *)

let canonical_chain_command db_path =
  let open Lwt_result_syntax in
  let db_uri = Uri.of_string ("sqlite3:" ^ db_path) in
  match Caqti_lwt.connect_pool db_uri with
  | Error e -> tzfail (Caqti_database_connection e)
  | Ok db_pool ->
      (* 1. Create canonical_table in teztale db *)
      let* () = create_canonical_chain_table db_pool in

      (* 2. Obtain the head level of the canonical chain *)
      let* head_level = get_head_level db_pool in

      (* 3. Retrieve the entries which form the canonical chain
            Use head_level - 2 because the blockchain has finality 2 *)
      let* map =
        get_canonical_chain
          db_pool
          (Option.value ~default:0 head_level - block_finality)
      in

      (* 4. Populate the canonical_chain table *)
      let* result =
        Canonical_Chain_Map.iter_es
          (fun id predecessor ->
            let id_str = string_of_int id in
            let predecessor_str =
              Option.value ~default:"N/A" (Option.map string_of_int predecessor)
            in
            insert_canonical_chain_entry db_pool id_str predecessor_str)
          map
      in
      return result

(* Arguments *)

let db_arg =
  let open Lwt_result_syntax in
  arg
    ~doc:"Teztale db path"
    ~long:"db-path"
    ~placeholder:"db-path"
    ( parameter @@ fun () db_path ->
      if Sys.file_exists db_path then return db_path
      else failwith "%s does not exist" db_path )

let commands =
  [
    command
      ~group:
        {
          name = "devtools";
          title = "Command for querying the teztale db for canonical chain.";
        }
      ~desc:"Canonical chain query."
      (args1 db_arg)
      (fixed ["canonical_chain_query"])
      (fun db_path () ->
        match db_path with
        | Some db_path -> canonical_chain_command db_path
        | None -> failwith "No database path provided");
  ]

let run () =
  let argv = Sys.argv |> Array.to_list |> List.tl |> Option.value ~default:[] in
  Tezos_clic.dispatch commands () argv

let () =
  match Lwt_main.run (run ()) with
  | Ok () -> ()
  | Error trace -> Format.printf "ERROR: %a%!" Error_monad.pp_print_trace trace
