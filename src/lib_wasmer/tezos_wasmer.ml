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
  Function_type.(Function (Cons_param (param, params), results))

type 'a ret = 'a Function_type.results

let ret1 x = Function_type.One_result x

let returning1 typ = Function_type.(Function (End_param, ret1 typ))

let ( @** ) lhs rhs = Function_type.Cons_result (lhs, ret1 rhs)

let ( @* ) lhs results = Function_type.Cons_result (lhs, results)

let returning r = Function_type.(Function (End_param, r))

let producer results =
  Function_type.(Function (Trigger_param End_param, results))

let nothing = Function_type.No_result

type extern = Extern.t

let fn typ f = Extern.Function (typ, f)
