open Lwt.Infix

module Store = Tezos_storage.Context.Irmin
module P = Store.Private

module Commit = Irmin.Private.Commit.V1(P.Commit.Val)

module Node = struct

  module M = Irmin.Private.Node.Make (P.Hash) (Store.Key) (Store.Metadata)

  module Hash = Irmin.Hash.V1 (P.Hash)

  type kind = [`Node | `Contents]

  type entry = {key: string Lazy.t; kind: kind; name: M.step; node: Hash.t}

  (* Irmin 1.4 uses int64 to store string lengths *)
  let step_t =
    let pre_hash = Irmin.Type.(pre_hash (string_of `Int64)) in
    Irmin.Type.like M.step_t ~pre_hash

  let metadata_t =
    let some = "\255\000\000\000\000\000\000\000" in
    let none = "\000\000\000\000\000\000\000\000" in
    Irmin.Type.(map (string_of (`Fixed 8)))
      (fun s ->
         match s.[0] with
         | '\255' -> Some ()
         | '\000' -> None
         | _ -> assert false )
      (function Some _ -> some | None -> none)

  (* Irmin 1.4 uses int64 to store list lengths *)
  let entry_t : entry Irmin.Type.t =
    let open Irmin.Type in
    record "Tree.entry" (fun kind name node ->
        let kind = match kind with None -> `Node | Some () -> `Contents in
        let key =
          match kind with
          | `Node -> lazy (name ^ "/")
          | `Contents -> lazy name
        in
        {key; kind; name; node} )
    |+ field "kind" metadata_t (function
        | {kind= `Node; _} -> None
        | {kind= `Contents; _} -> Some () )
    |+ field "name" step_t (fun {name; _} -> name)
    |+ field "node" Hash.t (fun {node; _} -> node)
    |> sealr

  type t = entry list

  let t : t Irmin.Type.t = Irmin.Type.(list ~len:`Int64 entry_t)

  let export_entry e = match e.kind with
    | `Node -> e.name, `Node e.node
    | `Contents -> e.name, `Contents (e.node, ())

  let export (t:t) = P.Node.Val.v (List.map export_entry t)
end

let (>>*) v f =
  match v with
  | Ok v -> f v
  | Error e -> failwith (Lmdb.string_of_error e)

let lmdb root =
  Fmt.epr "Opening lmdb context in %s...\n%!" root;
  let mapsize = 409_600_000_000L in
  let flags = [ Lmdb.NoRdAhead ;Lmdb.NoTLS ] in
  let file_flags =  0o444 in
  Lmdb.opendir ~mapsize ~flags root file_flags >>* fun t ->
  Lmdb.create_ro_txn t >>* fun txn ->
  Lmdb.opendb txn >>* fun db ->
  db, txn

let of_string t s = match Irmin.Type.of_bin_string t s with
  | Ok s -> s
  | Error (`Msg e) -> failwith e

let hash_of_string = of_string Store.Hash.t
let contents_of_string = of_string P.Contents.Val.t
let node_of_string = of_string Node.t
let commit_of_string = of_string Commit.t

let commits = ref 0
let contents = ref 0
let nodes = ref 0

let pp_stats ppf () =
  Fmt.pf ppf "%4dk blobs / %4dk trees / %4dk commits"
    (!contents / 1000) (!nodes / 1000) (!commits / 1000)

let classify k =
  match Astring.String.cut ~sep:"/" k with
  | Some ("commit", key) -> `Commit (hash_of_string key)
  | Some ("contents", key) -> `Contents (hash_of_string key)
  | Some ("node",key) -> `Node (hash_of_string key)
  | _ -> failwith "invalid key"

let skip _ = Lwt.return ()

let key_of_entry e =
  let hash = Irmin.Type.to_bin_string Store.Hash.t Node.(e.node) in
  assert (String.length hash = 32);
  match Node.(e.kind) with
  | `Node -> "node/" ^ hash
  | `Contents -> "contents/" ^ hash

let rec append (db, txn) x y z k v =
  let v = Bigstring.to_string v in
  match classify k with
  | `Contents k ->
      incr contents;
      P.Contents.unsafe_add x k (contents_of_string v)
  | `Commit k ->
      let c = commit_of_string v in
      let c = Commit.export c in
      incr commits;
      P.Commit.unsafe_add z k c
  | `Node k ->
      P.Node.mem y k >>= function
      | true -> Lwt.return ()
      | false ->
          let n = node_of_string v in
          Lwt_list.iter_s (fun e ->
              P.Node.mem y Node.(e.node) >>= function
              | true -> Lwt.return ()
              | false ->
                  let k = key_of_entry e in
                  match Lmdb.get txn db k with
                  | Ok v    -> (append[@tailcall]) (db, txn) x y z k v
                  | Error e ->
                      Fmt.epr "\n[error] %S: %a\n%!" k Lmdb.pp_error e;
                      Lwt.return ()
            ) n
          >>= fun () ->
          let n = Node.export n in
          incr nodes;
          P.Node.unsafe_add y k n

let move ~src:(db, txn) ~dst:repo =
  let count = ref 0 in
  Lmdb.opencursor txn db >>* fun c ->
  Lmdb.cursor_first c >>* fun () ->
  P.Repo.batch repo (fun x y z ->
      Lmdb.cursor_fold_left c ~init:() ~f:(fun () (key, value) ->
          incr count;
          if !count mod 100 = 0 then Fmt.epr "\r%a%!" pp_stats ();
          Lwt.async (fun () ->
              append (db, txn) x y z (Bigstring.to_string key) value);
          Ok ()
        ) >>* fun () ->
      Lwt.return ()
    ) >|= fun () ->
  Fmt.epr "\n[done]\n"

let irmin root =
  Fmt.epr "Creating an Irmin repository in %s...\n%!" root;
  let config = Irmin_pack.config root in
  Store.Repo.v config

let run root =
  let lmdb = lmdb (Filename.concat root "context") in
  irmin (Filename.concat root "context-pack") >>= fun irmin ->
  move ~src:lmdb ~dst:irmin

let () =
  if Array.length Sys.argv <> 2 then Fmt.epr "usage: %s <data-dir>" Sys.argv.(0);
  let datadir = Sys.argv.(1) in
  Lwt_main.run (run datadir)
