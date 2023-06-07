(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Sc_rollup_repr
module PS = Sc_rollup_PVM_sig

module type P = sig
  module Tree : Context.TREE with type key = string list and type value = bytes

  type tree = Tree.tree

  val hash_tree : tree -> State_hash.t

  type proof

  val proof_encoding : proof Data_encoding.t

  val proof_before : proof -> State_hash.t

  val proof_after : proof -> State_hash.t

  val verify_proof :
    proof -> (tree -> (tree * 'a) Lwt.t) -> (tree * 'a) option Lwt.t

  val produce_proof :
    Tree.t -> tree -> (tree -> (tree * 'a) Lwt.t) -> (proof * 'a) option Lwt.t
end

module Make (Context : P) = struct
  module TxTypes = Epoxy_tx.Types.P
  module TxLogic = Epoxy_tx.Tx_rollup.P
  module ZkTree = Plompiler.Merkle (Plompiler.Anemoi128)
  module S = Plompiler.S

  type context = Context.Tree.t

  type status =
    | Halted
    | Waiting_for_input_message
    | Waiting_for_reveal
    | Waiting_for_metadata
    | Parsing
    | Evaluating

  type state = {optimistic : Context.Tree.tree; instant : TxTypes.state}

  let pp _ = failwith "TODO"

  type hash = State_hash.t

  type proof = unit

  type instruction = TxTypes.tx

  let check_dissection ~default_number_of_sections ~start_chunk ~stop_chunk =
    let open Sc_rollup_dissection_chunk_repr in
    let dist = Sc_rollup_tick_repr.distance start_chunk.tick stop_chunk.tick in
    let section_maximum_size = Z.div dist (Z.of_int 2) in
    Sc_rollup_dissection_chunk_repr.(
      default_check
        ~section_maximum_size
        ~check_sections_number:default_check_sections_number
        ~default_number_of_sections
        ~start_chunk
        ~stop_chunk)

  module State = struct
    module Tree = Context.Tree

    type nonrec state = state

    type key = OKey of Tree.key | IKey of int

    module Monad : sig
      type 'a t

      val run : 'a t -> state -> (state * 'a option) Lwt.t

      val is_stuck : string option t

      val internal_error : string -> 'a t

      val return : 'a -> 'a t

      module Syntax : sig
        val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
      end

      val remove_o : Tree.key -> unit t

      val find_value_o : Tree.key -> 'a Data_encoding.t -> 'a option t

      val find_value_i :
        int -> (TxTypes.account * TxTypes.leaf array * ZkTree.P.tree) t

      val children : Tree.key -> 'a Data_encoding.t -> (string * 'a) list t

      val get_value_o : default:'a -> Tree.key -> 'a Data_encoding.t -> 'a t

      val set_value_o : Tree.key -> 'a Data_encoding.t -> 'a -> unit t

      val set_value_i : int -> TxTypes.account -> unit t
    end = struct
      type 'a t = state -> (state * 'a option) Lwt.t

      let return x state = Lwt.return (state, Some x)

      let bind m f state =
        let open Lwt_syntax in
        let* state, res = m state in
        match res with None -> return (state, None) | Some res -> f res state

      module Syntax = struct
        let ( let* ) = bind
      end

      let run m state = m state

      let internal_error_key = ["internal_error"]

      let internal_error msg (s : state) =
        let open Lwt_syntax in
        let* optimistic =
          Tree.add s.optimistic internal_error_key (Bytes.of_string msg)
        in
        return ({s with optimistic}, None)

      let is_stuck (s : state) =
        let open Lwt_syntax in
        let* v = Tree.find s.optimistic internal_error_key in
        return (s, Some (Option.map Bytes.to_string v))

      let remove_o key (state : state) =
        let open Lwt_syntax in
        let* optimistic = Tree.remove state.optimistic key in
        return ({state with optimistic}, Some ())

      let decode encoding bytes state =
        let open Lwt_syntax in
        match Data_encoding.Binary.of_bytes_opt encoding bytes with
        | None -> internal_error "Error during decoding" state
        | Some v -> return (state, Some v)

      let find_value_o key encoding (state : state) =
        let open Lwt_syntax in
        let* obytes = Tree.find state.optimistic key in
        match obytes with
        | None -> return (state, Some None)
        | Some bytes ->
            let* state, value = decode encoding bytes state in
            return (state, Some value)

      let find_value_i pos (state : state) =
        let open Lwt_syntax in
        return (state, Some (TxLogic.get_account pos state.instant.accounts))

      let children key encoding (state : state) =
        let open Lwt_syntax in
        let* children = Tree.list state.optimistic key in
        let rec aux = function
          | [] -> return (state, Some [])
          | (key, tree) :: children -> (
              let* obytes = Tree.to_value tree in
              match obytes with
              | None -> internal_error "Invalid children" state
              | Some bytes -> (
                  let* state, v = decode encoding bytes state in
                  match v with
                  | None -> return (state, None)
                  | Some v -> (
                      let* state, l = aux children in
                      match l with
                      | None -> return (state, None)
                      | Some l -> return (state, Some ((key, v) :: l)))))
        in
        aux children

      let get_value_o ~default key encoding =
        let open Syntax in
        let* ov = find_value_o key encoding in
        match ov with None -> return default | Some x -> return x

      let set_value_o key encoding value (state : state) =
        let open Lwt_syntax in
        Data_encoding.Binary.to_bytes_opt encoding value |> function
        | None -> internal_error "Internal_Error during encoding" state
        | Some bytes ->
            let* optimistic = Tree.add state.optimistic key bytes in
            return ({state with optimistic}, Some ())

      let set_value_i pos value (state : state) =
        let open Lwt_syntax in
        let TxTypes.{accounts; accounts_tree; next_position} = state.instant in
        let accounts =
          TxTypes.IMap.update
            pos
            (function
              | Some (_acc, leaves, tree) -> Some (value, leaves, tree)
              | None -> failwith "account not found in set_value_i")
            accounts
        in
        let accounts_tree =
          ZkTree.P.update_tree
            ~input_length:2
            accounts_tree
            pos
            (TxLogic.scalar_of_account value)
        in
        let instant = TxTypes.{accounts; accounts_tree; next_position} in
        return ({state with instant}, Some ())
    end

    open Monad

    module Make_var (P : sig
      type t

      val name : string

      val initial : t

      val pp : Format.formatter -> t -> unit

      val encoding : t Data_encoding.t
    end) =
    struct
      let key = [P.name]

      let create = set_value_o key P.encoding P.initial

      let get =
        let open Monad.Syntax in
        let* v = find_value_o key P.encoding in
        match v with
        | None ->
            (* This case should not happen if [create] is properly called. *)
            return P.initial
        | Some v -> return v

      let set = set_value_o key P.encoding

      let pp =
        let open Monad.Syntax in
        let* v = get in
        return @@ fun fmt () -> Format.fprintf fmt "@[%s : %a@]" P.name P.pp v
    end

    module Make_dict (P : sig
      type t

      val name : string

      val pp : Format.formatter -> t -> unit

      val encoding : t Data_encoding.t
    end) =
    struct
      let key k = [P.name; k]

      let get k = find_value_o (key k) P.encoding

      let set k v = set_value_o (key k) P.encoding v

      let entries = children [P.name] P.encoding

      let mapped_to k v state =
        let open Lwt_syntax in
        let* state', _ = Monad.(run (set k v) state) in
        let* t = Tree.find_tree state.optimistic (key k)
        and* t' = Tree.find_tree state'.optimistic (key k) in
        Lwt.return (Option.equal Tree.equal t t')

      let pp =
        let open Monad.Syntax in
        let* l = entries in
        let pp_elem fmt (key, value) =
          Format.fprintf fmt "@[%s : %a@]" key P.pp value
        in
        return @@ fun fmt () -> Format.pp_print_list pp_elem fmt l
    end

    module Make_deque (P : sig
      type t

      val name : string

      val encoding : t Data_encoding.t
    end) =
    struct
      (*

       A stateful deque.

       [[head; end[] is the index range for the elements of the deque.

       The length of the deque is therefore [end - head].

    *)

      let head_key = [P.name; "head"]

      let end_key = [P.name; "end"]

      let get_head = get_value_o ~default:Z.zero head_key Data_encoding.z

      let set_head = set_value_o head_key Data_encoding.z

      let get_end = get_value_o ~default:(Z.of_int 0) end_key Data_encoding.z

      let set_end = set_value_o end_key Data_encoding.z

      let idx_key idx = [P.name; Z.to_string idx]

      let top =
        let open Monad.Syntax in
        let* head_idx = get_head in
        let* end_idx = get_end in
        let* v = find_value_o (idx_key head_idx) P.encoding in
        if Z.(leq end_idx head_idx) then return None
        else
          match v with
          | None -> (* By invariants of the Deque. *) assert false
          | Some x -> return (Some x)

      let push x =
        let open Monad.Syntax in
        let* head_idx = get_head in
        let head_idx' = Z.pred head_idx in
        let* () = set_head head_idx' in
        set_value_o (idx_key head_idx') P.encoding x

      let pop =
        let open Monad.Syntax in
        let* head_idx = get_head in
        let* end_idx = get_end in
        if Z.(leq end_idx head_idx) then return None
        else
          let* v = find_value_o (idx_key head_idx) P.encoding in
          match v with
          | None -> (* By invariants of the Deque. *) assert false
          | Some x ->
              let* () = remove_o (idx_key head_idx) in
              let head_idx = Z.succ head_idx in
              let* () = set_head head_idx in
              return (Some x)

      let inject x =
        let open Monad.Syntax in
        let* end_idx = get_end in
        let end_idx' = Z.succ end_idx in
        let* () = set_end end_idx' in
        set_value_o (idx_key end_idx) P.encoding x

      let to_list =
        let open Monad.Syntax in
        let* head_idx = get_head in
        let* end_idx = get_end in
        let rec aux l idx =
          if Z.(lt idx head_idx) then return l
          else
            let* v = find_value_o (idx_key idx) P.encoding in
            match v with
            | None -> (* By invariants of deque *) assert false
            | Some v -> aux (v :: l) (Z.pred idx)
        in
        aux [] (Z.pred end_idx)

      let clear = remove_o [P.name]
    end

    module Current_tick = Make_var (struct
      include Sc_rollup_tick_repr

      let name = "tick"
    end)

    (* module Code = Make_deque (struct
         type t = instruction

         let name = "code"

         let encoding =
           Data_encoding.(
             union
               [
                 case
                   ~title:"push"
                   (Tag 0)
                   Data_encoding.int31
                   (function IPush x -> Some x | _ -> None)
                   (fun x -> IPush x);
                 case
                   ~title:"add"
                   (Tag 1)
                   Data_encoding.unit
                   (function IAdd -> Some () | _ -> None)
                   (fun () -> IAdd);
                 case
                   ~title:"store"
                   (Tag 2)
                   Data_encoding.(string Plain)
                   (function IStore x -> Some x | _ -> None)
                   (fun x -> IStore x);
               ])
       end) *)

    module Status = Make_var (struct
      type t = status

      let initial = Halted

      let encoding =
        Data_encoding.string_enum
          [
            ("Halted", Halted);
            ("Waiting_for_input_message", Waiting_for_input_message);
            ("Waiting_for_reveal", Waiting_for_reveal);
            ("Waiting_for_metadata", Waiting_for_metadata);
            ("Parsing", Parsing);
            ("Evaluating", Evaluating);
          ]

      let name = "status"

      let string_of_status = function
        | Halted -> "Halted"
        | Waiting_for_input_message -> "Waiting for input message"
        | Waiting_for_reveal -> "Waiting for reveal"
        | Waiting_for_metadata -> "Waiting for metadata"
        | Parsing -> "Parsing"
        | Evaluating -> "Evaluating"

      let pp fmt status = Format.fprintf fmt "%s" (string_of_status status)
    end)

    module Required_reveal = Make_var (struct
      type t = PS.reveal option

      let initial = None

      let encoding = Data_encoding.option PS.reveal_encoding

      let name = "required_reveal"

      let pp fmt v =
        match v with
        | None -> Format.fprintf fmt "<none>"
        | Some h -> PS.pp_reveal fmt h
    end)

    module Metadata = Make_var (struct
      type t = Sc_rollup_metadata_repr.t option

      let initial = None

      let encoding = Data_encoding.option Sc_rollup_metadata_repr.encoding

      let name = "metadata"

      let pp fmt v =
        match v with
        | None -> Format.fprintf fmt "<none>"
        | Some v -> Sc_rollup_metadata_repr.pp fmt v
    end)

    module Current_level = Make_var (struct
      type t = Raw_level_repr.t

      let initial = Raw_level_repr.root

      let encoding = Raw_level_repr.encoding

      let name = "current_level"

      let pp = Raw_level_repr.pp
    end)

    type dal_slots_list = Dal_slot_index_repr.t list

    let dal_slots_list_encoding =
      Data_encoding.list Dal_slot_index_repr.encoding

    let pp_dal_slots_list =
      Format.pp_print_list
        ~pp_sep:(fun fmt () -> Format.pp_print_string fmt ":")
        Dal_slot_index_repr.pp

    type dal_parameters = {
      attestation_lag : int32;
      number_of_pages : int32;
      tracked_slots : dal_slots_list;
    }

    module Dal_parameters = Make_var (struct
      type t = dal_parameters

      let initial =
        (* This initial value is, from a semantic point of vue, equivalent to
           have [None], as no slot is tracked.

           For the initial values of the fields, only [tracked_slots]'s content
           matters. Setting it the empty set means that the rollup is not
           subscribed to the DAL. *)
        {attestation_lag = 1l; number_of_pages = 0l; tracked_slots = []}

      let encoding =
        let open Data_encoding in
        conv
          (fun {attestation_lag; number_of_pages; tracked_slots} ->
            (attestation_lag, number_of_pages, tracked_slots))
          (fun (attestation_lag, number_of_pages, tracked_slots) ->
            {attestation_lag; number_of_pages; tracked_slots})
          (obj3
             (req "attestation_lag" int32)
             (req "number_of_pages" int32)
             (req "tracked_slots" dal_slots_list_encoding))

      let name = "dal_parameters"

      let pp fmt {attestation_lag; number_of_pages; tracked_slots} =
        Format.fprintf
          fmt
          "dal:%ld:%ld:%a"
          attestation_lag
          number_of_pages
          pp_dal_slots_list
          tracked_slots
    end)

    module Dal_remaining_slots = Make_var (struct
      type t = dal_slots_list

      let initial = []

      let encoding = dal_slots_list_encoding

      let name = "dal_remaining_slots"

      let pp = pp_dal_slots_list
    end)

    module Message_counter = Make_var (struct
      type t = Z.t option

      let initial = None

      let encoding = Data_encoding.option Data_encoding.n

      let name = "message_counter"

      let pp fmt = function
        | None -> Format.fprintf fmt "None"
        | Some c -> Format.fprintf fmt "Some %a" Z.pp_print c
    end)

    (** Store an internal message counter. This is used to distinguish
      an unparsable external message and a internal message, which we both
      treat as no-ops. *)
    module Internal_message_counter = Make_var (struct
      type t = Z.t

      let initial = Z.zero

      let encoding = Data_encoding.n

      let name = "internal_message_counter"

      let pp fmt c = Z.pp_print fmt c
    end)

    let incr_internal_message_counter =
      let open Monad.Syntax in
      let* current_counter = Internal_message_counter.get in
      Internal_message_counter.set (Z.succ current_counter)

    module Next_message = Make_var (struct
      type t = string option

      let initial = None

      let encoding = Data_encoding.(option (string Plain))

      let name = "next_message"

      let pp fmt = function
        | None -> Format.fprintf fmt "None"
        | Some s -> Format.fprintf fmt "Some %s" s
    end)
  end

  open State
  open Monad

  let initial_state ~empty =
    let m =
      let open Monad.Syntax in
      let* () = Status.set Halted in
      return ()
    in
    let open Lwt_syntax in
    let* state, _ = run m empty in
    return state

  let install_boot_sector state _boot_sector = return state

  let state_hash (state : state) =
    let instant_root_bytes =
      Epoxy_tx.Utils.scalar_to_bytes @@ TxLogic.state_scalar state.instant
    in
    let optimistic_hash_bytes =
      Context_hash.to_bytes @@ Tree.hash state.optimistic
    in
    Lwt.return
    @@ State_hash.hash_bytes [instant_root_bytes; optimistic_hash_bytes]

  let pp _state = failwith "TODO"

  let boot =
    let open Monad.Syntax in
    let* () = Status.create in
    let* () = Next_message.create in
    let* () = Status.set Waiting_for_metadata in
    return ()

  let result_of ~default m state =
    let open Lwt_syntax in
    let* _, v = run m state in
    match v with None -> return default | Some v -> return v

  let state_of m state =
    let open Lwt_syntax in
    let* s, _ = run m state in
    return s

  let get_tick = result_of ~default:Sc_rollup_tick_repr.initial Current_tick.get

  let is_input_state_monadic =
    let open Monad.Syntax in
    let* status = Status.get in
    match status with
    | Waiting_for_input_message -> (
        let* level = Current_level.get in
        let* counter = Message_counter.get in
        match counter with
        | Some n -> return (PS.First_after (level, n))
        | None -> return PS.Initial)
    | Waiting_for_reveal -> (
        let* r = Required_reveal.get in
        match r with
        | None -> internal_error "Internal error: Reveal invariant broken"
        | Some reveal -> return (PS.Needs_reveal reveal))
    | Waiting_for_metadata -> return PS.(Needs_reveal Reveal_metadata)
    | Halted | Parsing | Evaluating -> return PS.No_input_required

  let is_input_state =
    result_of ~default:PS.No_input_required @@ is_input_state_monadic

  let ticked m =
    let open Monad.Syntax in
    let* tick = Current_tick.get in
    let* () = Current_tick.set (Sc_rollup_tick_repr.next tick) in
    m

  let start_parsing : unit t =
    let open Monad.Syntax in
    let* () = Status.set Parsing in
    let* () = Parsing_result.set None in
    let* () = Parser_state.set SkipLayout in
    let* () = Lexer_state.set (0, 0) in
    let* () = Code.clear in
    return ()

  let set_inbox_message_monadic {PS.inbox_level; message_counter; payload} =
    let open Monad.Syntax in
    let deserialized = Sc_rollup_inbox_message_repr.deserialize payload in
    let* payload =
      match deserialized with
      | Error _ -> return None
      | Ok (External payload) -> return (Some payload)
      | Ok (Internal (Transfer {payload; destination; _})) -> (
          let* () = incr_internal_message_counter in
          let* (metadata : Sc_rollup_metadata_repr.t option) = Metadata.get in
          match metadata with
          | Some {address; _} when Address.(destination = address) -> (
              match Micheline.root payload with
              | Bytes (_, payload) ->
                  let payload = Bytes.to_string payload in
                  return (Some payload)
              | _ -> return None)
          | _ -> return None)
      | Ok (Internal (Protocol_migration _)) ->
          let* () = incr_internal_message_counter in
          return None
      | Ok (Internal Start_of_level) ->
          let* () = incr_internal_message_counter in
          return None
      | Ok (Internal End_of_level) ->
          let* () = incr_internal_message_counter in
          return None
      | Ok (Internal (Info_per_level _)) ->
          let* () = incr_internal_message_counter in
          return None
    in
    match payload with
    | Some payload ->
        let* () = Current_level.set inbox_level in
        let* () = Message_counter.set (Some message_counter) in
        let* () = Next_message.set (Some payload) in
        let* () = start_parsing in
        return ()
    | None -> (
        let* () = Current_level.set inbox_level in
        let* () = Message_counter.set (Some message_counter) in
        match deserialized with
        | Ok (Internal Start_of_level) -> (
            let* dal_params = Dal_parameters.get in
            let inbox_level = Raw_level_repr.to_int32 inbox_level in
            (* the [published_level]'s pages to request is [inbox_level -
               endorsement_lag - 1]. *)
            let lvl =
              Int32.sub (Int32.sub inbox_level dal_params.attestation_lag) 1l
            in
            match Raw_level_repr.of_int32 lvl with
            | Error _ ->
                (* Too early. We cannot request DAL data yet. *)
                return ()
            | Ok published_level -> (
                let* metadata = Metadata.get in
                match metadata with
                | None ->
                    assert false
                    (* Setting Metadata should be the first input provided to the
                       PVM. *)
                | Some {origination_level; _} ->
                    if Raw_level_repr.(origination_level >= published_level)
                    then
                      (* We can only fetch DAL data that are published after
                         the rollup's origination level. *)
                      Status.set Waiting_for_input_message
                    else
                      (* Start fetching DAL data for this [published_level]. *)
                      update_waiting_for_data_status ~published_level ()))
        | _ -> Status.set Waiting_for_input_message)

  let set_input_monadic input =
    match input with
    | PS.Inbox_message m -> set_inbox_message_monadic m
    | PS.Reveal _s -> failwith "TODO"

  let set_input input = set_input_monadic input |> ticked |> state_of
end
