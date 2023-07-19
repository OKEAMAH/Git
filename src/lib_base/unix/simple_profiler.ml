open Profiler

let time () = {wall = Unix.gettimeofday (); cpu = Sys.time ()}

type state = {
  aggregate : (string * time * aggregate StringMap.t) list;
  toplevel : (string * time * (string * float * report) list) list;
  reports : (string * float * report) list;
  t0 : time;
}

let empty () = {aggregate = []; toplevel = []; reports = []; t0 = time ()}

let aggregate state id =
  {state with aggregate = (id, time (), StringMap.empty) :: state.aggregate}

let record state id =
  match state.aggregate with
  | _ :: _ -> aggregate state id
  | [] -> {state with toplevel = (id, time (), []) :: state.toplevel}

let pp_delta_t ppf t =
  let t = int_of_float (t *. 1000000.) in
  let mus = t mod 1000 and t = t / 1000 in
  let ms = t mod 1000 and t = t / 1000 in
  let s = t mod 60 and t = t / 60 in
  let m = t mod 60 and h = t / 60 in
  if h <> 0 then Format.fprintf ppf "%dh" h ;
  if m <> 0 || h <> 0 then Format.fprintf ppf "%dm" m ;
  if s <> 0 || m <> 0 || h <> 0 then Format.fprintf ppf "%ds" s ;
  Format.fprintf ppf "%d.%03dms" ms mus

let rec merge (Node (na, ta, acontents)) (Node (nb, tb, bcontents)) =
  Node
    ( na + nb,
      ta +* tb,
      StringMap.merge
        (fun _ na nb ->
          match (na, nb) with
          | None, None -> None
          | Some a, None -> Some a
          | None, Some b -> Some b
          | Some a, Some b -> Some (merge a b))
        acontents
        bcontents )

let rec stop state id =
  match state.aggregate with
  | (aid, _, _) :: _ when id <> aid ->
      (* auto close *)
      let state = stop state aid in
      stop state id
  | (_, t0, contents) :: (pid, pt0, pcontents) :: rest ->
      let node = Node (1, time () -* t0, contents) in
      let node =
        match StringMap.find_opt id pcontents with
        | None -> node
        | Some enode -> merge node enode
      in
      let aggregate = (pid, pt0, StringMap.add id node pcontents) :: rest in
      {state with aggregate}
  | [(_, t0, contents)] -> (
      match state.toplevel with
      | [] ->
          let reports =
            ( id,
              t0.wall -. state.t0.wall,
              Aggregate (Node (1, time () -* t0, contents)) )
            :: state.reports
          in
          {state with reports; aggregate = []}
      | (sid, st0, seq) :: rest ->
          let sub = Aggregate (Node (1, time () -* t0, contents)) in
          let toplevel =
            (sid, st0, (id, t0.wall -. st0.wall, sub) :: seq) :: rest
          in
          {state with toplevel; aggregate = []})
  | [] -> (
      match state.toplevel with
      | [] ->
          Stdlib.failwith
            ("Simple_intrusive_profiler.stop: trying to close section " ^ id
           ^ " that was never opened")
      | (aid, _, _) :: _ when id <> aid ->
          (* auto close *)
          let state = stop state aid in
          stop state id
      | (_, t0, seq) :: (pid, pt0, pseq) :: rest ->
          let sub = Seq (time () -* t0, List.rev seq) in
          let toplevel =
            (pid, pt0, (id, t0.wall -. pt0.wall, sub) :: pseq) :: rest
          in
          {state with toplevel}
      | [(_, t0, seq)] ->
          let reports =
            (id, t0.wall -. state.t0.wall, Seq (time () -* t0, List.rev seq))
            :: state.reports
          in
          {state with reports; toplevel = []})

let span state d ids =
  let rec build_node = function
    | [] -> ("???", Node (1, d, StringMap.empty))
    | [id] -> (id, Node (1, d, StringMap.empty))
    | id :: ids ->
        let cid, cnode = build_node ids in
        (id, Node (1, d, StringMap.add cid cnode StringMap.empty))
  in
  let id, node = build_node ids in
  match state.aggregate with
  | (pid, pt0, pcontents) :: rest ->
      let node =
        match StringMap.find_opt id pcontents with
        | None -> node
        | Some enode -> merge node enode
      in
      let aggregate = (pid, pt0, StringMap.add id node pcontents) :: rest in
      {state with aggregate}
  | [] -> (
      match state.toplevel with
      | [] ->
          let t0 = time () -* d in
          let reports = [(id, t0.wall -. state.t0.wall, Aggregate node)] in
          {state with reports}
      | (tid, t0, items) :: rest ->
          {
            state with
            toplevel =
              (tid, t0, (id, (time ()).wall -. d.wall, Aggregate node) :: items)
              :: rest;
          })

let mark state id = span state zero_time id

let pp_line nindent ppf id n t t0 =
  let indent = Stdlib.List.init nindent (fun _ -> "  ") in
  let indentsym =
    String.concat
      ""
      (indent
      @ [
          id;
          " ......................................................";
          "......................................................";
          "......................................................";
        ])
  in
  Format.fprintf ppf "%s %-7i " (String.sub indentsym 0 80) n ;
  if t.wall = 0. then Format.fprintf ppf "                 "
  else
    Format.fprintf
      ppf
      "% 10.3fms %3d%%"
      (t.wall *. 1000.)
      (int_of_float (ceil (100. *. (t.cpu /. t.wall)))) ;
  match t0 with
  | None -> Format.fprintf ppf "@,"
  | Some t0 -> Format.fprintf ppf " +%a@," pp_delta_t t0

let rec pp_seq nident ppf seq = List.iter (pp_report nident ppf) seq

and pp_aggregate nident ppf contents =
  StringMap.iter
    (fun id (Node (i, t, sub)) ->
      pp_line nident ppf id i t None ;
      pp_aggregate (nident + 1) ppf sub)
    contents

and pp_report nident ppf (id, t0, report) =
  match report with
  | Seq (t, seq) ->
      pp_line nident ppf id 1 t (Some t0) ;
      pp_seq (nident + 1) ppf seq
  | Aggregate (Node (i, t, contents)) ->
      pp_line nident ppf id i t (Some t0) ;
      pp_aggregate (nident + 1) ppf contents

let pp_report ppf report =
  Format.fprintf ppf "@[<v 0>%a@]%!" (pp_report 0) report

let make name =
  let ppf = lazy (Format.formatter_of_out_channel (open_out name)) in
  let state = ref (empty ()) in
  let maybe_pp nstate =
    if nstate.reports <> [] then (
      List.iter (pp_report (Lazy.force ppf)) nstate.reports ;
      state := {nstate with reports = []})
    else state := nstate
  in
  let module P : DRIVER = struct
    let time = time

    let aggregate id = state := aggregate !state id

    let record id = state := record !state id

    let mark id = state := mark !state id

    let span d id = state := span !state d id

    let stop id = maybe_pp (stop !state id)

    let report () =
      match !state.reports with
      | [] -> None
      | report :: reports ->
          state := {!state with reports} ;
          Some report
  end in
  (module P : DRIVER)
