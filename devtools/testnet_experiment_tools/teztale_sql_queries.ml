(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

(* Create tables queries *)

let create_canonical_chain_table_query =
  Caqti_request.Infix.(Caqti_type.(unit ->. unit))
    {| CREATE TABLE IF NOT EXISTS canonical_chain(
         id INTEGER PRIMARY KEY,
         block_id INTEGER NOT NULL,
         predecessor INTEGER,
         FOREIGN KEY (block_id) REFERENCES blocks(id),
         FOREIGN KEY (predecessor) REFERENCES blocks(predecessor)) |}

let create_reorganised_blocks_table_query =
  Caqti_request.Infix.(Caqti_type.(unit ->. unit))
    {| CREATE TABLE IF NOT EXISTS reorganised_blocks(
         id INTEGER PRIMARY KEY,
         block_id INTEGER,
         level INTEGER NOT NULL,
         round INTEGER NOT NULL,
         FOREIGN KEY (block_id) REFERENCES blocks(id)) |}

(* Get entries queries *)

let get_canonical_chain_head_id_query =
  Caqti_request.Infix.(Caqti_type.unit ->* Caqti_type.int)
    {| SELECT predecessor
       FROM blocks
       WHERE id = (
         SELECT predecessor
         FROM blocks
         WHERE level = (
           SELECT MAX(level)
           FROM blocks
         )
         LIMIT 1
       ) |}

let get_canonical_chain_entries_query =
  Caqti_request.Infix.(Caqti_type.int ->* Caqti_type.(tup2 int (option int)))
    {| WITH canonical_chain AS (
         SELECT id, predecessor
         FROM blocks
         WHERE id = ?

         UNION ALL

         SELECT b.id, b.predecessor
         FROM canonical_chain c
         JOIN blocks b ON c.predecessor = b.id
       )

       SELECT id, predecessor
       FROM canonical_chain |}

let get_reorganised_blocks_entries_query =
  Caqti_request.Infix.(Caqti_type.int ->* Caqti_type.(tup3 int int int))
    {| SELECT b.id, b.level, b.round
       FROM blocks b 
       WHERE NOT EXISTS 
       ( SELECT *
         FROM canonical_chain c
         WHERE c.block_id = b.id )
       AND b.level <= (
         SELECT level
         FROM blocks
         WHERE id = ?
       ) |}

(* Populate tables queries *)

let insert_canonical_chain_entry_query =
  Caqti_request.Infix.(Caqti_type.(tup3 int int int ->. unit))
    {| INSERT INTO canonical_chain(id, block_id, predecessor) 
       VALUES ($1, $2, $3) ON CONFLICT DO NOTHING |}

let insert_reorganised_blocks_entry_query =
  Caqti_request.Infix.(Caqti_type.(tup4 int int int int ->. unit))
    {| INSERT INTO reorganised_blocks(id, block_id, level, round) 
       VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING |}
