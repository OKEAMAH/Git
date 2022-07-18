

#include "blst.h"
#include "caml_bls12_381_stubs.h"
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdlib.h>
#include <string.h>

#include <caml/custom.h>

// IMPROVEME: can be improve it with lookups?
int bitreverse__(int n, int l)
{
    int r = 0;
    while (l-- > 0)
    {
        r = (r << 1) | (n & 1);
        n = n >> 1;
    }
    return r;
}

int bitreverse2__(unsigned int n)
{
    // exchanges halves
    n = (n << 16) | (n >> 16);
    // exchange halves of upper and lower halves
    n = ((n & 0x00FF00FF) << 8) | ((n >> 8) & 0x00FF00FF);
    // repeat for the halves of quarters
    n = ((n & 0x0F0F0F0F) << 4) | ((n >> 4) & 0x0F0F0F0F);
    // permute consecutive pairs of bits
    n = ((n & 0x33333333) << 2) | ((n >> 2) & 0x33333333);
    // exchange even and odd bits
    n = ((n & 0x55555555) << 1) | ((n >> 1) & 0x55555555);
    return n;
}

// Fr
void reorg_fr_coefficients_(int n, int logn, value coefficients,
                            blst_fr *buffer)
{
    for (int i = 0; i < n; i++)
    {
        int reverse_i = bitreverse__(i, logn);
        if (i < reverse_i)
        {
            memcpy(buffer, Fr_val_k(coefficients, i), sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, i), Fr_val_k(coefficients, reverse_i),
                   sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, reverse_i), buffer, sizeof(blst_fr));
        }
    }
}

int bitCount(unsigned int n)
{
    n = ((0xaaaaaaaa & n) >> 1) + (0x55555555 & n);
    n = ((0xcccccccc & n) >> 2) + (0x33333333 & n);
    n = ((0xf0f0f0f0 & n) >> 4) + (0x0f0f0f0f & n);
    n = ((0xff00ff00 & n) >> 8) + (0x00ff00ff & n);
    n = ((0xffff0000 & n) >> 16) + (0x0000ffff & n);
    return n;
}

#define TO_BYTE_ARRAY(n, bytes)  \
    bytes[0] = (n >> 24) & 0xFF; \
    bytes[1] = (n >> 16) & 0xFF; \
    bytes[2] = (n >> 8) & 0xFF;  \
    bytes[3] = n & 0xFF;

void precompute_twiddle_factors(int log4_domain_size, blst_fr *phi2N,
                                blst_fr *wa1, blst_fr *wa2, blst_fr *wa3)
{
    // TODO: use unsigned?
    int domain_size = (1 << log4_domain_size) * (1 << log4_domain_size);
    int i = 0;
    for (int p = 0; p < log4_domain_size; p++)
    {
        int J = (1 << p) * (1 << p); // 4^p
        blst_fr wm;
        int exp1, exp2, exp3;
        byte b[4];
        TO_BYTE_ARRAY(J, b);
        blst_fr_pow(&wm, phi2N, b, bitCount(J));
        for (int k = 0; k < domain_size / (4 * J); k++)
        {
            exp1 = 2 * bitreverse2__(k) + 1;
            exp2 = 2 * (2 * bitreverse2__(k) + 1);
            exp3 = 3 * (2 * bitreverse2__(k) + 1);
            TO_BYTE_ARRAY(exp1, b);
            blst_fr_pow(&wa1[i++], &wm, b, bitCount(exp1));
            TO_BYTE_ARRAY(exp2, b);
            blst_fr_pow(&wa2[i++], &wm, b, bitCount(exp2));
            TO_BYTE_ARRAY(exp3, b);
            blst_fr_pow(&wa3[i++], &wm, b, bitCount(exp3));
        }
    }
}

CAMLprim value caml_fft_prepare_stubs2(value log4_domain_size, value phi2N,
                                       value wa1, value wa2, value wa3)
{

    CAMLparam5(log4_domain_size, phi2N, wa1, wa2, wa3);

    blst_fr *wa1_c = Blst_fr_val(wa1);
    blst_fr *wa2_c = Blst_fr_val(wa2);
    blst_fr *wa3_c = Blst_fr_val(wa3);
    blst_fr *phi2N_c = Blst_fr_val(phi2N);
    precompute_twiddle_factors(Int_val(log4_domain_size), phi2N_c,
                               wa1_c, wa2_c, wa3_c);
    CAMLreturn(Val_unit);
}

int intlog(double base, double x)
{
    return (int)(log(x) / log(base));
}

// Radix-4 NTT (bit-reverse free)
void fft_fr_inplace2(value coefficients,
                     blst_fr *wa1, blst_fr *wa2, blst_fr *wa3,
                     blst_fr *primroot4th)
{
    // TODO: check if domain_size fits in int

    blst_fr T[4];
    blst_fr tmp[2];

    int log4_domain_size = intlog(4, )

    int domain_size = (1 << log4_domain_size) * (1 << log4_domain_size);
    int m = 1;

    for (int p = log4_domain_size - 1; p >= 0; p--)
    {
        int J = (1 << p) * (1 << p);
        int r = 0;
        for (int k = 0; k < domain_size / (4 * J); k++)
        {
            r = r + 1;
            for (int j = 0; j < J; j++)
            {

                blst_fr_mul(&T[0], Fr_val_k(coefficients, 4 * k * J + j + 2 * J), &wa2[r]);
                blst_fr_add(&T[0], &T[0], Fr_val_k(coefficients, 4 * k * J + j));

                blst_fr_mul(&T[1], Fr_val_k(coefficients, 4 * k * J + j + 2 * J), &wa2[r]);
                blst_fr_sub(&T[1], Fr_val_k(coefficients, 4 * k * J + j), &T[1]);

                blst_fr_mul(&tmp[0], Fr_val_k(coefficients, 4 * k * J + j + J), &wa1[r]);
                blst_fr_mul(&tmp[1], Fr_val_k(coefficients, 4 * k * J + j + 3 * J), &wa3[r]);

                blst_fr_add(&T[2], &tmp[0], &tmp[1]);
                blst_fr_sub(&T[3], &tmp[0], &tmp[1]);

                // A
                blst_fr_add(Fr_val_k(coefficients, 4 * k * J + j), &T[0], &T[2]);

                blst_fr_mul(Fr_val_k(coefficients, 4 * k * J + j + J), &T[3], primroot4th);
                blst_fr_add(Fr_val_k(coefficients, 4 * k * J + j + J), &T[1], Fr_val_k(coefficients, 4 * k * J + j + 3 * J));

                blst_fr_sub(Fr_val_k(coefficients, 4 * k * J + j + 2 * J), &T[0], &T[2]);

                blst_fr_mul(Fr_val_k(coefficients, 4 * k * J + j + 3 * J), &T[3], primroot4th);
                blst_fr_sub(Fr_val_k(coefficients, 4 * k * J + j + 3 * J), &T[1], Fr_val_k(coefficients, 4 * k * J + j + 3 * J));
            }
        }
    }
}

CAMLprim value caml_fft_fr_inplace_stubs2(value coefficients, value domain,
                                          value log4_domain_size, value wa1,
                                          value wa2, value wa3,
                                          value primroot4th)
{

    CAMLparam5(coefficients, domain, log4_domain_size, wa1, wa2);
    CAMLxparam2(wa3, primroot4th);
    blst_fr *wa1_c = Blst_fr_val(wa1);
    blst_fr *wa2_c = Blst_fr_val(wa2);
    blst_fr *wa3_c = Blst_fr_val(wa3);
    blst_fr *primroot4th_c = Blst_fr_val(primroot4th);
    fft_fr_inplace2(coefficients, domain, Int_val(log4_domain_size),
                    wa1_c, wa2_c, wa3_c, primroot4th_c);
    CAMLreturn(Val_unit);
}
