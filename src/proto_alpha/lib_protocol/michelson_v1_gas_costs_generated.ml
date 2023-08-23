(* Do not edit this file manually.
   This file was automatically generated from benchmark models
   If you wish to update a function in this file,
   a. update the corresponding model, or
   b. move the function to another module and edit it there. *)

[@@@warning "-33"]

module S = Saturation_repr
open S.Syntax

(* model encoding/B58CHECK_DECODING_CHAIN_ID *)
(* 1600. *)
let cost_B58CHECK_DECODING_CHAIN_ID = S.safe_int 1600

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_HASH_bls *)
(* 3600. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_HASH_bls = S.safe_int 3600

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_HASH_ed25519 *)
(* 3300. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_HASH_ed25519 = S.safe_int 3300

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_HASH_p256 *)
(* 3300. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_HASH_p256 = S.safe_int 3300

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_HASH_secp256k1 *)
(* 3300. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_HASH_secp256k1 = S.safe_int 3300

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_bls *)
(* 79000. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_bls = S.safe_int 79000

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_ed25519 *)
(* 4200. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_ed25519 = S.safe_int 4200

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_p256 *)
(* 13450. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_p256 = S.safe_int 13450

(* model encoding/B58CHECK_DECODING_PUBLIC_KEY_secp256k1 *)
(* 9000. *)
let cost_B58CHECK_DECODING_PUBLIC_KEY_secp256k1 = S.safe_int 9000

(* model encoding/B58CHECK_DECODING_SIGNATURE_bls *)
(* 6400. *)
let cost_B58CHECK_DECODING_SIGNATURE_bls = S.safe_int 6400

(* model encoding/B58CHECK_DECODING_SIGNATURE_ed25519 *)
(* 6400. *)
let cost_B58CHECK_DECODING_SIGNATURE_ed25519 = S.safe_int 6400

(* model encoding/B58CHECK_DECODING_SIGNATURE_p256 *)
(* 6400. *)
let cost_B58CHECK_DECODING_SIGNATURE_p256 = S.safe_int 6400

(* model encoding/B58CHECK_DECODING_SIGNATURE_secp256k1 *)
(* 6400. *)
let cost_B58CHECK_DECODING_SIGNATURE_secp256k1 = S.safe_int 6400

(* model encoding/B58CHECK_ENCODING_CHAIN_ID *)
(* 1800. *)
let cost_B58CHECK_ENCODING_CHAIN_ID = S.safe_int 1800

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_HASH_bls *)
(* 3200. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_HASH_bls = S.safe_int 3200

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_HASH_ed25519 *)
(* 3200. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_HASH_ed25519 = S.safe_int 3200

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_HASH_p256 *)
(* 3200. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_HASH_p256 = S.safe_int 3200

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_HASH_secp256k1 *)
(* 3200. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_HASH_secp256k1 = S.safe_int 3200

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_bls *)
(* 5900. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_bls = S.safe_int 5900

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_ed25519 *)
(* 4500. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_ed25519 = S.safe_int 4500

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_p256 *)
(* 4550. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_p256 = S.safe_int 4550

(* model encoding/B58CHECK_ENCODING_PUBLIC_KEY_secp256k1 *)
(* 4950. *)
let cost_B58CHECK_ENCODING_PUBLIC_KEY_secp256k1 = S.safe_int 4950

(* model encoding/B58CHECK_ENCODING_SIGNATURE_bls *)
(* 8300. *)
let cost_B58CHECK_ENCODING_SIGNATURE_bls = S.safe_int 8300

(* model encoding/B58CHECK_ENCODING_SIGNATURE_ed25519 *)
(* 8300. *)
let cost_B58CHECK_ENCODING_SIGNATURE_ed25519 = S.safe_int 8300

(* model encoding/B58CHECK_ENCODING_SIGNATURE_p256 *)
(* 8300. *)
let cost_B58CHECK_ENCODING_SIGNATURE_p256 = S.safe_int 8300

(* model encoding/B58CHECK_ENCODING_SIGNATURE_secp256k1 *)
(* 8300. *)
let cost_B58CHECK_ENCODING_SIGNATURE_secp256k1 = S.safe_int 8300

(* model encoding/BLS_FR_FROM_Z *)
(* 178.443333333 *)
let cost_BLS_FR_FROM_Z = S.safe_int 180

(* model encoding/BLS_FR_TO_Z *)
(* 82.8933333333 *)
let cost_BLS_FR_TO_Z = S.safe_int 85

(* model encoding/CHECK_PRINTABLE *)
(* fun size -> 14. + (10. * size) *)
let cost_CHECK_PRINTABLE size =
  let size = S.safe_int size in
  S.safe_int 15 + (size * S.safe_int 10)

(* model encoding/DECODING_BLS_FR *)
(* 120. *)
let cost_DECODING_BLS_FR = S.safe_int 120

(* model encoding/DECODING_BLS_G1 *)
(* 54600. *)
let cost_DECODING_BLS_G1 = S.safe_int 54600

(* model encoding/DECODING_BLS_G2 *)
(* 69000. *)
let cost_DECODING_BLS_G2 = S.safe_int 69000

(* model encoding/DECODING_CHAIN_ID *)
(* 50. *)
let cost_DECODING_CHAIN_ID = S.safe_int 50

(* model encoding/DECODING_Chest *)
(* fun size -> 3750. + (0.03125 * size) *)
let cost_DECODING_Chest size =
  let size = S.safe_int size in
  S.safe_int 3750 + (size lsr 5)

(* model encoding/DECODING_Chest_key *)
(* 9550. *)
let cost_DECODING_Chest_key = S.safe_int 9550

(* model encoding/DECODING_PUBLIC_KEY_HASH_bls *)
(* 60. *)
let cost_DECODING_PUBLIC_KEY_HASH_bls = S.safe_int 60

(* model encoding/DECODING_PUBLIC_KEY_HASH_ed25519 *)
(* 60. *)
let cost_DECODING_PUBLIC_KEY_HASH_ed25519 = S.safe_int 60

(* model encoding/DECODING_PUBLIC_KEY_HASH_p256 *)
(* 60. *)
let cost_DECODING_PUBLIC_KEY_HASH_p256 = S.safe_int 60

(* model encoding/DECODING_PUBLIC_KEY_HASH_secp256k1 *)
(* 60. *)
let cost_DECODING_PUBLIC_KEY_HASH_secp256k1 = S.safe_int 60

(* model encoding/DECODING_PUBLIC_KEY_bls *)
(* 74000. *)
let cost_DECODING_PUBLIC_KEY_bls = S.safe_int 74000

(* model encoding/DECODING_PUBLIC_KEY_ed25519 *)
(* 60. *)
let cost_DECODING_PUBLIC_KEY_ed25519 = S.safe_int 60

(* model encoding/DECODING_PUBLIC_KEY_p256 *)
(* 9550. *)
let cost_DECODING_PUBLIC_KEY_p256 = S.safe_int 9550

(* model encoding/DECODING_PUBLIC_KEY_secp256k1 *)
(* 4900. *)
let cost_DECODING_PUBLIC_KEY_secp256k1 = S.safe_int 4900

(* model encoding/DECODING_SIGNATURE_bls *)
(* 40. *)
let cost_DECODING_SIGNATURE_bls = S.safe_int 40

(* model encoding/DECODING_SIGNATURE_ed25519 *)
(* 35. *)
let cost_DECODING_SIGNATURE_ed25519 = S.safe_int 35

(* model encoding/DECODING_SIGNATURE_p256 *)
(* 35. *)
let cost_DECODING_SIGNATURE_p256 = S.safe_int 35

(* model encoding/DECODING_SIGNATURE_secp256k1 *)
(* 35. *)
let cost_DECODING_SIGNATURE_secp256k1 = S.safe_int 35

(* model encoding/ENCODING_BLS_FR *)
(* 80. *)
let cost_ENCODING_BLS_FR = S.safe_int 80

(* model encoding/ENCODING_BLS_G1 *)
(* 3200. *)
let cost_ENCODING_BLS_G1 = S.safe_int 3200

(* model encoding/ENCODING_BLS_G2 *)
(* 3900. *)
let cost_ENCODING_BLS_G2 = S.safe_int 3900

(* model encoding/ENCODING_CHAIN_ID *)
(* 50. *)
let cost_ENCODING_CHAIN_ID = S.safe_int 50

(* model encoding/ENCODING_Chest *)
(* fun size -> 6250. + (0.09375 * size) *)
let cost_ENCODING_Chest size =
  let size = S.safe_int size in
  S.safe_int 6250 + (size lsr 4) + (size lsr 5)

(* model encoding/ENCODING_Chest_key *)
(* 15900. *)
let cost_ENCODING_Chest_key = S.safe_int 15900

(* model encoding/ENCODING_PUBLIC_KEY_HASH_bls *)
(* 80. *)
let cost_ENCODING_PUBLIC_KEY_HASH_bls = S.safe_int 80

(* model encoding/ENCODING_PUBLIC_KEY_HASH_ed25519 *)
(* 70. *)
let cost_ENCODING_PUBLIC_KEY_HASH_ed25519 = S.safe_int 70

(* model encoding/ENCODING_PUBLIC_KEY_HASH_p256 *)
(* 70. *)
let cost_ENCODING_PUBLIC_KEY_HASH_p256 = S.safe_int 70

(* model encoding/ENCODING_PUBLIC_KEY_HASH_secp256k1 *)
(* 70. *)
let cost_ENCODING_PUBLIC_KEY_HASH_secp256k1 = S.safe_int 70

(* model encoding/ENCODING_PUBLIC_KEY_bls *)
(* 90. *)
let cost_ENCODING_PUBLIC_KEY_bls = S.safe_int 90

(* model encoding/ENCODING_PUBLIC_KEY_ed25519 *)
(* 80. *)
let cost_ENCODING_PUBLIC_KEY_ed25519 = S.safe_int 80

(* model encoding/ENCODING_PUBLIC_KEY_p256 *)
(* 90. *)
let cost_ENCODING_PUBLIC_KEY_p256 = S.safe_int 90

(* model encoding/ENCODING_PUBLIC_KEY_secp256k1 *)
(* 455. *)
let cost_ENCODING_PUBLIC_KEY_secp256k1 = S.safe_int 455

(* model encoding/ENCODING_SIGNATURE_bls *)
(* 55. *)
let cost_ENCODING_SIGNATURE_bls = S.safe_int 55

(* model encoding/ENCODING_SIGNATURE_ed25519 *)
(* 45. *)
let cost_ENCODING_SIGNATURE_ed25519 = S.safe_int 45

(* model encoding/ENCODING_SIGNATURE_p256 *)
(* 45. *)
let cost_ENCODING_SIGNATURE_p256 = S.safe_int 45

(* model encoding/ENCODING_SIGNATURE_secp256k1 *)
(* 45. *)
let cost_ENCODING_SIGNATURE_secp256k1 = S.safe_int 45

(* model encoding/TIMESTAMP_READABLE_DECODING *)
(* fun size -> 105. + (0.046875 * (size * (sqrt size))) *)
let cost_TIMESTAMP_READABLE_DECODING size =
  let size = S.safe_int size in
  let w2 = sqrt size * size in
  S.safe_int 105 + (w2 lsr 5) + (w2 lsr 6)

(* model encoding/TIMESTAMP_READABLE_ENCODING *)
(* 820. *)
let cost_TIMESTAMP_READABLE_ENCODING = S.safe_int 820

(* model interpreter/N_IAbs_int *)
(* fun size -> 20. + (0.5 * size) *)
let cost_N_IAbs_int size =
  let size = S.safe_int size in
  S.safe_int 20 + (size lsr 1)

(* model interpreter/N_IAdd_bls12_381_fr *)
(* 30. *)
let cost_N_IAdd_bls12_381_fr = S.safe_int 30

(* model interpreter/N_IAdd_bls12_381_g1 *)
(* 900. *)
let cost_N_IAdd_bls12_381_g1 = S.safe_int 900

(* model interpreter/N_IAdd_bls12_381_g2 *)
(* 2470. *)
let cost_N_IAdd_bls12_381_g2 = S.safe_int 2470

(* model interpreter/N_IAdd_int *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IAdd_int size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IAdd_nat *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IAdd_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IAdd_seconds_to_timestamp *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IAdd_seconds_to_timestamp size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IAdd_tez *)
(* 20. *)
let cost_N_IAdd_tez = S.safe_int 20

(* model interpreter/N_IAdd_timestamp_to_seconds *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IAdd_timestamp_to_seconds size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IAddress *)
(* 10. *)
let cost_N_IAddress = S.safe_int 10

(* model interpreter/N_IAmount *)
(* 10. *)
let cost_N_IAmount = S.safe_int 10

(* model interpreter/N_IAnd *)
(* 10. *)
let cost_N_IAnd = S.safe_int 10

(* model interpreter/N_IAnd_bytes *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (min size1 size2)) *)
let cost_N_IAnd_bytes size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.min size1 size2 lsr 1)

(* model interpreter/N_IAnd_int_nat *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (min size1 size2)) *)
let cost_N_IAnd_int_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.min size1 size2 lsr 1)

(* model interpreter/N_IAnd_nat *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (min size1 size2)) *)
let cost_N_IAnd_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.min size1 size2 lsr 1)

(* model interpreter/N_IBalance *)
(* 10. *)
let cost_N_IBalance = S.safe_int 10

(* model interpreter/N_IBig_map_get *)
(* fun size1 ->
     fun size2 ->
       822.930542675 + (2.84341564432 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IBig_map_get size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 825 + (w3 * S.safe_int 2) + (w3 lsr 1) + (w3 lsr 2) + (w3 lsr 3)

(* model interpreter/N_IBig_map_get_and_update *)
(* fun size1 ->
     fun size2 ->
       834.633876008 + (2.84264684858 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IBig_map_get_and_update size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 835 + (w3 * S.safe_int 2) + (w3 lsr 1) + (w3 lsr 2) + (w3 lsr 3)

(* model interpreter/N_IBig_map_mem *)
(* fun size1 ->
     fun size2 ->
       824.703876008 + (2.8436528598 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IBig_map_mem size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 825 + (w3 * S.safe_int 2) + (w3 lsr 1) + (w3 lsr 2) + (w3 lsr 3)

(* model interpreter/N_IBig_map_update *)
(* fun size1 ->
     fun size2 ->
       816.020542675 + (3.16181279998 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IBig_map_update size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 820 + (w3 * S.safe_int 3) + (w3 lsr 3) + (w3 lsr 4)

(* model interpreter/N_IBlake2b *)
(* fun size -> 430. + (1.125 * size) *)
let cost_N_IBlake2b size =
  let size = S.safe_int size in
  S.safe_int 430 + (size lsr 3) + size

(* model interpreter/N_IBytes_int *)
(* fun size -> 90. + (3. * size) *)
let cost_N_IBytes_int size =
  let size = S.safe_int size in
  S.safe_int 90 + (size * S.safe_int 3)

(* model interpreter/N_IBytes_nat *)
(* fun size -> 75. + (3. * size) *)
let cost_N_IBytes_nat size =
  let size = S.safe_int size in
  S.safe_int 75 + (size * S.safe_int 3)

(* model interpreter/N_IBytes_size *)
(* 10. *)
let cost_N_IBytes_size = S.safe_int 10

(* model interpreter/N_ICar *)
(* 10. *)
let cost_N_ICar = S.safe_int 10

(* model interpreter/N_ICdr *)
(* 10. *)
let cost_N_ICdr = S.safe_int 10

(* model interpreter/N_IChainId *)
(* 15. *)
let cost_N_IChainId = S.safe_int 15

(* model interpreter/N_ICheck_signature_bls *)
(* fun size -> 1570000. + (3. * size) *)
let cost_N_ICheck_signature_bls size =
  let size = S.safe_int size in
  S.safe_int 1570000 + (size * S.safe_int 3)

(* model interpreter/N_ICheck_signature_ed25519 *)
(* fun size -> 65800. + (1.125 * size) *)
let cost_N_ICheck_signature_ed25519 size =
  let size = S.safe_int size in
  S.safe_int 65800 + (size lsr 3) + size

(* model interpreter/N_ICheck_signature_p256 *)
(* fun size -> 341000. + (1.125 * size) *)
let cost_N_ICheck_signature_p256 size =
  let size = S.safe_int size in
  S.safe_int 341000 + (size lsr 3) + size

(* model interpreter/N_ICheck_signature_secp256k1 *)
(* fun size -> 51600. + (1.125 * size) *)
let cost_N_ICheck_signature_secp256k1 size =
  let size = S.safe_int size in
  S.safe_int 51600 + (size lsr 3) + size

(* model interpreter/N_IComb *)
(* fun size -> 40. + (3.25 * (sub size 2)) *)
let cost_N_IComb size =
  let size = S.safe_int size in
  let w1 = S.sub size (S.safe_int 2) in
  S.safe_int 40 + (w1 * S.safe_int 3) + (w1 lsr 2)

(* model interpreter/N_IComb_get *)
(* fun size -> 20. + (0.5625 * size) *)
let cost_N_IComb_get size =
  let size = S.safe_int size in
  S.safe_int 20 + (size lsr 1) + (size lsr 4)

(* model interpreter/N_IComb_set *)
(* fun size -> 30. + (1.28125 * size) *)
let cost_N_IComb_set size =
  let size = S.safe_int size in
  S.safe_int 30 + (size lsr 2) + (size lsr 5) + size

(* model interpreter/N_ICompare *)
(* fun size1 -> fun size2 -> 35. + (0.0234375 * (sub (min size1 size2) 1)) *)
let cost_N_ICompare size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w1 = S.sub (S.min size1 size2) (S.safe_int 1) in
  S.safe_int 35 + (w1 lsr 6) + (w1 lsr 7)

(* model interpreter/N_IConcat_bytes_pair *)
(* fun size1 -> fun size2 -> 45. + (0.5 * (size1 + size2)) *)
let cost_N_IConcat_bytes_pair size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 45 + ((size1 + size2) lsr 1)

(* model interpreter/N_IConcat_string_pair *)
(* fun size1 -> fun size2 -> 45. + (0.5 * (size1 + size2)) *)
let cost_N_IConcat_string_pair size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 45 + ((size1 + size2) lsr 1)

(* model interpreter/N_ICons_list *)
(* 10. *)
let cost_N_ICons_list = S.safe_int 10

(* model interpreter/N_ICons_none *)
(* 10. *)
let cost_N_ICons_none = S.safe_int 10

(* model interpreter/N_ICons_pair *)
(* 10. *)
let cost_N_ICons_pair = S.safe_int 10

(* model interpreter/N_ICons_some *)
(* 10. *)
let cost_N_ICons_some = S.safe_int 10

(* model interpreter/N_IDiff_timestamps *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IDiff_timestamps size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IDig *)
(* fun size -> 30. + (6.75 * size) *)
let cost_N_IDig size =
  let size = S.safe_int size in
  S.safe_int 30 + (size lsr 1) + (size lsr 2) + (size * S.safe_int 6)

(* model interpreter/N_IDip *)
(* 10. *)
let cost_N_IDip = S.safe_int 10

(* model interpreter/N_IDipN *)
(* fun size -> 15. + (4. * size) *)
let cost_N_IDipN size =
  let size = S.safe_int size in
  S.safe_int 15 + (size * S.safe_int 4)

(* model interpreter/N_IDrop *)
(* 10. *)
let cost_N_IDrop = S.safe_int 10

(* model interpreter/N_IDug *)
(* fun size -> 35. + (6.75 * size) *)
let cost_N_IDug size =
  let size = S.safe_int size in
  S.safe_int 35 + (size lsr 1) + (size lsr 2) + (size * S.safe_int 6)

(* model interpreter/N_IDup *)
(* 10. *)
let cost_N_IDup = S.safe_int 10

(* model interpreter/N_IEdiv_int *)
(* fun size1 ->
     fun size2 ->
       let q = sub size1 size2 in
       ((((0.0010986328125 * q) * size2) + (1.25 * size1)) + (12. * q)) +
         150. *)
let cost_N_IEdiv_int size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w1 = S.sub size1 size2 in
  S.safe_int 150
  + (w1 * S.safe_int 12)
  + (((w1 lsr 10) + (w1 lsr 13)) * size2)
  + (size1 lsr 2) + size1

(* model interpreter/N_IEdiv_nat *)
(* fun size1 ->
     fun size2 ->
       let q = sub size1 size2 in
       ((((0.0010986328125 * q) * size2) + (1.25 * size1)) + (12. * q)) +
         150. *)
let cost_N_IEdiv_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w1 = S.sub size1 size2 in
  S.safe_int 150
  + (w1 * S.safe_int 12)
  + (((w1 lsr 10) + (w1 lsr 13)) * size2)
  + (size1 lsr 2) + size1

(* model interpreter/N_IEdiv_tez *)
(* 80. *)
let cost_N_IEdiv_tez = S.safe_int 80

(* model interpreter/N_IEdiv_teznat *)
(* 70. *)
let cost_N_IEdiv_teznat = S.safe_int 70

(* model interpreter/N_IEmpty_big_map *)
(* 300. *)
let cost_N_IEmpty_big_map = S.safe_int 300

(* model interpreter/N_IEmpty_map *)
(* 300. *)
let cost_N_IEmpty_map = S.safe_int 300

(* model interpreter/N_IEmpty_set *)
(* 300. *)
let cost_N_IEmpty_set = S.safe_int 300

(* model interpreter/N_IEq *)
(* 10. *)
let cost_N_IEq = S.safe_int 10

(* model interpreter/N_IExec *)
(* 10. *)
let cost_N_IExec = S.safe_int 10

(* model interpreter/N_IFailwith *)
(* 167.455190659 *)
let cost_N_IFailwith = S.safe_int 170

(* model interpreter/N_IGe *)
(* 10. *)
let cost_N_IGe = S.safe_int 10

(* model interpreter/N_IGt *)
(* 10. *)
let cost_N_IGt = S.safe_int 10

(* model interpreter/N_IHalt *)
(* 15. *)
let cost_N_IHalt = S.safe_int 15

(* model interpreter/N_IHalt_alloc *)
(* 0. *)
let cost_N_IHalt_alloc = S.safe_int 0

(* model interpreter/N_IHalt_synthesized *)
(* let time = 15. in let alloc = 0. in max time (alloc * 4) *)
let cost_N_IHalt_synthesized = S.safe_int 15

(* model interpreter/N_IHash_key *)
(* 605. *)
let cost_N_IHash_key = S.safe_int 605

(* model interpreter/N_IIf *)
(* 10. *)
let cost_N_IIf = S.safe_int 10

(* model interpreter/N_IIf_cons *)
(* 10. *)
let cost_N_IIf_cons = S.safe_int 10

(* model interpreter/N_IIf_left *)
(* 10. *)
let cost_N_IIf_left = S.safe_int 10

(* model interpreter/N_IIf_none *)
(* 10. *)
let cost_N_IIf_none = S.safe_int 10

(* model interpreter/N_IImplicit_account *)
(* 10. *)
let cost_N_IImplicit_account = S.safe_int 10

(* model interpreter/N_IInt_bls12_381_z_fr *)
(* 115. *)
let cost_N_IInt_bls12_381_z_fr = S.safe_int 115

(* model interpreter/N_IInt_bytes *)
(* fun size -> 20. + (2.5 * size) *)
let cost_N_IInt_bytes size =
  let size = S.safe_int size in
  S.safe_int 20 + (size lsr 1) + (size * S.safe_int 2)

(* model interpreter/N_IInt_nat *)
(* 10. *)
let cost_N_IInt_nat = S.safe_int 10

(* model interpreter/N_IIs_nat *)
(* 10. *)
let cost_N_IIs_nat = S.safe_int 10

(* model interpreter/N_IJoin_tickets *)
(* fun content_size_x ->
     fun content_size_y ->
       fun amount_size_x ->
         fun amount_size_y ->
           (88.1705426747 + (0. * (min content_size_x content_size_y))) +
             (0.0788934824125 * (max amount_size_x amount_size_y)) *)
let cost_N_IJoin_tickets _content_size_x _content_size_y amount_size_x
    amount_size_y =
  let amount_size_x = S.safe_int amount_size_x in
  let amount_size_y = S.safe_int amount_size_y in
  let w1 = S.max amount_size_x amount_size_y in
  S.safe_int 90 + (w1 lsr 4) + (w1 lsr 6) + (w1 lsr 9)

(* model interpreter/N_IKeccak *)
(* fun size -> 1350. + (8.25 * size) *)
let cost_N_IKeccak size =
  let size = S.safe_int size in
  S.safe_int 1350 + (size lsr 2) + (size * S.safe_int 8)

(* model interpreter/N_ILambda *)
(* max 10. 10. *)
let cost_N_ILambda = S.safe_int 10

(* model interpreter/N_ILambda_lam *)
(* 10. *)
let cost_N_ILambda_lam = S.safe_int 10

(* model interpreter/N_ILambda_lamrec *)
(* 10. *)
let cost_N_ILambda_lamrec = S.safe_int 10

(* model interpreter/N_ILe *)
(* 10. *)
let cost_N_ILe = S.safe_int 10

(* model interpreter/N_ILeft *)
(* 10. *)
let cost_N_ILeft = S.safe_int 10

(* model interpreter/N_ILevel *)
(* 10. *)
let cost_N_ILevel = S.safe_int 10

(* model interpreter/N_IList_iter *)
(* 20. *)
let cost_N_IList_iter = S.safe_int 20

(* model interpreter/N_IList_map *)
(* 20. *)
let cost_N_IList_map = S.safe_int 20

(* model interpreter/N_IList_size *)
(* 10. *)
let cost_N_IList_size = S.safe_int 10

(* model interpreter/N_ILoop *)
(* max 10. 1.01451868265 *)
let cost_N_ILoop = S.safe_int 10

(* model interpreter/N_ILoop_in *)
(* 10. *)
let cost_N_ILoop_in = S.safe_int 10

(* model interpreter/N_ILoop_left *)
(* max 10. 10. *)
let cost_N_ILoop_left = S.safe_int 10

(* model interpreter/N_ILoop_left_in *)
(* 10. *)
let cost_N_ILoop_left_in = S.safe_int 10

(* model interpreter/N_ILoop_left_out *)
(* 10. *)
let cost_N_ILoop_left_out = S.safe_int 10

(* model interpreter/N_ILoop_out *)
(* 1.01451868265 *)
let cost_N_ILoop_out = S.safe_int 5

(* model interpreter/N_ILsr_bytes *)
(* fun size1 ->
     fun size2 -> let q = sub size1 (size2 * 0.125) in 55. + (0.75 * q) *)
let cost_N_ILsr_bytes size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w1 = S.sub size1 (size2 lsr 3) in
  S.safe_int 55 + (w1 lsr 1) + (w1 lsr 2)

(* model interpreter/N_ILsr_nat *)
(* fun size -> 45. + (0.5 * size) *)
let cost_N_ILsr_nat size =
  let size = S.safe_int size in
  S.safe_int 45 + (size lsr 1)

(* model interpreter/N_ILt *)
(* 10. *)
let cost_N_ILt = S.safe_int 10

(* model interpreter/N_IMap_get *)
(* fun size1 -> fun size2 -> 45. + (0.046875 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IMap_get size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 45 + (w3 lsr 5) + (w3 lsr 6)

(* model interpreter/N_IMap_get_and_update *)
(* fun size1 -> fun size2 -> 75. + (0.140625 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IMap_get_and_update size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 75 + (w3 lsr 3) + (w3 lsr 6)

(* model interpreter/N_IMap_iter *)
(* fun size -> 50. + (7.625 * size) *)
let cost_N_IMap_iter size =
  let size = S.safe_int size in
  S.safe_int 50 + (size lsr 1) + (size lsr 3) + (size * S.safe_int 7)

(* model interpreter/N_IMap_map *)
(* fun size -> 40. + (8.5 * size) *)
let cost_N_IMap_map size =
  let size = S.safe_int size in
  S.safe_int 40 + (size lsr 1) + (size * S.safe_int 8)

(* model interpreter/N_IMap_mem *)
(* fun size1 -> fun size2 -> 45. + (0.046875 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IMap_mem size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 45 + (w3 lsr 5) + (w3 lsr 6)

(* model interpreter/N_IMap_size *)
(* 10. *)
let cost_N_IMap_size = S.safe_int 10

(* model interpreter/N_IMap_update *)
(* fun size1 -> fun size2 -> 55. + (0.09375 * (size1 * (log2 (1 + size2)))) *)
let cost_N_IMap_update size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 55 + (w3 lsr 4) + (w3 lsr 5)

(* model interpreter/N_IMin_block_time *)
(* 20. *)
let cost_N_IMin_block_time = S.safe_int 20

(* model interpreter/N_IMul_bls12_381_fr *)
(* 45. *)
let cost_N_IMul_bls12_381_fr = S.safe_int 45

(* model interpreter/N_IMul_bls12_381_fr_z *)
(* fun size -> 265. + (1.0625 * size) *)
let cost_N_IMul_bls12_381_fr_z size =
  let size = S.safe_int size in
  S.safe_int 265 + (size lsr 4) + size

(* model interpreter/N_IMul_bls12_381_g1 *)
(* 103000. *)
let cost_N_IMul_bls12_381_g1 = S.safe_int 103000

(* model interpreter/N_IMul_bls12_381_g2 *)
(* 220000. *)
let cost_N_IMul_bls12_381_g2 = S.safe_int 220000

(* model interpreter/N_IMul_bls12_381_z_fr *)
(* fun size -> 265. + (1.0625 * size) *)
let cost_N_IMul_bls12_381_z_fr size =
  let size = S.safe_int size in
  S.safe_int 265 + (size lsr 4) + size

(* model interpreter/N_IMul_int *)
(* fun size1 ->
     fun size2 ->
       let a = size1 + size2 in (0.8125 * (a * (log2 (1 + a)))) + 55. *)
let cost_N_IMul_int size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = size1 + size2 in
  let w4 = log2 (S.safe_int 1 + w3) * w3 in
  S.safe_int 55 + (w4 lsr 1) + (w4 lsr 2) + (w4 lsr 4)

(* model interpreter/N_IMul_nat *)
(* fun size1 ->
     fun size2 ->
       let a = size1 + size2 in (0.8125 * (a * (log2 (1 + a)))) + 55. *)
let cost_N_IMul_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = size1 + size2 in
  let w4 = log2 (S.safe_int 1 + w3) * w3 in
  S.safe_int 55 + (w4 lsr 1) + (w4 lsr 2) + (w4 lsr 4)

(* model interpreter/N_IMul_nattez *)
(* 50. *)
let cost_N_IMul_nattez = S.safe_int 50

(* model interpreter/N_IMul_teznat *)
(* 50. *)
let cost_N_IMul_teznat = S.safe_int 50

(* model interpreter/N_INat_bytes *)
(* fun size -> 45. + (2.5 * size) *)
let cost_N_INat_bytes size =
  let size = S.safe_int size in
  S.safe_int 45 + (size lsr 1) + (size * S.safe_int 2)

(* model interpreter/N_INeg *)
(* fun size -> 25. + (0.5 * size) *)
let cost_N_INeg size =
  let size = S.safe_int size in
  S.safe_int 25 + (size lsr 1)

(* model interpreter/N_INeg_bls12_381_fr *)
(* 30. *)
let cost_N_INeg_bls12_381_fr = S.safe_int 30

(* model interpreter/N_INeg_bls12_381_g1 *)
(* 50. *)
let cost_N_INeg_bls12_381_g1 = S.safe_int 50

(* model interpreter/N_INeg_bls12_381_g2 *)
(* 70. *)
let cost_N_INeg_bls12_381_g2 = S.safe_int 70

(* model interpreter/N_INeq *)
(* 10. *)
let cost_N_INeq = S.safe_int 10

(* model interpreter/N_INil *)
(* 10. *)
let cost_N_INil = S.safe_int 10

(* model interpreter/N_INot *)
(* 10. *)
let cost_N_INot = S.safe_int 10

(* model interpreter/N_INot_bytes *)
(* fun size -> 30. + (0.5 * size) *)
let cost_N_INot_bytes size =
  let size = S.safe_int size in
  S.safe_int 30 + (size lsr 1)

(* model interpreter/N_INot_int *)
(* fun size -> 25. + (0.5 * size) *)
let cost_N_INot_int size =
  let size = S.safe_int size in
  S.safe_int 25 + (size lsr 1)

(* model interpreter/N_INow *)
(* 10. *)
let cost_N_INow = S.safe_int 10

(* model interpreter/N_IOpen_chest *)
(* fun size1 ->
     fun size2 -> (919000. + (22528. * (sub size1 1))) + (3.25 * size2) *)
let cost_N_IOpen_chest size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 919000
  + (S.sub size1 (S.safe_int 1) * S.safe_int 22528)
  + (size2 lsr 2)
  + (size2 * S.safe_int 3)

(* model interpreter/N_IOpt_map *)
(* max 10. 0. *)
let cost_N_IOpt_map = S.safe_int 10

(* model interpreter/N_IOpt_map_none *)
(* 10. *)
let cost_N_IOpt_map_none = S.safe_int 10

(* model interpreter/N_IOpt_map_some *)
(* 0. *)
let cost_N_IOpt_map_some = S.safe_int 0

(* model interpreter/N_IOr *)
(* 10. *)
let cost_N_IOr = S.safe_int 10

(* model interpreter/N_IOr_bytes *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IOr_bytes size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IOr_nat *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IOr_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IPairing_check_bls12_381 *)
(* fun size -> 450000. + (342500. * size) *)
let cost_N_IPairing_check_bls12_381 size =
  let size = S.safe_int size in
  S.safe_int 450000 + (size * S.safe_int 344064)

(* model interpreter/N_IPush *)
(* 10. *)
let cost_N_IPush = S.safe_int 10

(* model interpreter/N_IRead_ticket *)
(* 10. *)
let cost_N_IRead_ticket = S.safe_int 10

(* model interpreter/N_IRight *)
(* 10. *)
let cost_N_IRight = S.safe_int 10

(* model interpreter/N_ISapling_empty_state *)
(* 300. *)
let cost_N_ISapling_empty_state = S.safe_int 300

(* model interpreter/N_ISapling_verify_update *)
(* fun size1 ->
     fun size2 -> (432500. + (5740000. * size1)) + (4636500. * size2) *)
let cost_N_ISapling_verify_update size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 432500 + (size1 * S.safe_int 5767168) + (size2 * S.safe_int 4718592)

(* model interpreter/N_ISelf *)
(* 10. *)
let cost_N_ISelf = S.safe_int 10

(* model interpreter/N_ISelf_address *)
(* 10. *)
let cost_N_ISelf_address = S.safe_int 10

(* model interpreter/N_ISender *)
(* 10. *)
let cost_N_ISender = S.safe_int 10

(* model interpreter/N_ISet_delegate *)
(* 60. *)
let cost_N_ISet_delegate = S.safe_int 60

(* model interpreter/N_ISet_iter *)
(* fun size -> 50. + (7.625 * size) *)
let cost_N_ISet_iter size =
  let size = S.safe_int size in
  S.safe_int 50 + (size lsr 1) + (size lsr 3) + (size * S.safe_int 7)

(* model interpreter/N_ISet_mem *)
(* fun size1 ->
     fun size2 ->
       39.3805426747 + (0.0564536354586 * (size1 * (log2 (1 + size2)))) *)
let cost_N_ISet_mem size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 40 + (w3 lsr 5) + (w3 lsr 6) + (w3 lsr 7) + (w3 lsr 9)

(* model interpreter/N_ISet_size *)
(* 10. *)
let cost_N_ISet_size = S.safe_int 10

(* model interpreter/N_ISet_update *)
(* fun size1 ->
     fun size2 ->
       49.8905426747 + (0.140036207663 * (size1 * (log2 (1 + size2)))) *)
let cost_N_ISet_update size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  S.safe_int 50 + (w3 lsr 3) + (w3 lsr 6)

(* model interpreter/N_ISha256 *)
(* fun size -> 600. + (4.75 * size) *)
let cost_N_ISha256 size =
  let size = S.safe_int size in
  S.safe_int 600 + (size lsr 1) + (size lsr 2) + (size * S.safe_int 4)

(* model interpreter/N_ISha3 *)
(* fun size -> 1350. + (8.25 * size) *)
let cost_N_ISha3 size =
  let size = S.safe_int size in
  S.safe_int 1350 + (size lsr 2) + (size * S.safe_int 8)

(* model interpreter/N_ISha512 *)
(* fun size -> 680. + (3. * size) *)
let cost_N_ISha512 size =
  let size = S.safe_int size in
  S.safe_int 680 + (size * S.safe_int 3)

(* model interpreter/N_ISlice_bytes *)
(* fun size -> 25. + (0.5 * size) *)
let cost_N_ISlice_bytes size =
  let size = S.safe_int size in
  S.safe_int 25 + (size lsr 1)

(* model interpreter/N_ISlice_string *)
(* fun size -> 25. + (0.5 * size) *)
let cost_N_ISlice_string size =
  let size = S.safe_int size in
  S.safe_int 25 + (size lsr 1)

(* model interpreter/N_ISource *)
(* 10. *)
let cost_N_ISource = S.safe_int 10

(* model interpreter/N_ISplit_ticket *)
(* fun size1 -> fun size2 -> 40. + (0.5 * (max size1 size2)) *)
let cost_N_ISplit_ticket size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 40 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IString_size *)
(* 15. *)
let cost_N_IString_size = S.safe_int 15

(* model interpreter/N_ISub_int *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_ISub_int size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_ISub_tez *)
(* 15. *)
let cost_N_ISub_tez = S.safe_int 15

(* model interpreter/N_ISub_tez_legacy *)
(* 20. *)
let cost_N_ISub_tez_legacy = S.safe_int 20

(* model interpreter/N_ISub_timestamp_seconds *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_ISub_timestamp_seconds size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_ISwap *)
(* 10. *)
let cost_N_ISwap = S.safe_int 10

(* model interpreter/N_ITicket *)
(* 10. *)
let cost_N_ITicket = S.safe_int 10

(* model interpreter/N_ITotal_voting_power *)
(* 450. *)
let cost_N_ITotal_voting_power = S.safe_int 450

(* model interpreter/N_IUncomb *)
(* fun size -> 30. + (4. * (sub size 2)) *)
let cost_N_IUncomb size =
  let size = S.safe_int size in
  S.safe_int 30 + (S.sub size (S.safe_int 2) * S.safe_int 4)

(* model interpreter/N_IUnit *)
(* 10. *)
let cost_N_IUnit = S.safe_int 10

(* model interpreter/N_IUnpair *)
(* 10. *)
let cost_N_IUnpair = S.safe_int 10

(* model interpreter/N_IView *)
(* 1460. *)
let cost_N_IView = S.safe_int 1460

(* model interpreter/N_IVoting_power *)
(* 640. *)
let cost_N_IVoting_power = S.safe_int 640

(* model interpreter/N_IXor *)
(* 15. *)
let cost_N_IXor = S.safe_int 15

(* model interpreter/N_IXor_bytes *)
(* fun size1 -> fun size2 -> 40. + (0.5 * (max size1 size2)) *)
let cost_N_IXor_bytes size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 40 + (S.max size1 size2 lsr 1)

(* model interpreter/N_IXor_nat *)
(* fun size1 -> fun size2 -> 35. + (0.5 * (max size1 size2)) *)
let cost_N_IXor_nat size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  S.safe_int 35 + (S.max size1 size2 lsr 1)

(* model interpreter/N_KCons *)
(* 10. *)
let cost_N_KCons = S.safe_int 10

(* model interpreter/N_KIter *)
(* max 10. 10. *)
let cost_N_KIter = S.safe_int 10

(* model interpreter/N_KIter_empty *)
(* 10. *)
let cost_N_KIter_empty = S.safe_int 10

(* model interpreter/N_KIter_nonempty *)
(* 10. *)
let cost_N_KIter_nonempty = S.safe_int 10

(* model interpreter/N_KList_exit_body *)
(* 10. *)
let cost_N_KList_exit_body = S.safe_int 10

(* model interpreter/N_KLoop_in *)
(* 10. *)
let cost_N_KLoop_in = S.safe_int 10

(* model interpreter/N_KLoop_in_left *)
(* 10. *)
let cost_N_KLoop_in_left = S.safe_int 10

(* model interpreter/N_KMap_exit_body *)
(* fun size1 ->
     fun size2 -> 0. + (0.114964427843 * (size1 * (log2 (1 + size2)))) *)
let cost_N_KMap_exit_body size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let w3 = log2 (S.safe_int 1 + size2) * size1 in
  (w3 lsr 4) + (w3 lsr 5) + (w3 lsr 6) + (w3 lsr 8) + (w3 lsr 9)

(* model interpreter/N_KMap_head *)
(* 20. *)
let cost_N_KMap_head = S.safe_int 20

(* model interpreter/N_KNil *)
(* 15. *)
let cost_N_KNil = S.safe_int 15

(* model interpreter/N_KReturn *)
(* 10. *)
let cost_N_KReturn = S.safe_int 10

(* model interpreter/N_KUndip *)
(* 10. *)
let cost_N_KUndip = S.safe_int 10

(* model interpreter/N_KView_exit *)
(* 20. *)
let cost_N_KView_exit = S.safe_int 20

(* model interpreter/amplification_loop_model *)
(* fun size -> 0.329309341324 * size *)
let cost_amplification_loop_model size =
  let size = S.safe_int size in
  (size lsr 2) + (size lsr 4) + (size lsr 6) + (size lsr 7)

(* model translator/PARSE_TYPE *)
(* fun size -> 0. + (60. * size) *)
let cost_PARSE_TYPE size =
  let size = S.safe_int size in
  size * S.safe_int 60

(* model translator/Parsing_Code_gas *)
(* fun size -> 0. + (0.890391244567 * size) *)
let cost_Parsing_Code_gas size =
  let size = S.safe_int size in
  (size lsr 1) + (size lsr 2) + (size lsr 3) + (size lsr 6)

(* model translator/Parsing_Code_size *)
(* fun size1 ->
     fun size2 ->
       fun size3 -> ((187.300458967 * size1) + (0. * size2)) + (0. * size3) *)
let cost_Parsing_Code_size size1 _size2 _size3 =
  let size1 = S.safe_int size1 in
  size1 * S.safe_int 188

(* model translator/Parsing_Data_gas *)
(* fun size -> 67277.397394 + (0.142972986751 * size) *)
let cost_Parsing_Data_gas size =
  let size = S.safe_int size in
  S.safe_int 67280 + (size lsr 3) + (size lsr 6) + (size lsr 8)

(* model translator/Parsing_Data_size *)
(* fun size1 ->
     fun size2 ->
       fun size3 ->
         ((80.363444899 * size1) + (16.1426805777 * size2)) +
           (68.9487320686 * size3) *)
let cost_Parsing_Data_size size1 size2 size3 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  let size3 = S.safe_int size3 in
  (size2 lsr 1)
  + (size1 * S.safe_int 82)
  + (size2 * S.safe_int 16)
  + (size3 * S.safe_int 70)

(* model translator/TY_EQ *)
(* fun size -> 31.1882471167 + (21.8805791266 * size) *)
let cost_TY_EQ size = S.safe_int 35 + (size * S.safe_int 22)

(* model translator/UNPARSE_TYPE *)
(* fun size -> 0. + (20. * size) *)
let cost_UNPARSE_TYPE size = size * S.safe_int 20

(* model translator/Unparsing_Code_gas *)
(* fun size -> 0. + (0.592309924661 * size) *)
let cost_Unparsing_Code_gas size =
  let size = S.safe_int size in
  (size lsr 1) + (size lsr 4) + (size lsr 5)

(* model translator/Unparsing_Code_size *)
(* fun size1 ->
     fun size2 ->
       fun size3 -> ((124.72642512 * size1) + (0. * size2)) + (0. * size3) *)
let cost_Unparsing_Code_size size1 _size2 _size3 =
  let size1 = S.safe_int size1 in
  size1 * S.safe_int 126

(* model translator/Unparsing_Data_gas *)
(* fun size -> 31944.7865384 + (0.033862305692 * size) *)
let cost_Unparsing_Data_gas size =
  let size = S.safe_int size in
  S.safe_int 31945 + (size lsr 5) + (size lsr 9) + (size lsr 10)

(* model translator/Unparsing_Data_size *)
(* fun size1 ->
     fun size2 ->
       fun size3 -> ((54.8706646933 * size1) + (0. * size2)) + (0. * size3) *)
let cost_Unparsing_Data_size size1 _size2 _size3 =
  let size1 = S.safe_int size1 in
  size1 * S.safe_int 55
