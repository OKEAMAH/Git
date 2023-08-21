(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type request = {
  proc_id : int;
  procedure : Uri.agent_uri Remote_procedure.packed;
}

let request_encoding =
  Data_encoding.(
    delayed @@ fun () ->
    conv
      (fun {proc_id; procedure} -> (proc_id, procedure))
      (fun (proc_id, procedure) -> {proc_id; procedure})
      (obj2
         (req "id" int31)
         (req
            "procedure"
            (Remote_procedure.packed_encoding Uri.agent_uri_encoding))))

let rec try_read_line ~input state k =
  let* res =
    Lwt.pick
      [
        (let* line = Lwt_io.read_line input in
         return (`Read line));
        (let* () = Lwt_unix.sleep 1.0 in
         return `Timeout);
      ]
  in
  match res with
  | `Read line -> k line
  | `Timeout ->
      if Agent_builtins.agent_should_continue state then
        try_read_line ~input state k
      else unit

let run ~input ~output state =
  Log.info "Ready %s..." (Agent_state.home_dir state) ;
  let rec run () =
    try_read_line ~input state @@ fun req_str ->
    let* _ =
      Lwt.both
        (if Agent_builtins.agent_should_continue state then run ()
        else return ())
      @@
      match Helpers.of_json_string request_encoding req_str with
      | {proc_id; procedure = Packed proc} ->
          Log.debug ">>[%d]" proc_id ;
          Lwt.try_bind
            (fun () -> Remote_procedure.run state proc)
            (fun res ->
              Lwt_io.atomic
                (fun output ->
                  Lwt_io.write_line
                    output
                    Format.(
                      sprintf
                        "<<[%d]: %s"
                        proc_id
                        (Helpers.to_json_string
                           (Remote_procedure.response_encoding proc)
                           res)))
                output)
            (fun _exn ->
              (* It seems that [Test.fail] does not close properly the
                 processes. This is why we kill them explicitely. It
                 is not clear why [Test.fail] is not enough. This
                 should be investigated. *)
              let* () = Remote_procedure.run state Agent_builtins.Quit in
              Test.fail
                "Something went wrong with request %d, we need to do something \
                 about that."
                proc_id)
    in
    unit
  in
  run ()
