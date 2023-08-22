(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
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

module S = struct
  let profiler_names = Shell_profiling.all_profilers

  let lod_arg =
    Resto.Arg.make
      ~name:"profiler level of detail"
      ~destruct:(function
        | "terse" -> Ok Profiler.Terse
        | "verbose" -> Ok Profiler.Verbose
        | "detailed" -> Ok Profiler.Detailed
        | _ -> Error "invalid lod parameter")
      ~construct:(function
        | Profiler.Terse -> "terse"
        | Profiler.Verbose -> "verbose"
        | Profiler.Detailed -> "detailed")
      ()

  let activate_all =
    Tezos_rpc.Service.get_service
      ~description:"Activate all profilers."
      ~query:
        Tezos_rpc.Query.(
          query Fun.id |+ field "lod" lod_arg Terse Fun.id |> seal)
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "activate_all")

  let deactivate_all =
    Tezos_rpc.Service.get_service
      ~description:"Deactivate all profilers."
      ~query:Tezos_rpc.Query.empty
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "deactivate_all")

  let profiler_name_arg =
    Resto.Arg.make
      ~name:"profiler name"
      ~destruct:(fun s ->
        if
          List.mem_assoc
            ~equal:String.equal
            s
            (List.map
               (fun (name, profiler) ->
                 (Shell_profiling.profiler_name_to_string name, profiler))
               Shell_profiling.all_profilers)
        then Ok s
        else Error (Printf.sprintf "no profiler named '%s' found" s))
      ~construct:Fun.id
      ()

  let activate =
    Tezos_rpc.Service.get_service
      ~description:"Activate a profiler."
      ~query:
        Tezos_rpc.Query.(
          query Fun.id |+ field "lod" lod_arg Terse Fun.id |> seal)
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "activate" /: profiler_name_arg)

  let deactivate =
    Tezos_rpc.Service.get_service
      ~description:"Deactivate a profiler."
      ~query:Tezos_rpc.Query.empty
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "deactivate" /: profiler_name_arg)

  let list =
    Tezos_rpc.Service.get_service
      ~description:"List profilers."
      ~query:Tezos_rpc.Query.empty
      ~output:Data_encoding.(list string)
      Tezos_rpc.Path.(root / "profiler" / "list")
end
