(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** Testing
    -------
    Component:    PBT for the SCORU refutation game
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/test_refutation_game.exe
    Subject:      SCORU refutation game
*)
open Protocol

open Alpha_context
open Sc_rollup
open Lwt_syntax
open Lib_test.Qcheck2_helpers

(**

   Helpers

*)

let hash_state state number =
  Digest.bytes @@ Bytes.of_string @@ state ^ string_of_int number

type dummy_proof = {
  start : State_hash.t;
  stop : State_hash.t option;
  valid : bool;
}

let dummy_proof_encoding : dummy_proof Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {start; stop; valid} -> (start, stop, valid))
    (fun (start, stop, valid) -> {start; stop; valid})
    (obj3
       (req "start" State_hash.encoding)
       (req "stop" (option State_hash.encoding))
       (req "valid" bool))

let proof_start_state proof = proof.start

let proof_stop_state proof = proof.stop

let number_of_messages_exn n =
  match Number_of_messages.of_int32 n with
  | Some x -> x
  | None -> Stdlib.failwith "Bad Number_of_messages"

let number_of_ticks_exn n =
  match Number_of_ticks.of_int32 n with
  | Some x -> x
  | None -> Stdlib.failwith "Bad Number_of_ticks"

let get_comm pred inbox_level messages ticks state =
  Commitment.
    {
      predecessor = pred;
      inbox_level = Raw_level.of_int32_exn inbox_level;
      number_of_messages = number_of_messages_exn messages;
      number_of_ticks = number_of_ticks_exn ticks;
      compressed_state = state;
    }

let random_hash () = State_hash.of_bytes_exn @@ Bytes.create 32

let tick_of_int_exn n =
  match Tick.of_int n with None -> assert false | Some t -> t

let tick_to_int_exn t =
  match Tick.to_int t with None -> assert false | Some n -> n

let mk_dissection_chunk (state_hash, tick) = Game.{state_hash; tick}

let random_dissection start_at start_hash stop_at stop_hash =
  let start_int = tick_to_int_exn start_at in
  let stop_int = tick_to_int_exn stop_at in
  let dist = stop_int - start_int in
  let branch = min (dist + 1) 32 in
  let size = (dist + 1) / (branch - 1) in

  if dist = 1 then return None
  else
    return
    @@ Result.to_option
         (List.init branch ~when_negative_length:"error" (fun i ->
              mk_dissection_chunk
              @@
              if i = 0 then (Some start_hash, start_at)
              else if i = branch - 1 then (stop_hash, stop_at)
              else
                (Some (random_hash ()), tick_of_int_exn (start_int + (i * size)))))

(**
 `genlist` is a `correct list` generator. It generates a list of strings that
  are either integers or `+` to be consumed by the arithmetic PVM.
  If a `+` is found then the previous two element of the stack are poped
   then added and the result is pushed to the stack.
   In particular, lists like `[1 +]` are incorrect.

  To preserve the correctness invariant, genlist is a recursive generator that
  produce a pair `(stack_size, state_list)` where  state_list is a correct list
  of integers and `+` and consuming it will produce a `stack` of length
  `stack_size`.
  For example a result can be `(3, [1; 2; +; 3; +; 2; 2; +; 1;]).
  Consuming the list will produce the stack`[6; 4; 2]` which has length 3.
  The generator has two branches.
  1. with frequency 1 adds integers to state_list and increases the
  corresponding stack_size.
  2. With frequency 2, at each step, it looks at the inductive result
  `(self (n - 1))=(stack_size, state_list)`.
  If the stack_size is smaller than 2 then it adds an integer to the state_list
   and increases the stack_size
  Otherwise it adds a plus to the state_list and decreases the stack_size.
  Remark: The algorithm is linear in the size of the generated list and
  generates all kinds of inputs not only those that produce a stack of size 1.
*)
let gen_arith_program =
  QCheck2.Gen.(
    map (fun (_, l) -> List.rev l)
    @@ sized_size small_nat
    @@ fix (fun self n ->
           match n with
           | 0 -> map (fun x -> (1, [string_of_int x])) small_nat
           | n ->
               frequency
                 [
                   ( 2,
                     map2
                       (fun x (stack_size, state_list) ->
                         if stack_size >= 2 then
                           (stack_size - 1, "+" :: state_list)
                         else (stack_size + 1, string_of_int x :: state_list))
                       small_nat
                       (self (n - 1)) );
                   ( 1,
                     map2
                       (fun x (i, y) -> (i + 1, string_of_int x :: y))
                       small_nat
                       (self (n - 1)) );
                 ]))

module type TestPVM = sig
  include PVM.S with type hash = State_hash.t

  module Utils : sig
    val init_context : unit -> context

    (** This a post-boot state. It is used as default in many functions. *)
    val default_state : context -> state

    (** [random_state n state] generates a random state. The integer n is
        used as a seed in the generation. *)
    val random_state : int -> state -> state

    (** [make_invalid_proof start stop] produces a completely random
        invalid proof *)
    val make_invalid_proof : context -> proof Lwt.t
  end
end

(**

   [MakeCountingPVM (P)] is a PVM whose state is an integer and that
   can count up to a certain [P.target].

   This PVM has no input states.

*)
module MakeCountingPVM (P : sig
  val target : int
end) : TestPVM with type state = int = struct
  let name = "countingPVM"

  let parse_boot_sector x = Some x

  let pp_boot_sector fmt x = Format.fprintf fmt "%s" x

  type state = int

  type hash = State_hash.t

  type context = unit

  type proof = dummy_proof

  let proof_start_state = proof_start_state

  let proof_stop_state = proof_stop_state

  let proof_input_given _ = None

  let proof_input_requested _ = No_input_required

  let state_hash_ (x : state) =
    State_hash.context_hash_to_state_hash
    @@ Context_hash.hash_string [Int.to_string x]

  let state_hash (x : state) = return (state_hash_ x)

  let is_input_state x =
    if x >= P.target then return Initial else return No_input_required

  let initial_state _ = return 0

  let install_boot_sector _ _ = return P.target

  let set_input _ s = return s

  module Utils = struct
    let init_context () = ()

    let default_state () = P.target

    let random_state _ _ = Random.bits ()

    let make_invalid_proof () =
      return {
        start = random_hash ();
        stop = Some (random_hash ());
        valid = false;
      }
  end

  let proof_encoding = dummy_proof_encoding

  let eval state = if state >= P.target then return state else return (state + 1)

  let verify_proof proof = return proof.valid

  let produce_proof () _ state =
    let* start = state_hash state in
    let* next = eval state in
    let* stop = state_hash next in
    if State_hash.equal start stop then
      return (ok {start; stop = None; valid = true})
    else return (ok {start; stop = Some stop; valid = true})

  let verify_origination_proof proof _ = return proof.valid

  let produce_origination_proof _ _ =
    Stdlib.failwith "Dummy PVM can't produce proof"

  type output_proof = unit

  let output_proof_encoding = Data_encoding.unit

  let state_of_output_proof _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"

  let output_of_output_proof _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"

  let verify_output_proof _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"

  let produce_output_proof _ _ _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"
end

(** This is a random PVM. Its state is a pair of a string and a
    list of integers. An evaluation step consumes the next integer
    of the list and concatenates its representation to the string. *)
module MakeRandomPVM (P : sig
  val initial_prog : int list
end) : TestPVM with type state = string * int list = struct
  let name = "randomPVM"

  let parse_boot_sector x = Some x

  let pp_boot_sector fmt x = Format.fprintf fmt "%s" x

  type state = string * int list

  type context = unit

  type proof = dummy_proof

  type hash = State_hash.t

  let to_string (a, b) =
    Format.sprintf "(%s, [%s])" a (String.concat ";" @@ List.map Int.to_string b)

  let proof_start_state = proof_start_state

  let proof_stop_state = proof_stop_state

  let proof_input_given _ = None

  let proof_input_requested _ = No_input_required

  let state_hash_ x =
    State_hash.context_hash_to_state_hash
    @@ Context_hash.hash_string [to_string x]

  let state_hash (x : state) = return @@ state_hash_ x

  let initial_state _ = return ("", [])

  let install_boot_sector _ _ = return ("hello", P.initial_prog)

  let is_input_state (_, c) =
    match c with [] -> return Initial | _ -> return No_input_required

  let set_input _ state = return state

  module Utils = struct
    let init_context () = ()

    let default_state () = ("hello", P.initial_prog)

    let random_state length ((_, program) : state) =
      let remaining_program = TzList.drop_n length program in
      let (stop_state : state) =
        (hash_state "" (Random.bits ()), remaining_program)
      in
      stop_state

    let make_invalid_proof () =
      return {
        start = random_hash ();
        stop = Some (random_hash ());
        valid = false;
      }
  end

  let proof_encoding = dummy_proof_encoding

  let eval (hash, continuation) =
    match continuation with
    | [] -> return (hash, continuation)
    | h :: tl -> return (hash_state hash h, tl)

  let verify_proof proof = return proof.valid

  let produce_proof () _ state =
    let* start = state_hash state in
    let* next = eval state in
    let* stop = state_hash next in
    if State_hash.equal stop start then
      return (ok {start; stop = None; valid = true})
      else return (ok {start; stop = Some stop; valid = true})

  let verify_origination_proof proof _ = return proof.valid

  let produce_origination_proof _ _ =
    Stdlib.failwith "Dummy PVM can't produce proof"

  type output_proof = unit

  let output_proof_encoding = Data_encoding.unit

  let state_of_output_proof _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"

  let output_of_output_proof _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"

  let verify_output_proof _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"

  let produce_output_proof _ _ _ =
    Stdlib.failwith "Dummy PVM can't handle output proof"
end

module ContextPVM = ArithPVM.Make (struct
  open Tezos_context_memory.Context

  module Tree = struct
    include Tezos_context_memory.Context.Tree

    type tree = Tezos_context_memory.Context.tree

    type t = Tezos_context_memory.Context.t

    type key = string list

    type value = bytes
  end

  type tree = Tree.tree

  let hash_tree tree =
    Sc_rollup.State_hash.context_hash_to_state_hash (Tree.hash tree)

  type proof = Proof.tree Proof.t

  let verify_proof proof f =
    Lwt.map Result.to_option (verify_tree_proof proof f)

  let produce_proof context state f =
    let* proof =
      produce_tree_proof (index context) (`Value (Tree.hash state)) f
    in
    return (Some proof)

  let kinded_hash_to_state_hash = function
    | `Value hash | `Node hash -> State_hash.context_hash_to_state_hash hash

  let proof_before proof = kinded_hash_to_state_hash proof.Proof.before

  let proof_after proof = kinded_hash_to_state_hash proof.Proof.after

  let proof_encoding =
    let open Data_encoding in
    conv (fun _ -> ()) (fun _ -> assert false) unit
end)

module TestArith (P : sig
  val initial_input : string

  val pre_evals : int
end) : TestPVM = struct
  include ContextPVM

  module Utils = struct
    let init_context = Tezos_context_memory.make_empty_context ~root:""

    let make_external_inbox_message str =
      WithExceptions.Result.get_ok
        ~loc:__LOC__
        Inbox.Message.(External str |> serialize)

    let default_state ctxt =
      let promise =
        let* boot = initial_state ctxt in
        let* boot = install_boot_sector boot "" in
        let* boot = eval boot in
        let input =
          {
            inbox_level = Raw_level.root;
            message_counter = Z.zero;
            payload = make_external_inbox_message P.initial_input;
          }
        in
        let prelim = set_input input boot in
        List.fold_left
          (fun acc () -> acc >>= fun acc -> eval acc)
          prelim
          (List.repeat P.pre_evals ())
      in
      Lwt_main.run promise

    let random_state i state =
      let program = QCheck2.Gen.(generate1 gen_arith_program) in
      let input =
        {
          inbox_level = Raw_level.root;
          message_counter = Z.zero;
          payload = make_external_inbox_message @@ String.concat " " program;
        }
      in
      let prelim = set_input input state in
      Lwt_main.run
      @@ List.fold_left (fun acc _ -> acc >>= fun acc -> eval acc) prelim
      @@ List.repeat (min i (List.length program - 2) + 1) ()

    let make_invalid_proof ctxt =
      let state = random_state 0 (default_state ctxt) in
      let* proof_opt = produce_proof ctxt None state in
      match proof_opt with Ok proof -> return proof | Error _ -> assert false
  end
end

type outcome_for_tests =
  | Defender_wins of Game.reason
  | Refuter_wins of Game.reason

let outcome_for_tests (outcome : Game.outcome) alice_is_refuter =
  match outcome.loser with
  | Game.Bob ->
      if alice_is_refuter then Refuter_wins outcome.reason
      else Defender_wins outcome.reason
  | Game.Alice ->
      if alice_is_refuter then Defender_wins outcome.reason
      else Refuter_wins outcome.reason

(** There are four strategies:

    - [Perfect] is a completely honest player
    - [Random] is a completely random player
    - [Lazy] is a player that is honest except that they stop evaluating
      too soon and commit prematurely
    - [Eager] is honest up to the correct commit tick, but continues
      with dishonest computation steps after that *)
type strategy = Perfect | Random | Lazy | Eager

let strategy_name = function
  | Perfect -> "perfect"
  | Random -> "random"
  | Lazy -> "lazy"
  | Eager -> "eager"

(**
   This module introduces some testing strategies for a game created
   from a PVM.
*)
module Strategies (PVM : TestPVM with type hash = State_hash.t) = struct
  (** [exec_all state tick] runs eval until the state machine reaches a
      state where it requires an input. It returns a map containing all
      the intermediate states, and the final tick.
      *)
  let exec_all state tick =
    let rec loop state tick tick_map =
      let* isinp = PVM.is_input_state state in
      match isinp with
      | No_input_required ->
          let* s = PVM.eval state in
          let* hash1 = PVM.state_hash state in
          let* hash2 = PVM.state_hash s in

          if State_hash.equal hash1 hash2 then assert false
          else loop s (Tick.next tick) (Tick.Map.add tick state tick_map)
      | _ -> return (Tick.Map.add tick state tick_map, tick)
    in
    loop state tick Tick.Map.empty

  (** [dissection_of_section start_tick start_state stop_tick] creates
     a dissection with at most [32] pieces that are (roughly) equal
     spaced and whose states are computed by running the eval function
     until the correct tick. Note that the last piece can be as much
     as 31 ticks longer than the others.  *)
  let dissection_of_section start_tick stop_tick state_fn =
    let start_int = tick_to_int_exn start_tick in
    let stop_int = tick_to_int_exn stop_tick in
    let dist = stop_int - start_int in
    if dist = 1 then return None
    else
      let branch = min (dist + 1) 32 in
      let size = (dist + 1) / (branch - 1) in
      let tick_list =
        Result.to_option
        @@ List.init branch ~when_negative_length:"error" (fun i ->
               if i = branch - 1 then stop_tick
               else tick_of_int_exn (start_int + (i * size)))
      in
      let a =
        Option.map
          (fun a ->
            List.map
              (fun tick ->
                let hash =
                  Lwt_main.run
                  @@ let state = state_fn tick in
                     match state with
                     | None -> return None
                     | Some s ->
                         let* h = PVM.state_hash s in
                         return (Some h)
                in
                mk_dissection_chunk (hash, tick))
              a)
          tick_list
      in
      return a

  type client = {
    initial : (Tick.t * PVM.hash) Lwt.t;
    next_move : Game.t -> Game.refutation option Lwt.t;
  }

  let run ~inbox ~refuter_client ~defender_client =
    let refuter, (_ : public_key), (_ : Signature.secret_key) =
      Signature.generate_key ()
    in
    let defender, (_ : public_key), (_ : Signature.secret_key) =
      Signature.generate_key ()
    in
    let alice_is_refuter = Staker.(refuter < defender) in
    let common_ctxt = PVM.Utils.init_context () in
    let* start_hash = PVM.state_hash (PVM.Utils.default_state common_ctxt) in
    let* tick, initial_hash = defender_client.initial in
    let int_tick = tick_to_int_exn tick in
    let number_of_ticks = Int32.of_int int_tick in
    let parent = get_comm Commitment.Hash.zero 0l 3l 1l start_hash in
    let child =
      get_comm Commitment.Hash.zero 0l 3l number_of_ticks initial_hash
    in
    let initial_game =
      Game.initial inbox ~pvm_name:PVM.name ~parent ~child ~refuter ~defender
    in
    let* outcome =
      let rec loop game refuter_move =
        let* move =
          if refuter_move then refuter_client.next_move game
          else defender_client.next_move game
        in
        match move with
        | None ->
            Printf.eprintf
              "@[No move from %s@]"
              (if refuter_move then "refuter" else "defender") ;
            return
              (if refuter_move then Defender_wins Timeout
              else Refuter_wins Timeout)
        | Some move -> (
            let* game_result = Game.play game move in
            match game_result with
            | Either.Left outcome ->
                Format.eprintf "@[%a@]@." Game.pp_outcome outcome ;
                return (outcome_for_tests outcome alice_is_refuter)
            | Either.Right game -> loop game (not refuter_move))
      in
      loop initial_game true
    in
    return outcome

  let random_tick ?(from = 0) () =
    Option.value ~default:Tick.initial (Tick.of_int (from + Random.int 31))

  (**
  checks that the stop state of a section conflicts with the one computed by the
   evaluation.
  *)
  let conflicting_section tick hash state_fn =
    let* new_hash =
      match state_fn tick with
      | None -> return None
      | Some state ->
          let* state = PVM.state_hash state in
          return (Some state)
    in

    return @@ not (Option.equal ( = ) hash new_hash)

  (** This function assembles a random decision from a given dissection.
    It first picks a random section from the dissection and modifies randomly
     its states.
    If the length of this section is one tick the returns a conclusion with
    the given modified states.
    If the length is longer it creates a random decision and outputs a Refine
     decision with this dissection.*)
  let random_decision ctxt d =
    let number_of_somes =
      List.length
        (List.filter (fun {Game.state_hash; _} -> Option.is_some state_hash) d)
    in
    let x = Random.int (number_of_somes - 1) in
    let start_hash, start =
      match List.nth d x with
      | Some Game.{state_hash = Some s; tick = t} -> (s, t)
      | _ -> assert false
    in
    let (_ : State_hash.t option), stop =
      match List.nth d (x + 1) with
      | Some Game.{state_hash; tick} -> (state_hash, tick)
      | None -> assert false
    in
    let stop_hash = Some (random_hash ()) in
    let* random_dissection =
      random_dissection start start_hash stop stop_hash
    in

    match random_dissection with
    | None ->
        let* pvm_proof = PVM.Utils.make_invalid_proof ctxt in
        let wrapped =
          let module P = struct
            include PVM

            let proof = pvm_proof
          end in
          Unencodable (module P)
        in
        let proof = Proof.{pvm_step = wrapped; inbox = None} in
        return (Some Game.{choice = start; step = Proof proof})
    | Some dissection ->
        return (Some Game.{choice = start; step = Dissection dissection})

  (**
  [find_conflict dissection] finds the section (if it exists) in a dissection that
    conflicts  with the actual computation. *)
  let find_conflict dissection state_fn =
    let rec aux states =
      match states with
      | start :: next :: rest ->
          let Game.{state_hash = next_hash; tick = next_tick} = next in
          let* conflict = conflicting_section next_tick next_hash state_fn in
          if conflict then return (start, next) else aux (next :: rest)
      | _ ->
          Format.eprintf "%a" Game.pp_dissection dissection;
          assert false
    in
    aux dissection

  (** [next_move branching dissection] finds the next move based on a
  dissection.
  It finds the first section of dissection that conflicts with the evaluation.
  If the section has length one tick it returns a move with a Conclude
  conflict_resolution_step.
  If the section is longer it creates a new dissection with branching
  many pieces and returns
   a move with a Refine type conflict_resolution_step.
   *)
  let next_move ctxt dissection state_fn =
    let* (agree, disagree) = find_conflict dissection state_fn in
    let Game.{tick = agree_tick; _} = agree in
    let Game.{tick = disagree_tick; _} = disagree in
    let agree_state = state_fn agree_tick in
    let* next_dissection =
      match agree_state with
      | None -> assert false
      | Some _ -> dissection_of_section agree_tick disagree_tick state_fn
    in
    let* refutation =
      match next_dissection with
      | None ->
          let* pvm_proof =
            match agree_state with
            | Some s -> PVM.produce_proof ctxt None s
            | None -> assert false
          in
          let wrapped =
            match pvm_proof with
            | Ok p ->
                let module P = struct
                  include PVM

                  let proof = p
                end in
                Unencodable (module P)
            | Error _ -> assert false
          in
          let proof = Proof.{pvm_step = wrapped; inbox = None} in
          return Game.{choice = agree_tick; step = Proof proof}
      | Some next_dissection ->
          return
            Game.{choice = agree_tick; step = Dissection next_dissection}
    in
    return (Some refutation)

  (** This is client directed by evaluating the PVM state honestly.
      
      If [extra] is non-zero, we add random states after the end of
      honest evaluation. If [missing] is non-zero, we remove states
      (replace them with [None]) before the end of honest evaluation. *)
  let machine_directed ~extra ~missing =
    let ctxt = PVM.Utils.init_context () in
    let start_state = PVM.Utils.default_state ctxt in
    let* tick_map, honest_stop_at = exec_all start_state Tick.initial in
    let stop_at =
      Tick.jump
        (Tick.jump honest_stop_at (Z.of_int extra))
        (Z.neg (Z.of_int missing))
    in
    let tick_map =
      let rec aux tm t up_to =
        if Tick.(t > up_to) then
          tm
          else
            let new_map =
              Tick.Map.add
                t
                (PVM.Utils.random_state (tick_to_int_exn t) start_state)
                tm
            in
            aux new_map (Tick.next t) up_to
      in
      aux tick_map (Tick.next honest_stop_at) stop_at
    in
    let state_fn t =
      if Tick.(t > stop_at) then None else Tick.Map.find t tick_map
    in
    let initial =
      let stop_state =
        match state_fn stop_at with Some s -> s | None -> assert false
      in
      let* stop_hash = PVM.state_hash stop_state in
      return (stop_at, stop_hash)
    in

    let next_move (game : Game.t) =
      let dissection = game.dissection in
      let* mv = next_move ctxt dissection state_fn in
      match mv with Some move -> return (Some move) | None -> return None
    in
    return {initial; next_move}

  (** This builds a client from a strategy. If the strategy is
     Perfect it uses the above constructions.  If the strategy
     is random then it uses a random section for the initial
     commitments and the random decision for the next move. *)
  let player_from_strategy = function
    | Random ->
        let ctxt = PVM.Utils.init_context () in
        let initial =
          let state = PVM.Utils.default_state ctxt in
          let* hash = PVM.state_hash state in
          let random_tick = random_tick ~from:1 () in
          return (random_tick, hash)
        in
        return
          {initial; next_move = (fun game -> random_decision ctxt game.dissection)}
    | Perfect -> machine_directed ~extra:0 ~missing:0
    | Lazy -> machine_directed ~extra:0 ~missing:10
    | Eager -> machine_directed ~extra:10 ~missing:0

  (** [test_strategies defender_strategy refuter_strategy expectation inbox]
      runs a game based oin the two given strategies and checks that the
      resulting outcome fits the expectations. *)
  let test_strategies defender_strategy refuter_strategy expectation inbox =
    let* defender_client = player_from_strategy defender_strategy in
    let* refuter_client = player_from_strategy refuter_strategy in
    let* outcome = run ~inbox ~defender_client ~refuter_client in
    return (expectation outcome)
end

(** some possible expectation functions *)
let defender_wins = function Defender_wins _ -> true | _ -> false

let refuter_wins = function Refuter_wins _ -> true | _ -> false

let either_wins _ = true

let construct_inbox payload_lists =
  let rollup = Address.hash_string [""] in
  let level = Raw_level.root in
  let context = Tezos_protocol_environment.Memory_context.empty in
  let* inbox = Inbox.empty context rollup level in
  let history = Inbox.history_at_genesis ~bound:10000L in
  let rec aux level history inbox level_tree = function
    | [] -> return (level_tree, history, inbox)
    | payloads :: ps ->
        let new_level = Raw_level.succ level in
        (match payloads with
        | [] -> aux new_level history inbox level_tree ps
        | _ ->
            let* result =
              Inbox.add_messages context history inbox level payloads level_tree
            in
            (match result with
            | Ok (level_tree, history, inbox) ->
                aux new_level history inbox (Some level_tree) ps
            | Error _ -> assert false))
  in
  aux level history inbox None payload_lists


(** This assembles a test from a RandomPVM and a function that chooses the
    type of strategies. *)
let testing_randomPVM ref_strat def_strat expectation =
  let open QCheck2 in
  let name =
    Format.sprintf
      "%s-vs-%s"
      (strategy_name ref_strat)
      (strategy_name def_strat)
  in
  Test.make
    ~name
    Gen.(list_size small_int (int_range 0 100))
    (fun initial_prog ->
      assume (initial_prog <> []) ;
      Lwt_main.run
      @@ let* _, _, inbox = construct_inbox [] in
         let snapshot = Inbox.take_snapshot inbox in
         let module P = MakeRandomPVM (struct
           let initial_prog = initial_prog
         end) in
         let module S = Strategies (P) in
         S.test_strategies def_strat ref_strat expectation snapshot)

(** This assembles a test from a CountingPVM and a function that
   chooses the type of strategies *)
let testing_countPVM ref_strat def_strat expectation =
  let open QCheck2 in
  let name =
    Format.sprintf
      "%s-vs-%s"
      (strategy_name ref_strat)
      (strategy_name def_strat)
  in
  Test.make ~name Gen.small_int (fun target ->
      assume (target > 200) ;
      Lwt_main.run
      @@ let* _, _, inbox = construct_inbox [] in
         let snapshot = Inbox.take_snapshot inbox in
         let module P = MakeCountingPVM (struct
           let target = target
         end) in
         let module S = Strategies (P) in
         S.test_strategies def_strat ref_strat expectation snapshot)

let testing_arith ref_strat def_strat expectation =
  let open QCheck2 in
  let name =
    Format.sprintf
      "%s-vs-%s"
      (strategy_name ref_strat)
      (strategy_name def_strat)
  in
  Test.make
    ~name
    Gen.(pair gen_arith_program small_int)
    (fun (initial_input, pre_evals) ->
      assume (pre_evals < List.length initial_input - 2) ;
      Lwt_main.run
      @@ let* _, _, inbox = construct_inbox [] in
         let snapshot = Inbox.take_snapshot inbox in
         let module P = TestArith (struct
           let initial_input = String.concat " " initial_input

           let pre_evals = pre_evals
         end) in
         let module S = Strategies (P) in
         S.test_strategies def_strat ref_strat expectation snapshot)

let test_random_dissection (module P : TestPVM) start_at length =
  let open P in
  let module S = Strategies (P) in
  let ctxt = P.Utils.init_context () in
  let section_start_state = Utils.default_state ctxt in
  let* tick_map, (_ : Tick.t) =
    S.exec_all section_start_state (tick_of_int_exn start_at)
  in
  let state_fn t = Tick.Map.find t tick_map in
  let section_stop_at = tick_of_int_exn (start_at + length) in
  let section_start_at = tick_of_int_exn start_at in
  let* option_dissection =
    S.dissection_of_section section_start_at section_stop_at state_fn
  in
  let dissection =
    match option_dissection with
    | None -> raise (Invalid_argument "no dissection")
    | Some x -> x
  in
  let* start = state_hash section_start_state in
  let* check =
    Game.check_dissection
      (Some start)
      section_start_at
      (Some (random_hash ()))
      section_stop_at
      dissection
  in
  match check with
  | Ok () -> return true
  | Error reason ->
      Format.eprintf "%a" Game.pp_reason reason ;
      assert false

let testDissection =
  let open QCheck2 in
  [
    Test.make
      ~name:"randomVPN"
      Gen.(triple (list_size small_int (int_range 0 100)) small_int small_int)
      (fun (initial_prog, start_at, length) ->
        assume
          (start_at >= 0 && length > 1
          && List.length initial_prog > start_at + length) ;
        let module P = MakeRandomPVM (struct
          let initial_prog = initial_prog
        end) in
        Lwt_main.run @@ test_random_dissection (module P) start_at length);
    Test.make
      ~name:"count"
      Gen.(triple small_int small_int small_int)
      (fun (target, start_at, length) ->
        assume (start_at >= 0 && length > 1) ;
        let module P = MakeCountingPVM (struct
          let target = target
        end) in
        Lwt_main.run @@ test_random_dissection (module P) start_at length);
  ]

let testRandomDissection =
  let open QCheck2 in
  [
    Test.make
      ~name:"randomdissection"
      Gen.(pair small_int small_int)
      (fun (start_int, length) ->
        assume (start_int > 0 && length >= 10) ;
        let testing_lwt =
          let start_at = tick_of_int_exn start_int in
          let stop_at = tick_of_int_exn (start_int + length) in
          let start_hash = random_hash () in
          let stop_hash = Some (random_hash ()) in

          let* dissection_opt =
            random_dissection start_at start_hash stop_at stop_hash
          in
          let dissection =
            match dissection_opt with None -> assert false | Some d -> d
          in
          let rec aux hash =
            let new_hash = Some (random_hash ()) in
            if hash = new_hash then aux hash else new_hash
          in
          let new_hash = aux stop_hash in
          let* check =
            Game.check_dissection
              (Some start_hash)
              start_at
              new_hash
              stop_at
              dissection
          in
          return (Result.to_option check = Some ())
        in
        Lwt_main.run testing_lwt);
  ]

let () =
  Alcotest.run
    "Refutation Game"
    [
      ("Dissection tests", qcheck_wrap testDissection);
      ("Random dissection", qcheck_wrap testRandomDissection);
      ( "RandomPVM",
        qcheck_wrap
          [
            (*testing_randomPVM Perfect Perfect defender_wins;*)
            testing_randomPVM Eager Perfect defender_wins;
            testing_randomPVM Perfect Eager refuter_wins;
            testing_randomPVM Lazy Perfect defender_wins;
            testing_randomPVM Perfect Lazy refuter_wins;
            testing_randomPVM Eager Lazy refuter_wins;
            testing_randomPVM Lazy Eager defender_wins;
            testing_randomPVM Random Random either_wins;
            testing_randomPVM Random Perfect defender_wins;
            testing_randomPVM Perfect Random refuter_wins;
          ] );
      ( "CountingPVM",
        qcheck_wrap
          [
            testing_countPVM Perfect Perfect defender_wins;
            testing_countPVM Random Random either_wins;
            testing_countPVM Random Perfect defender_wins;
            testing_countPVM Perfect Random refuter_wins;
          ] );
      ( "ArithPVM",
        qcheck_wrap
          [
            (*testing_arith Perfect Perfect defender_wins;*)
            testing_arith Random Random either_wins;
            (*testing_arith Random Perfect defender_wins;
            testing_arith Perfect Random refuter_wins;*)
          ] );
    ]
