#include "anemoi.h"
#include <stdio.h>
#include <stdlib.h>

int anemoi_get_state_size_from_context(anemoi_ctxt_t *ctxt) {
  // shift by state size
  return (2 * ctxt->l);
}

blst_fr *anemoi_get_state_from_context(anemoi_ctxt_t *ctxt) {
  // shift by state size
  return (ctxt->ctxt);
}

blst_fr *anemoi_get_mds_from_context(anemoi_ctxt_t *ctxt) {
  // shift by state size
  return (ctxt->ctxt + 2 * ctxt->l);
}

blst_fr *anemoi_get_round_constants_from_context(anemoi_ctxt_t *ctxt) {
  // shift by state size and MDS
  int state_size = anemoi_get_state_size_from_context(ctxt);
  return (ctxt->ctxt + state_size + ctxt->l * ctxt->l);
}

int anemoi_get_number_of_constants(anemoi_ctxt_t *ctxt) {
  return (ctxt->l * ctxt->nb_rounds * 2);
}

blst_fr *anemoi_get_beta_from_context(anemoi_ctxt_t *ctxt) {
  int nb_constants = anemoi_get_number_of_constants(ctxt);
  int state_size = anemoi_get_state_size_from_context(ctxt);
  return (ctxt->ctxt + state_size + ctxt->l * ctxt->l + nb_constants);
}

blst_fr *anemoi_get_delta_from_context(anemoi_ctxt_t *ctxt) {
  int nb_constants = anemoi_get_number_of_constants(ctxt);
  int state_size = anemoi_get_state_size_from_context(ctxt);
  return (ctxt->ctxt + state_size + ctxt->l * ctxt->l + nb_constants + 1);
}

void anemoi_fr_multiply_by_g(blst_fr *res, blst_fr *v) {
  blst_fr tmp;

  // Compute g * y and save it in tmp.
  // multiply by 7
  // y + y
  blst_fr_add(&tmp, v, v);
  // 2y + y
  blst_fr_add(&tmp, &tmp, v);
  // 3y + 3y
  blst_fr_add(&tmp, &tmp, &tmp);
  // 6y + y
  blst_fr_add(res, &tmp, v);
}

void blst_fr_double(blst_fr *r, blst_fr *x) { blst_fr_add(r, x, x); }

void anemoi_apply_constants_addition(anemoi_ctxt_t *ctxt, int round) {
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  blst_fr *state_x = state;
  blst_fr *state_y = state + ctxt->l;
  blst_fr *constants = anemoi_get_round_constants_from_context(ctxt);
  blst_fr *constants_x = constants;
  blst_fr *constants_y = constants + ctxt->nb_rounds * ctxt->l;
  for (int i = 0; i < ctxt->l; i++) {
    blst_fr_add(state_x + i, state_x + i, constants_x + ctxt->l * round + i);
    blst_fr_add(state_y + i, state_y + i, constants_y + ctxt->l * round + i);
  }
}

void anemoi_apply_shift_state(anemoi_ctxt_t *ctxt) {
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  blst_fr *state_y = state + ctxt->l;
  blst_fr tmp;

  memcpy(&tmp, state_y, sizeof(blst_fr));
  // And we apply the rotation
  // y_(i) <- y_(i + 1)
  for (int i = 0; i < ctxt->l - 1; i++) {
    memcpy(state_y + i, state_y + i + 1, sizeof(blst_fr));
  }
  // Put y_0 into y_(l - 1)
  memcpy(state_y + ctxt->l - 1, &tmp, sizeof(blst_fr));
}

void anemoi_1_apply_linear_layer(anemoi_ctxt_t *ctxt) {
  blst_fr tmp;
  blst_fr *state = anemoi_get_state_from_context(ctxt);

  // Compute "g * y' and save it in tmp.
  anemoi_fr_multiply_by_g(&tmp, state + 1);
  // x += g * y. Inplace operation
  blst_fr_add(state, state, &tmp);

  // Compute "g * x' and save it in tmp.
  anemoi_fr_multiply_by_g(&tmp, state);

  blst_fr_add(state + 1, state + 1, &tmp);
}

void anemoi_2_apply_linear_layer(anemoi_ctxt_t *ctxt) {
  blst_fr *state_x = anemoi_get_state_from_context(ctxt);
  blst_fr *state_y = state_x + ctxt->l;
  blst_fr tmp;

  // Apply M_x
  // Compute "g * y' and save it in tmp.
  anemoi_fr_multiply_by_g(&tmp, state_x + 1);
  // x += g * y. Inplace operation
  blst_fr_add(state_x, state_x, &tmp);

  // Compute "g * x' and save it in tmp.
  anemoi_fr_multiply_by_g(&tmp, state_x);

  blst_fr_add(state_x + 1, state_x + 1, &tmp);

  // swap y_1 et y_0 for linear layer
  memcpy(&tmp, state_y, sizeof(blst_fr));
  memcpy(state_y, state_y + 1, sizeof(blst_fr));
  memcpy(state_y + 1, &tmp, sizeof(blst_fr));

  // Apply M_y
  // Compute "g * y' and save it in tmp.
  anemoi_fr_multiply_by_g(&tmp, state_y + 1);
  // x += g * y. Inplace operation
  blst_fr_add(state_y, state_y, &tmp);

  // Compute "g * x' and save it in tmp.
  anemoi_fr_multiply_by_g(&tmp, state_y);

  blst_fr_add(state_y + 1, state_y + 1, &tmp);
}

// l = 3
void anemoi_3_apply_matrix(blst_fr *ctxt) {
  blst_fr tmp;
  blst_fr g_x0;

  // t = x[0] + g * x[2]
  anemoi_fr_multiply_by_g(&tmp, ctxt + 2);
  blst_fr_add(&tmp, &tmp, ctxt);

  // x[2] += x[1]
  blst_fr_add(ctxt + 2, ctxt + 2, ctxt + 1);
  // x[2] += b * x[0]
  anemoi_fr_multiply_by_g(&g_x0, ctxt);
  blst_fr_add(ctxt + 2, ctxt + 2, &g_x0);

  // x[0] = t + x[2]
  blst_fr_add(ctxt, ctxt + 2, &tmp);
  // x[1] += t
  blst_fr_add(ctxt + 1, ctxt + 1, &tmp);
}

void anemoi_3_apply_linear_layer(anemoi_ctxt_t *ctxt) {
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  blst_fr *state_x = state;
  blst_fr *state_y = state_x + ctxt->l;

  anemoi_3_apply_matrix(state_x);
  anemoi_apply_shift_state(ctxt);
  anemoi_3_apply_matrix(state_y);
}

// l = 4
void anemoi_4_apply_matrix(blst_fr *ctxt) {
  blst_fr tmp;

  // x[0] += x[1]
  blst_fr_add(ctxt, ctxt, ctxt + 1);
  // x[2] += x[3]
  blst_fr_add(ctxt + 2, ctxt + 2, ctxt + 3);
  // x[3] += g x[0]
  anemoi_fr_multiply_by_g(&tmp, ctxt);
  blst_fr_add(ctxt + 3, ctxt + 3, &tmp);
  // x[1] = g * (x[1] + x[2])
  blst_fr_add(&tmp, ctxt + 1, ctxt + 2);
  anemoi_fr_multiply_by_g(ctxt + 1, &tmp);
  // x[0] += x[1]
  blst_fr_add(ctxt, ctxt, ctxt + 1);
  // x[2] += g x[3]
  anemoi_fr_multiply_by_g(&tmp, ctxt + 3);
  blst_fr_add(ctxt + 2, ctxt + 2, &tmp);
  // x[1] += x[2]
  blst_fr_add(ctxt + 1, ctxt + 1, ctxt + 2);
  // x[3] += x[0]
  blst_fr_add(ctxt + 3, ctxt + 3, ctxt);
}

void anemoi_4_apply_linear_layer(anemoi_ctxt_t *ctxt) {
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  blst_fr *state_x = state;
  blst_fr *state_y = state_x + ctxt->l;

  anemoi_4_apply_matrix(state_x);
  anemoi_apply_shift_state(ctxt);
  anemoi_4_apply_matrix(state_y);
}

void anemoi_apply_s_box(blst_fr *x, blst_fr *y, blst_fr *beta, blst_fr *delta) {
  blst_fr tmp;
  // First we compute x_i = x_i - beta * y^2 = x_i - Q_i(y_i)
  // -- compute y^2
  blst_fr_sqr(&tmp, y);
  // -- Compute beta * y^2
  blst_fr_mul(&tmp, &tmp, beta);
  // -- Compute x = x - beta * y^2
  blst_fr_sub(x, x, &tmp);
  // Computing E(x)
  // -- Coppute x^alpha_inv and save it in tmp.
  // NB: this is the costly operation.
  // IMPROVEME: can be improved using addchain. Would be 21% faster (305 ops
  // instead of 384).
  // > addchain search
  // '20974350070050476191779096203274386335076221000211055129041463479975432473805'
  // > addition cost: 305
  blst_fr_pentaroot(&tmp, x);
  /* blst_fr_pow(&tmp, ctxt, ALPHA_INV_BYTES, ALPHA_INV_NUMBITS); */
  // -- Compute y_i = y_i - x^(alpha_inv) = y_i - E(x_i)
  blst_fr_sub(y, y, &tmp);
  // Computing x_i = x_i + (beta * y^2 + delta) = x_i + Q_f(x_i)
  // -- compute y^2
  blst_fr_sqr(&tmp, y);
  // -- compute beta * y^2
  blst_fr_mul(&tmp, &tmp, beta);
  // -- compute beta * y^2 + delta
  blst_fr_add(&tmp, &tmp, delta);
  // -- compute x + x + beta * y^2 + delta
  blst_fr_add(x, x, &tmp);
}

void anemoi_1_apply_flystel(anemoi_ctxt_t *ctxt) {
  blst_fr *beta = anemoi_get_beta_from_context(ctxt);
  blst_fr *delta = anemoi_get_delta_from_context(ctxt);
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  anemoi_apply_s_box(state, state + 1, beta, delta);
}

void anemoi_1_apply(anemoi_ctxt_t *ctxt) {
  for (int i = 0; i < ctxt->nb_rounds; i++) {
    // add cst
    anemoi_apply_constants_addition(ctxt, i);
    // apply linear layer
    anemoi_1_apply_linear_layer(ctxt);
    // apply sbox
    anemoi_1_apply_flystel(ctxt);
  }

  // Final call to linear layer. See page 15, High Level Algorithms
  anemoi_1_apply_linear_layer(ctxt);
}

void anemoi_generic_apply_flystel(anemoi_ctxt_t *ctxt) {
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  blst_fr *beta = anemoi_get_beta_from_context(ctxt);
  blst_fr *delta = anemoi_get_delta_from_context(ctxt);
  for (int i = 0; i < ctxt->l; i++) {
    anemoi_apply_s_box(state + i, state + ctxt->l + i, beta, delta);
  }
}

void anemoi_generic_apply_linear_layer(anemoi_ctxt_t *ctxt) {
  blst_fr *state = anemoi_get_state_from_context(ctxt);
  blst_fr *state_x = state;
  blst_fr *state_y = state + ctxt->l;
  blst_fr *mds = anemoi_get_mds_from_context(ctxt);

  blst_fr buffer[ctxt->l];

  blst_fr tmp;

  // Applying matrix multiplication
  for (int i = 0; i < ctxt->l; i++) {
    memset(buffer + i, 0, sizeof(blst_fr));
    for (int j = 0; j < ctxt->l; j++) {
      blst_fr_mul(&tmp, state_x + j, mds + j * ctxt->l + i);
      blst_fr_add(buffer + i, buffer + i, &tmp);
    }
  }

  // Copying the buffer into state
  for (int i = 0; i < ctxt->l; i++) {
    memcpy(state_x + i, buffer + i, sizeof(blst_fr));
  }

  memcpy(&tmp, state_y, sizeof(blst_fr));
  // And we apply the rotation
  // y_(i) <- y_(i + 1)
  for (int i = 0; i < ctxt->l - 1; i++) {
    memcpy(state_y + i, state_y + i + 1, sizeof(blst_fr));
  }
  // Put y_0 into y_(l - 1)
  memcpy(state_y + ctxt->l - 1, &tmp, sizeof(blst_fr));

  // Applying matrix multiplication
  for (int i = 0; i < ctxt->l; i++) {
    memset(buffer + i, 0, sizeof(blst_fr));
    for (int j = 0; j < ctxt->l; j++) {
      blst_fr_mul(&tmp, state_y + j, mds + j * ctxt->l + i);
      blst_fr_add(buffer + i, buffer + i, &tmp);
    }
  }

  // Copying the buffer into state
  for (int i = 0; i < ctxt->l; i++) {
    memcpy(state_y + i, buffer + i, sizeof(blst_fr));
  }
}

void anemoi_apply_flystel(anemoi_ctxt_t *ctxt) {
  if (ctxt->l == 1) {
    anemoi_1_apply_flystel(ctxt);
  } else
    anemoi_generic_apply_flystel(ctxt);
}

void anemoi_apply_linear_layer(anemoi_ctxt_t *ctxt) {
  if (ctxt->l == 1) {
    anemoi_1_apply_linear_layer(ctxt);
  }

  else if (ctxt->l == 2) {
    anemoi_2_apply_linear_layer(ctxt);
  }

  else if (ctxt->l == 3) {
    anemoi_3_apply_linear_layer(ctxt);
  }

  else if (ctxt->l == 4) {
    anemoi_4_apply_linear_layer(ctxt);
  }

  else {
    anemoi_generic_apply_linear_layer(ctxt);
  }
}

void anemoi_apply_one_round(anemoi_ctxt_t *ctxt, int round) {
  anemoi_apply_constants_addition(ctxt, round);
  anemoi_apply_linear_layer(ctxt);
  anemoi_apply_flystel(ctxt);
}

void anemoi_apply_permutation(anemoi_ctxt_t *ctxt) {
  for (int i = 0; i < ctxt->nb_rounds; i++) {
    anemoi_apply_one_round(ctxt, i);
  }

  anemoi_apply_linear_layer(ctxt);
}

void anemoi_set_state_from_context(anemoi_ctxt_t *ctxt, blst_fr *state) {
  int state_size = anemoi_get_state_size_from_context(ctxt);
  blst_fr *ctxt_state = anemoi_get_state_from_context(ctxt);

  for (int i = 0; i < state_size; i++) {
    memcpy(ctxt_state + i, state + i, sizeof(blst_fr));
  }
}

anemoi_ctxt_t *anemoi_allocate_context(int l, int nb_rounds) {
  // Returning null because we do not support bigger state size than 8 at the
  // moment
  if (l > 4 || l < 0) {
    return (NULL);
  }

  anemoi_ctxt_t *ctxt = malloc(sizeof(anemoi_ctxt_t));
  if (ctxt == NULL) {
    return (NULL);
  }
  blst_fr *state = malloc(sizeof(anemoi_ctxt_t));
  if (state == NULL) {
    free(ctxt);
    return (NULL);
  }

  ctxt->l = l;
  ctxt->nb_rounds = nb_rounds;
  ctxt->ctxt = state;

  return (ctxt);
}

void anemoi_free_context(anemoi_ctxt_t *ctxt) {
  if (ctxt != NULL) {
    free(ctxt->ctxt);
    free(ctxt);
  }
}
