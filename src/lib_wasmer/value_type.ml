open Api

type _ t =
  | I32 : int32 t
  | I64 : int64 t
  | F32 : float t
  | F64 : float t
  | AnyRef : Ref.t t
  | FuncRef : Ref.t t

let to_valkind : type a. a t -> Types.Valkind.t = function
  | I32 -> Types.Valkind.i32
  | I64 -> Types.Valkind.i64
  | F32 -> Types.Valkind.f32
  | F64 -> Types.Valkind.f64
  | AnyRef -> Types.Valkind.anyref
  | FuncRef -> Types.Valkind.funcref

let to_valtype typ = Functions.Valtype.new_ (to_valkind typ)

exception Type_mismatch of {expected : Types.Valkind.t; got : Types.Valkind.t}

let () =
  Printexc.register_printer (function
      | Type_mismatch {expected; got} ->
          Some
            (Printf.sprintf
               "Type mismatch: %s <> %s"
               (Unsigned.UInt8.to_string expected)
               (Unsigned.UInt8.to_string got))
      | _ -> None)

let check : type a. a t -> Types.Valtype.t Ctypes.ptr -> unit =
 fun typ valtype ->
  let got = Functions.Valtype.kind valtype in
  let check_assertion expected =
    if not (Unsigned.UInt8.equal got expected) then
      raise (Type_mismatch {got; expected})
  in
  match typ with
  | I32 -> check_assertion Types.Valkind.i32
  | I64 -> check_assertion Types.Valkind.i64
  | F32 -> check_assertion Types.Valkind.f32
  | F64 -> check_assertion Types.Valkind.f64
  | AnyRef -> check_assertion Types.Valkind.anyref
  | FuncRef -> check_assertion Types.Valkind.funcref
