(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* SPDX-FileCopyrightText: 2024 Nomadic Labs <contact@nomadic-labs.com>      *)
(*                                                                           *)
(*****************************************************************************)

(* This module is about shard amplification, a feature allowing DAL
   nodes which receive enough shards of a given slot to contribute to
   the DAL reliability by reconstructing the slot, recomputing all the
   shards, and republishing the missing shards on the DAL network. *)

(* [amplify shard_store] is called each time a new shard is received
   by an observer node and added to the shard store
   [shard_store]. This function is called after the update of the
   shard store. *)
val amplify : Store.Shards.t -> unit
