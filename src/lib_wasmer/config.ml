open Utils
open Api

exception Failed_to_create

type compiler = Types.Wasmer.Compiler.t = CRANELIFT | LLVM | SINGLEPASS

let is_compiler_available = Functions.Wasmer.Compiler.is_available

exception Compiler_unavailable of compiler

type t = {compiler : compiler}

let default = {compiler = SINGLEPASS}

let to_owned desc =
  let conf = Functions.Config.new_ () in
  check_null_ptr Failed_to_create conf ;
  let has_compiler = is_compiler_available desc.compiler in
  if not has_compiler then raise (Compiler_unavailable desc.compiler) ;
  Functions.Config.set_compiler conf desc.compiler ;
  conf
