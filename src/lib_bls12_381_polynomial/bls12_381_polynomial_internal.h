/* MIT License
 * Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef BLS12_381_POLYNOMIAL_INTERNAL_H
#define BLS12_381_POLYNOMIAL_INTERNAL_H

#include "blst.h"
#include "blst_misc.h"
#include <stdlib.h>
#include <string.h>

// H: domain_size = bls12_381_polynomial_internal degree
// Implementation with side effect. The FFT will be inplace, i.e. the array is
// going to be modified.
void bls12_381_polynomial_internal_fft_inplace(blst_fr *coefficients,
                                               blst_fr *domain,
                                               int log_domain_size, int degree,
                                               int log_degree);

void bls12_381_polynomial_internal_ifft_inplace(blst_fr *coefficients,
                                                blst_fr *domain,
                                                int log_domain_size);

void bls12_381_polynomial_internal_dft_inplace(blst_fr *coefficients,
                                               blst_fr *domain, blst_fr *buffer,
                                               int length, int inverse);

void bls12_381_polynomial_internal_prime_factor_algorithm_fft(
    blst_fr *coefficients, blst_fr *domain1, blst_fr *domain2, int length1,
    int length2, int inverse);

int bls12_381_polynomial_internal_degree(blst_fr *arg, const int n);

bool bls12_381_polynomial_internal_eq(blst_fr *poly_1, blst_fr *poly_2,
                                      int size_1, int size_2);

void bls12_381_polynomial_internal_add(blst_fr *res, blst_fr *arg_1,
                                       blst_fr *arg_2, int size_1, int size_2);

void bls12_381_polynomial_internal_sub(blst_fr *res, blst_fr *arg_1,
                                       blst_fr *arg_2, int size_1, int size_2);

void bls12_381_polynomial_internal_mul(blst_fr *res, const blst_fr *arg_1,
                                       const blst_fr *arg_2, const int size_1,
                                       const int size_2);

void bls12_381_polynomial_internal_mul_by_scalar(blst_fr *res, blst_fr *scalar,
                                                 blst_fr *arg, int size);

void bls12_381_polynomial_internal_linear(
    blst_fr *res, blst_fr **bls12_381_polynomial_internals,
    int *bls12_381_polynomial_internals_len, blst_fr *linear_coeffs,
    int nb_polys);

void bls12_381_polynomial_internal_linear_with_powers(
    blst_fr *res, blst_fr **bls12_381_polynomial_internals,
    int *bls12_381_polynomial_internals_len, blst_fr *linear_coeff,
    int nb_polys);

void bls12_381_polynomial_internal_negate(blst_fr *res, blst_fr *arg, int size);

bool bls12_381_polynomial_internal_is_zero(blst_fr *poly, int size);

void bls12_381_polynomial_internal_evaluate(blst_fr *res, const blst_fr *arg,
                                            const int size,
                                            const blst_fr *scalar);

void bls12_381_polynomial_internal_division_xn(blst_fr *res_q, blst_fr *res_r,
                                               const blst_fr *poly, int size,
                                               int n, const blst_fr *scalar);

void bls12_381_polynomial_internal_mul_xn(blst_fr *res, const blst_fr *poly,
                                          const int size, const int n,
                                          const blst_fr *scalar);

void bls12_381_polynomial_internal_evaluations_add(blst_fr *res,
                                                   blst_fr *eval_1,
                                                   blst_fr *eval_2, int size_1,
                                                   int size_2);

void bls12_381_polynomial_internal_evaluations_rescale(blst_fr *res,
                                                       blst_fr *eval,
                                                       int size_res,
                                                       int size_eval);

void bls12_381_polynomial_internal_evaluations_mul_arrays(
    blst_fr *res, blst_fr **evaluations, int *evaluations_len,
    int *composition_gx, byte **powers, int *powers_numbits, int size_res,
    int nb_evals);

void bls12_381_polynomial_internal_evaluations_linear_arrays(
    blst_fr *res, blst_fr **evaluations, int *evaluations_len,
    blst_fr *linear_coeffs, int *composition_gx, blst_fr *add_constant,
    int size_res, int nb_evals);

void bls12_381_polynomial_internal_derivative(blst_fr *res, blst_fr *poly,
                                              const int size);
#endif
