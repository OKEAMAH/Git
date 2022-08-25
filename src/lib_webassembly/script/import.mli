exception Unknown of Source.region * string

val link : Ast.module_ -> Instance.extern list Action.t (* raises Unknown *)

val register :
  module_name:Ast.name ->
  (Ast.name -> Instance.extern Action.t (* raises Not_found *)) ->
  unit Action.t
