(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

module Simple = struct
  include Internal_event.Simple

  let section = ["layer2_store"]

  let calling_gc =
    declare_2
      ~section
      ~name:"calling_gc"
      ~level:Info
      ~msg:
        "Garbage collection started for level {gc_level} at head level \
         {head_level}"
      ("gc_level", Data_encoding.int32)
      ("head_level", Data_encoding.int32)

  let starting_context_gc =
    declare_1
      ~section
      ~name:"starting_context_gc"
      ~level:Info
      ~msg:"Starting context garbage collection for commit {context_hash}"
      ("context_hash", Context_hash.encoding)
      ~pp1:Context_hash.pp

  let context_gc_already_launched =
    declare_0
      ~section
      ~name:"gc_already_launched"
      ~level:Info
      ~msg:
        "An attempt to launch context GC was made, but a previous GC run has \
         not yet finished. No action was taken"
      ()

  let ending_context_gc =
    declare_2
      ~section
      ~name:"ending_context_gc"
      ~level:Info
      ~msg:
        "Context garbage collection finished in {duration} (finalised in \
         {finalisation})"
      ~pp1:Time.System.Span.pp_hum
      ("duration", Time.System.Span.encoding)
      ~pp2:Time.System.Span.pp_hum
      ("finalisation", Time.System.Span.encoding)

  let context_gc_failure =
    declare_1
      ~section
      ~name:"gc_failure"
      ~level:Warning
      ~msg:"[Warning] Context garbage collection failed: {error}"
      ("error", Data_encoding.string)

  let context_gc_launch_failure =
    declare_1
      ~section
      ~name:"context_gc_launch_failure"
      ~level:Warning
      ~msg:"[Warning] Context garbage collection launch failed: {error}"
      ("error", Data_encoding.string)

  let gc_levels_storage_failure =
    declare_0
      ~section
      ~name:"gc_levels_storage_failure"
      ~level:Warning
      ~msg:"[Warning] An attempt to write GC level information to disk failed"
      ()

  let gc_finished =
    declare_2
      ~section
      ~name:"gc_finished"
      ~level:Info
      ~msg:
        "Garbage collection finished for level {gc_level} at head level \
         {head_level}"
      ("gc_level", Data_encoding.int32)
      ("head_level", Data_encoding.int32)
end

let calling_gc ~gc_level ~head_level =
  Simple.(emit calling_gc) (gc_level, head_level)

let starting_context_gc hash = Simple.(emit starting_context_gc) hash

let context_gc_already_launched () =
  Simple.(emit context_gc_already_launched) ()

let ending_context_gc t = Simple.(emit ending_context_gc) t

let context_gc_failure msg = Simple.(emit context_gc_failure) msg

let context_gc_launch_failure msg = Simple.(emit context_gc_launch_failure) msg

let gc_levels_storage_failure () = Simple.(emit gc_levels_storage_failure) ()

let gc_finished ~gc_level ~head_level =
  Simple.(emit gc_finished) (gc_level, head_level)
