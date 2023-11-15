(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

type 'tree tick_state_cache

val tick_state_cache : unit -> 'a tick_state_cache

(** [process_head plugin node_ctxt ctxt ~predecessor head (inbox, messages)]
    interprets the [messages] associated with a [head] (where [predecessor] is
    the predecessor of [head] in the L1 chain). This requires the [inbox] to be
    updated beforehand. It returns [(ctxt, num_messages, num_ticks, tick)] where
    [ctxt] is the updated layer 2 context (with the new PVM state),
    [num_messages] is the number of [messages], [num_ticks] is the number of
    ticks taken by the PVM for the evaluation and [tick] is the tick reached by
    the PVM after the evaluation. *)
val process_head :
  ('repo, 'tree) Protocol_plugin_sig.typed_partial ->
  'repo Node_context.rw ->
  ('a, 'repo, 'tree) Context.context ->
  predecessor:Layer1.header ->
  Layer1.header ->
  Octez_smart_rollup.Inbox.t * string list ->
  (('a, 'repo, 'tree) Context.context * int * int64 * Z.t) tzresult Lwt.t

(** [state_of_tick plugin node_ctxt ?start_state ~tick level] returns [Some
    (state, hash)] for a given [tick] if this [tick] happened before
    [level]. Otherwise, returns [None]. If provided, the evaluation is resumed
    from [start_state]. *)
val state_of_tick :
  ('repo, 'tree) Protocol_plugin_sig.typed_partial ->
  (_, 'repo) Node_context.t ->
  'tree tick_state_cache ->
  ?start_state:(Fuel.Accounted.t, 'tree) Pvm_plugin_sig.eval_state ->
  tick:Z.t ->
  int32 ->
  (Fuel.Accounted.t, 'tree) Pvm_plugin_sig.eval_state option tzresult Lwt.t

(** [state_of_head plugin node_ctxt ctxt head] returns the state corresponding
    to the block [head], or the state at rollup genesis if the block is before
    the rollup origination. *)
val state_of_head :
  ('repo, 'tree) Protocol_plugin_sig.typed_partial ->
  ('a, 'repo) Node_context.t ->
  ('a, 'repo, 'tree) Context.context ->
  Layer1.head ->
  (('a, 'repo, 'tree) Context.context * 'tree) tzresult Lwt.t
