module Verifier_storage : sig
include
Tx_rollup_l2_storage_sig.STORAGE
with type t = Context.tree
and type 'a m = ('a, error) result Lwt.t
end

module Verifier_context :
  sig
include Tx_rollup_l2_context_sig.CONTEXT with type t = Verifier_storage.t
  end

val verify_message :
  Alpha_context.Tx_rollup_message.t ->
  Context_hash.t ->
  Alpha_context.Tx_rollup_commitment_message_result_hash.t ->
  Context.Proof.stream Context.Proof.t ->
  (Alpha_context.Tx_rollup_commitment_message_result_hash.t, error trace) result Lwt.t
