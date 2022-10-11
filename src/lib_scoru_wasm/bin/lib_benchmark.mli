module Data : sig
  type time = float

  type datum

  val make_datum : string -> string -> string -> Z.t -> time -> datum

  type benchmark

  val empty_benchmark :
    ?verbose:bool -> ?totals:bool -> ?irmin:bool -> unit -> benchmark

  val init_scenario : benchmark -> string -> benchmark

  val switch_section : benchmark -> string -> benchmark

  val add_datum : benchmark -> string -> Z.t -> time -> benchmark

  val add_decode_datum : benchmark -> time -> benchmark

  val add_encode_datum : benchmark -> time -> benchmark

  val add_final_info : benchmark -> time -> Z.t -> benchmark

  module Pp : sig
    val pp_csv_line : string -> string -> string -> Z.t -> time -> unit

    val pp_datum : datum -> unit

    val pp_benchmark : benchmark -> unit

    val pp_header_section :
      benchmark -> Pvm_instance.Wasm.tree -> (Z.t * time) Lwt.t

    val pp_footer_section :
      benchmark -> Pvm_instance.Wasm.tree -> Z.t -> time -> unit Lwt.t

    val footer_action : benchmark -> string -> Z.t -> time -> unit

    val pp_scenario_header : benchmark -> string -> unit
  end
end
