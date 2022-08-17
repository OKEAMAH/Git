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

void reorg_fr_coefficients_(int n, blst_fr *coefficients)
{
  blst_fr buffer;
  for (int i = 1, j = 0; i < n; i++)
  {
    int bit = n >> 1;
    for (; j & bit; bit >>= 1)
      j ^= bit;
    j ^= bit;
    if (i < j)
    {
      memcpy(&buffer, coefficients + i, sizeof(blst_fr));
      memcpy(coefficients + i, coefficients + j,
             sizeof(blst_fr));
      memcpy(coefficients + j, &buffer, sizeof(blst_fr));
    }
  }
}

// Taken from https://gitlab.com/dannywillems/ocaml-bls12-381/
void fft_fr_inplace_(blst_fr *coefficients, blst_fr *domain, int log_domain_size)
{
  // FIXME: add a check on the domain_size to avoid ariane crash
  blst_fr buffer;

  int domain_size = 1 << log_domain_size;
  int m = 1;
  reorg_fr_coefficients_(domain_size, coefficients);

  for (int i = 0; i < log_domain_size; i++)
  {
    int exponent = domain_size / (2 * m);
    int k = 0;
    while (k < domain_size)
    {
      for (int j = 0; j < m; j++)
      {
        blst_fr_mul(&buffer, coefficients + (k + j + m),
                    domain + (exponent * j));
        blst_fr_sub(coefficients + (k + j + m),
                    coefficients + (k + j), &buffer);
        blst_fr_add(coefficients + (k + j),
                    coefficients + (k + j), &buffer);
      }
      k = k + (2 * m);
    }
    m = 2 * m;
  }
}

// TODO: get rid of transpose, read coefficients in the FFT in the correct order through a flag
void transpose(blst_fr *matrix, int rows, int columns)
{
  blst_fr tmp;
  for (int i = 0; i < rows; i++)
  {
    for (int j = i + 1; j < columns; j++)
    {
      tmp = matrix[j * rows + i];
      matrix[j * rows + i] = matrix[j + i * columns];
      matrix[j + i * columns] = tmp;
    }
  }
}

// The scratch zone must have size at least |domain1| * |domain2|
void prime_factor_algorithm_fft_(blst_fr *domain1, blst_fr *domain2, int length1_log, int length2, blst_fr *coefficients, blst_fr *scratch, int inverse)
{
  int length1 = 1 << length1_log;
  blst_fr scratch_dft[length2];
  int length = length1 * length2;
  for (int i = 0; i < length; i++)
  {
    scratch[(i % length1) * length2 + (i % length2)] = coefficients[i];
  }

  for (int i = 0; i < length1; i++)
  {
    dft_inplace(domain2, scratch + (i * length2), scratch_dft, length2, inverse);
  }

  transpose(scratch, length2, length1);

  for (int i = 0; i < length2; i++)
  {
    fft_fr_inplace_(scratch + (i * length1), domain1, length1_log);
  }

  for (int i = 0; i < length1; i++)
  {
    for (int j = 0; j < length2; j++)
    {
      coefficients[(length1 * j + length2 * i) % length] = scratch[j * length1 + i];
    }
  }
}

CAMLprim value prime_factor_algorithm_fft_native(value inverse, value domain1, value domain2,
                                                 value length1_log, value length2,
                                                 value coefficients, value scratch)
{
  CAMLparam5(domain1, domain2, length1_log, length2, coefficients);
  CAMLxparam2(scratch, inverse);
  prime_factor_algorithm_fft_(Blst_fr_array_val(domain1), Blst_fr_array_val(domain2),
                              Int_val(length1_log), Int_val(length2),
                              Blst_fr_array_val(coefficients),
                              Blst_fr_array_val(scratch),
                              Bool_val(inverse));
  CAMLreturn(Val_unit);
}

CAMLprim value prime_factor_algorithm_fft_bytecode(value *argv, int argn)
{
  prime_factor_algorithm_fft_native(argv[0], argv[1], argv[2], argv[3],
                                    argv[4], argv[5], argv[6]);
}
