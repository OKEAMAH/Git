#ifndef POLYNOMIAL_H
#define POLYNOMIAL_H

#include "blst.h"
#include "blst_misc.h"
#include <stdlib.h>
#include <string.h>

// H: domain_size = polynomial degree
// Implementation with side effect. The FFT will be inplace, i.e. the array is
// going to be modified.
void fft_inplace(blst_fr *coefficients, blst_fr *domain, int log_domain_size);

void ifft_inplace(blst_fr *coefficients, blst_fr *domain, int log_domain_size);

int degree(blst_fr *arg, const int n);

bool eq(blst_fr *poly_1, blst_fr *poly_2, int size_1, int size_2);

void add(blst_fr *res, blst_fr *arg_1, blst_fr *arg_2, int size_1, int size_2);

void sub(blst_fr *res, blst_fr *arg_1, blst_fr *arg_2, int size_1, int size_2);

void mul(blst_fr *res, const blst_fr *arg_1, const blst_fr *arg_2,
         const int size_1, const int size_2);

void mul_by_scalar(blst_fr *res, blst_fr *scalar, blst_fr *arg, int size);

void negate(blst_fr *res, blst_fr *arg, int size);

bool is_zero(blst_fr *poly, int size);

void evaluate(blst_fr *res, const blst_fr *arg, const int size,
              const blst_fr *scalar);

void division_x_z(blst_fr *res, const blst_fr *poly, int size, blst_fr *z);

void division_zs(blst_fr *res, const blst_fr *poly, int size, int n);

void mul_zs(blst_fr *res, const blst_fr *poly, const int size, const int n);

void evaluations_add(blst_fr *res, blst_fr *eval_1, blst_fr *eval_2, int size_1,
                     int size_2);

void evaluations_rescale(blst_fr *res, blst_fr *eval, int size_res,
                         int size_eval);

void evaluations_mul_arrays(blst_fr *res, blst_fr **evaluations,
                            int *evaluations_len, int *composition_gx,
                            byte **powers, int *powers_numbits, int size_res,
                            int nb_evals);

void evaluations_linear_arrays(blst_fr *res, blst_fr **evaluations,
                               int *evaluations_len, blst_fr *linear_coeffs,
                               int *composition_gx, blst_fr *add_constant,
                               int size_res, int nb_evals);

void derivative(blst_fr *res, blst_fr *poly, const int size);

#endif
