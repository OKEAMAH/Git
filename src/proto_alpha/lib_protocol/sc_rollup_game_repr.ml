(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type player = Alice | Bob

module V1 = struct
  type dissection_chunk = {
    state_hash : State_hash.t option;
    tick : Sc_rollup_tick_repr.t;
  }

  let pp_state_hash =
    let open Format in
    pp_print_option ~none:(fun ppf () -> fprintf ppf "None") State_hash.pp

  let pp_dissection_chunk ppf {state_hash; tick} =
    let open Format in
    fprintf
      ppf
      "State hash:%a@ Tick: %a"
      pp_state_hash
      state_hash
      Sc_rollup_tick_repr.pp
      tick

  type t = {
    turn : player;
    inbox_snapshot : Sc_rollup_inbox_repr.history_proof;
    (* A snapshot of the scoru inbox. *)
    dal_snapshot : Dal_slot_repr.Slots_history.t;
    (* A snapshot of the confirmed DAL slots. *)
    level : Raw_level_repr.t;
    pvm_name : string;
    dissection : dissection_chunk list;
    default_number_of_sections : int;
  }

  let player_encoding =
    let open Data_encoding in
    union
      ~tag_size:`Uint8
      [
        case
          ~title:"Alice"
          (Tag 0)
          (constant "alice")
          (function Alice -> Some () | _ -> None)
          (fun () -> Alice);
        case
          ~title:"Bob"
          (Tag 1)
          (constant "bob")
          (function Bob -> Some () | _ -> None)
          (fun () -> Bob);
      ]

  let player_equal p1 p2 =
    match (p1, p2) with
    | Alice, Alice -> true
    | Bob, Bob -> true
    | _, _ -> false

  let dissection_chunk_equal {state_hash; tick} chunk2 =
    Option.equal State_hash.equal state_hash chunk2.state_hash
    && Sc_rollup_tick_repr.equal tick chunk2.tick

  let equal
      {
        turn = turn1;
        inbox_snapshot = inbox_snapshot1;
        dal_snapshot = dal_snapshot1;
        level = level1;
        pvm_name = pvm_name1;
        dissection = dissection1;
        default_number_of_sections = default_number_of_sections1;
      }
      {
        turn = turn2;
        inbox_snapshot = inbox_snapshot2;
        dal_snapshot = dal_snapshot2;
        level = level2;
        pvm_name = pvm_name2;
        dissection = dissection2;
        default_number_of_sections = default_number_of_sections2;
      } =
    player_equal turn1 turn2
    && Compare.Int.equal default_number_of_sections1 default_number_of_sections2
    && Sc_rollup_inbox_repr.equal_history_proof inbox_snapshot1 inbox_snapshot2
    && Dal_slot_repr.Slots_history.equal dal_snapshot1 dal_snapshot2
    && Raw_level_repr.equal level1 level2
    && String.equal pvm_name1 pvm_name2
    && List.equal dissection_chunk_equal dissection1 dissection2

  let string_of_player = function Alice -> "alice" | Bob -> "bob"

  let pp_player ppf player = Format.fprintf ppf "%s" (string_of_player player)

  let opponent = function Alice -> Bob | Bob -> Alice

  let dissection_encoding =
    let open Data_encoding in
    list
      (conv
         (fun {state_hash; tick} -> (state_hash, tick))
         (fun (state_hash, tick) -> {state_hash; tick})
         (obj2
            (opt "state" State_hash.encoding)
            (req "tick" Sc_rollup_tick_repr.encoding)))

  let encoding =
    let open Data_encoding in
    conv
      (fun {
             turn;
             inbox_snapshot;
             dal_snapshot;
             level;
             pvm_name;
             dissection;
             default_number_of_sections;
           } ->
        ( turn,
          inbox_snapshot,
          dal_snapshot,
          level,
          pvm_name,
          dissection,
          default_number_of_sections ))
      (fun ( turn,
             inbox_snapshot,
             dal_snapshot,
             level,
             pvm_name,
             dissection,
             default_number_of_sections ) ->
        {
          turn;
          inbox_snapshot;
          dal_snapshot;
          level;
          pvm_name;
          dissection;
          default_number_of_sections;
        })
      (obj7
         (req "turn" player_encoding)
         (req "inbox_snapshot" Sc_rollup_inbox_repr.history_proof_encoding)
         (req "dal_snapshot" Dal_slot_repr.Slots_history.encoding)
         (req "level" Raw_level_repr.encoding)
         (req "pvm_name" string)
         (req "dissection" dissection_encoding)
         (req "default_number_of_sections" uint8))

  let pp_dissection ppf d =
    Format.pp_print_list
      ~pp_sep:(fun ppf () -> Format.pp_print_string ppf ";\n")
      (fun ppf {state_hash; tick} ->
        Format.fprintf
          ppf
          "%a: %a"
          Sc_rollup_tick_repr.pp
          tick
          pp_state_hash
          state_hash)
      ppf
      d

  let pp ppf game =
    Format.fprintf
      ppf
      "[%a] %a playing; inbox snapshot = %a; level = %a; pvm_name = %s;"
      pp_dissection
      game.dissection
      pp_player
      game.turn
      Sc_rollup_inbox_repr.pp_history_proof
      game.inbox_snapshot
      Raw_level_repr.pp
      game.level
      game.pvm_name
end

type versioned = V1 of V1.t

let versioned_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"V1"
        (Tag 0)
        V1.encoding
        (function V1 game -> Some game)
        (fun game -> V1 game);
    ]

include V1

let of_versioned = function V1 game -> game [@@inline]

let to_versioned game = V1 game [@@inline]

module Index = struct
  type t = {alice : Staker.t; bob : Staker.t}

  let make a b =
    let alice, bob =
      if Compare.Int.(Staker.compare a b > 0) then (b, a) else (a, b)
    in
    {alice; bob}

  let encoding =
    let open Data_encoding in
    conv
      (fun {alice; bob} -> (alice, bob))
      (fun (alice, bob) -> make alice bob)
      (obj2 (req "alice" Staker.encoding) (req "bob" Staker.encoding))

  let compare {alice = a; bob = b} {alice = c; bob = d} =
    match Staker.compare a c with 0 -> Staker.compare b d | x -> x

  let to_path {alice; bob} p =
    Staker.to_b58check alice :: Staker.to_b58check bob :: p

  let both_of_b58check_opt (a, b) =
    let ( let* ) = Option.bind in
    let* a_staker = Staker.of_b58check_opt a in
    let* b_staker = Staker.of_b58check_opt b in
    Some (make a_staker b_staker)

  let of_path = function [a; b] -> both_of_b58check_opt (a, b) | _ -> None

  let path_length = 2

  let rpc_arg =
    let descr =
      "A pair of stakers that index a smart contract rollup refutation game."
    in
    let construct {alice; bob} =
      Format.sprintf "%s-%s" (Staker.to_b58check alice) (Staker.to_b58check bob)
    in
    let destruct s =
      match String.split_on_char '-' s with
      | [a; b] -> (
          match both_of_b58check_opt (a, b) with
          | Some stakers -> ok stakers
          | None ->
              Result.error (Format.sprintf "Invalid game index notation %s" s))
      | _ -> Result.error (Format.sprintf "Invalid game index notation %s" s)
    in
    RPC_arg.make ~descr ~name:"game_index" ~construct ~destruct ()

  let staker {alice; bob} = function Alice -> alice | Bob -> bob
end

let make_chunk state_hash tick = {state_hash; tick}

let initial inbox dal_snapshot ~pvm_name ~(parent : Sc_rollup_commitment_repr.t)
    ~(child : Sc_rollup_commitment_repr.t) ~refuter ~defender
    ~default_number_of_sections =
  let ({alice; _} : Index.t) = Index.make refuter defender in
  let alice_to_play = Staker.equal alice refuter in
  let open Sc_rollup_tick_repr in
  let tick = of_number_of_ticks child.number_of_ticks in
  {
    turn = (if alice_to_play then Alice else Bob);
    inbox_snapshot = inbox;
    dal_snapshot;
    level = child.inbox_level;
    pvm_name;
    dissection =
      (if equal tick initial then
       [
         make_chunk (Some child.compressed_state) initial;
         make_chunk None (next initial);
       ]
      else
        [
          make_chunk (Some parent.compressed_state) initial;
          make_chunk (Some child.compressed_state) tick;
          make_chunk None (next tick);
        ]);
    default_number_of_sections;
  }

type step =
  | Dissection of dissection_chunk list
  | Proof of Sc_rollup_proof_repr.t

let step_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Dissection"
        (Tag 0)
        dissection_encoding
        (function Dissection d -> Some d | _ -> None)
        (fun d -> Dissection d);
      case
        ~title:"Proof"
        (Tag 1)
        Sc_rollup_proof_repr.encoding
        (function Proof p -> Some p | _ -> None)
        (fun p -> Proof p);
    ]

let pp_step ppf step =
  match step with
  | Dissection states ->
      Format.fprintf ppf "Dissection:@ " ;
      Format.pp_print_list
        ~pp_sep:(fun ppf () -> Format.pp_print_string ppf ";\n\n")
        (fun ppf {state_hash; tick} ->
          Format.fprintf
            ppf
            "Tick: %a,@ State: %a\n"
            Sc_rollup_tick_repr.pp
            tick
            (Format.pp_print_option State_hash.pp)
            state_hash)
        ppf
        states
  | Proof proof -> Format.fprintf ppf "proof: %a" Sc_rollup_proof_repr.pp proof

type refutation = {choice : Sc_rollup_tick_repr.t; step : step}

let pp_refutation ppf {choice; step} =
  Format.fprintf
    ppf
    "Tick: %a@ Step: %a"
    Sc_rollup_tick_repr.pp
    choice
    pp_step
    step

let refutation_encoding =
  let open Data_encoding in
  conv
    (fun {choice; step} -> (choice, step))
    (fun (choice, step) -> {choice; step})
    (obj2
       (req "choice" Sc_rollup_tick_repr.encoding)
       (req "step" step_encoding))

type invalid_move =
  | Dissection_choice_not_found of Sc_rollup_tick_repr.t
  | Dissection_number_of_sections_mismatch of {expected : Z.t; given : Z.t}
  | Dissection_invalid_number_of_sections of Z.t
  | Dissection_start_hash_mismatch of {
      expected : State_hash.t option;
      given : State_hash.t option;
    }
  | Dissection_stop_hash_mismatch of State_hash.t option
  | Dissection_edge_ticks_mismatch of {
      dissection_start_tick : Sc_rollup_tick_repr.t;
      dissection_stop_tick : Sc_rollup_tick_repr.t;
      chunk_start_tick : Sc_rollup_tick_repr.t;
      chunk_stop_tick : Sc_rollup_tick_repr.t;
    }
  | Dissection_ticks_not_increasing
  | Dissection_invalid_distribution
  | Dissection_invalid_successive_states_shape
  | Proof_unexpected_section_size of Z.t
  | Proof_start_state_hash_mismatch of {
      start_state_hash : State_hash.t option;
      start_proof : State_hash.t;
    }
  | Proof_stop_state_hash_mismatch of {
      stop_state_hash : State_hash.t option;
      stop_proof : State_hash.t option;
    }
  | Proof_invalid of string

let pp_invalid_move fmt =
  let pp_hash_opt fmt = function
    | None -> Format.fprintf fmt "None"
    | Some x -> State_hash.pp fmt x
  in
  function
  | Dissection_choice_not_found tick ->
      Format.fprintf
        fmt
        "No section starting with tick %a found"
        Sc_rollup_tick_repr.pp
        tick
  | Dissection_number_of_sections_mismatch {expected; given} ->
      Format.fprintf
        fmt
        "The number of sections must be equal to %a instead of %a"
        Z.pp_print
        expected
        Z.pp_print
        given
  | Dissection_invalid_number_of_sections n ->
      Format.fprintf
        fmt
        "A dissection with %a sections can never be valid"
        Z.pp_print
        n
  | Dissection_start_hash_mismatch {given = None; _} ->
      Format.fprintf fmt "The start hash must not be None"
  | Dissection_start_hash_mismatch {given; expected} ->
      Format.fprintf
        fmt
        "The start hash should be equal to %a, but the provided hash is %a"
        pp_hash_opt
        expected
        pp_hash_opt
        given
  | Dissection_stop_hash_mismatch h ->
      Format.fprintf fmt "The stop hash should not be equal to %a" pp_hash_opt h
  | Dissection_edge_ticks_mismatch
      {
        dissection_start_tick;
        dissection_stop_tick;
        chunk_start_tick;
        chunk_stop_tick;
      } ->
      Sc_rollup_tick_repr.(
        Format.fprintf
          fmt
          "We should have dissection_start_tick(%a) = %a and \
           dissection_stop_tick(%a) = %a"
          pp
          dissection_start_tick
          pp
          chunk_start_tick
          pp
          dissection_stop_tick
          pp
          chunk_stop_tick)
  | Dissection_ticks_not_increasing ->
      Format.fprintf fmt "Ticks should only increase in dissection"
  | Dissection_invalid_successive_states_shape ->
      Format.fprintf
        fmt
        "Cannot return to a Some state after being at a None state"
  | Dissection_invalid_distribution ->
      Format.fprintf
        fmt
        "Maximum tick increment in a section cannot be more than half total \
         dissection length"
  | Proof_unexpected_section_size n ->
      Format.fprintf
        fmt
        "dist should be equal to 1 in a proof, but got %a"
        Z.pp_print
        n
  | Proof_start_state_hash_mismatch {start_state_hash; start_proof} ->
      Format.fprintf
        fmt
        "start(%a) should be equal to start_proof(%a)"
        pp_hash_opt
        start_state_hash
        State_hash.pp
        start_proof
  | Proof_stop_state_hash_mismatch {stop_state_hash; stop_proof} ->
      Format.fprintf
        fmt
        "stop(%a) should not be equal to stop_proof(%a)"
        pp_hash_opt
        stop_state_hash
        pp_hash_opt
        stop_proof
  | Proof_invalid s -> Format.fprintf fmt "Invalid proof: %s" s

let invalid_move_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"sc_rollup_dissection_choice_not_found"
        (Tag 0)
        (obj2
           (req "kind" (constant "dissection_choice_not_found"))
           (req "tick" Sc_rollup_tick_repr.encoding))
        (function
          | Dissection_choice_not_found tick -> Some ((), tick) | _ -> None)
        (fun ((), tick) -> Dissection_choice_not_found tick);
      case
        ~title:"sc_rollup_dissection_number_of_sections_mismatch"
        (Tag 1)
        (obj3
           (req "kind" (constant "dissection_number_of_sections_mismatch"))
           (req "expected" n)
           (req "given" n))
        (function
          | Dissection_number_of_sections_mismatch {expected; given} ->
              Some ((), expected, given)
          | _ -> None)
        (fun ((), expected, given) ->
          Dissection_number_of_sections_mismatch {expected; given});
      case
        ~title:"sc_rollup_dissection_invalid_number_of_sections"
        (Tag 2)
        (obj2
           (req "kind" (constant "dissection_invalid_number_of_sections"))
           (req "value" n))
        (function
          | Dissection_invalid_number_of_sections value -> Some ((), value)
          | _ -> None)
        (fun ((), value) -> Dissection_invalid_number_of_sections value);
      case
        ~title:"sc_rollup_dissection_unexpected_start_hash"
        (Tag 3)
        (obj3
           (req "kind" (constant "dissection_unexpected_start_hash"))
           (req "expected" (option State_hash.encoding))
           (req "given" (option State_hash.encoding)))
        (function
          | Dissection_start_hash_mismatch {expected; given} ->
              Some ((), expected, given)
          | _ -> None)
        (fun ((), expected, given) ->
          Dissection_start_hash_mismatch {expected; given});
      case
        ~title:"sc_rollup_dissection_stop_hash_mismatch"
        (Tag 4)
        (obj2
           (req "kind" (constant "dissection_stop_hash_mismatch"))
           (req "hash" (option State_hash.encoding)))
        (function
          | Dissection_stop_hash_mismatch hopt -> Some ((), hopt) | _ -> None)
        (fun ((), hopt) -> Dissection_stop_hash_mismatch hopt);
      case
        ~title:"sc_rollup_dissection_edge_ticks_mismatch"
        (Tag 5)
        (obj5
           (req "kind" (constant "dissection_edge_ticks_mismatch"))
           (req "dissection_start_tick" Sc_rollup_tick_repr.encoding)
           (req "dissection_stop_tick" Sc_rollup_tick_repr.encoding)
           (req "chunk_start_tick" Sc_rollup_tick_repr.encoding)
           (req "chunk_stop_tick" Sc_rollup_tick_repr.encoding))
        (function
          | Dissection_edge_ticks_mismatch e ->
              Some
                ( (),
                  e.dissection_start_tick,
                  e.dissection_stop_tick,
                  e.chunk_start_tick,
                  e.chunk_stop_tick )
          | _ -> None)
        (fun ( (),
               dissection_start_tick,
               dissection_stop_tick,
               chunk_start_tick,
               chunk_stop_tick ) ->
          Dissection_edge_ticks_mismatch
            {
              dissection_start_tick;
              dissection_stop_tick;
              chunk_start_tick;
              chunk_stop_tick;
            });
      case
        ~title:"sc_rollup_dissection_ticks_not_increasing"
        (Tag 6)
        (obj1 (req "kind" (constant "dissection_ticks_not_increasing")))
        (function Dissection_ticks_not_increasing -> Some () | _ -> None)
        (fun () -> Dissection_ticks_not_increasing);
      case
        ~title:"sc_rollup_dissection_invalid_distribution"
        (Tag 7)
        (obj1 (req "kind" (constant "dissection_invalid_distribution")))
        (function Dissection_invalid_distribution -> Some () | _ -> None)
        (fun () -> Dissection_invalid_distribution);
      case
        ~title:"sc_rollup_dissection_invalid_successive_states_shape"
        (Tag 8)
        (obj1
           (req "kind" (constant "dissection_invalid_successive_states_shape")))
        (function
          | Dissection_invalid_successive_states_shape -> Some () | _ -> None)
        (fun () -> Dissection_invalid_successive_states_shape);
      case
        ~title:"sc_rollup_proof_unexpected_section_size"
        (Tag 9)
        (obj2
           (req "kind" (constant "proof_unexpected_section_size"))
           (req "value" n))
        (function Proof_unexpected_section_size n -> Some ((), n) | _ -> None)
        (fun ((), n) -> Proof_unexpected_section_size n);
      case
        ~title:"sc_rollup_proof_start_state_hash_mismatch"
        (Tag 10)
        (obj3
           (req "kind" (constant "proof_start_state_hash_mismatch"))
           (req "start_state_hash" (option State_hash.encoding))
           (req "start_proof" State_hash.encoding))
        (function
          | Proof_start_state_hash_mismatch e ->
              Some ((), e.start_state_hash, e.start_proof)
          | _ -> None)
        (fun ((), start_state_hash, start_proof) ->
          Proof_start_state_hash_mismatch {start_state_hash; start_proof});
      case
        ~title:"sc_rollup_proof_stop_state_hash_mismatch"
        (Tag 11)
        (obj3
           (req "kind" (constant "proof_stop_state_hash_mismatch"))
           (req "stop_state_hash" (option State_hash.encoding))
           (req "stop_proof" (option State_hash.encoding)))
        (function
          | Proof_stop_state_hash_mismatch e ->
              Some ((), e.stop_state_hash, e.stop_proof)
          | _ -> None)
        (fun ((), stop_state_hash, stop_proof) ->
          Proof_stop_state_hash_mismatch {stop_state_hash; stop_proof});
      case
        ~title:"sc_rollup_proof_invalid"
        (Tag 12)
        (obj2 (req "kind" (constant "proof_invalid")) (req "message" string))
        (function Proof_invalid s -> Some ((), s) | _ -> None)
        (fun ((), s) -> Proof_invalid s);
    ]

type reason = Conflict_resolved | Invalid_move of invalid_move | Timeout

let pp_reason ppf reason =
  match reason with
  | Conflict_resolved -> Format.fprintf ppf "conflict resolved"
  | Invalid_move mv -> Format.fprintf ppf "invalid move(%a)" pp_invalid_move mv
  | Timeout -> Format.fprintf ppf "timeout"

let reason_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Conflict_resolved"
        (Tag 0)
        (constant "conflict_resolved")
        (function Conflict_resolved -> Some () | _ -> None)
        (fun () -> Conflict_resolved);
      case
        ~title:"Invalid_move"
        (Tag 1)
        invalid_move_encoding
        (function Invalid_move reason -> Some reason | _ -> None)
        (fun s -> Invalid_move s);
      case
        ~title:"Timeout"
        (Tag 2)
        (constant "timeout")
        (function Timeout -> Some () | _ -> None)
        (fun () -> Timeout);
    ]

type status = Ongoing | Ended of (reason * Staker.t)

let pp_status ppf status =
  match status with
  | Ongoing -> Format.fprintf ppf "Game ongoing"
  | Ended (reason, staker) ->
      Format.fprintf
        ppf
        "Game ended due to %a, %a loses their stake"
        pp_reason
        reason
        Staker.pp
        staker

let status_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Ongoing"
        (Tag 0)
        (constant "ongoing")
        (function Ongoing -> Some () | _ -> None)
        (fun () -> Ongoing);
      case
        ~title:"Ended"
        (Tag 1)
        (obj2 (req "reason" reason_encoding) (req "staker" Staker.encoding))
        (function Ended (r, s) -> Some (r, s) | _ -> None)
        (fun (r, s) -> Ended (r, s));
    ]

type outcome = {loser : player; reason : reason}

let pp_outcome ppf outcome =
  Format.fprintf
    ppf
    "Game outcome: %a - %a has lost.\n"
    pp_reason
    outcome.reason
    pp_player
    outcome.loser

let outcome_encoding =
  let open Data_encoding in
  conv
    (fun {loser; reason} -> (loser, reason))
    (fun (loser, reason) -> {loser; reason})
    (obj2 (req "loser" player_encoding) (req "reason" reason_encoding))

let invalid_move reason =
  let open Lwt_result_syntax in
  fail (Invalid_move reason)

let find_choice game tick =
  let open Lwt_result_syntax in
  let rec traverse states =
    match states with
    | ({state_hash = _; tick = state_tick} as curr) :: next :: others ->
        if Sc_rollup_tick_repr.(tick = state_tick) then return (curr, next)
        else traverse (next :: others)
    | _ -> invalid_move (Dissection_choice_not_found tick)
  in
  traverse game.dissection

let check pred reason =
  let open Lwt_result_syntax in
  if pred then return () else invalid_move reason

let check_dissection ~default_number_of_sections ~start_chunk ~stop_chunk
    dissection =
  let open Lwt_result_syntax in
  let len = Z.of_int @@ List.length dissection in
  let dist = Sc_rollup_tick_repr.distance start_chunk.tick stop_chunk.tick in
  let should_be_equal_to expected =
    Dissection_number_of_sections_mismatch {expected; given = len}
  in
  let num_sections = Z.of_int @@ default_number_of_sections in
  let* () =
    if Z.geq dist num_sections then
      check Z.(equal len num_sections) (should_be_equal_to num_sections)
    else if Z.(gt dist one) then
      check Z.(equal len (succ dist)) (should_be_equal_to Z.(succ dist))
    else invalid_move (Dissection_invalid_number_of_sections len)
  in
  let* () =
    match (List.hd dissection, List.last_opt dissection) with
    | Some {state_hash = a; tick = a_tick}, Some {state_hash = b; tick = b_tick}
      ->
        let* () =
          check
            (Option.equal State_hash.equal a start_chunk.state_hash
            && not (Option.is_none a))
            (Dissection_start_hash_mismatch
               {expected = start_chunk.state_hash; given = a})
        in
        let* () =
          check
            (not (Option.equal State_hash.equal b stop_chunk.state_hash))
            ((* If the [b] state is equal to [stop_chunk], that means we
                agree on the after state of the section. But, we're trying
                to dispute it, it doesn't make sense. *)
               Dissection_stop_hash_mismatch
               stop_chunk.state_hash)
        in
        Sc_rollup_tick_repr.(
          check
            (a_tick = start_chunk.tick && b_tick = stop_chunk.tick)
            (Dissection_edge_ticks_mismatch
               {
                 dissection_start_tick = a_tick;
                 dissection_stop_tick = b_tick;
                 chunk_start_tick = start_chunk.tick;
                 chunk_stop_tick = stop_chunk.tick;
               }))
    | _ ->
        (* This case is probably already handled by the
           [Dissection_invalid_number_of_sections] returned above *)
        invalid_move (Dissection_invalid_number_of_sections len)
  in
  let half_dist = Z.(div dist (of_int 2) |> succ) in
  let rec traverse states =
    match states with
    | {state_hash = None; _} :: {state_hash = Some _; _} :: _ ->
        invalid_move Dissection_invalid_successive_states_shape
    | {tick; _} :: ({tick = next_tick; state_hash = _} as next) :: others ->
        if Sc_rollup_tick_repr.(tick < next_tick) then
          let incr = Sc_rollup_tick_repr.distance tick next_tick in
          if Z.(leq incr half_dist) then traverse (next :: others)
          else invalid_move Dissection_invalid_distribution
        else invalid_move Dissection_ticks_not_increasing
    | _ -> return ()
  in
  traverse dissection

(** We check firstly that the interval in question is a single tick.

    Then we check the proof begins with the correct state and ends
    with a different state to the one in the current dissection.

    Note: this does not check the proof itself is valid, just that it
    makes the expected claims about start and stop states. The function
    {!play} below has to call {!Sc_rollup_proof_repr.valid} separately
    to ensure the proof is actually valid. *)
let check_proof_start_stop ~start_chunk ~stop_chunk input_given proof =
  let open Lwt_result_syntax in
  let dist = Sc_rollup_tick_repr.distance start_chunk.tick stop_chunk.tick in
  let* () = check Z.(equal dist one) (Proof_unexpected_section_size dist) in
  let start_proof = Sc_rollup_proof_repr.start proof in
  let stop_proof = Sc_rollup_proof_repr.stop input_given proof in
  let* () =
    check
      (Option.equal State_hash.equal start_chunk.state_hash (Some start_proof))
      (Proof_start_state_hash_mismatch
         {start_state_hash = start_chunk.state_hash; start_proof})
  in
  check
    (not (Option.equal State_hash.equal stop_chunk.state_hash stop_proof))
    (Proof_stop_state_hash_mismatch
       {stop_state_hash = stop_chunk.state_hash; stop_proof})

let play game refutation =
  let open Lwt_result_syntax in
  let*! result =
    let* start_chunk, stop_chunk = find_choice game refutation.choice in
    match refutation.step with
    | Dissection states ->
        let* () =
          check_dissection
            ~default_number_of_sections:game.default_number_of_sections
            ~start_chunk
            ~stop_chunk
            states
        in
        return
          (Either.Right
             {
               turn = opponent game.turn;
               inbox_snapshot = game.inbox_snapshot;
               dal_snapshot = game.dal_snapshot;
               level = game.level;
               pvm_name = game.pvm_name;
               dissection = states;
               default_number_of_sections = game.default_number_of_sections;
             })
    | Proof proof ->
        let {inbox_snapshot; dal_snapshot; level; pvm_name; _} = game in
        let*! valid =
          Sc_rollup_proof_repr.valid
            inbox_snapshot
            dal_snapshot
            level
            ~pvm_name
            proof
        in
        let* () =
          match valid with
          | Ok (true, input) ->
              check_proof_start_stop ~start_chunk ~stop_chunk input proof
          | Ok (false, _) -> invalid_move (Proof_invalid "no detail given")
          | Error e ->
              invalid_move (Proof_invalid (Format.asprintf "%a" pp_trace e))
        in
        return
          (Either.Left {loser = opponent game.turn; reason = Conflict_resolved})
  in
  match result with
  | Ok x -> Lwt.return x
  | Error reason -> Lwt.return @@ Either.Left {loser = game.turn; reason}

module Internal_for_tests = struct
  let find_choice = find_choice

  let check_dissection = check_dissection
end

type timeout = {alice : int; bob : int; last_turn_level : Raw_level_repr.t}

let timeout_encoding =
  let open Data_encoding in
  conv
    (fun {alice; bob; last_turn_level} -> (alice, bob, last_turn_level))
    (fun (alice, bob, last_turn_level) -> {alice; bob; last_turn_level})
    (obj3
       (req "alice" int31)
       (req "bob" int31)
       (req "last_turn_level" Raw_level_repr.encoding))
