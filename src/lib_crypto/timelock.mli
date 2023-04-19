(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2021 Nomadic Labs, <contact@nomadic-labs.com>          *)
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

(** [Timelock] is a set of functions to handle time-locking a value and opening
    time-locked values.

    A time-locked value can be opened slowly by anyone doing a fixed number of
    sequential operations.

    In the interface of this module, this fixed number is consistently named
    [time] and is represented by an integer.

    Once opened via the slow method a proof of opening can be produced to avoid
    having to do so again. This proof is verifiable in logarithmic time.

    In order to time-lock an arbitrary sequence of bytes, we
       1. encrypt the bytes with a symmetric key, and then
       2. we time-lock the symmetric key itself.

   This module implements a scheme inspired by:
   Time-lock puzzles and timed release - Rivest, Shamir, Wagner
   https://people.csail.mit.edu/rivest/pubs/RSW96.pdf
*)

(** We will time-lock symmetric keys to then handle arbitrary bytes *)
type symmetric_key

(** RSA public key to define a group in which we will work.
    The key is an integer n = p*q with p, q primes number. The group we work in
    is the set of inversible mod n. *)
type rsa_public

(** Puzzles are locked values that can be retrieved with a number of sequential
    operations. It is concretely a member of the RSA group. *)
type puzzle

(** Function taking as input a string and returning Some puzzle if the
    element is in the RSA group with RSA2048 as modulus, None otherwise. *)
val to_puzzle_opt : string -> puzzle option

(** Function taking as input a string and returning a puzzle with no
    check. *)
val to_puzzle_unsafe : string -> puzzle

(** Solution to a timelock puzzle. It is concretely a member of the RSA group.
    In our case it represents a symmetric key. *)
type solution

(** VDF proof (Wesolowski) that a given timelock puzzle corresponds to a given
    time-locked solution for a given time. *)
type vdf_proof

(** A symmetric ciphertext and message authentication code, containing the
    bytes we want to protect *)
type ciphertext

(** Tuple of the RSA group elements associated to a given time.
    A honestly generate VDF tuple comprises a timelock puzzle (the time-locked
    value) and the corresponding solution (the unlocked value) as well as a
    (Wesolowski) proof that the solution indeed corresponds to the puzzle for
    the associated time. *)
type vdf_tuple = {puzzle : puzzle; solution : solution; vdf_proof : vdf_proof}

(** Function taking as input an [rsa_public], a [time] and three strings
    representing a timelock puzzle, its corresponding solution and a Wesolowski
    proof and returning Some vdf_tuple if the elements are in the RSA group
    with rsa_public as modulus and the Wesolowski proof verifies, None
    otherwise. *)
val to_vdf_tuple_opt :
  rsa_public -> time:int -> string -> string -> string -> vdf_tuple option

(** Function taking as input three strings representing a timelock puzzle, a
    solution and a Wesolowski proof and returning them as vdf_tuple without
    verifying them. *)
val to_vdf_tuple_unsafe : string -> string -> string -> vdf_tuple

(** Proof that a given solution of an associated puzzle is correct. It is
    concretely a [vdf_tuple] and a [randomness], that is a scalar representing
    the randomness linking the vdf_tuple to the timelock puzzle. *)
type timelock_proof = {vdf_tuple : vdf_tuple; randomness : Z.t}

(** Default modulus for RSA-based timelock, chosen as 2048 bit RSA modulus
    challenge "RSA-2048". *)
val rsa2048 : rsa_public

(** Generates almost uniformly an integer mod n.
    It is in the RSA group with overwhelming probability.
    We use this since we want to lock symmetric keys, not pre-determined
    messages.

    @raise Failure if there is not enough entropy available. *)
val gen_puzzle_unsafe : rsa_public -> puzzle

(** Returns None if [rsa_public] is not rsa2048, otherwise returns
    Some [gen_puzzle_unsafe] [rsa_public]. *)
val gen_puzzle_opt : rsa_public -> puzzle option

(** Generates a symmetric encryption key out of a [timelock_proof].
    More precisely, computes and hashes solution**randomness mod rsa_public to
    a symmetric key for authenticated encryption. *)
val timelock_proof_to_symmetric_key :
  rsa_public -> timelock_proof -> symmetric_key

(** Generates a [timelock_proof] by unlocking a timelock [puzzle], given a
    [time] and an [rsa_public] modulus. The proof certifies that the solution
    found by unlocking the puzzle is correct. *)
val unlock_and_prove : rsa_public -> time:int -> puzzle -> timelock_proof

(** Produces a proof certifying that the [solution] indeed corresponds to the
    opening of the [puzzle] given a [time] and an RSA modulus [rsa_public]. *)
val prove : rsa_public -> time:int -> puzzle -> solution -> timelock_proof

(** Verifies with the [timelock_proof] that the [puzzle] indeed opens to the
    [solution] with given a [time:int] and an RSA modulus [rsa_public]. *)
val verify : rsa_public -> time:int -> puzzle -> timelock_proof -> bool

(** Precomputes a [vdf_tuple] given a [time:int] and optionally a [puzzle].
    If [precompute_path] is given, it will attempt to read the [vdf_tuple]
    locally and if unfound, will write the newly computed [vdf_tuple] there. *)
val precompute_timelock :
  ?puzzle:puzzle option ->
  ?precompute_path:string option ->
  time:int ->
  unit ->
  vdf_tuple

(** Generates a fresh timelock [puzzle] and corresponding [timelock_proof] by
    randomizing a [vdf_tuple] with a freshly generated randomness given a
    [time:int] and an [rsa_public] modulus. *)
val proof_of_vdf_tuple :
  rsa_public -> time:int -> vdf_tuple -> puzzle * timelock_proof

(** On a claim opening [timelock_proof] of a timelock [puzzle], verifies if the
    opening is valid, given a [time] and [rsa_public] modulus.
    If the opening is valid, it is hashed opening using the function
    [timelock_proof_to_symmetric_key] and returned as Some symmetric_key,
    otherwise it returns None. *)
val puzzle_to_symmetric_key :
  rsa_public -> time:int -> puzzle -> timelock_proof -> symmetric_key option

(** Encrypt some bytes given a symmetric key using authenticated encryption.
    The output contains both a ciphertext and a message authentication code. *)
val encrypt : symmetric_key -> bytes -> ciphertext

(** Given a symmetric key and ciphertext, checks the message authentication
    code. If the check passes, it decrypts the ciphertext and returns
    Some plaintext, otherwise it returns None. *)
val decrypt : symmetric_key -> ciphertext -> bytes option

val ciphertext_encoding : ciphertext Data_encoding.t

val rsa_public_encoding : rsa_public Data_encoding.t

val vdf_tuple_encoding : vdf_tuple Data_encoding.t

val proof_encoding : timelock_proof Data_encoding.t

(* -------- Exposed to the protocol -------- *)

(** Contains a timelock [puzzle], an RSA group modulus [rsa_public] and a
    [ciphertext] and is associated to a given time.
    If the chest was generated honestly, the decryption of the ciphertext can
    be provably recovered in time sequential operation in the RSA group defined
    by the modulus. *)
type chest = {puzzle : puzzle; rsa_public : rsa_public; ciphertext : ciphertext}

val chest_encoding : chest Data_encoding.t

(** Contains a [timelock_tuple] and a [randommness] and is associated to a
    given chest and timelock solution.
    This represents a proof that the given solution indeed corresponds to the
    opening of the given chest. *)
type chest_key = timelock_proof

val chest_key_encoding : chest_key Data_encoding.t

(** Result of the opening of a chest.
    The opening can fail in two ways which we distinguish to blame the right
    party. One can provide a false solution or unlocked_proof, in which
    case we return [Bogus_opening] and the provider of the chest key is at
    fault. Otherwise we return [Correct payload] where [payload] is
    the content that had originally been put in the chest. *)

type opening_result = Correct of Bytes.t | Bogus_cipher | Bogus_opening

(** Takes a [chest], [chest_key] and [time] and tries to recover the underlying
    plaintext. See the documentation of opening_result. *)
val open_chest : chest -> chest_key -> time:int -> opening_result

(** Gives the size of the underlying plaintext in a chest in bytes.
    Used for gas accounting*)
val get_plaintext_size : chest -> int

(*---- End protocol exposure -----*)

(** High level function which given a [payload], [time] and optionally a
    [precomputed_path], generates a [chest] and [chest_key].
    The [payload] corresponds to the message to timelock while the [time]
    corresponds to the difficulty in opening the chest. Beware, it does not
    correspond to a duration per se but to the number of iteration needed.
    The optional [precomputed_path] is a local path where to read or write some
    auxiliary information to generate the chest quickly. *)
val create_chest_and_chest_key :
  ?precompute_path:string option ->
  payload:Bytes.t ->
  time:int ->
  unit ->
  chest * chest_key

(** High level function which unlock the value and create the time-lock
    proof. *)
val create_chest_key : chest -> time:int -> chest_key

(**  ----- !!!!! DO NOT USE in production: the RNG is not safe !!!!! -----
     Sampler for the gas and encoding benchmarks. Takes an Ocaml RNG state as
     arg for reproducibility. *)
val chest_sampler :
  rng_state:Random.State.t ->
  plaintext_size:int ->
  time:int ->
  chest * chest_key
