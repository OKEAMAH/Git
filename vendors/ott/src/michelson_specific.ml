(**************************************************************************)
(*                                 Ott                                    *)
(*                    Michelson-specific operations                       *)
(*                                                                        *)
(*                       Basile Pesin, Nomadic Labs                       *)
(**************************************************************************)

open Types

(** Retrieve all instruction names from the grammar definition
    (productions that begins with i_ and have the following character fully uppercase) *)
let rec get_all_instruction xd = function
  | [] -> []
  | s::q -> (match s with
      | Struct_rs ntrs ->
          let rs = List.map (fun ntr -> Auxl.rule_of_ntr xd ntr) ntrs in
          (List.map (fun s ->
               {s with prod_name = String.sub s.prod_name 2 (String.length s.prod_name - 2)})
              (List.filter (fun p ->
                   let s = p.prod_name in
                   try (String.sub s 0 2) = "i_" &&
                       (String.sub s 2 (String.length s - 2) =
                        (String.uppercase_ascii (String.sub s 2 (String.length s - 2))))
                   with _ -> false)
                  (List.flatten (List.map (fun r -> r.rule_ps) rs))))
          @(get_all_instruction xd q)
      | _ -> get_all_instruction xd q)

(** Retrieve all relations (that begins with t_) *)
let rec get_all_relations = function
  | [] -> []
  | s::q -> (match s with
      | RDC dc ->
        let semiraw_rules = List.flatten (List.map (fun def -> def.d_rules) dc.dc_defns) in
        let drules = List.fold_left (fun a r -> match r with PSR_Rule d -> d::a | PSR_Defncom _ -> a) [] semiraw_rules in
        drules@(get_all_relations q)
      | _ -> get_all_relations q)

(** Retrieve all typing rules (that begins with t_) *)
let get_all_typingrules rels =
  List.filter (fun d -> (String.sub d.drule_name 0 2) = "t_") (get_all_relations rels)

(** Retrieve all bigstep rules (that begins with bs_) *)
let get_all_bigsteprules rels =
  List.filter (fun d -> (String.sub d.drule_name 0 3) = "bs_") (get_all_relations rels)

(** Filter rules according to their names *)
let filter_rules prefix name rules =
  List.filter (fun r ->
	  try ignore (Str.search_forward (Str.regexp (prefix^"_"^name^"\\(__.*\\)?$")) r.drule_name 0); true
      with _ -> false) rules
