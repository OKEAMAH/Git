(* [Tezt] and its submodule [Base] are designed to be opened.
   [Tezt] is the main module of the library and it only contains submodules,
   such as [Test] which is used below.
   [Tezt.Base] contains values such as [unit] which is used below. *)
open Tezt_core
open Base

(* Register as many tests as you want like this. *)
let () =
  Test.register
  (* [~__FILE__] contains the name of the file in which the test is defined.
     It allows to select tests to run based on their filename. *)
    ~__FILE__
      (* Titles uniquely identify tests so that they can be individually selected. *)
    ~title:"demo"
      (* Tags are another way to group tests together to select them. *)
    ~tags:["math"; "addition"]
  @@ fun () ->
  (* Here is the actual test. *)
  if 1 + 1 <> 2 then Test.fail "expected 1 + 1 = 2, got %d" (1 + 1) ;
  (* Here is another way to write the same test. *)
  Check.((1 + 1 = 2) int) ~error_msg:"expected 1 + 1 = %R, got %L" ;
  Log.info "Math is safe today." ;
  (* [unit] is [Lwt.return ()]. *)
  unit

let () =
  Test.register
    ~__FILE__
    ~title:"fixed seed"
    ~tags:["seed"; "fixed"]
    ~seed:(Fixed 0)
  @@ fun () ->
  let x = Random.int64 Int64.max_int in
  Check.((x = 2497643567980153264L) int64) ~error_msg:"expected x = %R, got %L" ;
  unit

let () =
  Test.register
    ~__FILE__
    ~title:"random seed"
    ~tags:["seed"; "random"]
    ~seed:Random
  @@ fun () ->
  let x = Random.int64 Int64.max_int in
  Check.((x <> 2497643567980153264L) int64)
    ~error_msg:
      "expected x <> %R, got %L (there is a 1/2^63 chance that this happens)" ;
  unit

let () =
  Test.register
    ~__FILE__
    ~title:"string_tree: mem_prefix_of"
    ~tags:["string_tree"]
  @@ fun () ->
  let split file = String.split_on_char '/' file |> List.rev in
  List.iter
    (fun (suffixes, tests) ->
      let suffix_tree =
        List.fold_left
          (fun tree s -> Test.String_tree.add (split s) tree)
          Test.String_tree.empty
          suffixes
      in
      List.iter
        (fun (file, expected_res) ->
          let res = Test.String_tree.mem_prefix_of (split file) suffix_tree in
          Check.(
            (res = expected_res)
              bool
              ~__LOC__
              ~error_msg:
                (sf "mem_prefix_of(%s, %s) = " file (String.concat ";" suffixes)
                ^ "%L, expected %R")) ;
          Log.info
            "mem_prefix_of(%s, %s) = %b"
            file
            (String.concat ";" suffixes)
            res)
        tests)
    [
      (["c.ml"], [("c.ml", true); ("b/c.ml", true); ("d.ml", false)]);
      ( ["b/c.ml"],
        [("c.ml", false); ("b/c.ml", true); ("d.ml", false); ("a/b/c.ml", true)]
      );
      ([], [("c.ml", false); ("b/c.ml", false)]);
      ( ["b/x.ml"; "c/x.ml"; "y.ml"],
        [
          ("b/x.ml", true);
          ("c/x.ml", true);
          ("y.ml", true);
          ("z/x.ml", false);
          ("z/b/x.ml", true);
        ] );
    ] ;
  unit
