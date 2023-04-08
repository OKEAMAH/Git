#include "griffin.h"

int griffin_get_state_size_from_context(griffin_ctxt_t *ctxt) {
  return (ctxt->state_size);
}

int griffin_get_number_of_alpha_betas_from_context(griffin_ctxt_t *ctxt) {
  int state_size = griffin_get_state_size_from_context(ctxt);
  return ((state_size - 2) * 2);
}

blst_fr *griffin_get_state_from_context(griffin_ctxt_t *ctxt) {
  return (ctxt->state);
}

void griffin_set_state_from_context(griffin_ctxt_t *ctxt, blst_fr *state) {
  int state_size = griffin_get_state_size_from_context(ctxt);
  blst_fr *ctxt_state = griffin_get_state_from_context(ctxt);

  for (int i = 0; i < state_size; i++) {
    memcpy(ctxt_state + i, state + i, sizeof(blst_fr));
  }
}

blst_fr *griffin_get_alpha_beta_from_context(griffin_ctxt_t *ctxt) {
  // alpha_beta starts just after the state
  return (ctxt->state + ctxt->state_size);
}

blst_fr *griffin_get_round_constants_from_context(griffin_ctxt_t *ctxt) {
  // contstants stars after alpha_betas and the state
  return (ctxt->state + ctxt->state_size +
          griffin_get_number_of_alpha_betas_from_context(ctxt));
}

void griffin_apply_non_linear_layer(griffin_ctxt_t *ctxt) {
  blst_fr *state = griffin_get_state_from_context(ctxt);
  blst_fr *alpha_beta_s = griffin_get_alpha_beta_from_context(ctxt);
  int state_size = griffin_get_state_size_from_context(ctxt);

  blst_fr tmp;
  // y_0 = x_0^(1/d)
  blst_fr_pentaroot(state, state);
  // y_1 = x_1^d
  memcpy(&tmp, state + 1, sizeof(blst_fr));
  blst_fr_sqr(&tmp, &tmp);
  blst_fr_sqr(&tmp, &tmp);
  blst_fr_mul(&tmp, state + 1, &tmp);
  memcpy(state + 1, &tmp, sizeof(blst_fr));

  blst_fr res;
  // Initialize the accumulator for L_i to y_i
  blst_fr acc_l_i;
  memcpy(&acc_l_i, state + 1, sizeof(blst_fr));

  // y_2 = x_2 * [y_0 + y_1] +
  //       alpha_2 * [y_0 + y_1] +
  //       beta_2

  // Will be x_(i - 1) and also will contain alpha_i * acc_l_i
  memset(&tmp, 0, sizeof(blst_fr));
  for (int i = 0; i < state_size - 2; i++) {
    // compute (i - 1) y_0 + y_i. The accumulator contains already y_1 + (i - 2)
    // * y_0
    blst_fr_add(&acc_l_i, &acc_l_i, state);
    // tmp contains either 0 if i = 2 or x_(i - 1) (which is set at the end of
    // this loop)
    blst_fr_add(&acc_l_i, &acc_l_i, &tmp);
    //   -> res = (acc_l_i)^2
    blst_fr_sqr(&res, &acc_l_i);
    // Computing alpha_i * acc_l_i in a tmp var
    //   -> tmp = alpha_i * (acc_l_i)
    blst_fr_mul(&tmp, &acc_l_i, alpha_beta_s + 2 * i);
    //   -> res = res + tmp
    //          = acc_l_i^2 + alpha_i * acc_l_i
    blst_fr_add(&res, &res, &tmp);
    //   -> res = res + beta_i
    //          = acc_l_i^2 + alpha_i * acc_l_i + beta_i
    blst_fr_add(&res, &res, alpha_beta_s + 2 * i + 1);
    //   -> res = x_i * res
    //          = x_i * (acc_l_i^2 + alpha_i * acc_l_i + beta_i)
    blst_fr_mul(&res, &res, state + 2 + i);
    // Copying x_i in tmp for next call
    memcpy(&tmp, state + 2 + i, sizeof(blst_fr));
    // Copying into the state the computed value
    memcpy(state + 2 + i, &res, sizeof(blst_fr));
  }
}

void griffin_apply_linear_layer_3(griffin_ctxt_t *ctxt) {
  blst_fr *state = griffin_get_state_from_context(ctxt);
  blst_fr tmp;

  // We apply the circular matrix Circ(2, 1, 1)
  // -> require 5 additions
  // Compute sum(state)
  blst_fr_add(&tmp, state, state + 1);
  blst_fr_add(&tmp, &tmp, state + 2);

  // Compute x_i = x_i + sum(state)
  blst_fr_add(state, state, &tmp);
  blst_fr_add(state + 1, state + 1, &tmp);
  blst_fr_add(state + 2, state + 2, &tmp);
}

void griffin_apply_linear_layer_4(griffin_ctxt_t *ctxt) {
  blst_fr *state = griffin_get_state_from_context(ctxt);

  blst_fr sum;
  blst_fr x0_copy;
  blst_fr xi_copy;

  blst_fr_add(&sum, state, state + 1);
  blst_fr_add(&sum, &sum, state + 2);
  blst_fr_add(&sum, &sum, state + 3);

  // y_0
  memcpy(&x0_copy, state, sizeof(blst_fr));
  blst_fr_add(state, state, &sum);
  blst_fr_add(state, state, &x0_copy);
  blst_fr_add(state, state, state + 1);

  // y_1
  memcpy(&xi_copy, state + 1, sizeof(blst_fr));
  blst_fr_add(state + 1, state + 1, &sum);
  blst_fr_add(state + 1, state + 1, &xi_copy);
  blst_fr_add(state + 1, state + 1, state + 2);

  // y_2
  memcpy(&xi_copy, state + 2, sizeof(blst_fr));
  blst_fr_add(state + 2, state + 2, &sum);
  blst_fr_add(state + 2, state + 2, &xi_copy);
  blst_fr_add(state + 2, state + 2, state + 3);

  // y_3
  memcpy(&xi_copy, state + 3, sizeof(blst_fr));
  blst_fr_add(state + 3, state + 3, &sum);
  blst_fr_add(state + 3, state + 3, &xi_copy);
  blst_fr_add(state + 3, state + 3, &x0_copy);
}

int griffin_add_constant(griffin_ctxt_t *ctxt, int i_round_key) {
  blst_fr *state = griffin_get_state_from_context(ctxt);
  blst_fr *constants = griffin_get_round_constants_from_context(ctxt);
  int state_size = griffin_get_state_size_from_context(ctxt);

  for (int i = 0; i < state_size; i++) {
    blst_fr_add(state + i, state + i, constants + i_round_key++);
  }
  return (i_round_key);
}

int griffin_apply_one_round(griffin_ctxt_t *ctxt, int i_round_key) {
  // S box
  griffin_apply_non_linear_layer(ctxt);
  // Apply linear layer
  if (ctxt->state_size == 3) {
    griffin_apply_linear_layer_3(ctxt);
  } else if (ctxt->state_size == 4) {
    griffin_apply_linear_layer_4(ctxt);
  } else {
    // Only 3 and 4 is supported at the moment
    assert(1);
  }
  // Constant
  i_round_key = griffin_add_constant(ctxt, i_round_key);
  return (i_round_key);
}

void griffin_apply_permutation(griffin_ctxt_t *ctxt) {
  int i_round_key = 0;

  if (ctxt->state_size == 3) {
    griffin_apply_linear_layer_3(ctxt);
  } else if (ctxt->state_size == 4) {
    griffin_apply_linear_layer_4(ctxt);
  } else {
    // Only 3 and 4 is supported at the moment
    assert(1);
  }

  for (int i = 0; i < ctxt->nb_rounds; i++) {
    i_round_key = griffin_apply_one_round(ctxt, i_round_key);
  }
}

griffin_ctxt_t *griffin_allocate_context(int state_size, int nb_rounds,
                                         blst_fr *constants,
                                         blst_fr *alpha_beta_s) {
  // Check state size
  if (state_size != 3 && state_size % 4 != 0) {
    return (NULL);
  }

  griffin_ctxt_t *ctxt = malloc(sizeof(griffin_ctxt_t));
  if (ctxt == NULL) {
    return (NULL);
  }
  ctxt->state_size = state_size;
  ctxt->nb_rounds = nb_rounds;

  int nb_alpha_beta_s = (state_size - 2) * 2;
  int nb_constants = nb_rounds * state_size;

  int state_full_size = state_size + nb_constants + nb_alpha_beta_s;

  blst_fr *ctxt_state = malloc(sizeof(blst_fr) * state_full_size);
  if (ctxt_state == NULL) {
    free(ctxt);
    return (NULL);
  }
  ctxt->state = ctxt_state;
  blst_fr *ctxt_alpha_beta_s = ctxt_state + state_size;
  blst_fr *ctxt_constants = ctxt_alpha_beta_s + nb_alpha_beta_s;

  memset(ctxt_state, 0, state_size * sizeof(blst_fr));

  for (int i = 0; i < nb_alpha_beta_s; i++) {
    memcpy(ctxt_alpha_beta_s + i, alpha_beta_s + i, sizeof(blst_fr));
  }

  for (int i = 0; i < nb_constants; i++) {
    memcpy(ctxt_constants + i, constants + i, sizeof(blst_fr));
  }

  return (ctxt);
}

void griffin_free_context(griffin_ctxt_t *ctxt) {
  if (ctxt != NULL) {
    free(ctxt->state);
    free(ctxt);
  }
}
