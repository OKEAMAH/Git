(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

let proofs : string list ref = ref []

(* Each serialized proof is added to the list with a side effect, so that it is
   easy to generate (or augment) this file by instrumenting the rollup node. *)

let () =
  proofs :=
    "0000007b030002db10db4d3b595f59e0b53740f164bf951bcfae9e0873fd23fbce82fac4f404e1126f1b6c5546a5aeff4f59893ab63211a80e6f88e11b67339186109bf569d74a820b626f6f745f736563746f72c8baff5f78423676a25d9cd27a412dd932327b9b3e1cc26e754a36410a5efbf7b406737461747573c0010000"
    :: !proofs

let () =
  proofs :=
    "000001e2030002dff7b99fc09bd426898107f2a430633c61dde3863a0e29a795826f064d838b4a344b4f2d13d32e6bf10caf9a59ed667666d644bff87fb5ce85243fe46a62d0d400110007c094fb4ab02d1eaeebb21ddb7da4996ab4663db3e1d7b227f2c501aa13ced50e300004c003c40612363f2296a21ab5f72bd8106d16f1189d2512533c14fe023fe2a9505b8204636f6465d04e8c2629e50b60cab76e6c91232e771d142ebcb0467889de40e2a27c168a5591086d65746164617461c01901073e4cb15d82dc12ed63e0f86679a085a8bb3d9400000002000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc00176820b626f6f745f736563746f72c8baff5f78423676a25d9cd27a412dd932327b9b3e1cc26e754a36410a5efbf7b418696e7465726e616c5f6d6573736167655f636f756e746572c00106810d63757272656e745f6c6576656cc0040000000400050003810f6d6573736167655f636f756e746572c00201078206737461747573c001010476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765edc04203ac25917e1d6ded20b0a57bab57da15ba6edfaa63b5c885c2c9985ddc2265ff0000000004070000027b0000020d11e1cf8d8d6637edc27e04a3b6861fbc06336c950314d2f0be3a19bebdd873f47400000012000000607e9df5467aa1c14b8482c20a3e29168879697801892fbb1e896a89904ec1705fc999d259dc5ef030f190d45cfd7e4e503b2b2cad3bbd87b7f481dedbb3bf077fc999d259dc5ef030f190d45cfd7e4e503b2b2cad3bbd87b7f481dedbb3bf077f0f868a1d495f0e46265daaf4edfcc451fdd0e4d178c96807f775b68686e4b6c3ad0000001000000040c8e206c6092f3b50cef178a5ca373722684bf1d4bc4e6a3cf6f18ec8977c4f9ff7f922f475e8ee6eec9078395a379a2a1b905caefc92c75e9d474b8ff7f421440b0bd6c62766cfb2a314d827cead108848c389a9f7d824f5b6baa6920d74757b590000000c0000004020911b9f0a604aa0a669c82cca6015a73e06da67790efc1622e905d3cc7deb0441be5bf60ef04d6806f946483d16974c847e13696b97a5c57679e77bb43ebd520750eb5f108b13387d9bf493d38655d4e49e92958b296b50e11c91ecc37338f0240000000800000040f624258bca6f66863aa5dc00d781a68d01617a4e57c7eeb571586cfd5d4fa42feceb7013cb9a3709f1fabd85eeb1d29f94f01fae86ea1bd48b96d9dc5f2c6e06037aea153e62097eb669959c79ba91e715db84e411ffffee26ee17415e14f9adaf000000040000002033a66cd216417b22be5ff5b40a2884efd21b41ba30710151c8c8b631f78d872900000065078f1f9fd0816a310a79d0e0c4bf605a544c260c561740bcdeb175ea46f5312890000000406aa2f7281c84f94013408e9be51c00f0c269a9e0168bc4e1487f8bd158712b2a0223eb4ac4e1f8d91f67b451f8368483543437958eb47c656650b141eff001d300"
    :: !proofs

let () =
  proofs :=
    "000001e2030002dff7b99fc09bd426898107f2a430633c61dde3863a0e29a795826f064d838b4a344b4f2d13d32e6bf10caf9a59ed667666d644bff87fb5ce85243fe46a62d0d400110007c094fb4ab02d1eaeebb21ddb7da4996ab4663db3e1d7b227f2c501aa13ced50e300004c003c40612363f2296a21ab5f72bd8106d16f1189d2512533c14fe023fe2a9505b8204636f6465d04e8c2629e50b60cab76e6c91232e771d142ebcb0467889de40e2a27c168a5591086d65746164617461c01901073e4cb15d82dc12ed63e0f86679a085a8bb3d9400000002000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc00176820b626f6f745f736563746f72c8baff5f78423676a25d9cd27a412dd932327b9b3e1cc26e754a36410a5efbf7b418696e7465726e616c5f6d6573736167655f636f756e746572c00106810d63757272656e745f6c6576656cc0040000000400050003810f6d6573736167655f636f756e746572c00201078206737461747573c001010476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765edc04203ac25917e1d6ded20b0a57bab57da15ba6edfaa63b5c885c2c9985ddc2265ff0000000004070000027b0000020d118c4447d72cefb932b0ca79afe7e83680a3f5f940af12e510130890de093704e600000012000000608dfebf6bc80d3a6576db8bc05fdca115f1792bc708889f6c1e426a8fba62e41aec379b342e355104630c030f9fcdb2b45c8c1095ab4009aca365bceadabdcfb3ec379b342e355104630c030f9fcdb2b45c8c1095ab4009aca365bceadabdcfb30fbb838b70dafcb73c9fa937401a6b33dd4da8bfb1cc13518986029bd37814e280000000100000004069ef7e20a1f91d679504ab5a48899eec79e079a45f91939f0221a7a508358ef290e46fb7603c1723c2f698460a79f1e9642c1169fa2958961a87a74b9ff9e6430b480a065cd7198a5dc043acedef20e46dc7920c8592cca659cd961f5ea1dd90f00000000c000000406d802c5daf40c7215b73280efba85f67f0cc5747fcd2a0fe2328b5fdc252fd646920e1ffdb78b41f97546e80ad8a7287a1ba422057cad6f65c86c62a472aacfd0787e2b620f5c09d654e85e713d546450d660fc4988c658ddd3914d4bfc699d5cf000000080000004081b3c6ca730810be90b2f5ae9c4886e511f31933be84c0ac30af3b49b61fcdbfca6edbc188119ab8cf16b9e116af5f5a1de725fbaff2804f2508262b8d5dbc5a0347b79ca5ad4b09f9d7e9ead9854c082b664e51fba5558f2830fde4a5762367410000000400000020a17b14300c882553060d2694e5189fb3d86a998504248a47f4d359a29d2d6d6d00000065078f1f9fd0816a310a79d0e0c4bf605a544c260c561740bcdeb175ea46f53128900000004086f216dfb0131becbcc6a7a7e901db744c5030d09830fa3bbd5d0690eb5e2ec36877e8620a9491faa4d1a7c14b9fa50c394d69f699d239c1dce145d86566b49c00"
    :: !proofs

let () =
  proofs :=
    "000001e2030002d83a6fcbfa317ba868d42fae27ddce20ad903cbb357a1b16823a14bce0631d733bdcad893d1ec690f5e7f44b73cc9e7a9119eda7942d6776b70b02b8276cdfcb00110007c0f16246649211503c309f0679ac228a4c510e90cf699d0dd1c71123465e3b1f340004c003c40612363f2296a21ab5f72bd8106d16f1189d2512533c14fe023fe2a9505b8204636f6465d04e8c2629e50b60cab76e6c91232e771d142ebcb0467889de40e2a27c168a5591086d65746164617461c01901073e4cb15d82dc12ed63e0f86679a085a8bb3d9400000002000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc00179820b626f6f745f736563746f72c8baff5f78423676a25d9cd27a412dd932327b9b3e1cc26e754a36410a5efbf7b418696e7465726e616c5f6d6573736167655f636f756e746572c00109810d63757272656e745f6c6576656cc0040000000500050003810f6d6573736167655f636f756e746572c00201078206737461747573c001010476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765edc04203ac25917e1d6ded20b0a57bab57da15ba6edfaa63b5c885c2c9985ddc2265ff0000000005070000036d000002ff11fc6cf0426308d2bffb18bf2b478124887feabcb245cd6b0b9e129588192a54c40000001200000060b12f07c7d9af455f96ddc30c0006cae6a47d4012a1d9ee52381a6ac466b90282a6d0f8cd48d167078b8277d8ea52a7a2b289c1cd57253953d8152987bf527508a6d0f8cd48d167078b8277d8ea52a7a2b289c1cd57253953d8152987bf5275080f064a0994f5eb055ea8e9611989f2af420bbfd91b1114f92f2bc12fe6b7a0cf0e00000010000000406036dc7a4a6e3dd4d7c53e1d31f3ca11949539681aef75c98a1a6e99e5c8023389e71f2788c0928cf48c78e78f4262386d05c26b7afd22a9e8b825bb2641d8140b687657f959d8f4d09d4a5d0dc02a92fad1d4c0c1834cfa52de824c68b71e82220000000c0000004099e839e62f772ca0b40026794b9e375dc254545aa597b3ac92f5769b64be931b59946ddfb2e26dd43fb1b183e13a0676055bdc96c9afec634562f967c16b17a3078d3709187faab160b53420e44f31bf89247940d19c42e0ffb8f741c31eedf49f0000000800000040d02e518af31bb716c6c2b217d488f919a9c358985585a9bc36764e49b1a06d83787ada119155f533cfd8ae0dcf26eee797ad414c4a9cfd77e5bfb25ad9db49180646d0cfe6a53bd991515525f0b69234f6bd255e13f2268b0e7056cc9749fe96a80000000700000040641a59b4d74772af88bd26b01930fdc833e4da32a6a8b134a83eefd5a891c67f787ada119155f533cfd8ae0dcf26eee797ad414c4a9cfd77e5bfb25ad9db491805e3292cfbce3f99c456c357448caf12dbb8d94ae727713e76204070ee7f93ec6f000000060000004025cc6a901f1677467a5effacdbea5918e4fe1db847ca23aa2d32a6009f4e49c3787ada119155f533cfd8ae0dcf26eee797ad414c4a9cfd77e5bfb25ad9db491804440a917893d879e6d120791d6f3686ef0e138f1aafa4218b9f2986f3e6fa83c20000000500000040787ada119155f533cfd8ae0dcf26eee797ad414c4a9cfd77e5bfb25ad9db4918787ada119155f533cfd8ae0dcf26eee797ad414c4a9cfd77e5bfb25ad9db491800000065078f1f9fd0816a310a79d0e0c4bf605a544c260c561740bcdeb175ea46f531289000000040d5177419909a1fbbf44e4d765d6fb055eade688bab86c66f22464dc90d9646a9136cb726c83432b2cf178eb3b1a1c32245d8b30adcc01468dfdd84665824dbb900"
    :: !proofs

let () =
  proofs :=
    "000001e3030002dcfa6603288699daee959046196b807c6802422775a28aefa8955743b22be772b65ed549e8fc86fd1b0e4bfc2fe2e3562fa78bca93b48a46450d259daead220400110007c001fdc52ab8835ab29356f398abd306ece6190f2832649449a075fa02873be7870004c073b11921186a3ad9f169f3ce0b2f80b767ad931ff6e7828e8992ba73b3e72b918204636f6465d04e8c2629e50b60cab76e6c91232e771d142ebcb0467889de40e2a27c168a5591086d65746164617461c01901073e4cb15d82dc12ed63e0f86679a085a8bb3d9400000002000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc002b901820b626f6f745f736563746f72c8baff5f78423676a25d9cd27a412dd932327b9b3e1cc26e754a36410a5efbf7b418696e7465726e616c5f6d6573736167655f636f756e746572c00112810d63757272656e745f6c6576656cc0040000000800050003810f6d6573736167655f636f756e746572c00201078206737461747573c001010476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765edc04203ac25917e1d6ded20b0a57bab57da15ba6edfaa63b5c885c2c9985ddc2265ff00000000080700000232000001c411de172a5abce9a9a316b4d55bddb1f6208bd58546a42224aae7afe87e75103fbe00000012000000600babc274ae5da75f613af0b96c064841dc055fb086c7aee7c5cf59afc7a3c5eadda87e4df1828b9f40e4b3ddcb69903f1eceed5b45f796d5793a2406fc77a1e8dda87e4df1828b9f40e4b3ddcb69903f1eceed5b45f796d5793a2406fc77a1e80f96b234fd8fb7e2b70e9a773d91932d11a8cd2f58c5cff42f7756b4ae5982d2b00000001000000040a21c42cf974f22f9eeddc1cca859cee5e7e74a1d98571b4a48e78a70c867d1e99ae8cd149c8d4389f819cd04167e27b5339537f99a0ec1821b6fff92a92659130b29a8d6c8b6b112bb72dd52f8d68224a240340ebc707053997e1d140cc1625b090000000c00000040b982ce951ef7e4ddca7c1b9371d3dfc7840c1a5b661cdf28d0a727d3a34055fc2ddf903372525d24bca2cb46409f65960a1bb7dec7d4d3cf6107e6bed52c5a62079e4bad092eecab56a6945c7223ec0c7622d91724b7a26106b9bf3efbb0285e960000000800000040803d9fb1c0a3d81cc4806db2b519321bc7873a5e44dcc10f5948b47fc05ff827b0a464db5c39fe5809e2509465b36c17e24c18458175551c746256f129c6882000000065078f1f9fd0816a310a79d0e0c4bf605a544c260c561740bcdeb175ea46f5312890000000402f0b8c5524863a7d8b851a05f51888de954fd75bdb39638fba73bee6cd9f848238b7acf195d72a42ce6594d54911c2d544f581288c71502550916a1a32088f4100"
    :: !proofs

let () =
  proofs :=
    "00000214030002e077bef17af38499b44807fabde3837e2355f4988146b065236bac172087929e24bc4324adefe61ff70a912adfce146400586b408d46b371c287b5df9fcdba4000100006d0030170000382066f7574707574d033ba419fa9cc8b769d0a76f2839bdaee68f7e12566131d1edbebaaa1e12169900c7061727365725f7374617465c00102c0fca618d8cfb53c29e8b61bcf584028571b6b1f563e164df093810f07a93265060003820c6e6578745f6d657373616765c0060100000001310e6f75747075745f636f756e746572c00102c0322d95cbadd30a23603872646abd7b0d341c5f3eca8f39da9da74bd3264d9775000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc00179c03b85b8bcac7168100efeb43114a4679d17808ab9309d16a22be916283fbde863c0d22ceeb53dad5d5a36f1caca13fb2cce988bed6679f7370d0d2e5aa042c6556c00050003c0cb0d5024ea71731c4142bd8b8ce738c9d44298b45ccc3d4fc2717db8d4eb78068206737461747573c001040476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765ed820c6c657865725f627566666572c00800000000000000000e70617273696e675f726573756c74c87a31b1c8e3af61756b336bcfc3b0c292c89b40cc8a5080ba99c45463d110ce8b00"
    :: !proofs

let () =
  proofs :=
    "000002a7030002d918c66aa95d5080874df90faea75962fc4a4443996f8a6be3996739f9a2008804940e7d9453c3a83f99858741988f1b5056f21295ae698df95731c1ca00d70a00110007d0030170000382066f7574707574d0772e6802b1bb0a8f0553b122347b071e426307db4a54ca247a479f51d20c91170c7061727365725f7374617465c00101c0bf2d23e703638502856d46d16407070d7c47a5af5f5e33daa4d46a2d311eba870004820c6e6578745f6d657373616765c8794bebd4366203e527989fc7421c01bfc2976975f118a341ac007b5e0f53a1180e6f75747075745f636f756e746572c88a7ae305885619a2566d1c7fd87e3d67444fb5ce517a8fca5bee68a4061997ed8204636f6465d04e8c2629e50b60cab76e6c91232e771d142ebcb0467889de40e2a27c168a5591086d65746164617461c81bd59bb6258d782bad96d2164548403ee6b50359b81a885f3e11b988dfafe3ae000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc002ec01820b626f6f745f736563746f72c0040000000018696e7465726e616c5f6d6573736167655f636f756e746572c896f1f45bb65c0c32557f9a65d161156b248f2a1e62e1678892300949bd0589a2810d63757272656e745f6c6576656cc0040000000700050003810f6d6573736167655f636f756e746572c00201018206737461747573c001010476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765ed820c6c657865725f627566666572c8a8b484dd0c8b746c1a15618f6fb51a7b37f8c275afc6499d9c524fa0fbb743cc0e70617273696e675f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905ff0000000007010000032b0000022d112216fa511da8cf0ef50a29f5990dc65135aa9a72d1a686b2f1aba0bbdc1710f100000012000000608e03cd7fd0e4aafdb620093525a182431bc198b0ef56218f6e4d1253787df95c4f152285b05c88d8cbd414385df68dc0038a0949a6a2150a5835b64f620225404f152285b05c88d8cbd414385df68dc0038a0949a6a2150a5835b64f620225400f7c5d2e20abd394499b89ff0f01f8ca785cd4b83ac033a2b72bf6fc3ff6f72b76000000100000004030548b2d65eed411aab93a1050898da8b6560560efdeb6f5352ce25edf8990a1033e7e19ba33f12cc42a917f19767d2b0e9517855f905ce9f9b03edc4716511a0be7bc438063c29553e43fc7e0ad8672f2e47bac5622849003df6b29b11a01d4250000000c0000004003ad25557b67a5b5b0d5f484d69b5639d49290e57edbbcfab845a44c6d3caccaccc0ac98c43158ffc5dc55d3370c6a0d95e6f282b3f5c6c9bf924803f603636207797fef9633643ebdee8710d2481f2fe58af4201ef62570c79c1370f48108b5940000000800000040b69cf6e3364934b1d8e2f45152c899f1f787713d362b2d0962e5d2ed603b56f1722208556ce9c4cdffc91825b29d757bd81ef39b074b03b0afb5f9dd6f5601ee06c14c15749c2323c5571de585825120b0fcd8eaeffdbb3f38908581308d0312170000000700000040eabbe433d155ea8739a38e9c24bcfc7e23f4f3d69bdc9bdcb75ed722a605aa8a722208556ce9c4cdffc91825b29d757bd81ef39b074b03b0afb5f9dd6f5601ee000000ef078f1f9fd0816a310a79d0e0c4bf605a544c260c561740bcdeb175ea46f5312890000000401fb49ce2d7b7e3be61d2b4ca1774aa4740a1e1d12413f4a2a7597a9374645d422c20099c6029bbaa5a7cdeec1e3ddddbc5e4630af0ba11554535f657c27e38de035efc3165465aff68d3e5bd549d711f9e0e06e786bc1d6873f2e7e4faa43bbe130000002030cc84dad07aa536dbaaaccba95d4dabd7c5d6c6ca411372ca9326afeae3eed30228a91be1e75d0b3a4f6634ffbe25947d0bd042d41d1ab2f2a2a7d81b564312c000000020b384576e8dfeacafe447c7555442ed6057ec637adc6d72a1863b5e6a8094adf8ff000000020131"
    :: !proofs

let () =
  proofs :=
    "0000021503000204940e7d9453c3a83f99858741988f1b5056f21295ae698df95731c1ca00d70aeb9288624e864a8aeecbb882b30fa04c28830cd6331d1697fd6d78570a47f43e00100006d0030170000382066f7574707574d0772e6802b1bb0a8f0553b122347b071e426307db4a54ca247a479f51d20c91170c7061727365725f7374617465c00102c0bf2d23e703638502856d46d16407070d7c47a5af5f5e33daa4d46a2d311eba870003820c6e6578745f6d657373616765c0060100000001310e6f75747075745f636f756e746572c00104c0322d95cbadd30a23603872646abd7b0d341c5f3eca8f39da9da74bd3264d9775000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc002ed01c052c196fbe4546e163fd1d777dfb388cece157a88fe10cc0e1ae48aa053fac3fec0e0590ca6ea22f7dabe3889c02d87873535203b5a450ef9e5ce102d2f99d8c0b800050003c0cb0d5024ea71731c4142bd8b8ce738c9d44298b45ccc3d4fc2717db8d4eb78068206737461747573c001040476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765ed820c6c657865725f627566666572c00800000000000000000e70617273696e675f726573756c74c87a31b1c8e3af61756b336bcfc3b0c292c89b40cc8a5080ba99c45463d110ce8b00"
    :: !proofs

let () =
  proofs :=
    "00000215030002f677d054c8e623d1b22ecc8aea74f5074bf0c9529f898cac90db26a3992831d77b74a66258cc09c792da869b9b3bc683e35d9583c4206adc20d3b0296245408a00100006d0030170000382066f7574707574d0d5983c50395ec6533657eccf10ccf8d9c4062ff6501c2074868953ffee9073830c7061727365725f7374617465c00102c0bf2d23e703638502856d46d16407070d7c47a5af5f5e33daa4d46a2d311eba870003820c6e6578745f6d657373616765c0060100000001310e6f75747075745f636f756e746572c00104c0322d95cbadd30a23603872646abd7b0d341c5f3eca8f39da9da74bd3264d9775000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc002f301c01c1fab5de0181afb420733a2d6b0a12ce0b70c494b7dfccff1e2447eee86380fc04607fa9b3ac608330ef58339fb3dc505880bae0b9fae4f3f10ff9f8534a3856a00050003c0cb0d5024ea71731c4142bd8b8ce738c9d44298b45ccc3d4fc2717db8d4eb78068206737461747573c001040476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765ed820c6c657865725f627566666572c00800000000000000000e70617273696e675f726573756c74c87a31b1c8e3af61756b336bcfc3b0c292c89b40cc8a5080ba99c45463d110ce8b00"
    :: !proofs

let () =
  proofs :=
    "00000214030002e077bef17af38499b44807fabde3837e2355f4988146b065236bac172087929e24bc4324adefe61ff70a912adfce146400586b408d46b371c287b5df9fcdba4000100006d0030170000382066f7574707574d033ba419fa9cc8b769d0a76f2839bdaee68f7e12566131d1edbebaaa1e12169900c7061727365725f7374617465c00102c0fca618d8cfb53c29e8b61bcf584028571b6b1f563e164df093810f07a93265060003820c6e6578745f6d657373616765c0060100000001310e6f75747075745f636f756e746572c00102c0322d95cbadd30a23603872646abd7b0d341c5f3eca8f39da9da74bd3264d9775000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc00179c03b85b8bcac7168100efeb43114a4679d17808ab9309d16a22be916283fbde863c0d22ceeb53dad5d5a36f1caca13fb2cce988bed6679f7370d0d2e5aa042c6556c00050003c0cb0d5024ea71731c4142bd8b8ce738c9d44298b45ccc3d4fc2717db8d4eb78068206737461747573c001040476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765ed820c6c657865725f627566666572c00800000000000000000e70617273696e675f726573756c74c87a31b1c8e3af61756b336bcfc3b0c292c89b40cc8a5080ba99c45463d110ce8b00"
    :: !proofs

let () =
  proofs :=
    "00000214030002e077bef17af38499b44807fabde3837e2355f4988146b065236bac172087929e24bc4324adefe61ff70a912adfce146400586b408d46b371c287b5df9fcdba4000100006d0030170000382066f7574707574d033ba419fa9cc8b769d0a76f2839bdaee68f7e12566131d1edbebaaa1e12169900c7061727365725f7374617465c00102c0fca618d8cfb53c29e8b61bcf584028571b6b1f563e164df093810f07a93265060003820c6e6578745f6d657373616765c0060100000001310e6f75747075745f636f756e746572c00102c0322d95cbadd30a23603872646abd7b0d341c5f3eca8f39da9da74bd3264d9775000a0005000482116576616c756174696f6e5f726573756c74c8eda4dcfc891aa48bb021d3ed729b7efc072bfccb367c623f60ed227bc4de4905047469636bc00179c03b85b8bcac7168100efeb43114a4679d17808ab9309d16a22be916283fbde863c0d22ceeb53dad5d5a36f1caca13fb2cce988bed6679f7370d0d2e5aa042c6556c00050003c0cb0d5024ea71731c4142bd8b8ce738c9d44298b45ccc3d4fc2717db8d4eb78068206737461747573c001040476617273d0c8883069b5a30e9ece9f91b68e759f1909bed7c0ccc0f1a3aee8d2d8473765ed820c6c657865725f627566666572c00800000000000000000e70617273696e675f726573756c74c87a31b1c8e3af61756b336bcfc3b0c292c89b40cc8a5080ba99c45463d110ce8b00"
    :: !proofs

let () =
  proofs :=
    "000001af03000203fad519c60ce458d8173d60347a7165a47f94f34bb09563e3f916508a568ae5160daf16732031127d85916da8a2b2ed0b80e2ec6f76aeb5aed05f20e29535aa0005820764757261626c65d0700600b5ba8846f05688abbc84be210e9841df14210b69ecc81768bc2d7fa5be03746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00100196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e707574820468656164c00100066c656e677468c00100066f7574707574820133810f76616c69646974795f706572696f64c00400013b000134810d6d6573736167655f6c696d6974c002a401047761736d00038103746167c00b00000007636f6c6c656374820c63757272656e745f7469636bc001000e7265626f6f745f636f756e746572c002e907ff02"
    :: !proofs

let () =
  proofs :=
    "000004a20300029154c3457e545055d89ece682b7699aa6468646bc118d31183e606af03c8720d8fdb2e43063ba2e4eb6227939439718b119ff743d5c7f1c0cb53efca9290cebd0005820764757261626c65d0700600b5ba8846f05688abbc84be210e9841df14210b69ecc81768bc2d7fa5be03746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00100196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e7075740003810468656164c001008208636f6e74656e747300040003c0a06eb14bc76138f3404aa3d1907e8ea56cdcab66fd9774fa42ceb0b5db70f3678101330004810f6d6573736167652d636f756e746572c00103000381066c656e677468c00800000000000000028208636f6e74656e7473810130c102000131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000097261772d6c6576656cc00400000003810131d02be9203590ff323f40bb2e6123792ea6fe582c3004e90f2f07e341c357bb256f066c656e677468c00104066f75747075740004820132810a6c6173745f6c6576656cc004000000030133810f76616c69646974795f706572696f64c00400013b0082013181086f7574626f786573d085c221543585cc73785d90b8205fb70e0ff5fb3ec7cfb237c9de35507cdb04f70134810d6d6573736167655f6c696d6974c002a401047761736d00048205696e707574c005000000030303746167c00b00000007636f6c6c656374820c63757272656e745f7469636bc001040e7265626f6f745f636f756e746572c002e907ff000000000303000003fd00000256119e0f517b258ebaafc3b80f9580736196820e85a89a8b1dbcabc188dffb3c202e00000012000000609d64ecb31e24cbae9bffefb6398aeddbf63848d77a09f8abe6ec870520e52824f5ac4a20922d7f69815f53f2bc1d7e814237f7671dddb9b1da294c2dfc4c71def5ac4a20922d7f69815f53f2bc1d7e814237f7671dddb9b1da294c2dfc4c71de0fb08d67fcd4ee0d497ddf6d75ac8e18dc4828b7eaa24c9bab0d177ef15c0042f100000010000000403918d146062923546523ea77f9f279659b3ef195d3b078438f982c027b1d8917a9d39f2691329b1c8c9f7d42b4ebb7dafd332674e52f8abe2a1ab969e64e2fe50b7a898bab55e92ba1d139db2630c207cf08d698cd0a45b87d4f31ad0f863208db0000000c0000004007f78428e527a26c52b3663fe94540c0dcebc5c06812ac73483dc9e163aba6054734bbd10c6f776cfc899e2ed68c9922c46761ddaef39a7d6ad74f51db9a6ba007c33fc08871ca22ec9f40c437074d7c036c0f7f73847d1c06c9a17e1996b7d9440000000800000040b9229c6473b0774f80374639e5a5d67d9cf2a44a3791e716cd9c344158f95d43d1bd41e8f0d23a94f58094dfdd6138fd1789f68a675fac5315ed813d38fa5b9e0364a4a59f6b439e7e70cc6a3db142f3389ebe3c825c0e6415880ce60e4983db260000000400000020426a3cc0ad6a52091e3d0e0db02ee1fcd56f50c46b7d292502485c175d63c9b9020a5f043148e900d19d02f79abf24b4bd582f6e93abfb9bd8c988eaf75408af3a0000000300000020ed9e0e19c20a3b721dab18672f6970178470220ead77baa226397a08bd7e876b00000194078f1f9fd0816a310a79d0e0c4bf605a544c260c561740bcdeb175ea46f531289000000040157503c39a941b28605440c02809ba0c46e7d2f467898c8fb686ce2f3b2468734dd4e700aae1d5046368abd3874e2381a67183a76ee0c0d4470980a6b26c963006a1d6ed77f0922b69266702ace9a97f218b0b5d575e2bbe6a6b01b9412d8c58a000000040c8f36f8363b363b45329f572116fba1982f4d2d733dc6f8088ff3a0157b931874dd4e700aae1d5046368abd3874e2381a67183a76ee0c0d4470980a6b26c963005474c297bef20ab15fb8d93783d324d6f07fb1a017891890f3b606bac241f144c000000400a5735bc6db3536eba3b549320c870fd51ee99747f79d5702cb3c5982224d3ec4dd4e700aae1d5046368abd3874e2381a67183a76ee0c0d4470980a6b26c9630045efc3165465aff68d3e5bd549d711f9e0e06e786bc1d6873f2e7e4faa43bbe13000000404dd4e700aae1d5046368abd3874e2381a67183a76ee0c0d4470980a6b26c96304dd4e700aae1d5046368abd3874e2381a67183a76ee0c0d4470980a6b26c9630ff00000006013120312078"
    :: !proofs

let () =
  proofs :=
    "000004a2030002833ec3c4a0325b95cebe5505e305cc43ff64e52411b9363fe287f55b2dbd84d5499a79571ba2d9e172052e13d1eac510810ac4eca1d5157a65782d50a84b34690005820764757261626c6582066b65726e656cd07d20c53bdd5b536a6be9c4cdad16e69a9af40b93a6564655fffd88bba050519008726561646f6e6c7982066b65726e656cd0a645771d9d5228a31312b282119c596699ccb6b60b93d759c2072a493ddbb5740c7761736d5f76657273696f6e8101408208636f6e74656e7473810130c10200322e302e302d7231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066c656e677468c008000000000000000803746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00680f8e0cde105196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e7075740003810468656164c001008208636f6e74656e7473d029ca9b037bc58b2e8795cb5a78a9923e992ecb747d73aea69221f0bbf8862d9c066c656e677468c00108066f75747075740004820132810a6c6173745f6c6576656cc004000000050133810f76616c69646974795f706572696f64c00400013b0082013181086f7574626f786573d012db3a74b0a7328b572a034fb36111e11ca8db9beeee251c1b636e62b1a369500134810d6d6573736167655f6c696d6974c002a401047761736d00048205696e707574c005000000050703746167c00b0000000770616464696e67820c63757272656e745f7469636bc00688f8e0cde1050e7265626f6f745f636f756e746572c002e90700"
    :: !proofs

let () =
  proofs :=
    "000004a2030002b45db06e873356846dc9bec6df51256edf0ede76c2c4c1fb856ff62a1dd3a71bb4591da0e6a078af531c232280cb8e68554a1879eb6a9e4308c006395fa45d770005820764757261626c6582066b65726e656cd07d20c53bdd5b536a6be9c4cdad16e69a9af40b93a6564655fffd88bba050519008726561646f6e6c7982066b65726e656cd0a645771d9d5228a31312b282119c596699ccb6b60b93d759c2072a493ddbb5740c7761736d5f76657273696f6e8101408208636f6e74656e7473810130c10200322e302e302d7231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066c656e677468c008000000000000000803746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00680f0c19bc30b196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e7075740003810468656164c001008208636f6e74656e7473d06a600b954d7302fba4b55875e6025671f6e6364ed0514556b0554107b4c2d245066c656e677468c00108066f75747075740004820132810a6c6173745f6c6576656cc004000000070133810f76616c69646974795f706572696f64c00400013b0082013181086f7574626f786573d0652e374ff90771cb8ec84a7106d62b8cf29b46632699c378aec1afc4aceb3d960134810d6d6573736167655f6c696d6974c002a401047761736d00048205696e707574c005000000070703746167c00b0000000770616464696e67820c63757272656e745f7469636bc00688f0c19bc30b0e7265626f6f745f636f756e746572c002e90700"
    :: !proofs

let () =
  proofs :=
    "000004a203000298c8c12aa31ddb519d4848eca5b5faafafb686fc18232a7af3b9738eedbbf18b1b7a054f5dff5ac3a71c5b54d284633aa8390b7bcfcaad9f6cfab30466dc499c0005820764757261626c6582066b65726e656cd07d20c53bdd5b536a6be9c4cdad16e69a9af40b93a6564655fffd88bba050519008726561646f6e6c7982066b65726e656cd0a645771d9d5228a31312b282119c596699ccb6b60b93d759c2072a493ddbb5740c7761736d5f76657273696f6e8101408208636f6e74656e7473810130c10200322e302e302d7231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066c656e677468c008000000000000000803746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00680f0c19bc30b196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e7075740003810468656164c001008208636f6e74656e7473d095d3888221e81b7ccc795571fe150fca0b0b4f8fa6439bc3ad441f6677aa4238066c656e677468c00108066f75747075740004820132810a6c6173745f6c6576656cc004000000070133810f76616c69646974795f706572696f64c00400013b0082013181086f7574626f786573d0652e374ff90771cb8ec84a7106d62b8cf29b46632699c378aec1afc4aceb3d960134810d6d6573736167655f6c696d6974c002a401047761736d00048205696e707574c005000000070703746167c00b0000000770616464696e67820c63757272656e745f7469636bc00688f0c19bc30b0e7265626f6f745f636f756e746572c002e90700"
    :: !proofs

let () =
  proofs :=
    "000004a20300029287c2d0b68cd84c11b0950becf1f954cd26ea6661ce417ee1e871c85d42744a29e1c7e29367c4b40f7d63966bf15195f125a711a800b82f646cd7acc2ef818f0005820764757261626c6582066b65726e656cd07d20c53bdd5b536a6be9c4cdad16e69a9af40b93a6564655fffd88bba050519008726561646f6e6c7982066b65726e656cd0a645771d9d5228a31312b282119c596699ccb6b60b93d759c2072a493ddbb5740c7761736d5f76657273696f6e8101408208636f6e74656e7473810130c10200322e302e302d7231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066c656e677468c008000000000000000803746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00680f0c19bc30b196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e7075740003810468656164c001008208636f6e74656e7473d09488f46e420b9e6a86886b62f56f5be815250291de20e0bb901503c473029a24066c656e677468c00108066f75747075740004820132810a6c6173745f6c6576656cc004000000070133810f76616c69646974795f706572696f64c00400013b0082013181086f7574626f786573d0652e374ff90771cb8ec84a7106d62b8cf29b46632699c378aec1afc4aceb3d960134810d6d6573736167655f6c696d6974c002a401047761736d00048205696e707574c005000000070703746167c00b0000000770616464696e67820c63757272656e745f7469636bc00688f0c19bc30b0e7265626f6f745f636f756e746572c002e90700"
    :: !proofs

let () =
  proofs :=
    "000004a20300026c04959b2eeb9719f2fff009b30b1a3e056b2e303e00f30c6fa25649b2db6b6aa82b2e3cf2f36f0dbf44209528859e2ae36f77fc4cc844c91ec349a64e6f2c4f0005820764757261626c6582066b65726e656cd07d20c53bdd5b536a6be9c4cdad16e69a9af40b93a6564655fffd88bba050519008726561646f6e6c7982066b65726e656cd0a645771d9d5228a31312b282119c596699ccb6b60b93d759c2072a493ddbb5740c7761736d5f76657273696f6e8101408208636f6e74656e7473810130c10200322e302e302d7231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066c656e677468c008000000000000000803746167c00800000004536f6d650003810370766d00050004000381166f7574626f785f76616c69646974795f706572696f64c00400013b0082136c6173745f746f705f6c6576656c5f63616c6cc00680f0c19bc30b196d6178696d756d5f7265626f6f74735f7065725f696e707574c002e80781146f7574626f785f6d6573736167655f6c696d6974c002a401810c6d61785f6e625f7469636b73c00580dc9afd28820576616c7565810370766d8107627566666572738205696e7075740003810468656164c001008208636f6e74656e7473d02a07f402a57a796a07ac3ad8c832391cbf3b09435464e3c181c171a67ccf2dcc066c656e677468c00108066f75747075740004820132810a6c6173745f6c6576656cc004000000070133810f76616c69646974795f706572696f64c00400013b0082013181086f7574626f786573d0652e374ff90771cb8ec84a7106d62b8cf29b46632699c378aec1afc4aceb3d960134810d6d6573736167655f6c696d6974c002a401047761736d00048205696e707574c005000000070703746167c00b0000000770616464696e67820c63757272656e745f7469636bc00688f0c19bc30b0e7265626f6f745f636f756e746572c002e90700"
    :: !proofs

let proofs = !proofs
