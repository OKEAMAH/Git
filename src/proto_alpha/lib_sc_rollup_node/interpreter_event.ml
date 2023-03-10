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

open Protocol.Alpha_context.Sc_rollup

module Simple = struct
  include Internal_event.Simple

  let section = ["sc_rollup_node"; "interpreter"]

  let transitioned_pvm =
    declare_4
      ~section
      ~name:"sc_rollup_node_interpreter_transitioned_pvm"
      ~msg:
        "Transitioned PVM at inbox level {inbox_level} to {state_hash} at tick \
         {ticks} with {num_messages} messages"
      ~level:Notice
      ("inbox_level", Protocol.Alpha_context.Raw_level.encoding)
      ("state_hash", State_hash.encoding)
      ("ticks", Tick.encoding)
      ("num_messages", Data_encoding.int31)

  let intended_failure =
    declare_4
      ~section
      ~name:"sc_rollup_node_interpreter_intended_failure"
      ~msg:
        "Intended failure at level {level} for message indexed {message_index} \
         and at the tick {message_tick} of message processing (internal = \
         {internal})."
      ~level:Notice
      ("level", Data_encoding.int31)
      ("message_index", Data_encoding.int31)
      ("message_tick", Data_encoding.int64)
      ("internal", Data_encoding.bool)

  let pvm_compute_step_many_begins =
    declare_3
      ~section
      ~name:"sc_rollup_node_pvm_compute_step_many_begins"
      ~msg:
        "PVM starts executing compute_step_many at {timestamp}, with params \
         stop_at_snapshot: {stop_at_snapshot} and max_steps: {max_steps}"
      ~level:Debug
      ("timestamp", Data_encoding.float)
      ("stop_at_snapshot", Data_encoding.(option bool))
      ("max_steps", Data_encoding.int64)

  let pvm_compute_step_many_ends =
    declare_3
      ~section
      ~name:"sc_rollup_node_pvm_compute_step_many_ends"
      ~msg:
        "PVM ends executing compute_step_many at {timestamp}, with params \
         stop_at_snapshot: {stop_at_snapshot} and max_steps: {max_steps}"
      ~level:Debug
      ("timestamp", Data_encoding.float)
      ("stop_at_snapshot", Data_encoding.(option bool))
      ("max_steps", Data_encoding.int64)
end

(** [transition_pvm inbox_level hash tick n] emits the event that a PVM
   transition is leading to the state of the given [hash] by
   processing [n] messages at [tick]. *)
let transitioned_pvm inbox_level hash tick num_messages =
  Simple.(emit transitioned_pvm (inbox_level, hash, tick, num_messages))

(** [intended_failure level message_index message_tick internal] emits
   the event that an intended failure has been injected at some given
   [level], during the processing of a given [message_index] and at
   tick [message_tick] during this message processing. [internal] is
   [true] if the failure is injected in a PVM internal
   step. [internal] is [false] if the failure is injected in the input
   to the PVM. *)
let intended_failure ~level ~message_index ~message_tick ~internal =
  Simple.(emit intended_failure (level, message_index, message_tick, internal))

(* This event is emitted when Interpreter is about to invoke PMV.compute_step_many *)
let pvm_compute_step_many_begins ~timestamp ~stop_at_snapshot ~max_steps =
  Simple.(
    emit pvm_compute_step_many_begins (timestamp, stop_at_snapshot, max_steps))

(* This event is emitted when an invocation of PMV.compute_step_many has finished,
   and control flow has been returned to Interpreter *)
let pvm_compute_step_many_ends ~timestamp ~stop_at_snapshot ~max_steps =
  Simple.(
    emit pvm_compute_step_many_ends (timestamp, stop_at_snapshot, max_steps))
