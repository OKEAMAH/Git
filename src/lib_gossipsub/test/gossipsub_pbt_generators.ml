(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Tezos_gossipsub
open Gossipsub_intf
module M = QCheck2.Gen

(* We need monadic sequences to represent {!Fragments}. *)
module SeqM = Seqes.Monadic.Make1 (M)

(* In the signature of {!GS} below, the [Time.t = int] constraint is required
   to be able to pretty-print the time obtained from
   [Test_gossipsub_shared.Time.now]. To clean this, one could expose
   [now] in [GS.Time] but it's not much cleaner. *)

(** [Make] instantiates a generator for gossipsub transitions. *)
module Make (GS : AUTOMATON with type Time.t = int) = struct
  open M

  (** We re-export {!GS} modules and types for convenience. *)

  module Peer = GS.Peer
  module Topic = GS.Topic
  module Message_id = GS.Message_id

  type input =
    | Add_peer of GS.add_peer (* case 0 *)
    | Remove_peer of GS.remove_peer (* case 1 *)
    | Ihave of GS.ihave (* case 2 *)
    | Iwant of GS.iwant (* case 3 *)
    | Graft of GS.graft (* case 4 *)
    | Prune of GS.prune (* case 5 *)
    | Publish of GS.publish (* case 6 *)
    | Heartbeat (* case 7 *)
    | Join of GS.join (* case 8 *)
    | Leave of GS.leave (* case 9 *)
    | Subscribe of GS.subscribe (* case 10 *)
    | Unsubscribe of GS.unsubscribe (* case 11 *)

  type output = O : _ GS.output -> output

  type event = Input of input | Elapse of int

  type transition = {
    t : GS.Time.t;
    i : input;
    s : GS.state;
    s' : GS.state;
    o : output;
  }

  type trace = transition list

  let pp_input fmtr (i : input) =
    let open Format in
    match i with
    | Add_peer add_peer -> fprintf fmtr "Add_peer %a" GS.pp_add_peer add_peer
    | Remove_peer remove_peer ->
        fprintf fmtr "Remove_peer %a" GS.pp_remove_peer remove_peer
    | Ihave handle_ihave -> fprintf fmtr "Ihave %a" GS.pp_ihave handle_ihave
    | Iwant handle_iwant -> fprintf fmtr "Iwant %a" GS.pp_iwant handle_iwant
    | Graft handle_graft -> fprintf fmtr "Graft %a" GS.pp_graft handle_graft
    | Prune handle_prune -> fprintf fmtr "Prune %a" GS.pp_prune handle_prune
    | Publish publish -> fprintf fmtr "Publish %a" GS.pp_publish publish
    | Heartbeat -> fprintf fmtr "Heartbeat"
    | Join join -> fprintf fmtr "Join %a" GS.pp_join join
    | Leave leave -> fprintf fmtr "Leave %a" GS.pp_leave leave
    | Subscribe subscribe ->
        fprintf fmtr "Subscribe %a" GS.pp_subscribe subscribe
    | Unsubscribe unsubscribe ->
        fprintf fmtr "Unsubscribe %a" GS.pp_unsubscribe unsubscribe

  let pp_trace ?pp_state ?pp_state' ?pp_output () fmtr trace =
    let open Format in
    let pp fmtr {t; i; s; s'; o} =
      fprintf fmtr "[%a] " GS.Time.pp t ;
      Option.iter (fun pp -> fprintf fmtr "%a => " pp s) pp_state ;
      pp_input fmtr i ;
      Option.iter (fun pp -> fprintf fmtr "/ %a" pp o) pp_output ;
      Option.iter (fun pp -> fprintf fmtr " => %a" pp s') pp_state'
    in
    fprintf
      fmtr
      "%a"
      (pp_print_list ~pp_sep:(fun fmtr () -> fprintf fmtr "@,") pp)
      trace

  let add_peer ~gen_peer =
    let+ direct = bool and+ outbound = bool and+ peer = gen_peer in
    ({direct; outbound; peer} : GS.add_peer)

  let remove_peer ~gen_peer =
    let+ peer = gen_peer in
    ({peer} : GS.remove_peer)

  let ihave ~gen_peer ~gen_topic ~gen_message_id ~gen_msg_count =
    let* msg_count = gen_msg_count in
    let+ peer = gen_peer
    and+ topic = gen_topic
    and+ message_ids = list_repeat msg_count gen_message_id in
    ({peer; topic; message_ids} : GS.ihave)

  let iwant ~gen_peer ~gen_message_id ~gen_msg_count =
    let* msg_count = gen_msg_count in
    let+ peer = gen_peer
    and+ message_ids = list_repeat msg_count gen_message_id in
    ({peer; message_ids} : GS.iwant)

  let graft ~gen_peer ~gen_topic =
    let+ peer = gen_peer and+ topic = gen_topic in
    ({peer; topic} : GS.graft)

  let prune ~gen_peer ~gen_topic ~gen_span px_count =
    let+ peer = gen_peer
    and+ topic = gen_topic
    and+ px =
      let+ l = list_repeat px_count gen_peer in
      List.to_seq l
    and+ backoff = gen_span in
    ({peer; topic; px; backoff} : GS.prune)

  let publish ~gen_peer ~gen_topic ~gen_message_id ~gen_message =
    let+ sender = option gen_peer
    and+ topic = gen_topic
    and+ message_id = gen_message_id
    and+ message = gen_message in
    ({sender; topic; message_id; message} : GS.publish)

  let join ~gen_topic =
    let+ topic = gen_topic in
    ({topic} : GS.join)

  let leave ~gen_topic =
    let+ topic = gen_topic in
    ({topic} : GS.leave)

  let subscribe ~gen_topic ~gen_peer =
    let+ topic = gen_topic and+ peer = gen_peer in
    ({topic; peer} : GS.subscribe)

  let unsubscribe ~gen_topic ~gen_peer =
    let+ topic = gen_topic and+ peer = gen_peer in
    ({topic; peer} : GS.unsubscribe)

  let wrap : GS.state * _ GS.output -> GS.state * output =
   fun (state, out) -> (state, O out)

  let input i = Input i

  let dispatch : input -> GS.state -> GS.state * output =
   fun i state ->
    match i with
    | Add_peer m -> GS.add_peer m state |> wrap
    | Remove_peer m -> GS.remove_peer m state |> wrap
    | Ihave m -> GS.handle_ihave m state |> wrap
    | Iwant m -> GS.handle_iwant m state |> wrap
    | Graft m -> GS.handle_graft m state |> wrap
    | Prune m -> GS.handle_prune m state |> wrap
    | Publish m -> GS.publish m state |> wrap
    | Heartbeat -> GS.heartbeat state |> wrap
    | Join m -> GS.join m state |> wrap
    | Leave m -> GS.leave m state |> wrap
    | Subscribe m -> GS.handle_subscribe m state |> wrap
    | Unsubscribe m -> GS.handle_unsubscribe m state |> wrap

  (** A fragment is a sequence of events encoding a basic interaction with
      the gossipsub automaton. Fragments can be composed sequentially
      and interleaved (modelling concurrent interaction). *)
  module Fragment = struct
    type raw =
      | Thread of event SeqM.t
      | Par of raw list
      | Seq of raw list (* [raw SeqM.t]? TODO *)

    type t = raw M.t

    let raw_of_list l = Thread (List.to_seq l |> Seq.map input |> SeqM.of_seq)

    let of_list l =
      M.return (Thread (List.to_seq l |> Seq.map input |> SeqM.of_seq))

    (* Smart [raw] constructors *)

    let empty_raw = Thread SeqM.empty

    let seq rs =
      match rs with
      | [] -> empty_raw
      | [raw] -> raw
      | _ ->
          let flattened =
            List.fold_right
              (fun raw acc ->
                match raw with Seq rs -> rs @ acc | _ -> raw :: acc)
              rs
              []
          in
          Seq flattened

    let par rs =
      match rs with
      | [] -> empty_raw
      | [raw] -> raw
      | _ ->
          let flattened =
            List.fold_right
              (fun raw acc ->
                match raw with Par rs -> rs @ acc | _ -> raw :: acc)
              rs
              []
          in
          Par flattened

    (* Sample the next event from a [raw]. *)
    let rec next :
        raw ->
        ((event * raw) option -> (event * raw) option M.t) ->
        (event * raw) option M.t =
     fun raw k ->
      let open M in
      match raw with
      | Thread seq -> (
          let* opt = SeqM.uncons seq in
          match opt with
          | None -> k None
          | Some (hd, tail) -> k (Some (hd, Thread tail)))
      | Seq [] -> k None
      | Seq (hd :: rest) ->
          next hd (function
              | Some (event, hd') -> k (Some (event, seq (hd' :: rest)))
              | None -> next (seq rest) k)
      | Par [] -> k None
      | Par parallel_components -> (
          let length = List.length parallel_components in
          let* index = int_bound (length - 1) in
          let rev_prefix, tail = List.rev_split_n index parallel_components in
          match tail with
          | [] -> assert false
          | fragment :: rest ->
              next fragment (function
                  | None -> next (par (List.rev_append rev_prefix rest)) k
                  | Some (elt, fragment') ->
                      k
                        (Some
                           ( elt,
                             par
                               (List.rev_append rev_prefix (fragment' :: rest))
                           ))))

    let next : raw -> (event * raw) option M.t =
     fun fragment -> next fragment M.return

    (* Combinators *)

    let of_input_gen gen f : t =
      let+ x = gen in
      raw_of_list (f x)

    let tick : t = Thread ([Elapse 1] |> List.to_seq |> SeqM.of_seq) |> M.return

    let repeat : int -> t -> t =
     fun n fragment ->
      let+ rs = M.list_repeat n fragment in
      seq rs

    let repeat_at_most : int -> t -> t =
     fun n fragment ->
      let* n = M.int_bound n in
      repeat n fragment

    let ( @% ) : t -> t -> t =
     fun x y ->
      let+ x and+ y in
      seq [x; y]

    let interleave : t list -> t =
     fun fs ->
      let+ rs = M.flatten_l fs in
      par rs

    let fork : int -> t -> t =
     fun n fragment ->
      let frags = List.repeat n fragment in
      interleave frags

    let fork_at_most n fragment =
      let* n = M.int_bound n in
      fork n fragment

    (* Shrinking *)

    (*
       fold_zip (fun rev_prefix elt tail acc -> (List.rev rev_prefix, elt, tail) :: acc) [1;2;3] [];;
       - : (int list * int * int list) list =  [([1; 2], 3, []); ([1], 2, [3]); ([], 1, [2; 3])]
     *)
    let fold_zip :
        ('a list -> 'a -> 'a list -> 'acc -> 'acc) -> 'a list -> 'acc -> 'acc =
     fun f l acc ->
      let rec loop l rev_prefix acc =
        match l with
        | [] -> acc
        | hd :: tl -> loop tl (hd :: rev_prefix) (f rev_prefix hd tl acc)
      in
      loop l [] acc

    (*
       fold_over_sublists (fun l acc -> l :: acc) [1;2;3] [];;
       - : int list list = [[1; 2]; [1; 3]; [2; 3]]
     *)
    let _fold_over_sublists :
        ('a list -> 'acc -> 'acc) -> 'a list -> 'acc -> 'acc =
     fun f l acc ->
      fold_zip
        (fun rev_prefix _elt tail -> f (List.rev_append rev_prefix tail))
        l
        acc

    (* We only shrink leaf [Par] nodes, i.e. [Par] nodes that do not
       contain [Par] nodes as subterms *)

    let rec par_free : raw -> bool =
     fun raw ->
      match raw with
      | Thread _ -> true
      | Par _ -> false
      | Seq rs -> List.for_all par_free rs

    let c = ref 0

    let shrink_raw : int -> int -> raw -> raw Seq.t =
     fun max_depth _depth raw ->
      let () = incr c in
      let () = Format.printf "shrinking %d@." !c in
      if !c > 50_000 then Seq.return raw
      else
        match raw with
        | Thread _ ->
            (* Can't shrink a thread *)
            Seq.return raw
        | Par [] -> Seq.return raw
        | Par elts ->
            if List.for_all par_free elts then
              let len = Int.min (List.length elts - 1) max_depth in
              let seq = List.to_seq elts in
              Stdlib.Seq.init len (fun i -> Stdlib.Seq.take i seq) |> Seq.concat
            else Seq.return raw
        (* fold_zip
         *   (fun rev_prefix elt tail acc ->
         *
         *   ) *)
        (* | Par components ->
         *     (\* If the [Par] is not leaf-level, we try to shrink each component
         *        one after the other. *\)
         *     fold_zip
         *       (fun rev_prefix elt tail acc ->
         *         Seq.flat_map
         *           (fun shrunk_elt ->
         *             Seq.cons
         *               (par (List.rev_append rev_prefix (shrunk_elt :: tail)))
         *               acc)
         *           (shrink_raw max_depth (depth + 1) elt))
         *       components
         *       Seq.empty *)
        | Seq [] -> Seq.return raw
        | Seq elts ->
            let len = Int.min (List.length elts - 1) max_depth in
            (* let len = 2 in *)
            let seq = List.to_seq elts in
            Stdlib.Seq.init len (fun i -> Stdlib.Seq.take i seq) |> Seq.concat

    let shrink_raw raw = shrink_raw 20 0 raw

    (* Evaluate a [raw] on an initial state yields a trace. *)
    let raw_to_trace state raw =
      let open M in
      let seq = SeqM.M.unfold next raw in
      let* _, _, rev_trace =
        SeqM.fold_left
          (fun (time, state, acc) event ->
            match event with
            | Input i ->
                Test_gossipsub_shared.Time.set time ;
                let state', output = dispatch i state in
                let step = {t = time; i; s = state; s' = state'; o = output} in
                (time, state', step :: acc)
            | Elapse d -> (time + d, state, acc))
          (0, state, [])
          seq
      in
      return (List.rev rev_trace)

    let raw_generator (fragment : t) : raw M.t =
      M.set_shrink shrink_raw fragment
  end

  let run state fragment : trace t =
    let open M in
    let* raw = Fragment.raw_generator fragment in
    Fragment.raw_to_trace state raw

  let check_fold (type e inv) (f : transition -> inv -> (inv, e) result) init
      trace : (unit, e * trace) result =
    let exception Predicate_failed of e * trace in
    try
      let _, _ =
        List.fold_left
          (fun (invariant, rev_trace) step ->
            let rev_trace = step :: rev_trace in
            match f step invariant with
            | Ok invariant -> (invariant, rev_trace)
            | Error e -> raise (Predicate_failed (e, List.rev rev_trace)))
          (init, [])
          trace
      in
      Ok ()
    with Predicate_failed (e, prefix) -> Error (e, prefix)

  let check_final f (trace : trace) =
    match List.rev trace with [] -> Ok () | t :: _ -> f t.s' t.o
end

include Make (Test_gossipsub_shared.GS)
