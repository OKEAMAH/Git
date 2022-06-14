(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Protocol.Alpha_context

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2880
   Add corresponding .mli file. *)

module Simple = struct
  include Internal_event.Simple

  let section = ["sc_rollup_node"; "refutation_game"]

  let timeout =
    declare_1
      ~section
      ~name:"sc_rollup_node_timeout"
      ~msg:
        "The rollup node has been slashed because of a timeout issued by \
         {address}"
      ~level:Notice
      ("address", Signature.Public_key_hash.encoding)

  let invalid_move =
    declare_0
      ~section
      ~name:"sc_rollup_node_invalid_move"
      ~msg:
        "The rollup node is about to make an invalid move in the refutation \
         game! It is stopped to avoid being slashed. The problem should be \
         reported immediately or the rollup node should be upgraded to have a \
         chance to be back before the timeout is reached."
      ~level:Notice
      ()

  let refutation_published =
    declare_2
      ~section
      ~name:"sc_rollup_node_refutation_published"
      ~msg:
        "Refutation was published - opponent: {opponent}, refutation: \
         {refutation}"
      ~level:Notice
      ("opponent", Sc_rollup.Staker.encoding)
      ("refutation", Data_encoding.option Sc_rollup.Game.refutation_encoding)

  let refutation_failed =
    declare_2
      ~section
      ~name:"sc_rollup_node_refutation_failed"
      ~msg:
        "Publishing refutation has failed - opponent: {opponent}, refutation: \
         {refutation}"
      ~level:Notice
      ("opponent", Sc_rollup.Staker.encoding)
      ("refutation", Data_encoding.option Sc_rollup.Game.refutation_encoding)

  let refutation_backtracked =
    declare_2
      ~section
      ~name:"sc_rollup_node_refutation_backtracked"
      ~msg:
        "Publishing refutation was backtracked - opponent: {opponent}, \
         refutation: {refutation}"
      ~level:Notice
      ("opponent", Sc_rollup.Staker.encoding)
      ("refutation", Data_encoding.option Sc_rollup.Game.refutation_encoding)

  let refutation_skipped =
    declare_2
      ~section
      ~name:"sc_rollup_node_refutation_skipped"
      ~msg:
        "Publishing refutation was skipped - opponent: {opponent}, refutation: \
         {refutation}"
      ~level:Notice
      ("opponent", Sc_rollup.Staker.encoding)
      ("refutation", Data_encoding.option Sc_rollup.Game.refutation_encoding)

  let timeout_published =
    declare_1
      ~section
      ~name:"sc_rollup_node_timeout_published"
      ~msg:"Timeout was published - players: {players}"
      ~level:Notice
      ("players", Sc_rollup.Game.Index.encoding)

  let timeout_failed =
    declare_1
      ~section
      ~name:"sc_rollup_node_timeout_failed"
      ~msg:"Publishing timeout has failed - players: {players}"
      ~level:Notice
      ("players", Sc_rollup.Game.Index.encoding)

  let timeout_backtracked =
    declare_1
      ~section
      ~name:"sc_rollup_node_timeout_backtracked"
      ~msg:"Publishing timeout was backtracked - players: {players}"
      ~level:Notice
      ("players", Sc_rollup.Game.Index.encoding)

  let timeout_skipped =
    declare_1
      ~section
      ~name:"sc_rollup_node_timeout_skipped"
      ~msg:"Publishing timeout was skipped - players: {players}"
      ~level:Notice
      ("players", Sc_rollup.Game.Index.encoding)
end

let timeout address = Simple.(emit timeout address)

let invalid_move () = Simple.(emit invalid_move ())

let refutation_published opponent refutation =
  Simple.(emit refutation_published (opponent, refutation))

let refutation_failed opponent refutation =
  Simple.(emit refutation_failed (opponent, refutation))

let refutation_backtracked opponent refutation =
  Simple.(emit refutation_backtracked (opponent, refutation))

let refutation_skipped opponent refutation =
  Simple.(emit refutation_skipped (opponent, refutation))

let timeout_published players = Simple.(emit timeout_published players)

let timeout_failed players = Simple.(emit timeout_failed players)

let timeout_backtracked players = Simple.(emit timeout_backtracked players)

let timeout_skipped players = Simple.(emit timeout_skipped players)
