module Exec : sig
  open Pvm_instance

  type phase = Decoding | Initialising | Linking | Evaluating | Padding

  val run_loop : ('a -> phase -> 'a Lwt.t) -> 'a -> 'a Lwt.t

  val pp_phase : phase -> string

  val finish_top_level_call_on_state :
    Tezos_scoru_wasm.Wasm_pvm_state.Internal_state.pvm_state ->
    Tezos_scoru_wasm.Wasm_pvm_state.Internal_state.pvm_state Lwt.t

  val execute_on_state :
    phase ->
    Tezos_scoru_wasm.Wasm_pvm_state.Internal_state.pvm_state ->
    Tezos_scoru_wasm.Wasm_pvm_state.Internal_state.pvm_state Lwt.t

  val run : Lwt_io.file_name -> (string -> 'a Lwt.t) -> 'a Lwt.t

  val set_input_step : int -> string -> Wasm.tree -> Wasm.tree Lwt.t

  val read_message : string -> string

  val initial_boot_sector_from_kernel :
    ?max_tick:int -> string -> Wasm.tree Lwt.t
end
