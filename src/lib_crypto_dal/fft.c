#include "caml_bls12_381_stubs.h"
#include "ocaml_integers.h"
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <string.h>
#include <stdlib.h>

#define Blst_fr_array_val(v) ((blst_fr *)Caml_ba_data_val(v))

void dft_inplace(blst_fr *domain, blst_fr *coefficients, blst_fr *scratch, int length, int inverse)
{
  // We copy the coefficients to the scratchpad, to modify the coefficients in place
  memcpy(scratch, coefficients, length * sizeof(blst_fr));
  /*  for (int i = 0; i < length; i++)
    {
      scratch[i] = coefficients[i];
    }*/
  blst_fr tmp;
  for (int i = 0; i < length; i++)
  {
    blst_fr_set_to_zero(coefficients + i);
    for (int j = 0; j < length; j++)
    {
      blst_fr_mul(&tmp, scratch + j, domain + ((i * j) % length));
      blst_fr_add(coefficients + i, coefficients + i, &tmp);
    }
  }
  // Normalizing coefficients
  // TODO: remove if passing inverse domain
  if (inverse)
  {
    blst_fr inv_n, n;
    // blst_scalar_from_uint64 -> representation décimale
    // blst_fr_from_scalar -> conversion Montgomery
    //  pb: length pas élément de Fr
    //  l'allouer une fois pour toute
    blst_fr_from_uint64(&n, (uint64_t[4]){length, 0, 0, 0});
    // passer par les conversions du dessus
    blst_fr_inverse(&inv_n, &n);
    for (int i = 0; i < length; i++)
    {
      blst_fr_mul(coefficients + i, coefficients + i, &inv_n);
    }
  }
}

CAMLprim value dft_c(value domain, value inverse,
                     value length,
                     value coefficients, value scratch)
{
  CAMLparam5(domain, coefficients, scratch, length, inverse);
  blst_fr *domain_c = Blst_fr_array_val(domain);
  blst_fr *coefficients_c = Blst_fr_array_val(coefficients);
  blst_fr *scratch_c = Blst_fr_array_val(scratch);
  dft_inplace(domain_c, coefficients_c,
              scratch_c, Int_val(length), Bool_val(inverse));
  CAMLreturn(Val_unit);
}
