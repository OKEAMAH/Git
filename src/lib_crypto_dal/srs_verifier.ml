(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2024 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Kzg.Bls

module Parameters_bounds_for_tests = struct
  (* The following bounds are chosen to fit the invariants of [ensure_validity] *)

  (* The maximum value for the slot size is chosen to trigger
     cases where some domain sizes for the FFT are not powers
     of two.*)
  let max_slot_size_log2 = 13

  let max_redundancy_factor_log2 = 4

  (* The difference between slot size & page size ; also the minimal bound of
     the number of shards.
     To keep shard length < max_polynomial_length, we need to set nb_shard
     strictly greater (-> +1) than redundancy_factor *)
  let size_offset_log2 = max_redundancy_factor_log2 + 1

  (* The pages must be strictly smaller than the slot, and the difference of
     their length must be greater than the number of shards. *)
  let max_page_size_log2 = max_slot_size_log2 - size_offset_log2

  let max_srs_size = 1 lsl 16

  let max_verifier_srs_size = 1 lsl 8

  (* The set of parameters maximizing the SRS length, and which
     is in the codomain of [generate_parameters]. *)
  let max_parameters : Dal_config.parameters =
    {
      (* The +1 is here to ensure that the SRS will be large enough for the
         erasure polynomial *)
      slot_size = 1 lsl max_slot_size_log2;
      page_size = 1 lsl max_page_size_log2;
      redundancy_factor = 1 lsl max_redundancy_factor_log2;
      number_of_shards = 1;
    }
end

(* Number of bytes fitting in a Scalar.t. Since scalars are integer modulo
   r~2^255, we restrict ourselves to 248-bit integers (31 bytes). *)
let scalar_bytes_amount = Scalar.size_in_bytes - 1

(* The page size is a power of two and thus not a multiple of [scalar_bytes_amount],
   hence the + 1 to account for the remainder of the division. *)
let page_length ~page_size = Int.div page_size scalar_bytes_amount + 1

(* for a given [size] (in bytes), return the length of the corresponding
   domain *)
let domain_length ~size =
  let length = page_length ~page_size:size in
  let length_domain, _, _ = Kzg.Utils.FFT.select_fft_domain length in
  length_domain

(* [slot_as_polynomial_length ~slot_size ~page_size] returns the length of the
   polynomial of maximal degree representing a slot of size [slot_size] with
   [slot_size / page_size] pages. The returned length thus depends on the number
   of pages. *)
let slot_as_polynomial_length ~slot_size ~page_size =
  let page_length_domain = domain_length ~size:page_size in
  slot_size / page_size * page_length_domain

module For_tests = struct
  let fake_srs_seed =
    Scalar.of_string
      "20812168509434597367146703229805575690060615791308155437936410982393987532344"

  let fake_srs ?(size = Parameters_bounds_for_tests.max_srs_size) () =
    Srs_g1.generate_insecure size fake_srs_seed

  let get_srs1 i = G1.mul G1.one (Scalar.pow fake_srs_seed (Z.of_int i))

  let get_srs2 i = G2.mul G2.one (Scalar.pow fake_srs_seed (Z.of_int i))

  let get_verifier_srs2 ~max_polynomial_length ~page_length_domain ~shard_length
      =
    let srs_g2_shards = get_srs2 shard_length in
    let srs_g2_pages = get_srs2 page_length_domain in
    let srs_g2_commitment =
      let max_allowed_committed_poly_degree = max_polynomial_length - 1 in
      let max_committable_degree =
        Parameters_bounds_for_tests.max_srs_size - 1
      in
      let offset_monomial_degree =
        max_committable_degree - max_allowed_committed_poly_degree
      in
      get_srs2 offset_monomial_degree
    in
    (srs_g2_shards, srs_g2_pages, srs_g2_commitment)
end

(* Bounds (in log₂)
   1 <= redundancy<= 4
   7 <= page size + (redundancy + 1) <= slot size <= 20
   5 <= page size <= slot size - (redundancy + 1) <= 18 - 5 = 13
   2 <= redundancy + 1 <= nb shards <= slot size - page size <= 15
   we call range the number of logs to go through
   we call offset the index to start (included)
*)
type range = {
  redundancy_range : int;
  redundancy_offset : int;
  slot_range : int;
  slot_offset : int;
  page_range : int;
  page_offset : int;
}

let small_params_for_tests =
  {
    redundancy_range = 4;
    redundancy_offset = 1;
    slot_range = 6;
    slot_offset = 8;
    page_range = 3;
    page_offset = 5;
  }

let generate_poly_lengths p =
  let page_srs =
    let values =
      List.init p.page_range (fun i ->
          domain_length ~size:(1 lsl (i + p.page_offset)))
    in
    values
  in
  let commitment_srs =
    List.init p.slot_range (fun slot_size ->
        let slot_size = slot_size + p.slot_offset in
        List.init p.redundancy_range (fun redundancy ->
            let redundancy = redundancy + p.redundancy_offset in
            let page_range =
              max 0 (slot_size - (redundancy + 1) - p.page_offset + 1)
            in
            List.init page_range (fun page_size ->
                let page_size = page_size + p.page_offset in
                Parameters_bounds_for_tests.max_srs_size
                - slot_as_polynomial_length
                    ~page_size:(1 lsl page_size)
                    ~slot_size:(1 lsl slot_size))))
    |> List.concat |> List.concat
  in
  let shard_srs =
    List.init p.slot_range (fun slot_size ->
        let slot_size = slot_size + p.slot_offset in
        List.init p.redundancy_range (fun redundancy ->
            let redundancy = redundancy + p.redundancy_offset in
            let page_range =
              max 0 (slot_size - (redundancy + 1) - p.page_offset + 1)
            in
            List.init page_range (fun page_size ->
                let page_size = page_size + p.page_offset in
                let shard_range = max 0 (slot_size - page_size + 1) in
                let shard_offset = redundancy + 1 in
                List.init shard_range (fun nb_shards ->
                    let nb_shards = nb_shards + shard_offset in
                    redundancy
                    * slot_as_polynomial_length
                        ~page_size:(1 lsl page_size)
                        ~slot_size:(1 lsl slot_size)
                    / nb_shards))))
    |> List.concat |> List.concat |> List.concat
  in
  List.sort_uniq Int.compare (page_srs @ commitment_srs @ shard_srs)

let print_verifier_srs srs_g1 srs_g2 =
  let srs2 =
    List.map
      (fun i ->
        let g2 =
          Srs_g2.get srs_g2 i |> G2.to_compressed_bytes |> Hex.of_bytes
          |> Hex.show
        in
        Printf.sprintf "(%d, \"%s\")" i g2)
      (generate_poly_lengths small_params_for_tests)
  in
  let srs1 =
    List.init (1 lsl 8) (fun i ->
        Printf.sprintf
          "\"%s\""
          (Srs_g1.get srs_g1 i |> G1.to_compressed_bytes |> Hex.of_bytes
         |> Hex.show))
  in
  Printf.printf
    "\n\nlet srs_g1 = [|\n  %s\n|] |> read_srs_g1"
    (String.concat " ;\n  " @@ srs1) ;
  Printf.printf
    "\n\nlet srs_g2 = [\n  %s\n] |> read_srs_g2"
    (String.concat " ;\n  " @@ srs2)

let read_srs_g1 srs1 =
  let srs1 =
    Array.map
      (fun s -> Hex.to_bytes_exn (`Hex s) |> G1.of_compressed_bytes_exn)
      srs1
  in
  Srs_g1.of_array srs1

let read_srs_g2 srs2 =
  List.map
    (fun (i, s) -> (i, Hex.to_bytes_exn (`Hex s) |> G2.of_compressed_bytes_exn))
    srs2

let get_srs1 = Srs_g1.get

let get_srs2 list i = List.assoc i list

(* small SRS for tests *)
let srs_g1 =
  [|
    "97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
    "b4538616de1b71aec49f4da1c91fefe2a62decbefa1f5720b3f34923c216f4bec0284444edf8f7d2b032cab51d9191fe";
    "b570914b681eb126f1628699fc6565cbd8f906ee8a2510756ae011a2a552941f9bef205baa7c306e7d0e92d985089ab4";
    "84d9eda376013bee3b579a8494804782bc45f809ab67a7f9f093c8389be8af1a5e6257981aca3cc1321636829b0bd463";
    "86e38bdf3c7c76e88a74e10382525f82a326ca830d1dad05e0e8e36aa820cd3b65d96749003aae4c7676b53abbf7c7ff";
    "accbe0bc2580e4a7828189025c88fc2dbc1175b38f76080c8fce7513a97691969e146a89b51ed116df83ca1dacb17c43";
    "99ffa94b41c4a52e4f23554d06fcf246bfb0239db25f459ef68f8a22bc4384825c48c025bf43b2d360a4d5043f488999";
    "a0d524d1975c0bbf7ce9ceb376194e8f722e634e8b04e3330b2fcd5400f028392e0e03b959e76cc68a67125eb1904b91";
    "8390af57fe5bab9727d2c9bd8843f26a64d2f2f35780caef1218a04f0801e9f82abd8b69483b5944b215094f2738b5cf";
    "8ff30e0b6c67c473f05313018f490ba47d23fb09cb62e26f516e62f4567dcf265841f21febc8b48a104bee4e98e47934";
    "90053958303964e179f28571661eaa16a7be4162fcb6bd8096c6f03b33a3954ba48312646a8ad997cc4fd296f94a0ce3";
    "b225c3e28a6366fe8a1505ba5572db2163d9d5f739c4489beec39896c8b8c5508dbc115515d92938998f36304da5076c";
    "ac13b1ac1e0637338d352a637d60e8e6b2bec3007857a3b64b962077e2f5bb70f48eeef6c016cce8484026655efcfac0";
    "90ea9a970b44d90fd8d09ad19529625a272581710910e84044e5cca86c0900e480ef7bd910f06407bd06d13cf73ac184";
    "8e52221a1562eb77f7cc7b068d5eb1102efe9a1d49d1642c99395245e9af5a1f303c715e3811b4b5c4284244e92f47d6";
    "866e1a2a8ff94967bedd98b6390454d33946af079d6b80d2abb1b9d6c1e8c14ceb6154a0f62d12c30e6c65922d7eb668";
    "9886a7cf2d8525b8ada2668ca1f88652d9def40a1886e22b308efeca64a088611dd8bcd7dcecd0042902350fb74dfbda";
    "8f81f9c1cd4f6d63e5a5924bb8909b01b8974d0dae471f5f829d2ce979ef918c8b092141b966caf6f0676e16c72d9b24";
    "a4c759f7f8231f327bb201a2ce6a40bf53d4ec810092804bfce57910d32ff525eb226d704d1148667c4f679d6fefb6c9";
    "a3a3b5e0f68075d12876450c79826a5a18350b513ae4be9ab43b43c46240ac1d1ee489faacef604234fc4bc55e43cf72";
    "91e51900583e0bb41b21329c08af96df27099fafcfda0e0bbe4b69c697b1b25853954379b59e395c8d07c44315a250e2";
    "ae39274695260205e4f5aa0f6c262861d2146e2f25a701f8ad65afe72825a8a026c66f396e26560a478bae920f0c126e";
    "ac05bc0b811eae214615fe44b1b7ed055005f03f4162b2071a91ce5795fc70d8a232dbfac53655d726d1d57ebeccffb2";
    "8ad29894542db2e14ea6786d09b6745463f35402019308f0d5ded50681b402fdd67eae261fc506a1d8cb7c0a29eac0b8";
    "94dda63a7a8bd5941976f2617e58d3fc12a5ff9ee2bed7326883edf1c284c9121f9553a6524221f84f436e6e6f3d8ed2";
    "a2421967de32a71e26fcf444f4f7ad95a0973b139a96aabe891aedc2df1ac5fd47e485a4a7ee8b77dbfd8a269f64ecee";
    "b80894f8a4741255297825424e285ee6ebb24cdb013cc1ec9957a5a560e7d179f1551a0558b1c2b11a662b335d1d5356";
    "ac66710e108b857b1ef02e215fbae97f0361f647286f9284e035a079bb132447bda2368586b906691f09e998fd94e62f";
    "85a8a4b75e70e176fb92c8a374775766a185cd71953f179beb1bb70586be97107bd28ccde9cb1f115b7f8196771783e9";
    "b038ad4826100fae51a725988f469145d3dcbda659268bae718e9187d57598f773e708e17fcf56f1058a5626f285900b";
    "942ad6d145889d0975be1326ac3700679f44daa4252a70f0d3283563c7ebf890357b6541b0e84b40eaed68c52a91292c";
    "8816b7ce13771e4837095fa7e1f6762e16a5909eee48a20e0e9a263a6b3cb28b11799966f43fe14cdf986dda1f8d176b";
    "b0cd6db8194cdb95bbfd0858d03de9bfa8f8351e2680ea0ca5fc38bd8a4c71cb06797464497249b090d79087375b7565";
    "857765b3bbd7e94c7e0ba366619c07fbefc80d2f5e4eaadc09a913710eab37d65c19fffec7fb8e4b3eb41006ac07544b";
    "b52540d6d99b932def816b21c53e522f576e9050908fc6d081521102d9bb14255d42ba0886631c25c73fc13e5e7cb581";
    "8e9476fe535f727b8cf773d2eda16eeb6fdd00aecc05ec16b65fd9ff370e3f144b771ccfa5d71048d7fa215b407f43eb";
    "855a3652276747bd5fd2b2ed79c3e0ef4a14f3488241dcbf494e1b6ea41149288eeb82f78774b4729f69c48f1890d99f";
    "addedd3c25187a634bb69a240ac501b77f85d46764a3351169c1dd73123aca52c2c75d29e97383c11b38cabb2722da0a";
    "91c65314417f48813945b6289e71b03857ec978bd218ccf93eb89bea8dc9e4ef928ce208cd979ce49be46862607e372d";
    "81ad4617776a5129fb13668355c86a6790b8e44fd27dd36526947a8cfa8b8c5b121be5efb657eba430bd373a5fd39062";
    "8bed644fba1df8ee5bb137ccf16a4aadbdc3523a227adc2c064309efd6f0cc44666295f3b8a81002ada28d40125e3684";
    "8f57cc58ec9abbfad4bd0c1f16bebc1c788fe1671d457201d9ff63b716da356184ca6174f0a28906921cfda36078e361";
    "a6bbf4f39000a16138819cb9c6f290cd26cbfacc07fc65f3032486c302ea022e886ed824e4457ffb2d67f40e261f1f94";
    "b76e7339c87c2638857b18cc91920efd7c6a8a4c6240ba9e4b908355e60e59fafd65901f6bffac743b6c0f21567dd959";
    "b35f5eacefec65a1d4460d7402671f76d4721e8d70f6a7489babdadf5dcfccf617faa4060826175d5714e82bb5f319a0";
    "ae7f84e2ad04ae1127136c5ee5b4bfdcc5b10c4c02476b8c46b194625b893a664ce4f17f6097dceaf6a2b2c2664872e4";
    "8eab970717d727a430e08f9f0a7785f1d03331b4942765e7987f4341bb34fe62e7e644587264e1f12921de62c0eaff33";
    "97b545fd9e7516c4c224ee402005e285fd26b909f2782aa6178a784abb7191cc8b1f9002705329f9c7fd1558d8a6f2f1";
    "8e284c0ca58091b0d5ca374f9b9d2409447a16c16a71539822f6db9fc2f19213eda1ebddd2bf4763339466ab068fb6d4";
    "8210ca465e95f0e2412cfd55283c4e1993098add9acf084c2e9be922104e6d1c6c6da8d919a6ff624431f6dff040def1";
    "854870aa15072d1bd6557158af961ea6f46fcd2a84d2328da78248321dd0c64f1c5ced117ada04383ea725408fa7f1ad";
    "aa7f23a265c6653f24aaa85c7e156174fe11bc10439aada7f6b6076021d73cf6c1bf216c7604a549763c2a98718efc42";
    "97704b58df416af5c5dcf05d0b88232f20edb7871ed1440334d20fb5b0d47f57acc6610128ab83e6ec9522d87796cd51";
    "9844da0856b08a255d2e18b58a91285fd861b66bdb7e8b641d9b0f5e04a41831ad2b1bbd6adafe4e2a0a22bee59f7ba7";
    "8388518dcf3031bceee11f535678cd0726d083ea933d48969a97b119c24b1e60371bc4bd1f1fd5f61c79b735a87942ec";
    "ae2ac001b428c0b8ce69b16613b03efcd5d848df9ff5260e0e96f4ab2492a83ee989e5da399265bde937310559eaaac1";
    "b2d16337882a19a509dc444f3659d151869d680c5b1c692a0840874fbf620ba430080feab7acde39906da65b319113f2";
    "8a878290c6cf5359fd7674ce370d04ec3bb16ca2edc967acfa1a1835618e8cde20bf78f8fdb4f1c057881eb19f83d33b";
    "a1f5b56093145e8bcdffc9a2ca6b636dcfe0cfde9b307ef1317ed78c9693ac44c8fd998a49eb18db5bb3f897f17b4ce6";
    "94d901711f5156629e8c7f8a9702c4d91395a167f50e4222e6b708757a3603f2c28427b5cc8fbb5fd162cbbe15536af0";
    "8e81e3c36f624f6283a992362a076a28d923ffd8839243187dae4c39b5345db706fdf23d626aef04f01495b094f9acb6";
    "a53a30dc0a6210bd4721510d1d994e016761d4d377ed433074d2a76eaf37eca7a923f149ea405d5fface322cdf11ccd3";
    "b55538e6c65eb4197e6a5d344d2b4bafcd1df92bc3561bf7443be1bae66f1e7324a6e820642be784313aa25a7e1ceb40";
    "91a3a65fbcec97fcfb36f3ced63ffcc575a97d990838b4e88194e16776cf0cd0904b5da09bdae8ce8ccde000b0844c65";
    "b6008e8c29083c04824e7634c406b8c68f6bb38bf69386b5fd3ef77f24dc77f138de5d8d494769fd3f75f470b6de7b79";
    "adb70dfbc8617aeee56d7484de3ac8f8476ee3a5d711315d7f4c8939c7961831c8c3cf51278dc8ea5c89ee239a63bc3d";
    "ab5d181fcdd1d3994217f6e25fb2768ff0a126a3e7c92aa22387acb12517f9db11178765c168c4e4e29a550e4cb72e1c";
    "92daec00f0adfbb32555f1ec6143b3c9f3da7bc93fa1806a917414c8ac80f34de017a00dfa51c54be09dfddf02c32d39";
    "83622ee0ad0247a071ae6268a973cfc51b5dd4855ebfdf189ca80c69d12d2120a7fd117e4ee598ea9e5dcff9e3633ab4";
    "9695c346839c770d1307aa4e322019ed14ddd9756c13166cc767dc3879997f6fe3798f051e57817f728a05c3e4331bb1";
    "b144efa4101814740c263b903772d39175c0818d87e0919eec6438de5069f30f95154c8fd89bab37e704f065dd6f97c7";
    "941055f756504f7c8975f15cf43abcd389da4fd3aa905d681a83a8a799a5d594717ea18dfc21f89a71471871583fde5a";
    "a5da0f665e599f97821f3e123c3f26bfe7019dd716a90334c696b040a3f0434b80635a8f65421cbcc4be2275c38d7abd";
    "af764d2e08c7962acafd0584570d73fe6651de5d2c26e70b9c78e577feaa54a0f5cfa3eaf17aad32868d249cd69f2461";
    "abdafe812f51dd84aeac3416793b22a04bac9912438fcc1b3b94a369b67f16f3f87144378d65293f933e99e83dc1fd1e";
    "b937e0cadcd79e993968f2f98b068cbb5a144a1f1302976f5cbb222f09a99706f94e922dfd032e1e9f8f5c4dd415547b";
    "82c53b2c7d4c587b071b9f73e7b924ea5c90b3b910e00bc84d8d5fd39bd49e6bd36e9343dd0f1c495131b5cbadadb537";
    "a9061457686a2bbae5ccd01862f52ae6c1dcac607c30fdbe08fa43d506ef51b0f0aa5b639cafb36b4c26a7bced2b8839";
    "8ee54af32903ce722954e968aaa661966d73b10a808dde26de3477089f607041f8a9365033919c83e41f165ca7bf4882";
    "8ef9b79d3e4f73272badd7fffe2c8cde38154bef6d56a0155e5c61d462445e44b323636bd5649f35e1e6aef1aabccead";
    "b5b7185e06118f254f272ccf92f7439385a65b7d8fea0a748b8441da1b186eff8ce8ac026b785914cdeba16666383448";
    "b6e3e8f3dda4ec88d3ab5f5d94532476fde55c141a545894836a8e9b003860b9ed3c232b0ca5fae1dd00028edf458abc";
    "a83ff56e7eaa984509e151125fd995cfa4e961207f120cbfd72cc05a6081521a4687234ec9909e77d2458352d7b69919";
    "99f37b025cc52748c6d026fefe01db3fb7ffa16e795b8c94fc51552cf89e7036643f0d1db62530334374b1acaca87c44";
    "859ec59d1af4f24ad6cc965f4730866894ba0f3d348b1b7bdbb714115b880e8dee9f060f21375323267b8eadd9374e3b";
    "87063e290204f63801a2ab45fd8aff4a590d8ec56bedb4bf8496a74912efb19b224302ceaae4a3dab9fed30001ac5943";
    "85d7339a66992ba6a5ca333a1b134ab05f37e610f024e27585a00bcbda7eb64766389eaf91525181660e8311227b405a";
    "ab679966aa92a2c9c2bf66a5c52e8f1d3dee0361c63a8f91df594a4d48d7e6731410d27a3bef1073de9f001706b029cf";
    "b791db39a3522c71e1b2ab77423c88d94ee3bec3b88347a242347371ccd49d5585823be5247a40a669612ccfb77c790e";
    "8965b46d4b31c6d779ee031504c8dfb95fe209e72ddefc7caeef6ad4362529f3a459364c0817db51f9c34e59d386a390";
    "a9aedff8bbb41943c52c2c5f4a75489f3141ae7513df6e0ce6e831a4761431a46594adb3191db18714b0e30a69253a50";
    "8ecf05bc7a65101372b8be68eb5f7f7cc449707fe6f5194d1492443601e5a458e577fa17056f02295a4be8340d81fc02";
    "906602b3727eb065d977da63c4d39adfb81679293bfb86eebfa153185ef050501eea1b215d753c1ec63349b840eaa10f";
    "a1508e65bd4de0f24d2063acfc7c32bfe3b0fe83cd7302feddac9b5c773bbcd237b1d638e348592c7f1e29a9ddcb6211";
    "9853425ba5ad822719f9f89404a73f0154499702096047205782a54b3c7fd8487e4c041a26e128beac5ed0a9203fb567";
    "a0d2b1ab60a7270d5ace0e89fb2670f5d3dabb4641b7a9ee10a52a739309949cc316ab63c7df8965c03c94e82ff97bae";
    "b0627eb3a41d78d8877b9db036fe652e6c6a6c3a1af77a2dd8a4e27bf8742e35ea06b6cd11a2d73b45ecacdf7c1a8de1";
    "8e992eecbec38fb108920ed194a802f3f117704454b85bb0a2d853aef861996c5aedf8edf2e409f5bfc1260daf4b1597";
    "9644bcc564ab585a4a3f737ff6943ac25afb14fb109276e126c0c8bf281432d9e6088661ec77387584691eecc9b2aafa";
    "a0a9dc9dd1eea5042e36e30e1981b269510f080fa5a2b1d2987d5b3ef48e1f6310928d1b0ec42377ce861cdd72e1ae84";
    "8a21db80e999ee35934a4e19c71a256f84ac593d7afa4ca0cdac83d646448449fc09fd074a2aae956e0f40799eafc8ee";
    "83ec89e9b0a8aa2ecd327529ebf970fd66472074711cbe11a66f165f7413704c5d4739b7b462bda77c103def1bf703de";
    "8f84092407068855b26832c1784671e08f9dd54d20c3efd3a9c8a2b0bc67f903675d73626bd861f127e9b6f5eadbece4";
    "ae078ee46174ec30b45f31fa6b7c5bda61edea15e6f0f1ec4c3fd72fbdc77bdc2ddab93ffda7285139e76ce2734798c9";
    "b761d4fe291a198dcd19fb7f6320e84e1b30fa972d7b4ef1157893a0f25885a48410eb82c5ea251be7483d956fe292be";
    "a2f750c41af13773fefa8d67eee13813252532d937d4b8d1f8981a56cd9362842f75a947fc0cfcc02e1acc1ab96323ed";
    "a09b29632ec385537cdfbc095800aeb3acc81b48e03cbac15391e79a30401d19b5b29963b6ebfdbd157168434cb32c2c";
    "8a151cbbf8e810a55cc94604e746ed601ce23390c39b76c89fcac7f3b76010769522040d80bfc0cce5de0ea55a34807a";
    "98c9b7fc6266423595fd93a51029d48ddae9a8b689384e19f1873afceb348b10d0278e7113eae047a34217a61ce08598";
    "963cf8236db802324f38864a14da508438caf3605c07c972621c4308f120df07f25c7653fa9b6f5a3f55280c9ac2e48d";
    "91e89ab4d2facfba7585a3e4c13f89a0bac484bcd5fa78c18990ee262f1a96ee3e9a2d7d2bcef2f737f4bf95a69e91fc";
    "b8d603a46dc68d665b8dad733f26861eb665b39df2204a02906bf1c3a89f18d3305c4ed220565d2e9a35d4c086805655";
    "aeff239491d6054ba81b78e8731adca676223f66c54ef9bd568c18c07c2e9e6094ed721a05c2b2f14a196154ca6d8174";
    "833c595f7c0b17400c3137d39a63fbe58251f2d19f557e1396399d31e5a0844330eb1d9c8f965654618e984a9893c9f1";
    "8e2ee16bc5d8aae5acb6b56c8d6a5cbff72f09cd35771933b000371e52f78a1ebe8c5e3b9956b678c421cecf4e4bdab2";
    "a4880c88e276938f6a5c2e22f9d8e6e430cf7295a2a7cbf8ba754084e93fadbd6df1341da5676f3549377171c12bfcf6";
    "98ead4d15bdba404932195752de5fbb06bd987f93ebe4594abcac83119ad726c2b98aa7db309b2675cce3b22e8c777d6";
    "b641be388e98dc9dcce1f154081d930748548ec76f299a8ec723e8d6153e0c2b2b37c76d4191121d6a3116ea1e2d91ec";
    "845802fb883c6384095826353367bdb6df7a89645c7a0c4fa58040f9f86f6f9edb51d1faf336b7170e2393774ff16038";
    "83d78b53d43d3f85a80ba4ce4912aa6d3825c88d8cd2767b2fa3b1fb70ac54794c3b8ab408803b48310178c17a462888";
    "b3667253350a06ca351643cf6d4b8ad57b9e067a22695412ad7930937fd4885ef99d0181899cca051d63b0dcf9b64f32";
    "a3b3904fc7de73326aab7646512fdded09686677295e8d3f3e66634728e286325e8da83291495eff5cb98b7289277d6b";
    "9745e039666ea24093759fbf5f4559ca3467d4339980d07dae1e5a3d88c829086dbf858af2798cfe5c7d7b4ccaab702e";
    "a96f11bc9ec9a1926fd15a87a5719ab007aecbe30cafedc6080e140d0b76b3abc00a4bde6287fcc056f9d77d65a8819f";
    "90e3ad5d8823464a4af298836aa4675afebdcee559a27bac441da4aa8aa9e0287c728b2c9702a085ff5bf3bfcdb81b3d";
    "b08678dd6f83c2ddbee4f1e9d63a1c2f68f20a29a9f6b6452f8750ac6f800b33b81f5fcbb4e41c5ab0db88a016d4267f";
    "8e549745a393c81cc756dbd8baad0f14e5dbfc64936fe079ca7b428d0c9326b15548f395b8da1816d4aabe4e4aff506b";
    "8fe297185a941284738b997f56def771955850166d176eb0d3c9d3db8b398818bc096bf920f96a76fe9495c8331a545e";
    "b7ed82820d31946080e5d97c725cac5df378c5fca8d9266f753d7e398a9dc6ac299f2e26dc130dacaccbd14806baceef";
    "a2ab63bedcb95b26dd1439198f97365a4059c41a4dcf0c34b8cd15bc123b08247f999a25ae6e038cc7732f935c9686b5";
    "a59b16b05ab49b0b8d698f4ffd704eddef52b5950e893d1d8433efc24a6ed86297d4eb9f6692fcd45cb0c5b32de94c18";
    "b7cc3a3fdd36e057511aafa9b73547238dbfdbe62f5197b07c301229ccb800e3e619b6940aeb3fc38dc8e03d14490985";
    "8a924530f1836ab8ee4aaf3bf79f750d97976198bfaf30d29f96efbe9fc0b34933d5241f008f6ec9931281bae8b785db";
    "a1a622c7ecfbcbc3e28a979092810d39e68bb9b1739d18d025a93836dd8a4347298be6506a12c66575f3cc57546e7e7f";
    "848b261a8994470ebadcb7d3af9068f1867eb5948f5b278a2d9e9fe87ecb1a15ba6a2e30cba417072982e9b048cb8d10";
    "a54841879b6ad25e565b4261f66bae5840dfb601b75fd833d1d0f0bb6c22c07f6dea61364ba08d6b9888c0fd90ca7e93";
    "af7b11a367b729d7ad197ea6acb466e4abc19e4f588912f379061afcec8dd86686291d59cbbe654e57a13c11aaffe5f2";
    "a01624c7d4177f26fb37c49b0e882e42e15cb09cdc46306fa0f86fd43869da1ce20559d27235c975031aa3a318620c3c";
    "84fd9f4052a6101bc265e4b8b08f844dd3cbe1f4f058f4a1fcc9f085f71ee3ee1a7238fa2d1d144fd0108269f8b2f91d";
    "83b8a14e92bb6318e85df23080a01de2e2d39726e7d40e358f16f347842eca59f62b4dd57a00da5f05e20fe1a93d1942";
    "9237788940dfcba77f08a84e6bc59f9ae79f6854ace43ae3d4672b40cb4e04dbd614ee067c93a7516925be9346b3e11f";
    "8ffaa28549424c92f497081445a62a7c4019b20ba9c9e317eed1d6b7781799f33eaaae24875a2447914f769c5dcfa528";
    "a88708152720992e9c56b8f1d2e0a23d8e0c6e4a37c2c6e8512b87b10ddbf36bb4e329d5bd27811572c5d538eb2da089";
    "826de6a847ef6ab5a46d644d65a7c9906f36e9031df27726576ae5e5d06fce86c4d32ef3bba4afeb4d0c7e20caf21461";
    "80f337779a19a299fd69f414ca5162bbdbfccfdebbb4ca2b03e71d57cd247cee04d94c72afb11f367c30f75fb5376505";
    "8c018470892a37c438448954404b70947b716d78d0d329ca979f99f1d4e7825f9c18192714fa9057f8e26be1167b39bf";
    "a46d89a2b6aadac22ca01a9e624baca56b2a9e612a54057327eca5014facc3c6d2720544a5aefb6f37dba3e612e60d01";
    "92b26a97b5d10de300bec381e54866ff70d69d88ac101485a2f44d85b29f848baf309bbf48b759ce87e1b9e04a811868";
    "a57dc12d6471f23a6e6a27e482d53ea320633259641430ea19e345420e61b8533ae8d0a650d9089a4de06bc0610fc646";
    "ab1e5ad78d1ee5d0d470cfa8f127209f1bcd9cf403807e780abf7860bdbd95ce0658f12160f87d2d35384a2be25fa5d7";
    "a718db2d439d38542f76402cb9a8baeef04e40be18174a1b1f34731a715badfcc7c313c9f6ce8008241abf6a22f2fd2b";
    "b1387be64e2a36b3df637c679b8825f4c0b85dab3ae7edb6061d6644a24826a91fc289a42a1f2258540334ae2ef0dc42";
    "8a689593904e86ae811ddef042cc4230e99a5d36823f92841799d7b36450ed4c3ac5d6e68af240f0b110be0d6dee1c31";
    "85faf3140f257c4b55468baa880a21070a8b8db1b4fd313260228dc554ad48d55ab0e0beb54a4848cec025b777ded9e7";
    "a9407a4edd4f9575c6608810881be3c531dab7140cc3173cd0450709573db9b8f4153a1e0c9cc1f14d9a5de95c0ff8a5";
    "96ac1154cbeba5ac31b7e455b6bf48402f6034856329a159ee9bec721da860ed66c4a532a3f31c8b7975e06abb9b31bc";
    "91edf7d4ac8aa9a763caac52ffcbb12c574d9ce215570227e061e9698d5ed1a62686167ad0dbc23e791da2ab6b45d4a3";
    "95541194eab3bddb8828fd4c6a74e19d70dd4ceaba5dcd064fb3cf8b49e340e0bcde21376ab2f9c457149dfefa3b9687";
    "a23174ca043d8988264065453824cf04312c5a5ec3eb238c348b93271c1d8f8c9adcb5ebe1f42f5adc488a9e55097700";
    "835f266528b52cb8987aa5d80a995e97a08add036b78971c100fd111ad418bfbf81af59698d1ed304a7f9191d6b658c7";
    "89c27fc38e7b5bcbae20d026452eb47bc86693e01e6b6773894f1969032feebc170010203dfa13f85239479f1438cc62";
    "a3e8c2c35e3eaf1d9faa736e975fe389647b1c2c77daf5a4c5ea26d39865184ecc316ea218e10fa3042718d88f63555c";
    "a3f6133b298f3f04469482921e56c834811093c5a28bd58d23fb6844ae11294a9b6aeb7da6e5e7203b17a4f594c10775";
    "96fe30ddb24c25e702f716c011b4e899e574ca6a9226ce4f61c255b7eca10b867b429fff0984fd90ee9a72d33e661a53";
    "8b1803bb83859021e451a023f3b5f2c65305e2b482e54a8d5755257fa02f6fc1f133cf693bb231bca14149b9dd7e2571";
    "b65da362a10ba73d2ade7d2db7662ebb0ed49003656f46366b94e04275c76e523d006441d6adc36a161272d9bb6ac66b";
    "8997ebc54f2a6341e782c7ad52b5fa043ee1f62a828e11de0aa6e57c428f9540f0c8b3a40e56634936f2fdbcde7887f1";
    "89f1a00f1102ab9c8d962c7fa197113056be0198200df4ccfe15d69bd18bbfe528f27af92bb73566636093a7451697e2";
    "98afcc0ccb023ae69b267c9e1ae9f2c7d8def00f5f2bc1f6363c5b7c16c3e566d47ffcd1c4d72c15ca550b912e211451";
    "b8d53407d3693d9ec5d24de28be4d36be5b377f31bf886e01fef0c7291ac9eeb213032e30f43db79abb8505b621b39fb";
    "abcca050e5b3169c6f46b26dfb08e5cbde5d268dedadc114e3cc2cdd17dc5c829e7f57da9d429cf966fdc77edea52073";
    "8f97bba3c61a5deb42e3679441179b3db6e5e7b788e6ac0108c796021cbc6e2fc1144e9578401549041ccd76c7e6bf8d";
    "98a891054cb5fdfe9852245674dedb9be47f92f2fd3b9f9ea1d63f59a3fd3c17e8343bb26579a6b664cfb8fd37db29e7";
    "b68b9164cfec53fb482bf77bbd2b1644810d9aaa00b94abc7d2f18455ae5efa635ca84cdb1218992a026de1fce7246a2";
    "b644cbda121b198e21673daeab6cb5679c6b3c5157b1e0981259524d97e4f5023b9eac5ef0e38ab790e11f63463d61c6";
    "88284a83e7c58a524d329b9c58c00a68d95dba59d928114354de97a1e0e4aa44e44d7d449bb16c2ae6063712f6943606";
    "b42ef5be6694c7935afe161241ad85e79bbb4fe32740d1761904229078d7a2bb63efe1d5683f9f71d013e1803f7c9545";
    "974153a15bf9e95f143223db383872f69136496d5ea2573c79a4a061d8ee394ee9dd7e1fbfdfdc544a5e8c07e9bf2456";
    "94e2781f6c92aede86389e15961c02f85bb0e69e6aa48e31a5fd5b0b1f508802a31c0cbb424f7ed46a253ae6e01ea504";
    "8a59491c72726c0d36af278515ebaef04a0d17e537da21bad6a2ea4e6d4451dc1af00181a9fa1ebe00fbbe4c0333f499";
    "b4463e87b57972079c2304b05f81a29951bad1ee734e18a6d7fba27ecd3b9dbc617c9c9c048cd51d848a40ff0ac445ef";
    "b0e4836093a6eccf7d157144dec5a658caff9b581610bced8c927ed595ee41e0b9d88dcdcdb042676cd62c78c1dd6b02";
    "ae93babb4d9874078c204275f93caa8800edab512bd62fce8de7f24619b7099156b8512ec1365a1a2fa92d7258f9ced5";
    "9739332f612d0df7351187e9e97dc2649eac63a97a61b7654de6e10dadf6021bfcc64095ee284850c8cb112163db5f95";
    "914686a43b4a9f0a22332363f9d00c60e3706523f57641ae75b8c06c24613eda7c8d5354e3e45e02681ef5b48f3cb2b2";
    "b4ba854c0ae23efd5401c26f63611f21d35f5bd3c2bdfa86f879b04e1f07d981369308ee189e534cc619976165904b13";
    "8546deec6aa96edf5bcd177bee8ef6de418c08d9e936e8c3b0a21995a4a29c421c6e245eb2569a336f62215c4b0c2436";
    "b4cf713de484da15afafa170c8bc7aae0bd98d71242489f25df8c07ab53eed3f73907163f8f4a37b24e9aaf2a76ad3e7";
    "997fe931592999479bfd301a59a0251299417bb20d4fd4b3faa0e2d3f864fc837ba31444cfb2a424e1087bff6601d973";
    "b9d9b77ee594c3ffffeb3a075390ba330485de8455fdcac03e643d1fde7cc0aff4940fed91a1f51d34e01dd2d5497485";
    "824869cc4ed960b6d33ca1dc0961f515ee7888b488f7a3288d75b11fcd15075d554a92fc915f63af7564d80abbdb9a1f";
    "9233dc1c9c8615dfd430648f7b14cacd7bf7a6b49619abdba99693809ba417a733b249b706b745148248899d94e352ac";
    "8f8ed41bfa2fd16973b08f208a592a35c3656afb30069600f7420d881d5742bee51a45d7ebda10f5447ce0858329e54a";
    "864effc6ea4c7542044f1aa0d043c7959f6faa8fe60091c10c54dac6f1608abf02aa2ece65d32e9c81b1776cb98faf97";
    "8ba19542eec96b6d1c7de3fed024876929671d1a92e4c4a33f8545240f32be281293309f6a6c058f85f936fa575dc390";
    "a3abfcb3838108a8ff69e11ee5ce3925c5ff89606b8d7c4896f96b1b409bd7358f41d009f1d56703bc85712eacabc6de";
    "b24ce3e7bb8202875bd087dfbad44e0483e069e8382040a9e0bb71721c9f1200c2bedda82af7820d232f090317016560";
    "a8d1248a2f88ec6378f9478ea483fbc3d50b80c2ff55c0c632f5ace62c5809cffc7bf4e0400b321cb1037651b9d989e8";
    "8472b24e3ce46c370f3a556cc3a5b4f8ce48509c9f2eabe25a6cca4c11133dd5f4819a3125ade2b41424757853df1324";
    "a6d8a254142b07dc5349b2b5361d247c387db787697e823367a5f6e0866279db81f8ce6f2f5149282e7ea7a1538b0d2d";
    "b51d45f5c19a539fe61c64018cee1af8ad28a0e3514af223a9a0f08ea5a9f8ae503be0e7d3bde653e90a5091d167605a";
    "a2f8ddc42659cbd71cbc40a0ebd5cb34f3a7f8ec5f40a362b63bcfab4f3dc8c74bc661cee33e191f05bf5922e9d1eef3";
    "82ae0edd6bb928d9a34f89c7c609297c3acb93c3b12adb665f61c7a7b397a2240e4f6805078f30419cf08f5fe952f070";
    "aa20ce58cb29337574aab91b3aac25c0aa1830b6b449f86a7ca55f09f8d0dbf59ec8e41a3c2a23bf05dcccab84c6753c";
    "ab4ad02ae5d2a75d8eb0e134d73abf1505aa08d35c3334053ba094e77d6280d38570d559a10e9a83693ca2baf205a65d";
    "955668fbf42cb204b7749ba2e77cb41b82097eef2b2d84e5df8e97e3e1bf386978ad4b5a91b8b0d4bc2af60af92bd6a7";
    "b304636f9794acd5eea32559df6e5d088017923460beed943b0a7b69819988b84ac0821de91960ced5269f3394f0ff6a";
    "8e1f0202445176ff4f4256dcec49be8703efb4735af230662855103a1e56ef096ef3c7fbdc0360263a8adaf3cfdc55ac";
    "8167f39eb330e9d27be92137eec1ae4aaa2d9b8c444ed60ae5e5b4e47f8783cb4228993f9cb48b2d0ebe6f9333a649ca";
    "91574d1d1706680291b63ba64580868bb980b84557fd4ba5e58d227bf9d70bcf572e87e74418d3037d1de05a2e032c1b";
    "b58eac87d4b1e3fbf7d6c9eb8bdd4300867d8354015113b4617244af1a9969ec6901d62161c83bf9690c0322c28c12c5";
    "85b266324e22244e22b085cf6f8dac54ef768041b8084e8bf2e95c64dfbd41aaaf45273b9bdb1e8b07d459d84e1e222d";
    "b4be8668fa7745e0c311a91e32f6745c29e266349b45a9bdefc1b14fab2b08ffcd636ebf821e12ac3b3ab3d3e71e3eaa";
    "860ea80e007aa4869b7d4771547f3cb8b15f60fea1ce7354d476a133ee70739c91217269b32222953bf2f295e428ad94";
    "b1f02386024944e66b71a165a5b65b869da16e88bd16dcfcb70300120779f7d411ab47cba89027d1614e7b73ca4204c7";
    "983de4d49db70b75c7c2f80ed7b520fe0aa9526a6d531bddd40081cff566dd8324708eac4c072c3c0ae1afc8b23248c2";
    "84488795a53064cbc98b1a4618325bc0dee288dbffa72eb920dc18a65f7784a9644782824abb05faaaded19e52aac1fc";
    "a297ec256beb8b5bb577dc8c894b0c9f42b4db66e1e591d7ee2dbd1951b60b1234a1f81bc202ff5bc7af3918fe918358";
    "8c4c748e40287351111cab8d3db0fa2e3339ff4f4c1d40cfbc37b38dc0c66f80c610ea7f651a95b7e88ff58ea29800f5";
    "b010ed09cfc9487fe8fb426987cbd37091211992dc8f2773942b1f586ab86852235c9c5a104c28cdbf0f8667568508df";
    "b42be1557526a3e4ca33166a70c278cefaafea0d59bc9e8f3d6f16081d54994ec9d1d6e27bb254c8dce499cd54097324";
    "b70a3b2cb0955460270b7a8664086354843d5c8e8c1db6baf2eb705b5b7714e29d35665e713eb8c8f7641ed42ff191b2";
    "94679c0828807ed1a1ad99856f7e12560be4b357017519a876bae51fc2cf276556f5b14a5f82da156ec04393dd278912";
    "accfa51080db6596b8b9b185abb56643305821c637c3f9ab9df79c041149924913220b526c5c30af3d734eee0e2bd456";
    "aa8d62b1616a5c8ff7257c86b3e3c1be5ecad23141f064c75d601d141a6415d2db75caa1dd9fb75b757b61089e9c0f5a";
    "8ffae8921f8725e7fef7d77980da0a4d13690e916c6d881018bb626b0822c516f7851e7afd2d760d7be9697b17864485";
    "b0e263b8ece0622d9f21cd710f88713c72d59be66e4127babf565a3186037284805bf46bd730ef91138688772d7df8ca";
    "a4d5f3c386d5309db0daf206ebf27cddf7c75657d81ac5b8abeb3197df4171fb1cf7e37597cf05bed177fcb9659aefaf";
    "848cd1781408733b87ca6f959a20c4affe5da3382c50ac3583b5bf312039e0904407a2b1b2cbe1491e35812d3fb563b1";
    "8e443a1faf4ef45e1d6c402d35a6b078a637b9028e285034efc4d68c3f57651632470a7e0c434d5f854e61373d3bb996";
    "a096534d34d7d95a74bacefcdb82f6243f6c75bbd261ca8bb5fb6174ba33bbd10b72a278b6c46a1dd05c0fbb3859e90c";
    "aad76d33b0a62c95471b589155c0c9d84b2027da712eea94b43fc50b39b26c5fc96559f9515d72e3681486f8666878d9";
    "a9dead64be76bd95df131a73bce9a353933b8e27c0d42e614af4785654a6509d4df2ba2fa42dec98c48cbb2d6f7b1993";
    "aa226983231aa51bfe9662898360036f778914d2a5db134fb0d8e55d0b11dc0d579c1c4c7e3d034b05e4e1fe3ebaa12c";
    "a52b3d3c31cc820eb5591af26607beb1bc8c64faf168f9a82c0f0e40ad0dd68a260120321cef4c69f13e4c84ebc63f52";
    "915aa2954f0c4609ceec3933ceb2e2a670e5e63be1c781c70681ba3b702afdd9d6685d9b711109cdad8c8a2084f886fb";
    "a2c2f231048cded1b54e3659d056b8bfe0c1076937265a9e223035929083aef8e30c09ffe015dca09a8c3c8ac128464f";
    "87154f48f0d26ee4629b1e7f54090121508a7caff6ed81d98e213e5d646336894daefec7910f7751e586d0f699dd8c4b";
    "ac2fc3c113fd859ea6cb1e7e8fb7638ca9279a9ca2a373857af966ded3847f756d1486b2c8ebd5f4441c7defc459916c";
    "96324baecb197989b1ee8780e8c2ed1d402d3ae3ac159f71b8d6eba5e71b9fd7e7ae3800a31ab69bfb6d5db43bc0a64e";
    "a05e7522e78a7e43e657ad39e84dd5ec82e1ddcb78a35d41f59a9e615cf8934fb9043fcce1e8e3577f83d72004611a28";
    "b3be381bd47ecb85311f73eca6535232ad6691634cd5550b9446649c734b17d040c69e969028170cf2d729217d7e8956";
    "a5636fcac39822f9cebb1fe5a91c2a8c5536e010a48a9510ee80dee6c700dcdb74c90e95b144b737ed6f08cd0b7b339f";
    "abdc04e710c34bacefc72e2900e267cf6d68e1d6f25e95a2b6bcb88bfbfc35dd8849338d04474d326af7e80a439fd04f";
    "909190b92c9f54c6109c1747844dbc241e38896c600c5a16e5b2bb7e7b01bcdca7503146d1b138e6a5e94994ebbf84a4";
    "aa861be414faae59c9e1a89903d39ac6fc910b265a8d0f0e78ee21ef7e2c68018ddb156cfd14deb7a380c29a4246044b";
    "a7eee228026f71be62a5138eb7747a4d5834fae2f8a4a7dac43b720a9a7461f4c195a223625546f436583d93e18d66df";
    "8905fab381698c127f6a47151115fe1a16d610a880fcf3c0c271a126221fbbabe8feae470e3bff47f05bbc0e946dff1b";
    "863d5e919e6ed29ec747ae76747a9275c1dc4b466ae5145836c9578aa18ae58b017c465f93dc1a57e1c0fd48fc5b2fdf";
    "8332d2f94ac32973cad00dc73343d854d1553c977d2f2b3b898b5cfd725c0bf6e0b11ddcfe9fb7c79a8e82180bfee2ab";
    "a74081281330f7fcdab60e3d4542112b9f0256c6d4ae8ce8455103c22bb3084917973523cf6479474c31176b8db6e2fe";
    "a74abf619307ee34f2417bb66d8b778f72f27cec18407bb2b833fb3a5601a70288ffa2f6ac6a21ca4d4bb879820b1907";
    "a4922a0848c5d5e3edaa003f660c62a96a41dd4d8a53aab6e0fb492593c9e96e4ad19c1f7fea5b69b3b40e2b3af251c7";
    "b24a4a2adbc303dc23695d7dc1e24c4e9ffce5f2d0bcf895630121873b07574c6f250d304a855b567e316c0b1ec63854";
    "89a7f2a3fd785af109e6f2f5f6280ee2bc2a62cf51f3d231ae76569db099d364a286b5979874b1c7757f905f6493b888";
    "93d1419db1bb46476dd73ae0550f62180c73611206fcf2c6ea66b30277f0d32a969007b6551ed9737477592a1dc7c841";
  |]
  |> read_srs_g1

let srs_g2 =
  [
    ( 2,
      "8a7572dfc6cc8fa216e49f611baba2df2cc91092e48d1197e4176a1ff5b5d5a254246b73c3f839620388b8ab424744300d719cf31c209ea6289d11a160f4824eed858ac51a39ba722cef0ebc38218cb2bf5028b4f36197ea7a571849346cc461"
    );
    ( 3,
      "a5256f15940ef189440ff7aa7cc5b9ddc35eb430cf56d7a39a908bb10af66ab4eb286e694dd0cc69a6bbfdfeb3aa48e712672ce8521c6ceffc9b4de34a76c9cbda58706f2a91d9b0c8d2864464cd03f6af5af5839ec1032c348fbb87c49779d6"
    );
    ( 4,
      "a54978188953898d986f3d36656b99ff3d9bdb27bc0c869bec270c8f149b8f98f55a02b197da469cbebdfddf30931df506a489b6fb4ac71c67b346ee0aa665a6a5570c7321662003be997faccedb9860dbcc9b0a0e37b31ceda2d0e454b215cf"
    );
    ( 5,
      "967005ea0538b6ad772b3911f13e406ee5eab8de79725bffc7b6ab95dd5467d68ad8e0afca054f5839f8e99bf77a365112e44ef6d765ee88df5ae401c978278419e6f48a725126092c37e75462c63dd7af5deb3ad7f05d90717c912a606d71d6"
    );
    ( 6,
      "80e20b2c4b0f84b246d6990edf82cfd2705c9970b5b680d10bf3e3513e8d0f22ff1c65496afa923d4bb00c0244f3beec18be6220c35291679bade9910b2e22562f6d3da0f8455eecb70e2644daa56d3aa75198951e39e76e49bfa48b00a444c4"
    );
    ( 8,
      "909dbd99e0196c5db69eab4d02b83b7464c314f00d54703a96e0ea3118fe089ae1ee741c6c8331d7b9e720337ba4406c0ee60ca05b1b4cc8ec3b197cc81ba9bb0ec3da7a0c9afcfd1702feec92c57029b9f06b537e0ba76b0717a1f592278f2b"
    );
    ( 9,
      "916e2fbc6401e3ad9197b79b35c1c930a2024ff3e4585a3f52a5ef1b7e326242d4375e2fcc5b83f97eca8e4aced65a8b17a6b20df12dc9e4c0606d779d3ba596ae46f28ef9383f4e9e1491658891bb0057c2f9878c5d62f7fb27dfe8522deab5"
    );
    ( 10,
      "84f341634334a38b9c4b20800cb988c5d5bd55ea54293bce6955f0d9660a1e895ac621348da344fed9b0c57df6680a240372c4312340265576fa297826fcaf487dffac1f65afe0290209243095434267da5aa7afa310973fea40d59573b1e8ff"
    );
    ( 11,
      "8c3f5fd973b1b948cb641a87d66b7da49a21ac98bb4431f8db59baf1f4af06361109450c3056b68aa8224635545bef1709a3d4cd5375a91dbd9d452521a3f9df4027952d9b9d5701560c41eb383de7493c34a6fe7cbec0181f5de182058cf0fc"
    );
    ( 12,
      "91e2481dae3b85647563a5d0781a74d397cbfc42bb3dddc4397c4d9848a1a5c16149adfc3c9879fc15790c012addc64f0df107501c7698e0afbd0cfa3b7a9de3b94e5a4347adf777c008b0d1572e466dfc68f4a4e18f08f1d919968f8a4e550e"
    );
    ( 13,
      "8e6a1e2fb1388a393962e2bf4d030607d57525b011b3e05969ed688bc6e79c13d5a67fefd977772a5035f6055a1e337f034a13bad13fc981cbe74e71f6e5a165012676ad5fa4ae672a3c28df966d3ff7a67f879f7ff34145de21d7f8535151ea"
    );
    ( 14,
      "89322ded0fa72ecad1e702e75f833ea6ee313dccde0c8ac30d0ee31e88941f46b8c3822d6f38f6f31af511f8541f4b7a0fdb723a2d532f3f81f1be7c24ae4a89172856e1421f7022f6bb74399ea234e3e346749c665c3d67ed4466fe28723e84"
    );
    ( 16,
      "94f213ff74d96b679fb5e8e032e4c80f907a923754c037276c29144dfaff1ed02c5c49a3b559df862b7c64cb7bfc180c0f8547695f55229d7fe176597bd85d422ef0276923675313191358f4d17101a1d1bcb4c6c0a1a3ab56c1f1497e23f4a6"
    );
    ( 17,
      "abac3b65d05ff94acec9e865d4b7e00d05783003f4b9e4ca75cc30dcf1a78d9edf3771e2bf31952bb4ddf349958b687a0f5eaaee2000dc57235389647525445ea6baab16f5874b551ac3eab12ae425cbe79595c5012efed3d718a3ac33351f7f"
    );
    ( 18,
      "a4559696d71952a3f19693575b71cf40b0d4ea57b17471321662c7f38326b139f47ee281807813b589cd53c2410b705b072c6b28379112b04909dc0b4342ef078462e1c7f5cb6caae173950b537495d844f878bc5bebb834dccf00e644eabe71"
    );
    ( 19,
      "8b0cdf11903912bd44979a0c0e1ffd4f16bc01a81ee2fa79623783a56343f0ec12e202b64f1b8f568d7b4be57389448515c8008922c8cd5e927bce0f1b5946500e596304347a756c6d7ffbee66db75b75260e812b6bdd5e7d5e2dc795156d448"
    );
    ( 20,
      "81c17c0f428885394e033762ef9cf98c30f674d039017f51e34bbde390c405597a6a6f24bd750fe6336997f36dbd017211f5e96777333323e9896e4e609f8edb8aec8ed6ccfadc0734abe185244d163a9a00886754af7cf61e81aa7c535f3190"
    );
    ( 21,
      "ae82a4245d383f44828725371df479cebf072f2f488389a5ecc5e85cf38b0cc5a38250d1c782af4fbf08ee4f833245eb0ac65bb7756fe5d216e4f899310df781e48c710638fe933fe1638d9c03572a739b30a57e1bad175840ecdae702fccdbb"
    );
    ( 22,
      "aca7ed473011bddac59110a7065298814529da5b67ae2eea30aa10e92eafcb33c7f18592877b925f8b286b7128c79c250b8ed74ff807da52eba7d9e908cc306fb4b2997c3a8a6619b1f14be318b7022ce56e59b9439f3da28ccf3554d94e4935"
    );
    ( 24,
      "b801298ac0a803e7c68aa621d533a0dea8867f60a354925a7eb9185c5bbe000a6ddd436a2db3dc983c6d9601f9d4854d03449e07869d6d04d913f45d275a49a986067e25d5c528d48e3f0b5b24a3a951a9cf3cbb21463cd5ac400d1c26fe8fd3"
    );
    ( 25,
      "b277f1ba02b53b43a8d7bfd8b3acddefdb884e62c4519c2df37c117824be4b967110e5af50a45ef951e4409d73d5641016ed4d6d3583c1633be4894ceff6638719577a1773c4dfc25bf5ef0b380f3cd6b58fbec7efcbffbb1c0bea144d98d40d"
    );
    ( 27,
      "8ce0ab0d99a63b9c7d44ac4b5734e005ce96e1e2defe7aa42d8552403273a46d511db2f3a076f4cd01b1c0bdd543f94f118de4b121ada80afca6b89aa57f5c8738f73f003ff976ee09757011e4a35163890683900c4662f4805703e3c76b63e0"
    );
    ( 28,
      "998647c8e6f939fac189b6d7c9ea68d96617390ae0278a77de1496f07bf5a56d5b84631ff65948ddcd142c2d8fd4c4d506c6116d72c861dbdbabfc846a8c62ade70a1e6e5132d056429fb7031ad9cd61ad678c705c784d7e84a12bceeb20ab6d"
    );
    ( 29,
      "8440f8e980e937589ae8187764df6f79de4fca4e1aeb5d36e1907662245e104349d76c263da7eb87072ad2b45e95f03918b0e4be9d59872e0f6d6519c074250d31ab9b720049c0bebc2c5ea656583896d05837778ed735137addd0d6e6d9b46f"
    );
    ( 30,
      "8f0b67d0eabde27a62aac0285001d8efe0b966c52dc6e33d0bf7df03f76aaaac0c7f54a81cbbd9693c08a7e59bf103330c3b9e5f107b39631ef6dc98c618cea7c9fd058ab339ff69c96990bfa9d986fb21222690408331d1830bb1eaea04b67a"
    );
    ( 32,
      "893cf10e292d2f00ad5922970aa593e606e1ceca6e913338c778635e177668c56853b78ed92b8949d23e5526534d9af10886853ec05815387a4a1498a6c3cc6ed6bdc51e49151179e5a89958b23ac4eda6bc4011c64f6abc8dc15aaadf2fa82c"
    );
    ( 35,
      "a176bfa3d29e52d0d916a06c8c01809ac55b902223e4272b400e9fd1cfa848c31e9ff2687bbcb350c9fbd7c005a36f8b0442c20aa02b55e490d89cfad28e25dddae310fedeca3d84b35d47abda412ee9bedbbc3ea0ffac9c7c99c2c9703662d8"
    );
    ( 36,
      "883a15831c80fbe0053111effa6fc4391f770b20f50b13c8fdf945d8ff63e6ec4c38d1cf510401eb13498776b21dec2216ea46af6f0af06d0876663b11221ba48f1e874d73ffa0455271f2f6d88139fbaa5c55b489e81e9bea3f7a2f8793fd2c"
    );
    ( 38,
      "b65abea1d309bd01cec58b27083f63f2ee9a0829cd0beb8462236a62c430c8b2a2b6b737be643c97a82cc271b5632e42006f1c8e12127f55482f67914f4fcb9db05ad04e16fdecdd2d11c3cbfa7710557af5e8c378f5d054738ea5977c32469b"
    );
    ( 41,
      "80f1b0505ea8977108f7191b7aa530a51b56503207b08cc8bf2e77172c02df28a6ef0e1527939ce5d8a579e7fda10b5e03016971f206b1f08abde5a0bd1f90c5228cfa6d562a48042d0edfb49a030148c4f67aa457c183b5e7be3685b2487ace"
    );
    ( 42,
      "8954cc3cfa822a5daf8ea2ec32eb26b235e9408ab3be43828e6fe998152b054a51da2131de924c2e5bb6ff6967dd172b0a8dc661e7015f0ae6643a9cae47f3fff222444625fc4e66d0f16be49339b89523eaaae4a5b006ffbe2489e8f6a2fe6a"
    );
    ( 44,
      "b0eb1dd6eaef98c8a2862a53c9b68c1e64aaab8d32ac534007916d1edbcd1cc7bb671f8cc54a5e6d4df9d3f93895f186148e8e480ba357df5e7893180d453becbe29e4b7a0e67150e9c403234ccf88e8666e3b13629347713dc117df49260d45"
    );
    ( 46,
      "809a3ae6f8f99fca3ad0916918f18494507cacebacd1fa609b934b5ce24bd15bffd07d277292490ed5b8a9ecf081f4ea12c675eb54d5c80c224cfbccde73e98f9e1adcff00c6fc25307e24c413c7ab54bff8dce49ffb5bef437e3829d04283f3"
    );
    ( 48,
      "b0813cd52736b3dbb891e738ec3c5009afc6894635ae04fe55840efc2c405fa17a952a00c68c0f8024a482520597b6e30a6d0833bca105a6b472d61487354691670dc4258b7ee8366158dd406248e4157716f7083b08465e3283edc8ab3c8a49"
    );
    ( 50,
      "ae1a21b867dfc792ac82c1bd44a26bd451773100468b785903ac6a7de855557b778e853b084e94ae46097f112d1f6fac10eee90f2936c8fce73bb72de22cfb6b183ca517327f1989da19d0b55a4aa46486bf92d2860140d9e3c18f08c1c65a76"
    );
    ( 51,
      "a23e3e1667e282ab401480d99829b1b546fe0226576ef76a46b094827804c173bd1aa2494c75d13d186f4a65c9dcb8ca090ece65d31fb68d600477143d6cd1254aa9c5851b1ddc781f34ce2278109a90c32f5aa29cbcad8d3faa6f46a24b15b1"
    );
    ( 54,
      "8b816529faf5c639e909cdcec80180f4337733e488f9f728903341c1929bc2e69f0d1f0c87d662690aacb0ed83de012f01846e5ae26ee89bef1ee844a5a2c1b56b316b797e8ebaacd49e3bfd18763f0322485ceb3d8eb762afc9ec3d108fb6a8"
    );
    ( 56,
      "8a10035ed764c1d518c654d13d30750accfb23bc05f9e05f3eef13fcbbf0185ff9bb1ae9077698fa2d954c03d7127bdb19e287b3e2dfa86fcb201240a88b498ed0c9b88be52563f36eedfc6e0f82b932448da00d56f9bd50f8257ed0434cc1b7"
    );
    ( 57,
      "8399dd78e3369edf157607abb3d6be6e8fc79b741f31a5a48d2d5284cbe42da34068fe0079a4adb0eaa79d35bc87122504e784b07ef860a5b1f910e7626eb268fcf049c184f72fef94c917da1ba27d0556c968ff6e1e63b431e7dd772f1dde5f"
    );
    ( 58,
      "8fe325b0a5df0a9aeca38332cabdcf959bd38f234cfbd6ddfdc397762af801bea443fd8e0acc106a099fb78114d09ff109e2f7b7d058117115e5b1cf374770cd45e3f0b50f058f315bf2eecaab8cec9895ff739dd5a77ac9efc9f1bf81b2d82e"
    );
    ( 60,
      "a1cee87410bfcf24239e95d19f658e4a85a5bbe7e759798570a6b7bb19a07123cdb5fb0452c5aac5012ee35e00eba4d908b693e0de66f22c9e22cb343a249ab8beb0fc8db0c7ce19e62f20b86d9459a64cce3bbd6b163270a8c306687f0a5f2e"
    );
    ( 64,
      "95886a90236daf7c8b1e2021a9352fe0d3969de57b63c06dec15432017c97cdc12fda4974181a572e37b679ab7ac0b9d166849db3d6182c2193248794dfe697d8558d1c2d24397fe5ef210bd829ea2484af05b92ba239f892f88b36d627f6f0a"
    );
    ( 66,
      "b3011876d64f29a5bd56f662ec6f5e1a40999376f93fdf31f043f309d8b9cb4e864418cd866f8b76739a0d8143dd36e20f927fb429df96c25d3f9183828d161c5583f883ec834873a6c1d402c7a7ba4bf85c7c142f7e23a417daeeb8339ab32c"
    );
    ( 69,
      "8c2d41c8d2d0c0de5cfaa6ecb889285726ad9f040bb5d05ca38b03f27593e8a6a0ad80d1e43a3c9e6975fd0ce0f2adca07a97d3016e9f31795fe3bcbe0e10b0153d9ea20d1e2bd0b0d9836f0225647b67162f71c6ea6eb91e2fa7d60f9c550b9"
    );
    ( 70,
      "8787a2514d0611de679d3fadf7655fff37980353521b7151a88b709f7e86d9db4dcd3fd1a5bfa7dfbd0b81acb4c96fc80cf933e3201188ffcc75ba201dcd471c45f89e07e31782b9f1ccc6ddac4f26f9ec2321169dd1641c45e2b6ba1ed0571c"
    );
    ( 72,
      "80d38398882bd6f7026b6efccc6759890081d721b458182829d2152bc92fe44e480ab8c8012c7fb9f85e0ee733904e5f0b77b437ac557b00f7e10bd26d2a18846e0621c29486c43438497502918c73de01458f7e221ceeedc781b8ff2ed12b89"
    );
    ( 73,
      "b4313f894f902cdef0e1a541f5afbc5596deb13ab54de98be4e0dcd44ac98ae4d4c1d6e3ce6595cfdc0b99031f91412103959053972dd5179fe4bb7178964e34ab619010a7f266ebe858d1a6f8c17c65ea41f796bae59044540ce0af6aa9fdc5"
    );
    ( 75,
      "936230f5a08c52d79237ebc9eaa5dcc00c47684b2e0bc27cba580e245c17986d67f5776a921374ec6160582d8dfecaf0144af4f45c903f13b76d18b32d26aaa9fab9ac3d67b495d307766cef4a0135cd088a8e3206385ac333a0e44c57dd31e3"
    );
    ( 76,
      "861701edc4fd03dfb8d507ffc9fdc81b57a2a2290c536433e8c6d1ddbf1ce7af144adf8b66968b50b19feb6a1b2adfc61991126874650e56f542c279c196e1b0d28939db0684dd65face55921a5d69f5326073ed5fffb058dc809c97b05369c0"
    );
    ( 82,
      "98b1f0899e6be7fc683f48ca05f935d4989b2a8bf5a24005dfe498a41511074f00a34d80c6184f3c71b69c20f3970a890a1c9356ac794d21f0d1bba560fa87bb68cf6e1f9fe58ffd1f3b30ebe6b57a3c69254174dda1c40d8615fff8523f5d8c"
    );
    ( 85,
      "802ee411b9b7dd9fe0720436b465ea9e5b347684b268e7dab9e21de823e0c7c55b78ad3147f6688ff7a7b57178a4cdaf0813c135ad5ec7d4458dbe45a3d83af35639bc162fdb56d71188d371b4a97b5326ba88850aa1f3aa236846df1844b29e"
    );
    ( 86,
      "a69776bf1def6e3447b72e5d003514cc16b81d518d5168d72139d7d294145533e5c6e001885016fc8bb25e64799810340ae20a1ba8e7eb4ff3290770e5c3cb2478362626fc5ac031c8c0532c3bd4ca3ab2d0012ea099df5c5e032bfbe0182a1e"
    );
    ( 88,
      "8706f7644aab1364b4d0d45c592eb8934d744bc97679e31a10ad3cd7ff3d055fbef72a352f6df72cbdcc81f39fe5253e172b09133fb8cb29938bfc603bb3e37cf8d16e85e1a37980f3a41ee9bf00d5f387b7bbc7765959a9cabb2a83e77b8a38"
    );
    ( 93,
      "90739fc0072debc5b057de963eb8b31a6a8b5fe8a2d49f4a77739d36f3e49928c59c0c52e87ca6599645d4cb50c1faf113451ea84fc3609d3af3afec1a2491bf57ee58e7dc983567a4738a0037fca4ac5e016e4a030fd231dd6b655113506caf"
    );
    ( 96,
      "ab979aa01a516ffdf293add1e33e79f876bf1a02401ce380c432e89421cef714c8321eada9b76f141e909dff576570a00f113bc7b3d54f7e5311e384b187102630953e904881201c85e2398755493b5de874ad426e5f5bfdfac87a83a3f4f02c"
    );
    ( 100,
      "912cdc078aab880362f676afb54159ad32bb3d92a0a644c4043876646ca2c9d935b4f0323c984daff351e969030a8bb100e94cb4ce3481eb2f1fdd37cd10d2ed8df39d1956c0a50090948afd1bc5406855eb5864de3b0e23dfce200d99171cb8"
    );
    ( 101,
      "a298f7946531a7dfe0987e04dc26179f97ead5fde2b8c572af7289d27e171ec87900ecc66cd55b6a7a01df12995f28f40a7eaeb952e480a88f936f4f39ff84018f34e08f50618a09b9e615367f726931a112e43e5952f128b2f6b20374e6aaa7"
    );
    ( 102,
      "8c38dbca7b79a10417197d5531c1a33df456ca344056056f93722d45a79117c819230a8c660b294d061f3034f7deb3fd0359e118321cc27b9b0148724d5625e0e0af3137472de1113549d34a228cda6c22c443906f2c010702fc7fe6efe2852e"
    );
    ( 104,
      "a09b954925437e01d8fe168b623ad456be45a7ceaeedcfbfd6eea20beec0a355848aee24ccb60c4ba776a93fee00d7051324639b44fd7f00cd0044980812ddbbfb2affa07f45b7705147f68a6ce9844534656c6a693aa81a52a221496424be95"
    );
    ( 105,
      "ad7eac20ee0f03b4fc8628b4630ffa3aee5ec82c8b5c4eecf45502c0407c9b6b2bc2068d5c0847d1584b1d41b7918d0516b1acccc37f7603a0f7b2353dcc6b32219989e83ae8f3b4af24294ecf47e974a77b43215effc61e4e6cc6ea4c581790"
    );
    ( 109,
      "888dda51bf57590944485d56f634a136c39248e36b0ede57d05d4caad9a2b969ad078d43bd20e4d8a1050e9780dbd0c608e6b0fd295887d1ef0b0e86973783f30bf64192edb41369fe655f5db3b91dffd8595b9a1e7f5f958cc3cd110e44cf05"
    );
    ( 113,
      "a5cfde9f6569eff00a99ef69ab7573ec4a2855cae98579d018309e7a1c3b433eb785afe8ec2135c04e396d649d349717034028c1ad5d337c2711cf48d40e4e909dea9cb0567c59bb1acf7fca6ac6defbe61dec31c3790c380589daddfa642f52"
    );
    ( 114,
      "98204adbde2165c5668f5ab1ebeb9b06897a96c2f02e57c786df4fe57c92a6dd8772bd2f19c39f0bad0df36ba5bed88f10b58028a49c39d0d293ce397b31021a83d79f43ad4ce31357e1c88822f565e28911b2aed5a06b9bd1a1a350f2354489"
    );
    ( 115,
      "b94613f034125d0c8a40a8ed3f120f64daa9750b36d25f173063d9991185cb5b8e89975b9fc6101f2fa7c887b9fe3e4d0402d43e60a64ac14cef61eac58f204935755a2129d7571c11c0ae0d8a40e09f599e474add8d84ade972e50f800e5819"
    );
    ( 117,
      "a72e7924fa2789df5888c96194b7cc98fca26d754636ce4ed4111a02e588a01bedf7a18fbed9dfda24d2eef6645351b50928b53ff500ea32865dfec523a15c8cc4198c341830b9be5a7b63cde7f1ff2f5a60d92e7b6fd659203dc601b00fcd96"
    );
    ( 121,
      "b7b0e396f6a95b50f9228654fbbdf6b48d98a4e0bcf1135e792c9596780d129bb7fc938986fcb03410be15c1b858c6920653b1c4d49f57667947ef5ca8c5bb9abe37b9e0d24ebc04067b873aca857f1e8ed77d0524f242417182fa5c4ccaed61"
    );
    ( 128,
      "a442977d63f1d3c1267eb5971be6fc7a6aa59de484bbc1e1ec89f3ebce0eff7631420b0114d6a23fb7765c9797d9c0c3056e390d6149eab60837711d6746212ff801ca80f48ba5dec11193a8eef6d33038f7dad029cd7804cdb4267a2f73f3d7"
    );
    ( 130,
      "820fdb99ec11fa72320aa4fb8823813c6795f841951acaad8d1df62d0f4e7b06ae942900e545887fc80312d64e2ecf5c0d8069278b6c751d71ad1e907565b495ed9c5e2eb923c6ab6f964ed53db15585b81354e3d7b996a05a37baea1a32c380"
    );
    ( 132,
      "96b473356ac1031666a1790c8dda5ddfddb32ccc44df167252defde14080aba0fedc36c2bb64d9f15a96117202a5709a0fdb450ab30a291e0e8c12f1f11e8088b303565c11db53344034112c217414df2b042bcad583a8f0362eaa8f02cff903"
    );
    ( 139,
      "92399d8b2f5305320a9bda2c57f998e5d0090d82a2767b52116d71fd3f4f68f1068a5f8ff108c9380f51dc2c284222ea0260c4832f8a5796a3b35cf989392642b0215ee156fde0848977bf8292b966e63889b323c1e3ad57bdb36cca8bb441e5"
    );
    ( 140,
      "8137ca17ba39451b28fa5210f44ca3e5b68ad112d09a9241443f488b91d792f7c5e6896f517f243131f77e00d14213c218e1821beb7739b1407794ee01645c206d75a4f2599bc381512a4043502ba9bd69e11f6937bc69a2d64a93e6b5ba8339"
    );
    ( 144,
      "957de4c8a429e4ad6eba938ca0e4db05c1af37a536469915087d5c47f73af49ee30a5fb3c697a77f76f5b9319cf6011a019abfdf97cee051626564d54ff7e1f9cbbfcc9edcac21eb2d701ca5b2fc23b07e858805122808e88938bbbd54f93f66"
    );
    ( 146,
      "9926300fc02c8157df4c323d0eaa35808d781976d785ba5e6129e4ea4f509740aeda06e5eff36287e8c6d61e3553a122147d50b817dc83589b369539ff96288d5c55eabe277595b93af000686e27f222f82401247307c6b037724c6272957917"
    );
    ( 150,
      "84898476a60ab3d21daaf417d152a309995a855f9154803e3414fc1f1d5c4ac19e0ba2edc32aaef2f4de20cfc67323f501c8d53d64e82a3c56e5a8a83c72f3ca74b390bfe904b79a15a4744c24c8f6325a90728b09b30eb9da94b760cb81e24f"
    );
    ( 152,
      "a2889f459d01eb25577011f711b3dfd4736f5e8ffb0845bac2826c195a709f1f423fcb7fbe82a12cc32a8f5ea9f217be0480e386ddadb1aa566c7de3486f814a64a398e17a27f5056a71cd6b9a383808fe342d28cb204709977aada5d6e49d68"
    );
    ( 153,
      "ab5147870cdb6d8fc98c684d1ef6995fdd140af005630a3612d18f4ac6e628d1e7990ce5481b882c52f5dbcbe3953ab01086cc5f2de15e2982b3627b59b96968abdf80bee61454ec3dedcc0fac8a68e10e105cc1f0c8133c6f08c45cc3ea49b3"
    );
    ( 156,
      "852c52c85c330c2565d4142784ec298f08979e7842ba186ec9c22f5fb8399cb5ae1aa578a75ac80b2b90384100a4858009f52424d4a3ec6865330235f0fa751e2667c9eeb57cf9c33c0254504c1555d1cdd6c3ad5cc2db7da227184f8bb38b95"
    );
    ( 157,
      "829ef868cb72d44ba801df3e867764c490e4ab53d89492dd65ed6d6361f41db0041d5e591b958b755f3710d1b3b14b471392383ee5e89d94d2b0e7f7fd8cb0d9f136eea2c8069873a77a63d46a7031f0b5fd025a87ffb909766ab3b855e4e68d"
    );
    ( 164,
      "a0d14759b15d33438bfc9f4e38be35b6d6f21b461a40124468c1c455e06220289b54d92f18c4f0f08bde72310fd63581058acc27c831c22cd745c749203c869113ad8ebe3661fb640e2754a3bcef74d13bb7f66c4881069522809a5977398fbd"
    );
    ( 170,
      "b16e860f310f2f243435db5006d200c792b842ef9dc524fcc787ca316d6d9a86a3a313488a8d5ea0775a535f188c41610be69c9078fc775af60e4d2156a10dff00e7b1e61a26b54a00fab2c4486ebcc41dbfbb491754ff0b0699fcbb541ce6ff"
    );
    ( 176,
      "9504202e00cd40771a1338593f9e011f272f407e8600a7ae57c7ff201b4e79183ddd0e4d33d854bd69c4a10c428f6996053603773be1c0556f09c211c0ccdecbaed470648275a51ae78440d71c197239befba0d0e0b4f4983aab57f158155327"
    );
    ( 182,
      "a3b65ea23636bedfb3e5a1a3bece70b1c2bf6b3e827f5c6ba05da35a22b23dda222874a432aa6dca52edf9bddb4f994a0f0403e04b83bea018f788c4704721450533db7f30702088dfa688a0e503e2c242dc27148be4d0f047347a817b01b2f2"
    );
    ( 186,
      "a497de8e0d298792595eac44e0cd9959f08840afe99394d5c29328101302b1acf992df7f9e25666fb40a26895f50b79b0a553db9874d820db2753f55926ea64eea9b2917f1945469d58412efaf8350a081da38067a828b408c7c7cc2ae4c3d52"
    );
    ( 192,
      "817bc4d11a82e932460622a9b5ca2ea19fc531dd4100a818df92d2311384e6b3c6d1bb8b5ef2f69f2f0e8ff8c82b07cb1584044c964a84da6d90a57cadae017df0b920f01a63b3f16459092fbe36b25aa30f38b30809941c72f209eb1d47c3ae"
    );
    ( 201,
      "97aad1f39ef2cbfe48015aa2b8e15140d6d62ae38d8578e6f39e901ee3b7472426d8c3d21227ae257a88c1a4256a8fc2028b330ef4b835067252891209d8b604c8044b98ea9d1e6e2a5d5a1b7647cc254da87739baa139c661c6732ddd9ec36c"
    );
    ( 202,
      "a106ece60f57e8ed96c5ba4b0463e850f105ffcdef179b4ff7d39323d384fbae0bedd49a42838da135041bea1518efc80e0037e917b1045cd10ce22594c28d22852b1d9cbdf22c46b10eba56cedc244e451c2bc11ea33bfbc22f877c07ec4a96"
    );
    ( 204,
      "8a0ff97e4bc4024ba8d56104c4a0cde4625c3089768a23410bde822ac7acc2bdc66f5d9964ff4900fe71653590c9faa405b4d3da6322396917588d2eda3f3416abe82b0a1152a9a63785d5395ac80605d83e7a4c4c7b4bf1f8bf999da8272a83"
    );
    ( 211,
      "919002ae129bd8ca15a49f6edb69f7186a4b8f737da998890d8a9ac73de86fcc9084d48633abc2c1f7e4fd3ed5a90aae17eb11439e4f33717a206e0b1b13e413b689ddbfb6888d1be080d5db716bf10d2345a1c19b9a56eef1bf23e96d0ad12c"
    );
    ( 219,
      "91bc4884a563674fb290d0eb6a4ce778c579d3ac0f49872baf4d8480b348f1720a5607b5b200f0a54baba817b9b1679c0626f6e178bbb11234e73adabfbce9c00da1e6c14cc1a9d2b3d09b774ccf83bde0a60576e4813ff3b9dfe590383c9d53"
    );
    ( 227,
      "b057ec390167fdb758ad30e920b29d1deb6d32705f7408c294ed0802b481dff089c6c0b802872699c5e968ef3a9150fd1883e407d822129d35358e1cbfabcc1b0c51a6fc707433d884332c583b4d3a48fab9e83396fd95a56927902b45a9509c"
    );
    ( 228,
      "b71e8704fbce3c4001b025468f793622e20d0e104ad5dfed2c7e00ca6ca7c2ad3e83812cf9c7bd97914bafb9bbd3356d070ad1de4d329d89c01e46bc21421b3337fe7f15fa12212e6a8d9bf822669044f76105cda9588286fae48a2923c94102"
    );
    ( 230,
      "afd1e5f30e01866c8e75987264e39279452482cacbf3ec3ba2cf8125dced6715c55530743e07dc11874b3b12cf6a15731275ca89af345e0a349fcfe2c41ad080e6b96c46b835aa0bac71ac3e98b020f391c38898f221ed1de5803a8439bbc039"
    );
    ( 234,
      "a1beb960c586e434b735b1d402a438cfc82dc21250ffe911ae5b860b59b74f5f4a1838f83109a433bdc18d2ca3632ccf089a5ddf25b9fc4e5d8fb3ffc8af30fb6b9e5d463ae0269a10da0776770012823beee07592f0db1d92eb43f56049195c"
    );
    ( 256,
      "890af3dacc1096c9b667902f179ff3f431add2be0cac2adb58287749bc09acb2202389dcedec9c54bcad0490a01412f007218618604a856bf76cf5de4a8a01f8eb4f18ead00219d613c8e09700b9967922bfd16285906f808ae7ea978a1db27f"
    );
    ( 264,
      "88f01bcda5aa5deab2e6ed39609bdd39e0cfc7d6eeedf4466971220cb7d43699aba68d6323fe2c9a7458f4b3c205838202ab18d0128b317cd0ce6805a24ec375ce45038ff65f95b65bf1f24271ff20c6a1197fc1a5a1448411cac1d8cd1c4fd2"
    );
    ( 281,
      "b83f095beffce91be17b2d6c7c68c7af4a97a0f71117523a835eeb2b9f5bb1714d7a8ac5584fcf892dfbad6ba6b28fc11381cfd8bb1c4122ed0f5a488c490605a37a322a91064eda98114378c222d82e628c3c3d3074feb57aa963d17617d18a"
    );
    ( 288,
      "929bb37fbc2c67423dbc085e1b84db65f5e3cb2564d8b43b5e591c244cebd01ce70b9cce5052e5ffd06b77e12638a42411514f55d9f5f534f9c9f159a1eec1205831f708c7b7ce6878f00341ec528a45080fd1f8ca2ca412d7db1e266a514195"
    );
    ( 292,
      "a5a41ac4fe7fe844c8d309d8814dd38b2427eb877b34381a0529b5aa9b81c53a144f1180b32375c4a65f0b510966676308dfe86f1f7cdc36ab5dbcd4d6b199eb401cb8a6c9e37344296148dd4fb29f434df0205cc7be2b95c254c0f852430d8d"
    );
    ( 307,
      "89096fc1db0ab2834ceb3868bf9a0c31b970f69254e8d94b8f4082cdb9571f4cf3a8b295caba26859c9257559a4221c3057d39a92f1f357a201cd06c873dabd77115e4694d1ce9aa5c3580f809e4505e1ac568aed4e080437c9879705f81c43e"
    );
    ( 341,
      "8ee1eec48ee468069eefb53c4f787e8eb2545b3c5f043a163fb36938f98ad9f9f3bf67d21b599cffc13060f288448441182c55b3eb3e07aa0a3ad6d19cf065bfb64b4bb36cb9c4f90ca40d124ffa97ef140f3fd82ab6ad525de0608da4e209db"
    );
    ( 384,
      "a1ea1b209103fb175e18e3723930bc8b95e9a8bd79d53ecb82b6626441e4fa0964eeb265ae57ba58aab2f18190e46faf09e062e3603ad3143f219e454f8d57255dcb114d9042087ea7a0116f6b4178c376ac9610a37a219394b3d82c505c4ae6"
    );
    ( 409,
      "889b85fbc799780d8b67ae44ce65d2a2b96c151546e5d01d2e9c2dfe88ed20aa5653670f9f0e8712db80001ac81537a006f16f6bd29cf66f7f355bbf0db05a9c92d824a7f62251793ed8594a12a37c5d8465a19abf34f6a0f5cac3dfdaff55bc"
    );
    ( 15872,
      "92f627e5d7ee2e390fdad4ff18717eaa86a37ce69df2974c9dc125501465c168ab04a8b28e62d86a08b4fffee1e2cb95146750f49f5d65280ac6964174f00e0d540ec412e5585ac19e35606b757f0f8098f51f981c64dc23d9bd4b8f6d257d20"
    );
    ( 16000,
      "b4d5a7373b7ab90431a1e1d2d1d069ec90e04edc998f9557607635cd070b0968a4515001184750c5e0fa69a6d91ef49e00ed66c2351cd76a268adb6131eeb3ae2da89ad0ede8372963526da7017cbafb93b26868db06e3f0436cdff714822229"
    );
    ( 16032,
      "812ca1e4f420173c0820483781163a97600833dec7f6b2e7f7f1f6fed61ca2e16e5f789ed76f0b82e7277de21b2b0161005b47778f22f76b29f172f9a4b1f295f864fd22098de56f31dd315af21930fefd1ab6f1eb37a892b78b9c1b1595ba00"
    );
    ( 16080,
      "81d6764847adf5155ef65568ab8f6fc6b6fc474dd7501d9e04e7c8e906ebcb9b8549b477bc0c10a82b29182f68eb30900da59b4dcfaaec1e91741e8ffa6ba0097c78527029d69922f5563b2097721b42db41de1cab5432dc3ac07eb7a7bb9185"
    );
    ( 16128,
      "b66090a8a2f1f229a3e6f00e6a9faa76b8cfc0fb936cae82cff24abd768a0444b73e80a4ebe0645020f74062d88ebe6f033952f9755d6036aff8e07c105d7abe1fd97a662197cf2c6801baa5a1afe1f40f44916a37cf0299d0f0122b040de41b"
    );
    ( 16192,
      "924cd3c575d3c6b8269aabc3bd01735c0404a45b1bb82ee818a0e616524be143936f5bc2c8296d28f8dcccf111e932ce1571fa8e01940e576dc72d963897aa390a459f3b578c01a15c34fbcabfe3caceaee62cc50da05e2d3cbf2e144b280ff5"
    );
    ( 16208,
      "a9601ddda22a9d1824bb064b5b27a2bb98c800ea964eec5031e9024bbbaf9b35984a81397591549a4fc424cfd887eb2901602e740b33a4cabacf30235ce3fa72931cf0a32aa919441f73d5fe020f061339e94322e1cb0993afe5bbb3d677e0f2"
    );
    ( 16232,
      "8b4bf55389daa61c8a1f19686290f8c839bf7a16241fa14e25749f71dc853d1bb4268e7cc03b5bad8af9a3ce09274c3b05541ea95aaf13c29614bed2befe517875b8d49b34c1c1544d82a65e5f0ef9cc5463c441773156c4e186d404db7f849e"
    );
    ( 16256,
      "a1a784eb7507c30e8fd6408e8afea4c87b472e265e831c3a54e6c21ff8f8b23ebde443b74e3548959adce8a86b6a702e01d3fcc4afb97a90e956252378fb4a37b3c9b0f8262cdab6c2276fd84ecfa3700d59ff1b22df443e99c519f4b236030e"
    );
    ( 16288,
      "8c9eb6c69273123d09cf7ee4890bb28f01ff01a5317cb1730ecaa96547f459c5545e298cd67e6f72f76bd9c1e8773b4102835c98dedf6a39e6600786e9e2aa920d5dd00ff2deb4aeb790d756add8efcd618a8c1c42edcd3470987f684a2310c0"
    );
    ( 16296,
      "84c001111e5a54e3fa38a2b03b9c4e3e990e0237902a748b0b509ab4fab76d9770eb91f96d78bcb9ab22e940f19b0ea40b856d7bdf6441628f82210f08a4ba9e457d19f6b2e0e3c7fc414a01d42276afb4765e6ce25c4624db68b646596130f0"
    );
    ( 16308,
      "817e4f0caa784d330a251ece6ae58113a4746f402d57f09eef75a7fdf4c740fb968ba3993b1e82fe4c185ba437fa5eaf029c2ad453efa4ccf8b9f72b200b533925c38af8b5073863fdc4e10228f2ab3793e3df7c0b778e11e7bae53feaac83ba"
    );
    ( 16320,
      "a479ae8fcd75a2b321aad1c885047391fdc4173379a47f84aa23eba1f42bab02ef103abcbc236d81c76b1b80f02399591668c6622d68885dc710b31b46376f12f3e4302837d9abf9e08d7a5236fcfe8196822039f687baca78656330b0eb184c"
    );
    ( 16336,
      "95882b18da7b5849a6cb1b881e5c40d0d50878c678b70b15a26cbbb5cf0c706487fc293a5c83d65ec12339f5c889c17c0d37f4d203ab2cb3ec371d323d88f1e8c3209e98c9c3892f48134bb817da2b93561ebd1ef1a6b5130cbdf4e242298cd6"
    );
    ( 16340,
      "90b31d0372db82c5bfff3e51693fd197e02f84aff7a6bdcfa9ef587970d36a8fba656c26df1e1ee9ac438a189d99b2df0dbc820ba3e414cf60d7cc8af96ceea02b95436aa0342ebe15193b4f8a0e5bef1036187d1bfbbf3878fcac144fb06a6f"
    );
    ( 16352,
      "8ed9e5879b2ad77b07d187d82b739822dd1850b84173e89437a4747ed3bb83cc3d27f2f9fcfb4c7c089eddb57dd3406313c915439c70e3691b2c376a6d61242e36c8c293c9127b0d958a4e51aa851bdcf276da42e5c6b9518ea3d0e8bdd1a86e"
    );
    ( 16360,
      "8967dadcf9febdb229adfc9c31ec22aefdb63eaa4a691857c3ba1e990a14acb155c2ad9f309dc53813bb3e068435e23a19b7384195b5a5a6a3188977d22f3d560c2138595bc1d84a0b9c517d61555fb0c5bd95a31581e9da2a3fdab3b1be5650"
    );
    ( 16368,
      "97cce6d71b0f50212b338304cc644804a3074b531a399e9372c7131b23d06ed3ae950ac632adde62c0d7bbc61f9aa33c014362bd50839686e8b8cdd8c011671208f610a704ab333136cdcc9393194615c4b5e98c1b48e9106c1465839ad97a53"
    );
    ( 16372,
      "a1374f75b26813492c607f1e974980904de670dc63073f1893c534361fa55ac10503b24397e06d20dc756143a86e98750648192528e7337f04e971bcea4e4b3099611547ce8c00b9fccee750bb4b42d5a0a5def92cb68fb68aa5177740eeecbb"
    );
  ]
  |> read_srs_g2

(* let get_verifier_srs2 ~max_polynomial_length ~page_length_domain ~shard_length =
   let srs_g2_shards = get_srs2 srs_g2 shard_length in
   let srs_g2_pages = get_srs2 srs_g2 page_length_domain in
   let srs_g2_commitment =
     let max_allowed_committed_poly_degree = max_polynomial_length - 1 in
     let max_committable_degree = Parameters_bounds_for_tests.max_srs_size - 1 in
     let offset_monomial_degree =
       max_committable_degree - max_allowed_committed_poly_degree
     in
     get_srs2 srs_g2 offset_monomial_degree
   in
   (srs_g2_shards, srs_g2_pages, srs_g2_commitment) *)
