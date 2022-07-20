

#include "blst.h"
#include "caml_bls12_381_stubs.h"
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

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
void reorg_fr_coefficients_(int n, int logn, value coefficients)
{
    blst_fr buffer;
    for (int i = 0; i < n; i++)
    {
        int reverse_i = bitreverse__(i, logn);
        if (i < reverse_i)
        {
            memcpy(&buffer, Fr_val_k(coefficients, i), sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, i), Fr_val_k(coefficients, reverse_i),
                   sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, reverse_i), &buffer, sizeof(blst_fr));
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

void precompute_twiddle_factors(int domain_size, int log4_domain_size, blst_fr *phi2N,
                                blst_fr *wa)
{
    // TODO: use unsigned?

    int len = (domain_size - domain_size / pow(4, log4_domain_size)) / 3 + 1;

    printf("\n len = %d\n", len);

    int i = 0;
    int J = 1;

    blst_fr wm;
    int exp1, exp2, exp3;
    byte b[4];
    blst_fr *wa1, *wa2, *wa3;

    for (int p = 0; p < log4_domain_size; p++)
    {
        TO_BYTE_ARRAY(J, b);
        blst_fr_pow(&wm, phi2N, b, bitCount(J));
        for (int k = 0; k < domain_size / (4 * J); k++)
        {
            wa1 = wa + i;
            wa2 = wa + (len + i);
            wa3 = wa + (len + i);
            exp1 = 2 * bitreverse2__(k) + 1;
            exp2 = 2 * (2 * bitreverse2__(k) + 1);
            exp3 = 3 * (2 * bitreverse2__(k) + 1);
            TO_BYTE_ARRAY(exp1, b);
            blst_fr_pow(wa1, &wm, b, bitCount(exp1));
            TO_BYTE_ARRAY(exp2, b);
            blst_fr_pow(wa2, &wm, b, bitCount(exp2));
            TO_BYTE_ARRAY(exp3, b);
            // printf("wa3=%p", wa3);
            // blst_fr_set_to_one(wa3);
            // printf("len=%d", len);
            blst_fr_pow(wa3, &wm, b, bitCount(exp3));
            i++;
        }
        J = J * 4;
    }
    printf("\n 2*len+i =%d \n", 2 * len + i);
}

CAMLprim value caml_fft_prepare_stubs2(value domain_size, value log4_domain_size, value phi2N,
                                       value wa)
{

    CAMLparam4(domain_size, log4_domain_size, phi2N, wa);

    blst_fr *wa_c = Blst_fr_val(wa);
    blst_fr *phi2N_c = Blst_fr_val(phi2N);
    precompute_twiddle_factors(Int_val(domain_size), Int_val(log4_domain_size), phi2N_c, wa_c);
    CAMLreturn(Val_unit);
}

int intlog(double base, double x)
{
    return (int)(log(x) / log(base));
}

// Radix-4 NTT (bit-reverse free)
void fft_fr_inplace2(value coefficients, int domain_size, int log4_domain_size,
                     blst_fr *wa,
                     blst_fr *primroot4th)
{
    // TODO: check if domain_size fits in int

    blst_fr T[4];
    blst_fr tmp[4];
    int len = (domain_size - domain_size / pow(4, log4_domain_size)) / 3 + 1;
    printf("\n dom=%d ; log4 dom = %d ; len = %d\n", domain_size, log4_domain_size, len);

    blst_fr *wa1, *wa2, *wa3;

    int J = domain_size;
    int r = 0;
    for (int p = log4_domain_size - 1; p >= 0; p--)
    {
        J = J / 4;

        for (int k = 0; k < domain_size / (4 * J); k++)
        {
            wa1 = wa + r;
            wa2 = wa + (len + r);
            wa3 = wa + ((2 * len) + r);

            for (int j = 0; j < J; j++)
            {

                blst_fr_mul(&tmp[2], Fr_val_k(coefficients, 4 * k * J + j + 2 * J), wa2);

                // blst_fr_mul(&T[0], Fr_val_k(coefficients, 4 * k * J + j + 2 * J), wa2);
                blst_fr_add(&T[0], Fr_val_k(coefficients, 4 * k * J + j), &tmp[2]); // Fr_val_k(coefficients, 4 * k * J + j));

                // blst_fr_mul(&T[1], Fr_val_k(coefficients, 4 * k * J + j + 2 * J), wa2);
                blst_fr_sub(&T[1], Fr_val_k(coefficients, 4 * k * J + j), &tmp[2]);

                // A[4*k*J+j+J]*wa1[r] & A[4*k*J+j+3*J]*wa3[r]
                blst_fr_mul(&tmp[0], Fr_val_k(coefficients, 4 * k * J + j + J), wa1);
                blst_fr_mul(&tmp[1], Fr_val_k(coefficients, 4 * k * J + j + 3 * J), wa3);

                blst_fr_add(&T[2], &tmp[0], &tmp[1]);
                blst_fr_sub(&T[3], &tmp[0], &tmp[1]);

                // A
                // A[4*k*J+j]=T0+T1
                blst_fr_add(Fr_val_k(coefficients, 4 * k * J + j), &T[0], &T[2]);

                blst_fr_mul(&tmp[3], &T[3], primroot4th);

                // A[4*k*J+j+J]= T1+T3*primroot4th
                // blst_fr_mul(Fr_val_k(coefficients, 4 * k * J + j + J), &T[3], primroot4th);
                blst_fr_add(Fr_val_k(coefficients, 4 * k * J + j + J), &T[1], &tmp[4]);

                // A[4*k*J+j+2*J]=T0-T2
                blst_fr_sub(Fr_val_k(coefficients, 4 * k * J + j + 2 * J), &T[0], &T[2]);

                // A[4*k*J+j+3*J]=T1-T3*primroot4th
                // blst_fr_mul(Fr_val_k(coefficients, 4 * k * J + j + 3 * J), &T[3], primroot4th);
                blst_fr_sub(Fr_val_k(coefficients, 4 * k * J + j + 3 * J), &T[1], &tmp[4]); // Fr_val_k(coefficients, 4 * k * J + j + 3 * J));
            }

            r++;
        }
    }
    printf("\n r=%d \n", r);
}

CAMLprim value caml_fft_fr_inplace_stubs2(value coefficients, value domain_size,
                                          value log4_domain_size, value wa,
                                          value primroot4th)
{

    CAMLparam5(coefficients, domain_size, log4_domain_size, wa, primroot4th);
    blst_fr *wa_c = Blst_fr_val(wa);
    blst_fr *primroot4th_c = Blst_fr_val(primroot4th);
    fft_fr_inplace2(coefficients, Int_val(domain_size), Int_val(log4_domain_size),
                    wa_c, primroot4th_c);
    CAMLreturn(Val_unit);
}

// Fr
void reorg_fr_coefficients__(int n, value coefficients)
{
    /*for (int i = 0; i < n; i++)
    {
        int reverse_i = bitreverse__(i, logn);
        if (i < reverse_i)
        {
            memcpy(buffer, Fr_val_k(coefficients, i), sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, i), Fr_val_k(coefficients, reverse_i),
                   sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, reverse_i), buffer, sizeof(blst_fr));
        }
    }*/
    blst_fr buffer;
    for (int i = 1, j = 0; i < n; i++)
    {
        int bit = n >> 1;
        for (; j & bit; bit >>= 1)
            j ^= bit;
        j ^= bit;

        if (i < j)
        {
            memcpy(&buffer, Fr_val_k(coefficients, i), sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, i), Fr_val_k(coefficients, j),
                   sizeof(blst_fr));
            memcpy(Fr_val_k(coefficients, j), &buffer, sizeof(blst_fr));
        }
    }
}

void fft_fr_inplace4mod(value coefficients, value domain, int log_domain_size, int log4)
{
    // FIXME: add a check on the domain_size to avoid ariane crash
    blst_fr *buffer = (blst_fr *)calloc(1, sizeof(blst_fr));

    int domain_size = 1 << log_domain_size;

    reorg_fr_coefficients__(domain_size, coefficients);
    int k, j;
    for (int transformSize = 2; transformSize <= domain_size; transformSize *= 2)
    {
        int xDist = transformSize / 2;
        int twiddleFacStep = domain_size / transformSize;

        for (int i = 0; i < domain_size; i += transformSize)
        {

            for (j = i, k = 0; j < i + xDist; j++, k += twiddleFacStep)
            {
                blst_fr_mul(buffer, Fr_val_k(coefficients, j + xDist),
                            Fr_val_k(domain, k));
                blst_fr_sub(Fr_val_k(coefficients, j + xDist),
                            Fr_val_k(coefficients, j), buffer);
                blst_fr_add(Fr_val_k(coefficients, j),
                            Fr_val_k(coefficients, j), buffer);
            }
        }
    }
    free(buffer);
}

void fft_fr_inplaceRadix4(value coefficients, value domain, int log_domain_size, int log4_domain_size)
{

    blst_fr T0, T1, T2, T3;
    blst_fr tmp0, tmp1;

    int domain_size = 1 << log_domain_size;

    blst_fr *primroot4th = Fr_val_k(domain, domain_size / 4);

    reorg_fr_coefficients__(domain_size, coefficients);

    int j, k;
    for (int transformSize = 4; transformSize <= domain_size; transformSize *= 4)
    {
        int xDist = transformSize / 4;
        int twiddleFactorStep = domain_size / transformSize;

        for (int i = 0; i < domain_size; i += transformSize)
        {
            for (j = i, k = 0; j < i + xDist; j++, k += twiddleFactorStep)
            {
                // A[k+j+2m] * w_N^(2j*exponent)
                blst_fr_mul(&tmp0, Fr_val_k(coefficients, j + 2 * xDist), Fr_val_k(domain, 2 * k));

                // T0 = A[k+j] + A[k+j+2*m] * w_N^(2j*exponent)
                blst_fr_add(&T0, Fr_val_k(coefficients, j), &tmp0);

                // T1 = A[k+j] - A[k+j+2*m] * w_N^(2j*exponent)
                blst_fr_sub(&T1, Fr_val_k(coefficients, j), &tmp0);

                // A[k+j+m] * w_N^(j*exponent)
                blst_fr_mul(&tmp0, Fr_val_k(coefficients, j + xDist), Fr_val_k(domain, k));
                // A[k+j+3*m] * w_N^(3j*exponent)
                blst_fr_mul(&tmp1, Fr_val_k(coefficients, j + 3 * xDist), Fr_val_k(domain, 3 * k));

                // T2 = A[k+j+m] * w_N^(j*exponent) + A[k+j+3*m] * w_N^(3j*exponent)
                blst_fr_add(&T2, &tmp0, &tmp1);
                // T3 = A[k+j+m] * w_N^(j*exponent) - A[k+j+3*m] * w_N^(3j*exponent)
                blst_fr_sub(&T3, &tmp0, &tmp1);

                // F0'=A[k+j]=T0+T2
                blst_fr_add(Fr_val_k(coefficients, j), &T0, &T2);

                blst_fr_mul(&tmp0, &T3, primroot4th);

                // F1'=A[k+j+m]= T1+T3*primroot4th
                blst_fr_add(Fr_val_k(coefficients, j + xDist), &T1, &tmp0);

                // F2'=A[k+j+2*m]=T0-T2
                blst_fr_sub(Fr_val_k(coefficients, j + 2 * xDist), &T0, &T2);

                // F3'=A[k+j+3*m]=T1-T3*primroot4th
                blst_fr_sub(Fr_val_k(coefficients, j + 3 * xDist), &T1, &tmp0);
            }
        }
    }
}

void fft_fr_inplace3(value coefficients, value domain, int log_domain_size, int log4_domain_size)
{
    blst_fr T0, T1, T2, T3;
    blst_fr tmp0, tmp1;

    int domain_size = 1 << log_domain_size;

    blst_fr *primroot4th = Fr_val_k(domain, domain_size / 4);
    int m = 1;
    reorg_fr_coefficients__(domain_size, coefficients);
    int c = 0;
    for (int i = 0; i < log4_domain_size; i++)
    {
        c++;
        int exponent = domain_size / (4 * m);

        for (int k = 0; k < domain_size; k = k + 4 * m)
        {
            c++;
            for (int j = 0; j < m; j++)
            {
                c++;
                // A[k+j+2m] * w_N^(2j*exponent)
                blst_fr_mul(&tmp0, Fr_val_k(coefficients, k + j + 2 * m), Fr_val_k(domain, exponent * 2 * j));

                // T0 = A[k+j] + A[k+j+2*m] * w_N^(2j*exponent)
                blst_fr_add(&T0, Fr_val_k(coefficients, k + j), &tmp0);

                // T1 = A[k+j] - A[k+j+2*m] * w_N^(2j*exponent)
                blst_fr_sub(&T1, Fr_val_k(coefficients, k + j), &tmp0);

                // A[k+j+m] * w_N^(j*exponent)
                blst_fr_mul(&tmp0, Fr_val_k(coefficients, k + j + m), Fr_val_k(domain, exponent * j));
                // A[k+j+3*m] * w_N^(3j*exponent)
                blst_fr_mul(&tmp1, Fr_val_k(coefficients, k + j + 3 * m), Fr_val_k(domain, exponent * 3 * j));

                // T2 = A[k+j+m] * w_N^(j*exponent) + A[k+j+3*m] * w_N^(3j*exponent)
                blst_fr_add(&T2, &tmp0, &tmp1);
                // T3 = A[k+j+m] * w_N^(j*exponent) - A[k+j+3*m] * w_N^(3j*exponent)
                blst_fr_sub(&T3, &tmp0, &tmp1);

                // F0'=A[k+j]=T0+T2
                blst_fr_add(Fr_val_k(coefficients, k + j), &T0, &T2);

                blst_fr_mul(&tmp0, primroot4th, &T3);

                // F1'=A[k+j+m]= T1+T3*primroot4th
                blst_fr_add(Fr_val_k(coefficients, k + j + m), &T1, &tmp0);

                // F2'=A[k+j+2*m]=T0-T2
                blst_fr_sub(Fr_val_k(coefficients, k + j + 2 * m), &T0, &T2);

                // F3'=A[k+j+3*m]=T1-T3*primroot4th
                blst_fr_sub(Fr_val_k(coefficients, k + j + 3 * m), &T1, &tmp0);
                /*blst_fr_mul(&T0, Fr_val_k(coefficients, j + k + m), Fr_val_k(domain, j));
                blst_fr_mul(&T1, Fr_val_k(coefficients, j + k + 2 * m), Fr_val_k(domain, 2 * j));
                blst_fr_mul(&T2, Fr_val_k(coefficients, j + k + 3 * m), Fr_val_k(domain, 3 * j));

                blst_fr_add(Fr_val_k(coefficients, j + k), Fr_val_k(coefficients, j + k), &T0);
                blst_fr_add(Fr_val_k(coefficients, j + k), Fr_val_k(coefficients, j + k), &T1);
                blst_fr_add(Fr_val_k(coefficients, j + k), Fr_val_k(coefficients, j + k), &T2);

                blst_fr_add(Fr_val_k(coefficients, j + k + 2 * m), Fr_val_k(coefficients, j + k), &T1);
                blst_fr_sub(Fr_val_k(coefficients, j + k + 2 * m), Fr_val_k(coefficients, j + k + 2 * m), &T0);
                blst_fr_sub(Fr_val_k(coefficients, j + k + 2 * m), Fr_val_k(coefficients, j + k + 2 * m), &T2);

                blst_fr_sub(Fr_val_k(coefficients, j + k + m), Fr_val_k(coefficients, j + k), &T1);
                blst_fr_sub(Fr_val_k(coefficients, j + k + 3 * m), Fr_val_k(coefficients, j + k), &T1);

                blst_fr_mul(&tmp0, primroot4th, &T0);
                blst_fr_mul(&tmp1, primroot4th, &T2);

                blst_fr_add(Fr_val_k(coefficients, j + k + m), Fr_val_k(coefficients, j + k + m), &tmp0);
                blst_fr_sub(Fr_val_k(coefficients, j + k + m), Fr_val_k(coefficients, j + k + m), &tmp1);

                blst_fr_add(Fr_val_k(coefficients, j + k + 3 * m), Fr_val_k(coefficients, j + k + 3 * m), &tmp1);
                blst_fr_sub(Fr_val_k(coefficients, j + k + 3 * m), Fr_val_k(coefficients, j + k + 3 * m), &tmp0);*/
            }
        }
        m = 4 * m;
    }
    printf("n iter = %d", c);
}

CAMLprim value caml_fft_fr_inplace_stubs3(value coefficients, value domain,
                                          value log_domain_size, value log4_domain_size)
{
    CAMLparam4(coefficients, domain, log_domain_size, log4_domain_size);
    fft_fr_inplace3(coefficients, domain, Int_val(log_domain_size), Int_val(log4_domain_size));
    CAMLreturn(Val_unit);
}

void mul_map_fr_inplace3(value coefficients, value factor, int domain_size)
{
    for (int i = 0; i < domain_size; i++)
    {
        blst_fr_mul(Fr_val_k(coefficients, i), Fr_val_k(coefficients, i),
                    Blst_fr_val(factor));
    }
}
CAMLprim value caml_mul_map_fr_inplace_stubs3(value coefficients, value factor,
                                              value domain_size)
{
    CAMLparam3(coefficients, factor, domain_size);
    mul_map_fr_inplace3(coefficients, factor, Int_val(domain_size));
    CAMLreturn(Val_unit);
}
