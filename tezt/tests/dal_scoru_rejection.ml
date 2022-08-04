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

(* Testing
   -------
   Component: Data-availability layer + SCORU with rejection
   Invocation: dune exec tezt/tests/main.exe -- --file dal_scoru_rejection.ml
   Subject: Integration tests related to the data-availability
            layer and the rejection mechanism with SCORU
*)

(*

    - Assume two slot indices [k1] and [k2]

    - Assume a three slots [s_k1;s_k2]

    - The slots [s_k1] and [s_k2] can be split into [n] segments

    - For each segment [i], there is a proof [p_i] that ensures the
   segment is part of the slot header [sh].

    - For each proof [p_i], we can build a rejection proof to reject a
   commitment. Let's assume that this rejection proof is a function
   [r(level,k,sh,i,p)] where:

      1. [level] is the layer'1 level

      2. k is the slot index refuted

      3. [sh] is the slot header associated with the segment

      4. i is the segment index

      5. p is a proof of the [i]th segment


    We consider the following set of rejections proofs
   R(target_level):

    [R(target_level)={r(l,k,i,s,p) | C}] where C are the following
   conditions:

      1. n \in [target_level-1;target_level;target_level+1] \cup
   [n;n+lag]

      2. k \in [k1;k2]

      3. i \in [0,1,max_segment_index]

      4. [s] is either [sh], the slot header mentioned above, or
   another slot header [sh']

      5. p is the corresponding proof [p_i]


   Scenario family A

     Assume a common setup where:

      1. We have a rollup that subscribed to slot index [k1], and a
   slot header [sh] posted at level [n] corresponding to slot [s_k1].

      2. The slot must be part of the rollup at the target level. This
   target level will be either [n] or [n+lag] depending of the
   technical choice that will be made.

   The set of rejection proofs considered is the one described above
   with the target level being the one decided by step 2.

    Scenario 0 :

    - The rollup behaves as expected and applies the slot [s_k1] for
   the target level. We ensure that all the rejection proofs in R are
   invalid.

    Scenario 1 :

    - The rollup does not apply the slot [s_k1] for the target level.

    - We check that all the rejection proofs r(i,sh,p,target_level)
   are valid and the rollup can be refuted and all the other ones are
   invalid.

    Scenario 2 :

    - The rollup does apply a slot associated to the wrong slot header
   [sh'] for the target level.

    - We check that all the rejection proofs r(i,sh,p,target_level)
   are valid. All the other rejction proofs are invalid.

    Scenario 3 :

    - The rollup does apply a slot [s'] which is similar to slot [s]
   with commitment [sh] except for the segments
   [0;i;max_segment_index].with [0 < i < max_segment_index].

    - We check that only the rejection proofs r(j,sh,p,target_level)
   are valid with j \in [0;i;max_segment_index]. All the other
   rejection proofs are invalid.

   Scenario family B

   We adapt the scenario family A where the rollup subscribed to slot
   indicies [k1] and [k2].

   Scenario family C

   We adapt the scenario family A where the rollup did not subscribe to
   any slot.
*)

let test_scoru_slot_inbox_refutation =
  Protocol.register_test
    ~__FILE__
    ~title:"Ensure the slot inbox refutation game works as expected"
    ~tags:["dal"; "scoru"; "refutation"]
  @@ fun protocol ->
  Rollup.Dal.setup ~dal_enable:true ~protocol
  @@ fun parameters cryptobox node client ->
  let account_index = ref 0 in
  let next_source () =
    (* the activator is at index 0. *)
    let bootstrap_accounts = List.tl Constant.all_secret_keys in
    let n = List.length bootstrap_accounts in
    let source_index = !account_index in
    account_index := (!account_index + 1) mod n ;
    List.nth bootstrap_accounts source_index
  in
  let publish_slot ~index ~message =
    let source = next_source () in
    let level = Node.get_level node in
    let header =
      Rollup.Dal.Commitment.dummy_commitment parameters cryptobox message
    in
    Operation.Manager.(
      inject
        [
          make ~source ~fee:2_000
          @@ dal_publish_slot_header ~index ~level ~header;
        ]
        client)
  in
  let originate_sc_rollup () =
    let src = next_source () in
    Client.Sc_rollup.originate
      ~burn_cap:Tez.(of_int 9999999)
      ~src:src.public_key_hash
      ~kind:"arith"
      ~boot_sector:""
      ~parameters_ty:"unit"
      client
  in
  let subscribe_rollup_to_slot ~slot_index rollup =
    let source = next_source () in
    Operation.Manager.(
      inject
        [make ~source @@ sc_rollup_dal_slot_subscribe ~rollup ~slot_index]
        client)
  in
  let* rollup_a = originate_sc_rollup () in
  let* rollup_b = originate_sc_rollup () in
  let* _rollup_c = originate_sc_rollup () in
  let* () = Client.bake_for_and_wait client in
  let k1 = 2 in
  let k2 = 5 in
  let* _oph_sb_a_k1 = subscribe_rollup_to_slot ~slot_index:k1 rollup_a in
  let* _oph_sb_b_k1 = subscribe_rollup_to_slot ~slot_index:k1 rollup_b in
  let* _oph_sb_b_k2 = subscribe_rollup_to_slot ~slot_index:k2 rollup_b in
  (* FIXME: check inclusion of operations. *)
  let* () = Client.bake_for_and_wait client in
  let* _oph_slot_header_c = publish_slot ~index:k1 ~message:"c" in
  let* _oph_slot_header_c = publish_slot ~index:k2 ~message:"d" in
  (* FIXME: check inclusion of operations. *)
  unit

let register ~protocols = test_scoru_slot_inbox_refutation protocols
