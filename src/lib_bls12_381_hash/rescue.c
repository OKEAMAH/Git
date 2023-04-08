#include "rescue.h"
#include <stdlib.h>
#include <string.h>

blst_fr *rescue_get_state_from_context(rescue_ctxt_t *ctxt) {
  return (ctxt->state);
}

int rescue_get_state_size_from_context(rescue_ctxt_t *ctxt) {
  return (ctxt->state_size);
}

blst_fr *rescue_get_mds_from_context(rescue_ctxt_t *ctxt) {
  // contstants stars after alpha_betas and the state
  return (ctxt->state + ctxt->state_size);
}

blst_fr *rescue_get_round_constants_from_context(rescue_ctxt_t *ctxt) {
  // contstants stars after alpha_betas and the state
  return (ctxt->state + ctxt->state_size + ctxt->state_size * ctxt->state_size);
}

int rescue_get_number_of_constants_from_context(rescue_ctxt_t *ctxt) {
  return (ctxt->state_size * ctxt->nb_rounds * 2);
}

void marvellous_apply_nonlinear_alpha(rescue_ctxt_t *ctxt) {
  blst_fr *state = rescue_get_state_from_context(ctxt);

  blst_fr buffer;
  for (int i = 0; i < ctxt->state_size; i++) {
    // x * (x^2)^2
    blst_fr_sqr(&buffer, state + i);
    blst_fr_sqr(&buffer, &buffer);
    blst_fr_mul(state + i, &buffer, state + i);
  }
}

void marvellous_apply_nonlinear_alphainv(rescue_ctxt_t *ctxt) {
  blst_fr *state = rescue_get_state_from_context(ctxt);

  for (int i = 0; i < ctxt->state_size; i++) {
    blst_fr_pentaroot(state + i, state + i);
  }
}

void marvellous_apply_linear(rescue_ctxt_t *ctxt) {
  blst_fr *state = rescue_get_state_from_context(ctxt);
  blst_fr *mds = rescue_get_mds_from_context(ctxt);

  blst_fr buffer;
  blst_fr res[ctxt->state_size];
  for (int i = 0; i < ctxt->state_size; i++) {
    for (int j = 0; j < ctxt->state_size; j++) {
      if (j == 0) {
        blst_fr_mul(res + i, mds + i * ctxt->state_size + j, state + j);
      } else {
        blst_fr_mul(&buffer, mds + i * ctxt->state_size + j, state + j);
        blst_fr_add(res + i, res + i, &buffer);
      }
    }
  }
  for (int i = 0; i < ctxt->state_size; i++) {
    memcpy(state + i, res + i, sizeof(blst_fr));
  }
}

int marvellous_apply_cst(rescue_ctxt_t *ctxt, int i_round_key) {
  blst_fr *state = rescue_get_state_from_context(ctxt);
  blst_fr *round_constants = rescue_get_round_constants_from_context(ctxt);
  for (int i = 0; i < ctxt->state_size; i++) {
    blst_fr_add(state + i, state + i, round_constants + i_round_key++);
  }
  return (i_round_key);
}

void marvellous_apply_permutation(rescue_ctxt_t *ctxt) {
  int i_round_key = 0;

  for (int i = 0; i < ctxt->nb_rounds; i++) {
    marvellous_apply_nonlinear_alpha(ctxt);
    marvellous_apply_linear(ctxt);
    i_round_key = marvellous_apply_cst(ctxt, i_round_key);
    marvellous_apply_nonlinear_alphainv(ctxt);
    marvellous_apply_linear(ctxt);
    i_round_key = marvellous_apply_cst(ctxt, i_round_key);
  }
}
