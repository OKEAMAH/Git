(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxheadalpha.com>                    *)
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
    Component:  Protocol (tx rollup l2)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                -- test "tx rollup l2"
    Subject:    test the layer-2 implementation of transaction rollup
*)

open Tztest
open Tx_rollup_l2_helpers
open Protocol
open Tx_rollup_l2_context

(** {1. Storage and context tests. } *)

(** {3. Utils wrapping tztest. } *)

let wrap_test t () =
  t () >|= function
  | Ok x -> Ok x
  | Error err -> Error [Environment.Ecoproto_error err]

let wrap_tztest_tests =
  List.map (fun (name, test) -> tztest name `Quick @@ wrap_test test)

(** {2. Storage tests. } *)

type Environment.Error_monad.error += Test

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/2362
   Use the Irmin store provided by [lib_context] for layer-2
   solutions, once available.
   As of now, we define a ad-hoc [STORAGE] implementation to run our
   tests, but eventually we need to actually make use of the same
   implementation as the transaction rollup node and the protocol. *)

(** [test_irmin_storage] checks that the implementation of [STORAGE]
    has the expected properties. *)
let test_irmin_storage () =
  let open Irmin_storage.Syntax in
  let store = empty_storage in

  let k1 = Bytes.of_string "k1" in
  let k2 = Bytes.of_string "k2" in
  let v1 = Bytes.of_string "v1" in
  let v2 = Bytes.of_string "v2" in

  (* 1. get (set store k1 v1) k1 == Some v1 *)
  let* store = Irmin_storage.set store k1 v1 in
  let* v1' = Irmin_storage.get store k1 in
  assert (v1' = Some v1) ;

  (* 2. k1 != k2 -> get (set store k2 v2) k1 = get store k1*)
  let* store = Irmin_storage.set store k2 v2 in
  let* v1'' = Irmin_storage.get store k1 in
  assert (v1' = v1'') ;

  (* 3. catch (fail e) f return == e *)
  let* e = catch (fail Test) (fun _ -> assert false) return in
  assert (e = Test) ;

  return_unit

(** {2. Context tests. } *)

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2461
   A lot of l2-context properties can be property-based tested. *)

(** {3. Utils } *)

let expect_error f err =
  let open Context_l2.Syntax in
  catch
    f
    (fun _ -> assert false)
    (fun err' -> if err = err' then return () else assert false)

let rng_state = Random.State.make_self_init ()

let gen_l2_address () =
  let seed =
    Bytes.init 32 (fun _ -> char_of_int @@ Random.State.int rng_state 255)
  in
  let secret_key = Bls12_381.Signature.generate_sk seed in
  let public_key = Bls12_381.Signature.MinPk.derive_pk secret_key in
  (secret_key, public_key, Tx_rollup_l2_address.of_bls_pk public_key)

let gen_n_address n =
  List.init ~when_negative_length:[] n (fun _ -> gen_l2_address ()) |> function
  | Ok addresses -> addresses
  | _ -> assert false

let nth_exn l i = match List.nth l i with Some x -> x | None -> assert false

let ((_, pk, addr1) as l2_addr) = gen_l2_address ()

let context_with_one_addr =
  let open Context_l2 in
  let open Syntax in
  let ctxt = empty_context in
  let+ (ctxt, _, idx1) = Address_index.get_or_associate_index ctxt addr1 in
  (ctxt, idx1)

(** {3. Test Address_metadata.} *)

module Test_Address_medata = struct
  open Context_l2
  open Address_metadata
  open Syntax

  (** Test that an initilized metadata has a counter of zero and is correctly
      incremented. *)
  let test_init_and_incr () =
    let* (ctxt, idx) = context_with_one_addr in

    let* metadata = get ctxt idx in
    assert (metadata = None) ;

    let* ctxt = init_with_public_key ctxt idx pk in
    let* metadata = get ctxt idx in
    assert (metadata = Some {counter = 0L; public_key = pk}) ;

    let* ctxt = incr_counter ctxt idx in
    let* metadata = get ctxt idx in
    assert (metadata = Some {counter = 1L; public_key = pk}) ;

    return_unit

  (** Test that initializing an index to a public key fails if the index
      has already been initialized. *)
  let test_init_twice_fails () =
    let* (ctxt, idx) = context_with_one_addr in

    let* ctxt = init_with_public_key ctxt idx pk in

    let* () =
      expect_error
        (init_with_public_key ctxt idx pk)
        (Metadata_already_initialized (Indexable.index_exn 0l))
    in

    return_unit

  (** Test that incrementing the counter of an unknown index fails. *)
  let test_incr_unknown_index () =
    let ctxt = empty_context in

    let idx = Indexable.index_exn 0l in

    let* () =
      expect_error
        (incr_counter ctxt idx)
        (Unknown_address_index (Indexable.index_exn 0l))
    in

    return_unit

  (** Test that crediting more than {!Int64.max_int} causes an overflow. *)
  let test_counter_overflow () =
    let* (ctxt, idx) = context_with_one_addr in
    let* ctxt = init_with_public_key ctxt idx pk in

    let* ctxt =
      Internal_for_tests.set ctxt idx {counter = Int64.max_int; public_key = pk}
    in

    let* () = expect_error (incr_counter ctxt idx) Counter_overflow in

    return_unit

  let tests =
    wrap_tztest_tests
      [
        ("test init and increments", test_init_and_incr);
        ("test init twice fails", test_init_twice_fails);
        ("test incr unknown index", test_incr_unknown_index);
        ("test overflow counter", test_counter_overflow);
      ]
end

(** {3. Test indexes. } *)

module type S = sig
  open Context_l2

  type value

  type index = value Indexable.index

  val name : string

  val init_context_n : int -> (t * value list) m

  val count : t -> int32 m

  val set_count : t -> int32 -> t m

  val get_or_associate_index :
    t -> value -> (t * [`Created | `Existed] * index) m

  val get : t -> value -> index option m

  val too_many : Environment.Error_monad.error
end

module Test_index (Index : S) = struct
  let init_context_1 () =
    let open Context_l2.Syntax in
    let* (ctxt, values) = Index.init_context_n 1 in
    let value = nth_exn values 0 in
    return (ctxt, value)

  (** Test that first associating a value creates an index and getting the index
      from the value gives the same index. *)
  let test_set_and_get () =
    let open Context_l2.Syntax in
    let* (ctxt, value) = init_context_1 () in

    let* (ctxt, created, idx1) = Index.get_or_associate_index ctxt value in
    assert (created = `Created) ;
    let* idx2 = Index.get ctxt value in

    assert (Some idx1 = idx2) ;

    return_unit

  (** Test that the empty context has no address indexes and associating a new
    address increments the count. *)
  let test_associate_fresh_index () =
    let open Context_l2.Syntax in
    let* (ctxt, value) = init_context_1 () in

    let* count = Index.count ctxt in
    assert (count = 0l) ;

    let* idx = Index.get ctxt value in
    assert (idx = None) ;

    let* (ctxt, created, idx) = Index.get_or_associate_index ctxt value in
    assert (created = `Created) ;
    let* count = Index.count ctxt in

    assert (count = 1l) ;
    assert (idx = Indexable.index_exn 0l) ;

    return_unit

  (** Test that associating twice the same value give the same index. *)
  let test_associate_value_twice () =
    let open Context_l2.Syntax in
    let* (ctxt, value) = init_context_1 () in

    let expected = Indexable.index_exn 0l in

    let* (ctxt, created, idx) = Index.get_or_associate_index ctxt value in
    assert (created = `Created) ;
    assert (idx = expected) ;

    let* idx = Index.get ctxt value in
    assert (idx = Some (Indexable.index_exn 0l)) ;

    let* (ctxt, existed, idx) = Index.get_or_associate_index ctxt value in
    assert (existed = `Existed) ;
    assert (idx = expected) ;

    let* count = Index.count ctxt in
    assert (count = 1l) ;

    return_unit

  let test_reach_too_many_l2 () =
    let open Context_l2.Syntax in
    let* (ctxt, value) = init_context_1 () in
    let* ctxt = Index.set_count ctxt Int32.max_int in

    let* () =
      expect_error (Index.get_or_associate_index ctxt value) Index.too_many
    in

    return_unit

  let tests =
    wrap_tztest_tests
      [
        ("test set and get", test_set_and_get);
        ("test associate fresh index", test_associate_fresh_index);
        ("test associate same value twice", test_associate_value_twice);
        ("test the limit of indexes", test_reach_too_many_l2);
      ]
end

module Test_Address_index = Test_index (struct
  include Context_l2.Address_index

  let name = "Address"

  type value = Tx_rollup_l2_address.t

  type index = value Indexable.index

  let init_context_n n =
    let open Context_l2.Syntax in
    let ctxt = empty_context in
    let addresses = gen_n_address n in
    let addresses = List.map (fun (_, _, x) -> x) addresses in
    return (ctxt, addresses)

  let set_count = Internal_for_tests.set_count

  let too_many = Too_many_l2_addresses
end)

(** [make_unit_ticket_key ctxt ticketer tx_rollup] computes the key hash of
    the unit ticket crafted by [ticketer] and owned by [tx_rollup].

    TODO: extracted from https://gitlab.com/tezos/tezos/-/merge_requests/4017,
    is there a more convenient way to forge a ticket?
*)
let make_unit_ticket_key ctxt ticketer address =
  let open Tezos_micheline.Micheline in
  let open Michelson_v1_primitives in
  let ticketer =
    Bytes
      ( 0,
        Data_encoding.Binary.to_bytes_exn
          Alpha_context.Contract.encoding
          ticketer )
  in
  let typ = Prim (0, T_unit, [], []) in
  let contents = Prim (0, D_Unit, [], []) in
  let owner =
    String (dummy_location, Tx_rollup_l2_address.to_b58check address)
  in
  match Alpha_context.Ticket_hash.make ctxt ~ticketer ~typ ~contents ~owner with
  | Ok (x, _) -> x
  | Error _ -> raise (Invalid_argument "make_unit_ticket_key")

(** [gen_n_ticket_hash n] generates [n]  {!Alpha_context.Ticket_hash.t} based on
    {!gen_n_address} and {!make_unit_ticket_key}.

    TODO: Is there a more convenient way to forge such hashes? Are dumb hashes
    enough?
*)
let gen_n_ticket_hash n =
  let x =
    Lwt_main.run
      ( Context.init n >>=? fun (b, contracts) ->
        Incremental.begin_construction b >|=? Incremental.alpha_ctxt
        >>=? fun ctxt ->
        let addressess = gen_n_address n in
        let tickets =
          List.map2
            ~when_different_lengths:[]
            (fun contract (_, _, address) ->
              make_unit_ticket_key ctxt contract address)
            contracts
            addressess
        in
        match tickets with Ok x -> return x | Error _ -> assert false )
  in

  match x with Ok x -> x | Error _ -> assert false

module Test_Ticket_index = Test_index (struct
  include Context_l2.Ticket_index

  let name = "Ticket"

  type value = Alpha_context.Ticket_hash.t

  type index = value Indexable.index

  let init_context_n n =
    let open Context_l2.Syntax in
    let ctxt = empty_context in
    let tickets = gen_n_ticket_hash n in
    return (ctxt, tickets)

  let set_count = Internal_for_tests.set_count

  let too_many = Too_many_l2_tickets
end)

module Test_Ticket_ledger = struct
  open Context_l2
  open Ticket_ledger
  open Syntax

  let ticket_idx1 = Indexable.index_exn 0l

  (** Test that crediting a ticket index to an index behaves correctly. *)
  let test_credit () =
    let* (ctxt, idx1) = context_with_one_addr in

    let* amount = get ctxt ticket_idx1 idx1 in
    assert (amount = 0L) ;

    let* ctxt = credit ctxt ticket_idx1 idx1 1L in
    let* amount = get ctxt ticket_idx1 idx1 in
    assert (amount = 1L) ;

    return_unit

  (** Test that crediting more than {!Int64.max_int} causes an overflow. *)
  let test_credit_too_much () =
    let* (ctxt, idx1) = context_with_one_addr in

    let* ctxt = credit ctxt ticket_idx1 idx1 Int64.(max_int) in

    let* () =
      expect_error (credit ctxt ticket_idx1 idx1 Int64.one) Balance_overflow
    in

    return_unit

  (** Test that crediting a non strictly positive quantity fails. *)
  let test_credit_invalid_quantity () =
    let* (ctxt, idx1) = context_with_one_addr in
    let* () =
      expect_error (credit ctxt ticket_idx1 idx1 Int64.zero) Invalid_quantity
    in

    return_unit

  (** Test that an index can be credited ticket indexes even if its not associated
      to an address. *)
  let test_credit_unknown_index () =
    let ctxt = empty_context in

    let* _ctxt = credit ctxt ticket_idx1 (Indexable.index_exn 0l) 1L in

    return_unit

  (** Test that spending a ticket from an index to another one behaves correctly *)
  let test_spend_valid () =
    let* (ctxt, idx1) = context_with_one_addr in

    let* ctxt = credit ctxt ticket_idx1 idx1 10L in

    let* amount = get ctxt ticket_idx1 idx1 in
    assert (amount = 10L) ;

    let* ctxt = spend ctxt ticket_idx1 idx1 5L in

    let* amount = get ctxt ticket_idx1 idx1 in
    assert (amount = 5L) ;

    return_unit

  (** Test that spending a ticket without the required balance fails. *)
  let test_spend_without_balance () =
    let* (ctxt, idx1) = context_with_one_addr in

    let* () = expect_error (spend ctxt ticket_idx1 idx1 1L) Balance_too_low in

    return_unit

  let tests =
    wrap_tztest_tests
      [
        ("test credit", test_credit);
        ("test credit too much", test_credit_too_much);
        ("test credit invalid quantity", test_credit_invalid_quantity);
        ("test credit unknown index", test_credit_unknown_index);
        ("test spend", test_spend_valid);
        ("test spend without required balance", test_spend_without_balance);
      ]
end

let tests =
  [tztest "test irmin storage" `Quick @@ wrap_test test_irmin_storage]
  @ Test_Address_index.tests @ Test_Ticket_index.tests
  @ Test_Address_medata.tests @ Test_Ticket_ledger.tests
