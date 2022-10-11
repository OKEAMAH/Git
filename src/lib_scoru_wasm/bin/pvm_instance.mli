module Context = Tezos_context_memory.Context_binary

module Wasm : Tezos_scoru_wasm.Gather_floppies.S with type tree = Context.tree

open Tezos_scoru_wasm
open Wasm_pvm_state

val get_tick_from_tree : Wasm.tree -> Z.t Lwt.t

val get_tick_from_pvm_state : Internal_state.pvm_state -> Z.t Lwt.t

module PP : sig
  val pp_error_state : Wasm_pvm_errors.t -> string

  val tick_label : Internal_state.tick_state -> string
end
