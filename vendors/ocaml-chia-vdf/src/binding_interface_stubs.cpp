#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "src/verifier.h"
#include "src/prover_slow.h"
#include "src/refcode/lzcnt.c"
#include "src/Reducer.h"
#include "src/alloc.hpp"
#include "ocaml_integers.h"

// From ocaml-ctypes:
// https://github.com/ocamllabs/ocaml-ctypes/blob/9048ac78b885cc3debeeb020c56ea91f459a4d33/src/ctypes/ctypes_primitives.h#L110
#if SIZE_MAX == UINT64_MAX
#define ctypes_size_t_val Uint64_val
#define ctypes_copy_size_t integers_copy_uint64
#else
#error "No suitable OCaml type available for representing size_t values"
#endif

int form_size = BQFC_FORM_SIZE;

using namespace std;

// TODO create function to generate random group element?

void create_discriminant(unsigned char *seed, int seed_size,
                         int discriminant_size, unsigned char *buffer) {
  // Converting to C++ types
  vector<uint8_t> seed_bits(seed, seed + seed_size);

  // Generating safe discriminant
  integer res = CreateDiscriminant(seed_bits, discriminant_size * 8);

  // Serialising to unsigned discriminant in bytes
  vector<uint8_t> res_bytes = res.to_bytes();
  copy(res_bytes.begin(), res_bytes.end(), buffer);
}

void prove(unsigned char *discriminant_bytes, size_t discriminant_size_in_bytes,
           unsigned char *challenge, uint64_t num_iterations,
           unsigned char *result, unsigned char *proof) {
  // Deserialising the discriminant and multiplying by -1 as it is always
  // negative
  integer discriminant =
      -integer(discriminant_bytes, discriminant_size_in_bytes);

  // Deserialising the challenge in form
  form x_form = DeserializeForm(discriminant, challenge, form_size);

  // Generating result and proof, already serialised and concatenated together.
  vector<unsigned char> res = ProveSlow(discriminant, x_form, num_iterations);

  // Copying result and proof in respective input buffers
  unsigned char *res_data = res.data();
  memcpy(result, res_data, sizeof(unsigned char) * form_size);
  memcpy(proof, &res_data[form_size], sizeof(unsigned char) * form_size);
}

bool verify(unsigned char *discriminant_bytes,
            size_t discriminant_size_in_bytes, const unsigned char *challenge,
            const unsigned char *result, const unsigned char *proof,
            uint64_t num_iterations) {
  // Deserialising the discriminant and multiplying by -1 as it is always
  // negative
  integer discriminant =
      -integer(discriminant_bytes, discriminant_size_in_bytes);

  // Deserialising to forms
  form challenge_form = DeserializeForm(discriminant, challenge, form_size);
  form result_form = DeserializeForm(discriminant, result, form_size);
  form proof_form = DeserializeForm(discriminant, proof, form_size);

  // Verifying proof
  bool is_valid;
  VerifyWesolowskiProof(discriminant, challenge_form, result_form, proof_form,
                        num_iterations, is_valid);
  return is_valid;
}

extern "C" {
CAMLprim value caml_create_discriminant_stubs(value seed_ml, value seed_size_ml,
                                              value discriminant_size_ml,
                                              value buffer_ml) {
  CAMLparam4(seed_ml, seed_size_ml, discriminant_size_ml, buffer_ml);
  unsigned char *seed = Bytes_val(seed_ml);
  int seed_size = Int_val(seed_size_ml);
  int discriminant_size = Int_val(discriminant_size_ml);
  unsigned char *buffer = Bytes_val(buffer_ml);
  create_discriminant(seed, seed_size, discriminant_size, buffer);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_prove_stubs(value discriminant_ml,
                                value discriminant_size_ml, value challenge_ml,
                                value num_iterations_ml, value result_buffer_ml,
                                value proof_buffer_ml) {
  CAMLparam5(discriminant_ml, discriminant_size_ml, challenge_ml,
             num_iterations_ml, result_buffer_ml);
  CAMLxparam1(proof_buffer_ml);
  unsigned char *discriminant_bytes = Bytes_val(discriminant_ml);
  size_t discriminant_size = ctypes_size_t_val(discriminant_size_ml);
  unsigned char *challenge = Bytes_val(challenge_ml);
  uint64_t n = Uint64_val(num_iterations_ml);
  unsigned char *result_buffer = Bytes_val(result_buffer_ml);
  unsigned char *proof_buffer = Bytes_val(proof_buffer_ml);
  prove(discriminant_bytes, discriminant_size, challenge, n, result_buffer,
        proof_buffer);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_prove_bytecode_stubs(value *argv, int argn) {
  return caml_prove_stubs(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim value caml_verify_stubs(value discriminant_bytes_ml,
                                 value discriminant_size_ml, value challenge_ml,
                                 value result_ml, value proof_ml,
                                 value num_iterations_ml) {
  CAMLparam5(discriminant_bytes_ml, discriminant_size_ml, challenge_ml,
             result_ml, proof_ml);
  CAMLxparam1(num_iterations_ml);
  unsigned char *discriminant_bytes = Bytes_val(discriminant_bytes_ml);
  size_t discriminant_size = ctypes_size_t_val(discriminant_size_ml);

  unsigned char *challenge = Bytes_val(challenge_ml);
  unsigned char *result = Bytes_val(result_ml);
  unsigned char *proof = Bytes_val(proof_ml);
  uint64_t n = Uint64_val(num_iterations_ml);

  // discriminant must be an integer
  bool res = verify(discriminant_bytes, discriminant_size, challenge, result,
                    proof, n);
  CAMLreturn(Val_bool(res));
}

CAMLprim value caml_verify_bytecode_stubs(value *argv, int argn) {
  return caml_verify_stubs(argv[0], argv[1], argv[2], argv[3], argv[4],
                           argv[5]);
}
}
