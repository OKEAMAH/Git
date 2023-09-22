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

(** Testing
    -------
    Component:  Lib_crypto_dal Bench_dal_cryptobox
    Invocation: dune exec src/lib_crypto_dal/test/main.exe -- --file bench_dal_cryptobox.ml
    Subject:    Benchmarks the cryptography used in the Data Availability Layer (DAL)
*)

(* Initializes the DAL parameters *)
let init parameters = Cryptobox.Internal_for_tests.load_parameters parameters

let verify_shard =
  let open Error_monad.Result_syntax in
  let config =
    Dal_config.
      {
        page_size = 4096;
        slot_size = 1 lsl 20;
        redundancy_factor = 16;
        number_of_shards = 2048;
      }
  in
  let params = Cryptobox.Internal_for_tests.parameters_initialisation config in
  init params ;
  assert (Cryptobox.Internal_for_tests.ensure_validity config) ;
  let* t = Cryptobox.make config in
  let slot = Bytes.make config.slot_size '\000' in
  let* polynomial = Cryptobox.polynomial_from_slot t slot in
  let* commitment = Cryptobox.commit t polynomial in
  let shards = Cryptobox.shards_from_polynomial t polynomial in
  let precomputation = Cryptobox.precompute_shards_proofs t in
  let shard_proofs = Cryptobox.prove_shards t ~polynomial ~precomputation in
  let shard_index = Random.int config.number_of_shards in
  match
    Seq.find (fun ({index; _} : Cryptobox.shard) -> index = shard_index) shards
  with
  | None ->
      (* The shard index was sampled within the bounds, so this case
         (the queried index is out of bounds) doesn't happen. *)
      assert false
  | Some shard ->
      Cryptobox.verify_shard t commitment shard shard_proofs.(shard_index)

let () =
  Lwt.async (fun () ->
      verify_shard |> function Ok _ -> Lwt.return () | _ -> assert false)
