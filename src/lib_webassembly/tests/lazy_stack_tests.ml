open QCheck_alcotest
open QCheck2
open Lazy_vector
open Decode
module TzStdLib = Tezos_lwt_result_stdlib.Lwtreslib.Bare

let gen_of_list =
  let open Gen in
  let* list = list nat in
  let+ length = int_range 0 (List.length list) in
  LazyStack {vector = LwtInt32Vector.of_list list; length = Int32.of_int length}

let check_pop (LazyStack {vector; length} as stack) =
  let open Lwt.Syntax in
  let* v = pop_stack stack in
  match v with
  | None -> Lwt.return (length = 0l)
  | Some (v, LazyStack {length = length'; _}) ->
      let+ v_before = LwtInt32Vector.get (Int32.pred length) vector in
      length = Int32.succ length' && v_before = v

let check_pop_doesnt_mutate (LazyStack {vector; length} as stack) =
  let open Lwt.Syntax in
  let* v = pop_stack stack in
  match v with
  | None -> Lwt.return_true
  | Some (_, LazyStack {vector = vector'; length = length'}) ->
      let* v_before = LwtInt32Vector.get (Int32.pred length) vector in
      let+ v' = LwtInt32Vector.get (Int32.pred length) vector' in
      length = Int32.succ length' && v_before = v'

let check_push v (LazyStack {length; _} as stack) =
  let open Lwt.Syntax in
  let (LazyStack {vector = vector'; length = length'}) = push_stack v stack in
  let+ v' = LwtInt32Vector.get length vector' in
  v = v' && length' = Int32.succ length

let check_push_growth v (LazyStack {vector; length} as stack) =
  let size_before = LwtInt32Vector.num_elements vector in
  let (LazyStack {vector = vector'; length = length'}) = push_stack v stack in
  if length = size_before then LwtInt32Vector.num_elements vector' = length'
  else LwtInt32Vector.num_elements vector = size_before

let check_pop_at_most number (LazyStack {length; vector} as stack) =
  let open Lwt.Syntax in
  let* values, _ = pop_at_most number stack in
  TzStdLib.List.fold_left_i_s
    (fun i res v ->
      let index = Int32.(pred (sub length (Int32.of_int i))) in
      let+ v' = LwtInt32Vector.get index vector in
      v = v' && res)
    true
    values

let check_pop_at_most_doesnt_overflow number (LazyStack {length; _} as stack) =
  let open Lwt.Syntax in
  let+ values, LazyStack {length = length'; _} = pop_at_most number stack in
  let len_values = List.length values in
  Format.printf
    "length: %ld; number: %d; length values: %d; length' = %ld\n%!"
    length
    number
    len_values
    length' ;
  len_values <= number && Int32.(sub length (of_int len_values)) = length'

let check_push_rev values (LazyStack {length; _} as stack) =
  let open Lwt.Syntax in
  let len_values = List.length values in
  let (LazyStack {length = length'; vector}) = push_rev_values values stack in
  TzStdLib.List.fold_left_i_s
    (fun i res v ->
      let index = Int32.(pred (sub length' (Int32.of_int i))) in
      let+ v' = LwtInt32Vector.get index vector in
      v = v' && res)
    (length' = Int32.(add (of_int len_values) length))
    values

let check_pop =
  Test.make ~name:"check pop" gen_of_list (fun stack ->
      Lwt_main.run @@ check_pop stack)

let check_pop_doesnt_mutate =
  Test.make ~name:"check pop doesn't mutate" gen_of_list (fun stack ->
      Lwt_main.run @@ check_pop_doesnt_mutate stack)

let check_push =
  Test.make
    ~name:"check pop"
    Gen.(pair int gen_of_list)
    (fun (v, stack) -> Lwt_main.run @@ check_push v stack)

let check_push_growth =
  Test.make
    ~name:"check pop"
    Gen.(pair int gen_of_list)
    (fun (v, stack) -> check_push_growth v stack)

let check_pop_at_most =
  Test.make
    ~name:"check pop_at_most"
    Gen.(pair nat gen_of_list)
    (fun (v, stack) -> Lwt_main.run @@ check_pop_at_most v stack)

let check_pop_at_most_doesnt_overflow =
  Test.make
    ~name:"check pop_at_most doesn't overflow"
    Gen.(pair nat gen_of_list)
    (fun (v, stack) ->
      Lwt_main.run @@ check_pop_at_most_doesnt_overflow v stack)

let check_push_rev =
  Test.make
    ~name:"check push_rev"
    Gen.(pair (list_size small_nat int) gen_of_list)
    (fun (values, stack) -> Lwt_main.run @@ check_push_rev values stack)

let tests =
  [
    to_alcotest check_pop;
    to_alcotest check_pop_doesnt_mutate;
    to_alcotest check_push;
    to_alcotest check_push_growth;
    to_alcotest check_pop_at_most;
    to_alcotest check_pop_at_most_doesnt_overflow;
    to_alcotest check_push_rev;
  ]
