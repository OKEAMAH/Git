#[cfg(any(feature = "ed25519", feature = "secp256_k1", feature = "p256"))]
use crate::{CryptoProvider, Error, Result};

/// Default implementation for the ed25519 crypto provider. It is activated by enabling the `ed25519` feature.
///
/// This implementation internally uses [ed25519-dalek](https://github.com/dalek-cryptography/ed25519-dalek).
#[cfg(feature = "ed25519")]
#[derive(Debug)]
pub struct DefaultEd25519CryptoProvider;

#[cfg(feature = "ed25519")]
impl CryptoProvider for DefaultEd25519CryptoProvider {
    fn sign(&self, message: &[u8], secret: &[u8]) -> Result<Vec<u8>> {
        use ed25519_dalek::{Keypair, Signer};

        let keypair = Keypair::from_bytes(secret).map_err(|_| Error::InvalidSecretKeyBytes)?;
        let signature = keypair.sign(message);

        Ok(signature.to_bytes().to_vec())
    }

    fn verify(
        &self,
        message: &[u8],
        signature_bytes: &[u8],
        public_key_bytes: &[u8],
    ) -> Result<bool> {
        use ed25519_dalek::{PublicKey, Signature, Verifier};

        let public_key =
            PublicKey::from_bytes(public_key_bytes).map_err(|_| Error::InvalidPublicKeyBytes)?;
        let signature =
            Signature::from_bytes(signature_bytes).map_err(|_| Error::InvalidSignatureBytes)?;

        Ok(public_key.verify(message, &signature).is_ok())
    }
}

/// Default implementation for the secp256_k1 crypto provider. It is activated by enabling the `secp256_k1` feature.
///
/// This implementation internally uses [k256](https://github.com/RustCrypto/elliptic-curves/tree/master/k256).
#[cfg(feature = "secp256_k1")]
#[derive(Debug)]
pub struct DefaultSecp256K1CryptoProvider;

#[cfg(feature = "secp256_k1")]
impl CryptoProvider for DefaultSecp256K1CryptoProvider {
    fn sign(&self, message: &[u8], secret: &[u8]) -> Result<Vec<u8>> {
        use k256::ecdsa::signature::hazmat::PrehashSigner;

        let sk = k256::ecdsa::SigningKey::from_bytes(secret.into())
            .map_err(|_error| Error::InvalidSecretKeyBytes)?;

        let signature: k256::ecdsa::Signature = sk.sign_prehash(message)?;

        Ok(signature.to_vec())
    }

    fn verify(&self, message: &[u8], signature: &[u8], public_key: &[u8]) -> Result<bool> {
        use k256::ecdsa::signature::hazmat::PrehashVerifier;

        let vk = k256::ecdsa::VerifyingKey::from_sec1_bytes(public_key)
            .map_err(|_error| Error::InvalidPublicKeyBytes)?;
        let signature: k256::ecdsa::Signature =
            k256::ecdsa::Signature::from_bytes(signature.into())
                .map_err(|_error| Error::InvalidSignatureBytes)?;
        Ok(vk.verify_prehash(message, &signature).is_ok())
    }
}

/// Default implementation for the p256 crypto provider. It is activated by enabling the `p256` feature.
///
/// This implementation internally uses [p256](https://github.com/RustCrypto/elliptic-curves/tree/master/p256).
#[cfg(feature = "p256")]
#[derive(Debug)]
pub struct DefaultP256CryptoProvider;

#[cfg(feature = "p256")]
impl CryptoProvider for DefaultP256CryptoProvider {
    fn sign(&self, message: &[u8], secret: &[u8]) -> Result<Vec<u8>> {
        use p256::ecdsa::signature::hazmat::PrehashSigner;

        let sk = p256::ecdsa::SigningKey::from_bytes(secret.into())
            .map_err(|_error| Error::InvalidSecretKeyBytes)?;

        let signature: p256::ecdsa::Signature = sk.sign_prehash(message.into())?;

        Ok(signature.to_vec())
    }

    fn verify(&self, message: &[u8], signature: &[u8], public_key: &[u8]) -> Result<bool> {
        use p256::ecdsa::signature::hazmat::PrehashVerifier;

        let vk = p256::ecdsa::VerifyingKey::from_sec1_bytes(public_key)
            .map_err(|_error| Error::InvalidPublicKeyBytes)?;
        let signature: p256::ecdsa::Signature =
            p256::ecdsa::Signature::from_bytes(signature.into())
                .map_err(|_error| Error::InvalidSignatureBytes)?;
        Ok(vk.verify_prehash(message, &signature).is_ok())
    }
}

#[cfg(test)]
mod test {
    #[cfg(any(feature = "ed25519", feature = "secp256_k1", feature = "p256"))]
    use super::*;

    fn ed25519_pair() -> (&'static [u8], &'static [u8]) {
        (
            &[
                138, 86, 201, 43, 125, 244, 132, 30, 161, 167, 155, 45, 170, 71, 139, 154, 98, 159,
                243, 89, 224, 15, 211, 68, 224, 197, 251, 209, 57, 233, 17, 79, 32, 140, 29, 13,
                236, 146, 180, 23, 186, 247, 43, 237, 57, 53, 127, 167, 6, 44, 89, 51, 106, 89,
                129, 250, 35, 156, 31, 66, 104, 65, 234, 131,
            ],
            &[
                32, 140, 29, 13, 236, 146, 180, 23, 186, 247, 43, 237, 57, 53, 127, 167, 6, 44, 89,
                51, 106, 89, 129, 250, 35, 156, 31, 66, 104, 65, 234, 131,
            ],
        )
    }

    fn secp256_k1_pair() -> (&'static [u8], &'static [u8]) {
        (
            &[
                2, 251, 104, 203, 198, 119, 255, 180, 51, 104, 166, 16, 242, 213, 120, 42, 21, 154,
                226, 120, 58, 173, 52, 168, 243, 83, 185, 77, 99, 115, 140, 88,
            ],
            &[
                2, 67, 78, 53, 41, 205, 106, 25, 46, 134, 93, 40, 214, 12, 245, 22, 173, 181, 139,
                176, 116, 185, 193, 125, 253, 60, 69, 217, 198, 151, 184, 51, 51,
            ],
        )
    }

    fn p256_pair() -> (&'static [u8], &'static [u8]) {
        (
            &[
                67, 114, 247, 135, 119, 63, 176, 102, 156, 75, 164, 83, 118, 133, 115, 198, 30, 32,
                173, 9, 97, 96, 67, 223, 60, 241, 106, 183, 230, 191, 185, 75,
            ],
            &[
                3, 151, 224, 199, 108, 168, 80, 52, 156, 251, 118, 132, 18, 28, 95, 199, 81, 111,
                127, 243, 48, 11, 240, 71, 99, 28, 200, 230, 177, 85, 181, 103, 88,
            ],
        )
    }

    #[cfg(feature = "ed25519")]
    #[test]
    fn test_ed25519_sign() -> Result<()> {
        let cp = DefaultEd25519CryptoProvider;
        let values: Vec<(&'static [u8], &'static [u8])> = vec![
            (
                &[
                    187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                    146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                ],
                &[
                    243, 215, 194, 90, 109, 213, 83, 238, 154, 85, 139, 71, 14, 62, 191, 230, 7,
                    184, 231, 37, 218, 148, 111, 105, 132, 227, 162, 169, 225, 128, 80, 160, 79,
                    180, 93, 252, 39, 85, 135, 99, 169, 51, 158, 132, 26, 242, 23, 20, 201, 208,
                    56, 183, 16, 131, 9, 117, 173, 146, 162, 143, 180, 179, 50, 5,
                ],
            ),
            (
                &[
                    162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74, 245,
                    220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                ],
                &[
                    88, 26, 2, 141, 142, 99, 116, 35, 227, 43, 80, 185, 111, 248, 99, 110, 12, 10,
                    104, 211, 38, 82, 196, 147, 164, 255, 55, 33, 245, 13, 1, 123, 54, 234, 217,
                    207, 26, 198, 131, 15, 174, 120, 152, 26, 103, 163, 229, 9, 99, 140, 48, 138,
                    2, 176, 239, 253, 23, 68, 46, 183, 105, 12, 26, 13,
                ],
            ),
        ];
        let secret = ed25519_pair().0;
        for (message, expected) in values {
            let signature = cp.sign(message, secret)?;
            assert_eq!(expected, signature);
        }

        Ok(())
    }

    #[cfg(feature = "ed25519")]
    #[test]
    fn test_ed25519_verify() -> Result<()> {
        let cp = DefaultEd25519CryptoProvider;
        let values: Vec<((&'static [u8], &'static [u8]), bool)> = vec![
            (
                (
                    &[
                        187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                        146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                    ],
                    &[
                        243, 215, 194, 90, 109, 213, 83, 238, 154, 85, 139, 71, 14, 62, 191, 230,
                        7, 184, 231, 37, 218, 148, 111, 105, 132, 227, 162, 169, 225, 128, 80, 160,
                        79, 180, 93, 252, 39, 85, 135, 99, 169, 51, 158, 132, 26, 242, 23, 20, 201,
                        208, 56, 183, 16, 131, 9, 117, 173, 146, 162, 143, 180, 179, 50, 5,
                    ],
                ),
                true,
            ),
            (
                (
                    &[
                        162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74,
                        245, 220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                    ],
                    &[
                        88, 26, 2, 141, 142, 99, 116, 35, 227, 43, 80, 185, 111, 248, 99, 110, 12,
                        10, 104, 211, 38, 82, 196, 147, 164, 255, 55, 33, 245, 13, 1, 123, 54, 234,
                        217, 207, 26, 198, 131, 15, 174, 120, 152, 26, 103, 163, 229, 9, 99, 140,
                        48, 138, 2, 176, 239, 253, 23, 68, 46, 183, 105, 12, 26, 13,
                    ],
                ),
                true,
            ),
            (
                (
                    &[
                        187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                        146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                    ],
                    &[
                        88, 26, 2, 141, 142, 99, 116, 35, 227, 43, 80, 185, 111, 248, 99, 110, 12,
                        10, 104, 211, 38, 82, 196, 147, 164, 255, 55, 33, 245, 13, 1, 123, 54, 234,
                        217, 207, 26, 198, 131, 15, 174, 120, 152, 26, 103, 163, 229, 9, 99, 140,
                        48, 138, 2, 176, 239, 253, 23, 68, 46, 183, 105, 12, 26, 13,
                    ],
                ),
                false,
            ),
            (
                (
                    &[
                        162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74,
                        245, 220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                    ],
                    &[
                        243, 215, 194, 90, 109, 213, 83, 238, 154, 85, 139, 71, 14, 62, 191, 230,
                        7, 184, 231, 37, 218, 148, 111, 105, 132, 227, 162, 169, 225, 128, 80, 160,
                        79, 180, 93, 252, 39, 85, 135, 99, 169, 51, 158, 132, 26, 242, 23, 20, 201,
                        208, 56, 183, 16, 131, 9, 117, 173, 146, 162, 143, 180, 179, 50, 5,
                    ],
                ),
                false,
            ),
        ];

        let public_key = ed25519_pair().1;
        for ((message, signature), expected) in values {
            let result = cp.verify(message, signature, public_key)?;
            assert_eq!(expected, result);
        }

        Ok(())
    }

    #[cfg(feature = "secp256_k1")]
    #[test]
    fn test_secp256_k1_sign() -> Result<()> {
        let cp = DefaultSecp256K1CryptoProvider;
        let values: Vec<(&'static [u8], &'static [u8])> = vec![
            (
                &[
                    187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                    146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                ],
                &[
                    194, 114, 181, 200, 244, 171, 164, 203, 172, 154, 64, 2, 6, 57, 66, 158, 219,
                    33, 26, 51, 134, 191, 146, 119, 153, 236, 99, 36, 165, 66, 57, 199, 117, 131,
                    176, 3, 181, 154, 123, 188, 113, 17, 35, 15, 5, 48, 192, 93, 84, 77, 87, 13,
                    231, 188, 94, 243, 2, 221, 220, 189, 98, 40, 28, 190,
                ],
            ),
            (
                &[
                    162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74, 245,
                    220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                ],
                &[
                    37, 152, 77, 200, 78, 92, 29, 51, 174, 133, 202, 17, 177, 218, 50, 147, 143, 3,
                    246, 254, 76, 106, 138, 229, 195, 203, 149, 166, 45, 111, 228, 55, 23, 115,
                    228, 132, 19, 69, 138, 253, 60, 26, 65, 112, 120, 228, 129, 85, 3, 127, 166,
                    78, 187, 225, 77, 140, 95, 166, 43, 105, 47, 215, 250, 155,
                ],
            ),
        ];
        let secret = secp256_k1_pair().0;
        for (message, expected) in values {
            let signature = cp.sign(message, secret)?;
            assert_eq!(expected, signature);
        }

        Ok(())
    }

    #[cfg(feature = "secp256_k1")]
    #[test]
    fn test_secp256_k1_verify() -> Result<()> {
        let cp = DefaultSecp256K1CryptoProvider;
        let values: Vec<((&'static [u8], &'static [u8]), bool)> = vec![
            (
                (
                    &[
                        187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                        146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                    ],
                    &[
                        194, 114, 181, 200, 244, 171, 164, 203, 172, 154, 64, 2, 6, 57, 66, 158,
                        219, 33, 26, 51, 134, 191, 146, 119, 153, 236, 99, 36, 165, 66, 57, 199,
                        117, 131, 176, 3, 181, 154, 123, 188, 113, 17, 35, 15, 5, 48, 192, 93, 84,
                        77, 87, 13, 231, 188, 94, 243, 2, 221, 220, 189, 98, 40, 28, 190,
                    ],
                ),
                true,
            ),
            (
                (
                    &[
                        162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74,
                        245, 220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                    ],
                    &[
                        37, 152, 77, 200, 78, 92, 29, 51, 174, 133, 202, 17, 177, 218, 50, 147,
                        143, 3, 246, 254, 76, 106, 138, 229, 195, 203, 149, 166, 45, 111, 228, 55,
                        23, 115, 228, 132, 19, 69, 138, 253, 60, 26, 65, 112, 120, 228, 129, 85, 3,
                        127, 166, 78, 187, 225, 77, 140, 95, 166, 43, 105, 47, 215, 250, 155,
                    ],
                ),
                true,
            ),
            (
                (
                    &[
                        187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                        146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                    ],
                    &[
                        232, 163, 117, 77, 11, 127, 127, 64, 128, 148, 125, 193, 6, 124, 132, 242,
                        15, 173, 6, 243, 49, 102, 229, 119, 163, 121, 133, 252, 11, 40, 206, 109,
                        13, 55, 120, 254, 180, 124, 14, 51, 9, 94, 253, 53, 216, 234, 145, 233, 10,
                        122, 35, 215, 167, 248, 104, 222, 119, 26, 111, 121, 54, 240, 7, 115,
                    ],
                ),
                false,
            ),
            (
                (
                    &[
                        162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74,
                        245, 220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                    ],
                    &[
                        94, 27, 125, 173, 22, 236, 142, 61, 138, 175, 27, 174, 254, 241, 227, 168,
                        161, 106, 210, 168, 244, 148, 135, 226, 173, 29, 153, 123, 31, 151, 204,
                        160, 12, 62, 47, 5, 212, 224, 246, 234, 35, 35, 110, 19, 150, 220, 252,
                        221, 217, 143, 23, 70, 237, 19, 182, 73, 17, 224, 135, 215, 169, 244, 242,
                        24,
                    ],
                ),
                false,
            ),
        ];

        let public_key = secp256_k1_pair().1;
        for ((message, signature), expected) in values {
            let result = cp.verify(message, signature, public_key)?;
            assert_eq!(expected, result);
        }

        Ok(())
    }

    #[cfg(feature = "p256")]
    #[test]
    fn test_p256_sign() -> Result<()> {
        let cp = DefaultP256CryptoProvider;
        let values: Vec<(&'static [u8], &'static [u8])> = vec![
            (
                &[
                    187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                    146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                ],
                &[
                    224, 253, 177, 134, 177, 64, 222, 121, 95, 115, 195, 14, 216, 194, 105, 162,
                    167, 27, 164, 192, 98, 80, 44, 139, 239, 232, 93, 56, 4, 79, 217, 236, 74, 50,
                    70, 182, 186, 127, 176, 96, 69, 162, 209, 33, 228, 246, 200, 226, 170, 144,
                    190, 1, 181, 169, 101, 2, 232, 229, 52, 7, 187, 177, 59, 194,
                ],
            ),
            (
                &[
                    162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74, 245,
                    220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                ],
                &[
                    60, 28, 124, 81, 248, 206, 221, 195, 30, 108, 129, 164, 107, 49, 71, 181, 44,
                    250, 52, 191, 150, 57, 175, 11, 84, 31, 126, 185, 78, 169, 53, 110, 114, 158,
                    242, 213, 124, 141, 190, 104, 106, 135, 181, 86, 149, 100, 61, 143, 164, 175,
                    80, 225, 127, 179, 40, 8, 224, 233, 201, 74, 49, 90, 118, 58,
                ],
            ),
        ];
        let secret = p256_pair().0;
        for (message, expected) in values {
            let signature = cp.sign(message, secret)?;
            assert_eq!(expected, signature);
        }

        Ok(())
    }

    #[cfg(feature = "p256")]
    #[test]
    fn test_p256_verify() -> Result<()> {
        let cp = DefaultP256CryptoProvider;
        let values: Vec<((&'static [u8], &'static [u8]), bool)> = vec![
            (
                (
                    &[
                        187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                        146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                    ],
                    &[
                        224, 253, 177, 134, 177, 64, 222, 121, 95, 115, 195, 14, 216, 194, 105,
                        162, 167, 27, 164, 192, 98, 80, 44, 139, 239, 232, 93, 56, 4, 79, 217, 236,
                        74, 50, 70, 182, 186, 127, 176, 96, 69, 162, 209, 33, 228, 246, 200, 226,
                        170, 144, 190, 1, 181, 169, 101, 2, 232, 229, 52, 7, 187, 177, 59, 194,
                    ],
                ),
                true,
            ),
            (
                (
                    &[
                        162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74,
                        245, 220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                    ],
                    &[
                        60, 28, 124, 81, 248, 206, 221, 195, 30, 108, 129, 164, 107, 49, 71, 181,
                        44, 250, 52, 191, 150, 57, 175, 11, 84, 31, 126, 185, 78, 169, 53, 110,
                        114, 158, 242, 213, 124, 141, 190, 104, 106, 135, 181, 86, 149, 100, 61,
                        143, 164, 175, 80, 225, 127, 179, 40, 8, 224, 233, 201, 74, 49, 90, 118,
                        58,
                    ],
                ),
                true,
            ),
            (
                (
                    &[
                        187, 103, 163, 186, 154, 198, 79, 184, 154, 180, 128, 246, 52, 117, 95, 13,
                        146, 194, 99, 249, 128, 184, 112, 93, 187, 36, 179, 1, 10, 59, 30, 105,
                    ],
                    &[
                        232, 163, 117, 77, 11, 127, 127, 64, 128, 148, 125, 193, 6, 124, 132, 242,
                        15, 173, 6, 243, 49, 102, 229, 119, 163, 121, 133, 252, 11, 40, 206, 109,
                        13, 55, 120, 254, 180, 124, 14, 51, 9, 94, 253, 53, 216, 234, 145, 233, 10,
                        122, 35, 215, 167, 248, 104, 222, 119, 26, 111, 121, 54, 240, 7, 115,
                    ],
                ),
                false,
            ),
            (
                (
                    &[
                        162, 95, 108, 242, 149, 88, 93, 127, 72, 2, 237, 97, 203, 77, 244, 77, 74,
                        245, 220, 17, 196, 174, 134, 246, 26, 44, 171, 143, 220, 219, 255, 192,
                    ],
                    &[
                        94, 27, 125, 173, 22, 236, 142, 61, 138, 175, 27, 174, 254, 241, 227, 168,
                        161, 106, 210, 168, 244, 148, 135, 226, 173, 29, 153, 123, 31, 151, 204,
                        160, 12, 62, 47, 5, 212, 224, 246, 234, 35, 35, 110, 19, 150, 220, 252,
                        221, 217, 143, 23, 70, 237, 19, 182, 73, 17, 224, 135, 215, 169, 244, 242,
                        24,
                    ],
                ),
                false,
            ),
        ];

        let public_key = p256_pair().1;
        for ((message, signature), expected) in values {
            let result = cp.verify(message, signature, public_key)?;
            assert_eq!(expected, result);
        }

        Ok(())
    }
}
