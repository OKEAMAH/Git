meta:
  id: id_017__ptnairob__contract
  endian: be
doc: ! 'Encoding id: 017-PtNairob.contract'
types:
  id_017__ptnairob__contract_id_:
    seq:
    - id: id_017__ptnairob__contract_id_tag
      type: u1
      enum: id_017__ptnairob__contract_id_tag
    - id: implicit__id_017__ptnairob__contract_id
      type: implicit__public_key_hash_
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: originated__id_017__ptnairob__contract_id
      type: originated__id_017__ptnairob__contract_id
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::originated)
  implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  originated__id_017__ptnairob__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
enums:
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_017__ptnairob__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_017__ptnairob__contract_id_
  type: id_017__ptnairob__contract_id_
  doc: ! >-
    A contract handle: A contract notation as given to an RPC or inside scripts. Can
    be a base58 implicit contract hash or a base58 originated contract hash.
