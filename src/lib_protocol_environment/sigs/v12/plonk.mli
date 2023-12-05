(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(**
  aPlonK is a {e PlonK}-based proving system.
  As such, it provides a way to create {e succinct cryptographic proofs}
  about a given predicate, which can be then verified with a low
  computational cost.

  In this system, a predicate is represented by an {e arithmetic circuit},
  i.e. a collection of arithmetic {e gates} operating over a {e prime field},
  connected through {e wires} holding {e scalars} from this field.
  For example, the following diagram illustrates a simple circuit checking that
  the addition of two scalars ([w1] and [w2]) is equal to [w0]. Here,
  the [add] gate can be seen as taking two inputs and producing an output,
  while the [eq] gate just takes two inputs and asserts they're equal.

{[
          (w0)│      w1│         w2│
              │        └───┐   ┌───┘
              │          ┌─┴───┴─┐
              │          │  add  │
              │          └───┬───┘
              └──────┐   ┌───┘w3
                   ┌─┴───┴─┐
                   │  eq   │
                   └───────┘
]}

  The wires of a circuit are called {e prover inputs}, since the prover needs
  an assignment of all wires to produce a proof.
  The predicate also declares a subset of the wires called {e verifier inputs}.
  In our example, wire [w0] is the only verifier input, which is
  indicated by the parenthesis.
  A proof for a given [w0] would prove the following statement:
    [∃ w1, w2, w3: w3 = w1 + w2 ∧ w0 = w3]
  This means that the verifier only needs a (typically small) subset of the
  inputs alongside the (succinct) proof to check the validity of the statement.

  A more interesting example would be to replace the [add] gate
  by a more complicated hash circuit. This would prove the knowledge of the
  pre-image of a hash.

  A simplified view of aPlonk's API consists of the following three functions:
{[
    val setup : circuit -> srs ->
      (prover_public_parameters, verifier_public_parameters)

    val prove : prover_public_parameters -> prover_inputs ->
      private_inputs -> proof

    val verify : verifier_public_parameters -> verifier_inputs ->
      proof -> bool
]}

  In addition to the prove and verify, the interface provides a function
  to setup the system. The setup function requires a {e Structured Reference String}.
  Two large SRSs were generated by the ZCash and Filecoin
  projects and are both used in aPlonK.
  Notice also that the circuit is used during setup only and, independently
  from its size, the resulting {e verifier_public_parameters} will be a
  succinct piece of data that will be posted on-chain to allow
  verification and they are bound to the specific circuit that generated
  them.
  The {e prover_public_parameters}'s size is linear in the size of the circuit.
  *)

type scalar := Bls.Primitive.Fr.t

(** Set of public parameters needed by the verifier.
    Its size is constant w.r.t. the size of the circuits. *)
type public_parameters

(** Map where each circuit identifier is bound to the verifier inputs for
    this circuit. *)
type verifier_inputs = (string * scalar array list) list

(** Succinct proof for a collection of statements. *)
type proof

val public_parameters_encoding : public_parameters Data_encoding.t

val proof_encoding : proof Data_encoding.t

val scalar_encoding : scalar Data_encoding.t

val scalar_array_encoding : scalar array Data_encoding.t

(** [verify public_parameters inputs proof] returns true if the [proof] is valid
    on the given [inputs] according to the [public_parameters]. *)
val verify : public_parameters -> verifier_inputs -> proof -> bool
