open Api

type t = Function : 'a Function_type.t * 'a -> t

let to_extern wasmer ext =
  match ext with
  | Function (typ, f) ->
      Function.create wasmer typ f |> Functions.Func.as_extern

let to_externkind = function Function _ -> Types.Externkind.func
