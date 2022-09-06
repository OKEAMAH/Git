open Source
open Ast

module Unknown = Error.Make ()

exception Unknown = Unknown.Error (* indicates unknown import name *)

(* TODO: https://gitlab.com/tezos/tezos/-/issues/3587
   change this to probably use a better representation of module
   names, like hashes for example.
*)
module Registry = Map.Make (struct
  type t = Ast.name_list

  let compare = compare
end)

let registry = ref Registry.empty

let from_ast_name name = Action.of_lwt (Lazy_vector.Int32Vector.to_list name)

let register ~module_name lookup =
  let open Action.Syntax in
  let lookup name =
    Action.run (lookup (Lazy_vector.Int32Vector.of_list name))
  in
  let* name = from_ast_name module_name in
  registry := Registry.add name lookup !registry ;
  Action.return_unit

let lookup (im : import) : Instance.extern Action.t =
  let open Action.Syntax in
  let {module_name; item_name; _} = im.it in
  let* module_name_l = from_ast_name module_name in
  let* item_name_l = from_ast_name item_name in
  Action.catch
    (fun () ->
      Action.of_lwt (Registry.find module_name_l !registry item_name_l))
    (function
      | Not_found ->
          Unknown.error
            im.at
            ("unknown import \"" ^ string_of_name module_name ^ "\".\""
           ^ string_of_name item_name ^ "\"")
      | exn -> raise exn)

let link m =
  let open Action.Syntax in
  let* imports = Action.of_lwt (Lazy_vector.Int32Vector.to_list m.it.imports) in
  Action.List.map_s lookup imports
