module Scalar = struct
  include Bls12_381.Fr

  type scalar = t

  let mone = negate one

  let string_of_scalar x =
    if eq x (of_string "-1") then "-1"
    else if eq x (of_string "-2") then "-2"
    else
      let s = to_string x in
      if String.length s > 3 then "h" ^ string_of_int (Z.hash (to_z x)) else s

  let equal a b = Bytes.equal (to_bytes a) (to_bytes b)
end

module Gates = Custom_gate.Custom_gate_impl (Polynomial_protocol)

let module_list =
  [
    (module Gates.Constant_gate : Gates.Gate_base_sig);
    (* (module Gates.Public_gate); *)
    (module Gates.AddLeft_gate);
    (module Gates.AddRight_gate);
    (module Gates.AddOutput_gate);
    (module Gates.AddNextLeft_gate);
    (module Gates.AddNextRight_gate);
    (module Gates.AddNextOutput_gate);
    (module Gates.Multiplication_gate);
    (module Gates.X5_gate);
    (module Gates.AddWeierstrass_gate);
    (module Gates.AddEdwards_gate);
  ]

let to_eqs m =
  let module M = (val m : Gates.Gate_base_sig) in
  M.equations

let to_ids m =
  let module M = (val m : Gates.Gate_base_sig) in
  M.identity

let module_map =
  let to_q_label m =
    let module M = (val m : Gates.Gate_base_sig) in
    M.q_label
  in
  List.map (fun m -> (to_q_label m, m)) module_list |> SMap.of_list

let q_list ?q_table ~qc ~ql ~qr ~qo ~qlg ~qrg ~qog ~qm ~qx5 ~qecc_ws_add
    ~qecc_ed_add ~q_plookup () =
  let base =
    [
      ("qc", qc);
      ("ql", ql);
      ("qr", qr);
      ("qo", qo);
      ("qlg", qlg);
      ("qrg", qrg);
      ("qog", qog);
      ("qm", qm);
      ("qx5", qx5);
      ("qecc_ws_add", qecc_ws_add);
      ("qecc_ed_add", qecc_ed_add);
      ("q_plookup", q_plookup);
    ]
  in
  Option.(map (fun q -> ("q_table", q)) q_table |> to_list) @ base

let gates_equal = SMap.equal (List.equal Scalar.equal)

type selector_tag = Linear | ThisConstr | NextConstr | WireA | WireB | WireC

let all_selectors =
  q_list
    ~qc:[ThisConstr]
    ~ql:[ThisConstr; Linear; WireA]
    ~qr:[ThisConstr; Linear; WireB]
    ~qo:[ThisConstr; Linear; WireC]
    ~qlg:[NextConstr; Linear; WireA]
    ~qrg:[NextConstr; Linear; WireB]
    ~qog:[NextConstr; Linear; WireC]
    ~qm:[ThisConstr; WireA; WireB]
    ~qx5:[ThisConstr; WireA]
    ~qecc_ws_add:[ThisConstr; NextConstr; WireA; WireB; WireC]
    ~qecc_ed_add:[ThisConstr; NextConstr; WireA; WireB; WireC]
    ~q_plookup:[ThisConstr; WireA; WireB; WireC]
    ~q_table:[ThisConstr; WireA; WireB; WireC]
    ()

(* We assert here that all modules/selectors have been used.
  The "+2" is to take into account lookup selectors which are not defined in
  plonk/gates/custom_gates.ml *)
let () = assert (List.length all_selectors = SMap.cardinal module_map + 2)

let selectors_with_tags tags =
  List.filter
    (fun (_, sel_tags) -> List.for_all (fun t -> List.mem t sel_tags) tags)
    all_selectors
  |> List.map fst

let this_constr_selectors = selectors_with_tags [ThisConstr]

let next_constr_selectors = selectors_with_tags [NextConstr]

let this_constr_linear_selectors = selectors_with_tags [ThisConstr; Linear]

let next_constr_linear_selectors = selectors_with_tags [NextConstr; Linear]

let gates_to_string m =
  SMap.fold
    (fun k v s ->
      s ^ k ^ " " ^ String.concat "," (List.map Scalar.to_string v) ^ "\n")
    m
    ""

(* If multiple tables are used, they all need to have the same number of wires,
   so any smaller one will be padded. *)
module Table : sig
  type t

  val empty : t

  val size : t -> int

  type entry = {a : Scalar.t; b : Scalar.t; c : Scalar.t}

  type partial_entry = {
    a : Scalar.t option;
    b : Scalar.t option;
    c : Scalar.t option;
  }

  val mem : entry -> t -> bool

  val find : partial_entry -> t -> entry option

  val to_list : t -> Scalar.t array list

  val of_list : Scalar.t array list -> t
end = struct
  (* Rows are variables, columns are entries in the table.
     If the table is full it would be |domain|^#variables e.g. 2^3=8
     Example OR gate:
     [
       [|0; 0; 1; 1|] ;
       [|0; 1; 0; 1|] ;
       [|0; 1; 1; 1|] ;
     ]
  *)

  type entry = {a : Scalar.t; b : Scalar.t; c : Scalar.t}

  type partial_entry = {
    a : Scalar.t option;
    b : Scalar.t option;
    c : Scalar.t option;
  }

  type t = Scalar.t array array

  let empty = [||]

  let size table = Array.length table.(0)

  (* Function returning the first table corresponding to the input partial entry.
     A partial entry is found on the table at row i if it coincides
     with the table values in all specified (i.e., not None) columns *)
  let find_entry_i : partial_entry -> t -> int -> entry option =
   fun pe table i ->
    let match_partial_entry o s =
      Option.(value ~default:true @@ map (Scalar.eq s) o)
    in
    if
      match_partial_entry pe.a table.(0).(i)
      && match_partial_entry pe.b table.(1).(i)
      && match_partial_entry pe.c table.(2).(i)
    then Some {a = table.(0).(i); b = table.(1).(i); c = table.(2).(i)}
    else None

  let find pe table =
    (* TODO make it a binary search *)
    let sz = size table in
    let rec aux i =
      match i with
      | 0 -> find_entry_i pe table 0
      | _ ->
          let o = find_entry_i pe table i in
          if Option.is_some o then o else aux (i - 1)
    in
    aux (sz - 1)

  let mem : entry -> t -> bool =
   fun e table ->
    match find {a = Some e.a; b = Some e.b; c = Some e.c} table with
    | Some _ -> true
    | None -> false

  let to_list table =
    Format.printf "\n%i %i\n" (Array.length table) (Array.length table.(0)) ;
    Array.to_list table

  let of_list table = Array.of_list table
end

let table_or =
  Table.of_list
    Scalar.
      [
        [|zero; zero; one; one|];
        [|zero; one; zero; one|];
        [|zero; one; one; one|];
      ]

module Tables = Map.Make (String)

let table_registry = Tables.add "or" table_or Tables.empty

module Circuit : sig
  type t = private {
    wires : int list SMap.t;
    gates : Scalar.t list SMap.t;
    tables : Scalar.t array list list;
    public_input_size : int;
    circuit_size : int;
    nb_wires : int;
    table_size : int;
    nb_lookups : int;
    ultra : bool;
  }

  val make_wires :
    a:int list ->
    b:int list ->
    c:int list ->
    ?d:int list ->
    ?e:int list ->
    ?f:int list ->
    ?g:int list ->
    ?h:int list ->
    unit ->
    int list SMap.t

  val make_gates :
    ?qc:Scalar.t list ->
    ?ql:Scalar.t list ->
    ?qr:Scalar.t list ->
    ?qo:Scalar.t list ->
    ?qlg:Scalar.t list ->
    ?qrg:Scalar.t list ->
    ?qog:Scalar.t list ->
    ?qm:Scalar.t list ->
    ?qx5:Scalar.t list ->
    ?qecc_ws_add:Scalar.t list ->
    ?qecc_ed_add:Scalar.t list ->
    ?q_plookup:Scalar.t list ->
    ?q_table:Scalar.t list ->
    unit ->
    Scalar.t list SMap.t

  val make :
    wires:int list SMap.t ->
    gates:Scalar.t list SMap.t ->
    ?tables:Scalar.t array list list ->
    public_input_size:int ->
    unit ->
    t

  val get_nb_of_constraints : t -> int

  (* /////////////////////////////////////////////////////////////////////// *)

  type raw_constraint = {
    a : int;
    b : int;
    c : int;
    sels : (string * Scalar.t) list;
    label : string;
  }

  val new_constraint :
    a:int ->
    b:int ->
    c:int ->
    ?qc:Scalar.t ->
    ?ql:Scalar.t ->
    ?qr:Scalar.t ->
    ?qo:Scalar.t ->
    ?qlg:Scalar.t ->
    ?qrg:Scalar.t ->
    ?qog:Scalar.t ->
    ?qm:Scalar.t ->
    ?qx5:Scalar.t ->
    ?qecc_ws_add:Scalar.t ->
    ?qecc_ed_add:Scalar.t ->
    ?q_plookup:Scalar.t ->
    ?q_table:Scalar.t ->
    string ->
    raw_constraint

  type gate = raw_constraint Array.t

  type cs = gate list

  val sat : cs -> Table.t list -> Scalar.t array -> bool

  val get_sel : (string * Scalar.t) list -> string -> Scalar.t

  val to_string : cs -> string

  val to_plonk : public_input_size:int -> ?tables:Table.t list -> cs -> t

  val raw_constraint_equal : raw_constraint -> raw_constraint -> bool

  val cs_encoding : cs Data_encoding.encoding

  val cs_pub_size_encoding : (cs * int) Data_encoding.encoding

  val scalar_encoding : Scalar.t Data_encoding.encoding

  val is_linear_raw_constr : raw_constraint -> bool

  (** It returns the value of the 3 wires (a, b, c) of the i-th raw constraint
      in a gate. The value is set to -1 for wires not used by any selector. *)
  val wires_of_constr_i : gate -> int -> int list

  val gate_wires : gate -> int list

  val linear_terms : raw_constraint -> (Scalar.t * int) list

  val mk_linear_constr : int list * (string * Scalar.t) list -> raw_constraint
end = struct
  type t = {
    wires : int list SMap.t;
    gates : Scalar.t list SMap.t;
    tables : Scalar.t array list list;
    public_input_size : int;
    circuit_size : int;
    nb_wires : int;
    table_size : int;
    nb_lookups : int;
    ultra : bool;
  }

  let make_wires ~a ~b ~c ?(d = []) ?(e = []) ?(f = []) ?(g = []) ?(h = []) () =
    (* Filtering and mapping selectors with labels. *)
    let wire_map = SMap.of_list [("a", a); ("b", b); ("c", c)] in
    let add_map map (label, l) = if l = [] then map else SMap.add label l map in
    List.fold_left
      add_map
      wire_map
      [("d", d); ("e", e); ("f", f); ("g", g); ("h", h)]

  let make_gates ?(qc = []) ?(ql = []) ?(qr = []) ?(qo = []) ?(qlg = [])
      ?(qrg = []) ?(qog = []) ?(qm = []) ?(qx5 = []) ?(qecc_ws_add = [])
      ?(qecc_ed_add = []) ?(q_plookup = []) ?(q_table = []) () =
    (* Filtering and mapping selectors with labels. *)
    let gate_list =
      q_list
        ~qc
        ~ql
        ~qr
        ~qo
        ~qlg
        ~qrg
        ~qog
        ~qm
        ~qx5
        ~qecc_ws_add
        ~qecc_ed_add
        ~q_plookup
        ()
    in

    let add_map map (label, q) =
      match q with
      | [] -> map
      | l -> if List.for_all Scalar.is_zero l then map else SMap.add label q map
    in
    let base =
      if q_table = [] then SMap.empty else SMap.singleton "q_table" q_table
    in
    List.fold_left add_map base gate_list

  let verify_name name i =
    assert (i < 26) ;
    let alphabet = "abcdefghijklmnopqrstuvwxyz" in
    let letter_i = alphabet.[i] in
    let msg =
      Printf.sprintf
        "%d-th wire must be named '%c' (current name is '%s')."
        i
        letter_i
        name
    in
    if String.length name <> 1 then raise (Invalid_argument msg)
    else if Char.equal name.[0] letter_i then ()
    else raise (Invalid_argument msg)

  (* For efficiency reason this function does not check for all-zero selectors,
     it's responsability of the caller to filter them out.
     If public_input_size is greater than 0, selector ql will be added if not
     already present.
     Wires and gates cannot be empty and must all have the same length.
  *)
  let make ~wires ~gates ?(tables = []) ~public_input_size () =
    if SMap.is_empty wires then
      raise @@ Invalid_argument "Make Circuit: empty wires." ;
    if SMap.is_empty gates then
      raise @@ Invalid_argument "Make Circuit: empty gates." ;
    let circuit_size = List.length (snd (SMap.choose wires)) in
    if Int.equal circuit_size 0 then
      raise (Invalid_argument "Make Circuit: empty circuit.") ;

    (* Check that all wires have same size, and each wire i is named
       as the i-th alphabet’s letter. *)
    let nb_wires = SMap.cardinal wires in
    let () =
      List.iteri
        (fun i (name, l) ->
          verify_name name i ;
          if List.compare_length_with l circuit_size = 0 then ()
          else raise (Invalid_argument "Make Circuit: different length wires."))
        (SMap.bindings wires)
    in
    (* Check that all selectors have the same size, and that they are available. *)
    let () =
      SMap.iter
        (fun label q ->
          if List.compare_length_with q circuit_size = 0 then ()
          else raise (Invalid_argument "Make Circuit: different length gates.") ;
          if List.mem label (List.map fst all_selectors) then ()
          else raise (Invalid_argument "Make Circuit: unknown gates."))
        gates
    in
    (* Check all tables' columns have the same size. *)
    let () =
      List.iter
        (fun l ->
          let sub_table_size = Array.length (List.hd l) in
          if List.length l > nb_wires then
            raise
              (Invalid_argument "Make Circuit: table(s) with too many columns.") ;
          List.iter
            (fun t ->
              if Array.length t != sub_table_size then
                raise
                  (Invalid_argument
                     "Make Circuit: table(s) with columns of different length.")
              else ())
            l)
        tables
    in
    let table_size =
      if tables = [] then 0
      else List.fold_left (fun acc t -> acc + Array.length (List.hd t)) 0 tables
    in
    (* Determining if UltraPlonk or TurboPlonk needs to be used. *)
    let ultra = SMap.mem "q_plookup" gates in
    let nb_lookups =
      if not ultra then 0
      else
        let q_plookup = SMap.find "q_plookup" gates in
        List.fold_left
          (fun acc qi -> if Scalar.is_zero qi then acc else acc + 1)
          0
          q_plookup
    in
    if ultra && not (SMap.mem "q_table" gates) then
      raise (Invalid_argument "Make Circuit: expected table selector.") ;
    if ultra && tables = [] then
      raise (Invalid_argument "Make Circuit: tables empty.") ;
    if (not ultra) && (tables != [] || SMap.mem "q_table" gates) then
      raise (Invalid_argument "Make Circuit: table(s) given with no lookups.") ;
    {
      circuit_size;
      wires;
      gates;
      tables;
      public_input_size;
      nb_wires;
      table_size;
      nb_lookups;
      ultra;
    }

  let get_nb_of_constraints cs = List.length (snd (SMap.choose cs.wires))
  (* ////////////////////////////////////////////////////////// *)

  type raw_constraint = {
    a : int;
    b : int;
    c : int;
    sels : (string * Scalar.t) list;
    label : string;
  }

  type gate = raw_constraint array

  type cs = gate list

  let new_constraint ~a ~b ~c ?qc ?ql ?qr ?qo ?qlg ?qrg ?qog ?qm ?qx5
      ?qecc_ws_add ?qecc_ed_add ?q_plookup ?q_table label =
    let sels =
      List.filter_map
        (fun (l, x) -> Option.bind x (fun c -> Some (l, c)))
        (q_list
           ~qc
           ~ql
           ~qr
           ~qo
           ~qlg
           ~qrg
           ~qog
           ~qm
           ~qx5
           ~qecc_ws_add
           ~qecc_ed_add
           ~q_plookup
           ~q_table
           ())
    in

    {a; b; c; sels; label}

  let get_sel sels s =
    match List.find_opt (fun (x, _) -> s = x) sels with
    | None -> Scalar.zero
    | Some (_, c) -> c

  let to_string_raw_constraint {a; b; c; label; sels} : string =
    let selectors =
      String.concat
        " "
        (List.map (fun (s, c) -> s ^ ":" ^ Scalar.string_of_scalar c) sels)
    in
    Format.sprintf "a:%i b:%i c:%i %s %s" a b c selectors label

  let to_string_gate g =
    String.concat "\n" @@ Array.to_list @@ Array.map to_string_raw_constraint g

  let to_string cs =
    List.fold_left (fun acc con -> acc ^ to_string_gate con ^ "\n") "" cs

  let sat_gate identities gate trace tables =
    let nb_cs = Array.length gate in
    let fold_list = List.init nb_cs (fun i -> i) in
    let identities =
      (* For each constraint *)
      List.fold_left
        (fun id_map i ->
          (* Retrieving its values as well as the next constraint's values *)
          let j = (i + 1) mod nb_cs in
          let (ci, cj) = (gate.(i), gate.(j)) in
          let (a, b, c) = (trace.(ci.a), trace.(ci.b), trace.(ci.c)) in
          let (ag, bg, cg) = (trace.(cj.a), trace.(cj.b), trace.(cj.c)) in
          (* Folding on selectors *)
          List.fold_left
            (fun id_map (s_name, q) ->
              match s_name with
              | x when x = "q_plookup" -> id_map
              | x when x = "q_table" ->
                  (* We assume there can be only one lookup per gate *)
                  let entry : Table.entry = Table.{a; b; c} in
                  let sub_table = List.nth tables (Scalar.to_z q |> Z.to_int) in
                  let b = Table.mem entry sub_table in
                  let id = [|(if b then Scalar.zero else Scalar.one)|] in
                  SMap.update "q_table" (fun _ -> Some id) id_map
              | _ ->
                  (* Retrieving the selector's identity name and equations *)
                  let m = SMap.find s_name module_map in
                  let (s_id_name, _) = to_ids m in
                  let s_ids = SMap.find s_id_name id_map in
                  (* Updating the identities with the equations' output *)
                  List.iteri
                    (fun i s -> s_ids.(i) <- Scalar.(s_ids.(i) + s))
                    ((to_eqs m) ~q ~a ~b ~c ~ag ~bg ~cg ()) ;
                  SMap.update s_id_name (fun _ -> Some s_ids) id_map)
            id_map
            ci.sels)
        identities
        fold_list
    in
    (* Checking all identities are verified, i.e. the map contains only 0s *)
    SMap.for_all
      (fun _id_name id ->
        let b = Array.for_all Scalar.is_zero id in
        (* if Bool.not b then Printf.printf "\nIdentity '%s' not satisfied" id_name
           else () ; *)
        b)
      identities

  let sat cs tables trace =
    let identities =
      List.fold_left
        (fun map m ->
          let (id, nb_ids) = to_ids m in
          if SMap.mem id map then map
          else SMap.add id (Array.init nb_ids (fun _ -> Scalar.zero)) map)
        (SMap.singleton "q_table" [|Scalar.zero|])
        module_list
    in
    let exception Constraint_not_satisfied of string in
    try
      List.iteri
        (fun i gate ->
          (* Printf.printf "\n\nGate %i: %s" i (to_string_gate gate); *)
          let b = sat_gate identities gate trace tables in
          if b then ()
          else
            (* just to exit the iter *)
            raise
              (Constraint_not_satisfied
                 (Printf.sprintf "\nGate #%i not satisfied." i)))
        cs ;
      true
    with Constraint_not_satisfied _ -> false

  let to_plonk ~public_input_size ?(tables = []) cs =
    let cs = List.rev Array.(to_list @@ concat cs) in
    assert (cs <> []) ;
    let add_wires a b c wires =
      let aa = SMap.find "a" wires in
      let bb = SMap.find "b" wires in
      let cc = SMap.find "c" wires in
      let wires = SMap.add "a" (a :: aa) wires in
      let wires = SMap.add "b" (b :: bb) wires in
      let wires = SMap.add "c" (c :: cc) wires in
      wires
    in
    let add_selectors sels map pad =
      (* Add to the map all new selectors with the coresponding padding
         (array of [pad] zeroes). *)
      let map =
        List.fold_left
          (fun map (k, _) ->
            if SMap.mem k map then map
            else
              let zeros = List.init pad (fun _ -> Scalar.zero) in
              SMap.add k zeros map)
          map
          sels
      in

      (* Extend every binding in the map by either add the coefficient
         or pad with a zero. *)
      SMap.fold
        (fun label qq map ->
          let q =
            match List.find_opt (fun (s, _) -> s = label) sels with
            | None -> Scalar.zero
            | Some (_, coeff) -> coeff
          in
          SMap.add label (q :: qq) map)
        map
        map
    in

    let wires_map = SMap.of_list [("a", []); ("b", []); ("c", [])] in
    let selectors_map = SMap.empty in

    List.fold_left
      (fun (wires_map, selectors_map, pad) {a; b; c; sels; _} ->
        let wires_map = add_wires a b c wires_map in
        let selectors_map = add_selectors sels selectors_map pad in
        (wires_map, selectors_map, pad + 1))
      (wires_map, selectors_map, 0)
      cs
    |> fun (wires, selectors, _) ->
    let tables = List.map Table.to_list tables in
    make ~wires ~gates:selectors ~public_input_size ~tables ()

  let raw_constraint_equal c1 c2 =
    c1.a = c2.a && c1.b = c2.b && c1.c = c2.c && c1.label = c2.label
    && List.for_all2
         (fun (name, coeff) (name', coeff') ->
           name = name' && Scalar.eq coeff coeff')
         c1.sels
         c2.sels

  let pretty_z_of_scalar s =
    let z = Scalar.to_z s in
    let mz = Scalar.to_z (Scalar.negate s) in
    if Z.compare mz z < 0 then Z.neg mz else z

  let scalar_encoding : Scalar.t Data_encoding.t =
    Data_encoding.(conv pretty_z_of_scalar Scalar.of_z z)

  let selectors_encoding = Data_encoding.(list (tup2 string scalar_encoding))

  let raw_constraint_encoding : raw_constraint Data_encoding.t =
    Data_encoding.(
      conv
        (fun {a; b; c; sels; label} -> (a, b, c, sels, label))
        (fun (a, b, c, sels, label) -> {a; b; c; sels; label})
        (obj5
           (req "a" int31)
           (req "b" int31)
           (req "c" int31)
           (req "sels" selectors_encoding)
           (req "label" string)))

  let gate_encoding = Data_encoding.array raw_constraint_encoding

  let cs_encoding = Data_encoding.list gate_encoding

  let cs_pub_size_encoding = Data_encoding.(tup2 cs_encoding int31)

  let is_linear_raw_constr constr =
    let linear_selectors =
      "qc" :: this_constr_linear_selectors @ next_constr_linear_selectors
    in
    let is_linear_sel (s, _q) = List.mem s linear_selectors in
    List.for_all is_linear_sel constr.sels

  let used_selectors gate i =
    let this_sels = gate.(i).sels in
    let prev_sels = if i = 0 then [] else gate.(i - 1).sels in
    List.filter (fun (s, _) -> List.mem s this_constr_selectors) this_sels
    @ List.filter (fun (s, _) -> List.mem s next_constr_selectors) prev_sels

  let wires_of_constr_i gate i =
    let a_selectors = selectors_with_tags [WireA] in
    let b_selectors = selectors_with_tags [WireB] in
    let c_selectors = selectors_with_tags [WireC] in
    let intersect names = List.exists (fun (s, _q) -> List.mem s names) in
    let sels = used_selectors gate i in
    List.map2
      (fun wsels w -> if intersect wsels sels then w else -1)
      [a_selectors; b_selectors; c_selectors]
      [gate.(i).a; gate.(i).b; gate.(i).c]

  let gate_wires gate =
    List.init (Array.length gate) (wires_of_constr_i gate)
    |> List.concat |> List.sort_uniq Int.compare
    |> List.filter (fun x -> x >= 0)

  (* the relationship of this function wrt is_linear_raw_constr is a bit weird *)
  let linear_terms constr =
    if not @@ is_linear_raw_constr constr then
      raise @@ Invalid_argument "constraint is non-linear"
    else
      List.map
        (fun (sel_name, coeff) ->
          match sel_name with
          | "qc" -> (coeff, -1)
          | "ql" -> (coeff, constr.a)
          | "qr" -> (coeff, constr.b)
          | "qo" -> (coeff, constr.c)
          | _ -> assert false)
        constr.sels
      |> List.filter (fun (q, _) -> not @@ Scalar.is_zero q)

  let mk_linear_constr (wires, sels) =
    match wires with
    | [a; b; c] -> {a; b; c; sels; label = "linear"}
    | _ -> assert false
end

include Circuit
