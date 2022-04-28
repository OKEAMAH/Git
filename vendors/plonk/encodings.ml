let fr_encoding =
  Data_encoding.(conv Bls12_381.Fr.to_bytes Bls12_381.Fr.of_bytes_exn bytes)

let gt_encoding =
  Data_encoding.(conv Bls12_381.GT.to_bytes Bls12_381.GT.of_bytes_exn bytes)

let g1_encoding =
  Data_encoding.(
    conv
      Bls12_381.G1.to_compressed_bytes
      Bls12_381.G1.of_compressed_bytes_exn
      bytes)

let g2_encoding =
  Data_encoding.(
    conv
      Bls12_381.G2.to_compressed_bytes
      Bls12_381.G2.of_compressed_bytes_exn
      bytes)
