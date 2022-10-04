module Config = Config
module Engine = Engine
module Store = Store
module Module = Module
module Ref = Ref
module Memory = Memory
module Exports = Exports
module Instance = Instance

type 'a typ = 'a Value_type.t

let i32 = Value_type.I32

let i64 = Value_type.I64

let f32 = Value_type.F32

let f64 = Value_type.F64

let anyref = Value_type.AnyRef

let funcref = Value_type.FuncRef

type 'a fn = 'a Function_type.t

let ( @-> ) param (Function_type.Function (params, results)) =
  Function_type.Function (Function_type.Cons_param (param, params), results)

let returning1 typ =
  Function_type.Function (Function_type.End_param, Function_type.One_result typ)

type 'a ret = 'a Function_type.results

let ( @** ) lhs rhs =
  Function_type.Cons_result (lhs, Function_type.One_result rhs)

let ( @* ) lhs results = Function_type.Cons_result (lhs, results)

let returning r = Function_type.Function (Function_type.End_param, r)

let void =
  Function_type.Function (Function_type.End_param, Function_type.No_result)

type extern = Extern.t

let fn typ f = Extern.Function (typ, f)
