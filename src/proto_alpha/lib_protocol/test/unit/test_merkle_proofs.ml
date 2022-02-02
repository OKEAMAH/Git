(** Testing
    -------
    Component:  Protocol (time repr)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                -- test "^\[Unit\] time$"
    Subject:    Error handling of time operations
*)

open Protocol

let (let*) = (>>=?)

module E = Protocol.Environment
module C = Environment.Context

let consume _ctxt =
  return ()

let key_to_string : C.key -> string = fun key
  -> "/" ^ E.String.concat "/" key

let kinded_hash_to_string (hash : C.Proof.kinded_hash) : string = match hash with
  | `Value h ->
      Format.asprintf "%a" E.Context_hash.pp_short h
  | `Node h ->
      Format.asprintf "%a" E.Context_hash.pp_short h
let rec proof_tree_to_string (tree : C.Proof.tree) : string =
  let open C.Proof in
  match tree with
  | Value v ->
      Format.asprintf "Value(%s)" (E.Bytes.to_string v)
  | Blinded_value h ->
      Format.asprintf "Blinded_value(%a)"
        E.Context_hash.pp_short h
  | Node xs ->
      Format.asprintf "Node(%s)"
      (E.String.concat "," @@ E.List.map (fun (step,proof) -> step ^ proof_tree_to_string proof) xs)
  | Blinded_node h ->
      Format.asprintf "Blinded_node(%a)"
      E.Context_hash.pp_short h
  | Inode _ -> Stdlib.failwith "TODO"
  | Extender _ -> Stdlib.failwith "TODO"

let proof_to_string : C.Proof.tree C.Proof.t -> string = fun {version;before;after;state} ->
  Format.asprintf "{\nversion=%d;\nbefore=%s;\nafter=%s;\nstate=%s;\n}\n" version (kinded_hash_to_string before) (kinded_hash_to_string after) (proof_tree_to_string state)

let print_tree ctxt : 'a Lwt.t =
  let (let*) = (>>=) in

  let* () = C.fold ctxt [] ~order:`Sorted ~init:() ~f:(fun key _tree () ->
    E.Hack.printf "  %s = ?\n" (key_to_string key);
    Lwt.return ()
      )
  (* fail so we can see debug printing
  *)
  in
  Stdlib.failwith "Stopped to print tree"

(* TODO move *)
let test_raw_ctxt () =
  let* raw_ctxt = Context.default_raw_context () in
  let ctxt = Raw_context.recover raw_ctxt in
  (* Switch to Lwt syntax *)
  let (let*) = (>>=) in

  (* Test find/mem + tree versions *)
  let* res = C.find ctxt ["foo"] in
  let* _ = match res with
    | None -> return ()
    | Some _ -> Stdlib.failwith "Expected /foo not to be a value" in
  let* res = C.find_tree ctxt ["foo"] in
  let* _ = match res with
    | None -> return ()
    | Some _ -> Stdlib.failwith "Expected /foo not to be a tree" in


  (* Set /foo to empty tree, /foo is still unset *)
  let e = C.Tree.empty ctxt in
  let* ctxt = C.add_tree ctxt ["foo"] e in
  let* res = C.find ctxt ["foo"] in
  let* _ = match res with
    | None -> return ()
    | Some _ -> Stdlib.failwith "Expected /foo not to be a value" in
  let* res = C.find_tree ctxt ["foo"] in
  let* _ = match res with
    | None -> return ()
    | Some _ -> Stdlib.failwith "Expected /foo not to be a tree" in

  (* Set /foo = 123 *)
  let e = C.Tree.empty ctxt in
  let* t = C.Tree.add e [] @@ E.Bytes.of_string "123" in
  let* ctxt = C.add_tree ctxt ["foo"] t in
  (* Check /foo is a value *)
  let* res = C.find ctxt ["foo"] in
  let* _ = match res with
    | None -> Stdlib.failwith "None"
    | Some _ -> return ()
  in
  (* Check /foo/bar is not a tree *)
  let* res = C.find_tree ctxt ["foo";"bar"] in
  let* _ = match res with
    | None -> return ()
    | Some _ -> Stdlib.failwith "None"
  in
  (* Check that total size (number of values) of ctxt is 1 *)
  let* res = C.length ctxt [] in
  let* _ = match res with
    | 1 -> return ()
    | _n -> Stdlib.failwith "Wrong size"
  in

  (* Set /foo/bar = 123 *)
  let e = C.Tree.empty ctxt in
  let* t = C.Tree.add e ["bar"] @@ E.Bytes.of_string "123" in
  let* ctxt = C.add_tree ctxt ["foo"] t in
  (* check that /foo/bar is a value *)
  let* res = C.find ctxt ["foo";"bar"] in
  let* _ = match res with
    | None -> Stdlib.failwith "None"
    | Some _ -> return () (* TODO check it's the right value *)
  in
  (* check that /foo/bar is a tree - yes it can be a single-value tree  *)
  let* res = C.find_tree ctxt ["foo";"bar"] in
  let* _ = match res with
    | None -> Stdlib.failwith "None"
    | Some _ -> return ()
  in

  (* Set /bar = 123, /bar/x = 123, /foo/y = 123 *)
  let e = C.Tree.empty ctxt in
  let* ctxt = C.add_tree ctxt [] e in
  let* t = C.Tree.add e [] @@ E.Bytes.of_string "123" in
  let* ctxt = C.add_tree ctxt ["bar"] t in
  let* ctxt = C.add_tree ctxt ["foo"] t in (* to be overwritten *)
  let* ctxt = C.add_tree ctxt ["foo";"x"] t in
  let* ctxt = C.add_tree ctxt ["foo";"y"] t in


  (* NOTE: length only counts subtrees, NOT values *)
  let* mt = C.find_tree ctxt [] in
  match mt with
    | None -> Stdlib.failwith "Expected a tree"
    | Some t2 ->
      let* res = C.Tree.length t2 [] in
      let* _ = match res with
        | 2 -> return ()
        | n ->
              E.Hack.printf "\n\n<<< %d >>>\n\n" n;
              Stdlib.failwith "Wrong size"
  in
  (* NOTE: (length ctxt []) is not equal to (length @@ find_tree ctxt [])
  *)

  (* Reset to empty tree *)
  let e = C.Tree.empty ctxt in
  let* ctxt = C.add_tree ctxt [] e in
  (* Set /foo/x = 123 *)
  let* ctxt = C.add_tree ctxt ["foo";"x"] t in
  let* ctxt = C.add_tree ctxt ["bar";"x";"y";"z"] t in

  let* (proof,()) = C.produce_tree_proof ctxt (fun tree ->
      let* _ = C.Tree.find_tree tree ["foo"] in
      Lwt.return (tree,())) in


  let () = E.Hack.printf "%s\n\n" (proof_to_string proof) in

  (* Print the full tree
  let* () = print_tree ctxt in
  *)

  (* All done *)
  consume ctxt


let tests =
  [
    Tztest.tztest "test merkle proofs from env" `Quick test_raw_ctxt;
  ]
