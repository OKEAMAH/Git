open Api

exception Kind_mismatch of {expected : Types.Valkind.t; got : Types.Valkind.t}

let check_kind value expected =
  let got = Ctypes.getf value Types.Val_repr.kind in
  if expected <> got then raise (Kind_mismatch {expected; got})

let unpack_value value field =
  let of_ = Ctypes.getf value Types.Val_repr.of_ in
  Ctypes.getf of_ field

let unpack : type a. a Value_type.t -> Types.Val.t -> a =
 fun typ value ->
  match typ with
  | I32 ->
      check_kind value Types.Valkind.i32 ;
      unpack_value value Types.Val_repr.Of.i32
  | I64 ->
      check_kind value Types.Valkind.i64 ;
      unpack_value value Types.Val_repr.Of.i64
  | F32 ->
      check_kind value Types.Valkind.f32 ;
      unpack_value value Types.Val_repr.Of.f32
  | F64 ->
      check_kind value Types.Valkind.f64 ;
      unpack_value value Types.Val_repr.Of.f64
  | AnyRef ->
      check_kind value Types.Valkind.anyref ;
      Ref (unpack_value value Types.Val_repr.Of.ref)
  | FuncRef ->
      check_kind value Types.Valkind.funcref ;
      Ref (unpack_value value Types.Val_repr.Of.ref)

let pack_value kind field value =
  let repr = Ctypes.make Types.Val_repr.t in
  let of_ =
    let of_ = Ctypes.make Types.Val_repr.Of.t in
    Ctypes.setf of_ field value ;
    of_
  in
  Ctypes.setf repr Types.Val_repr.kind kind ;
  Ctypes.setf repr Types.Val_repr.of_ of_ ;
  repr

let pack : type a. a Value_type.t -> a -> Types.Val.t =
 fun typ value ->
  match typ with
  | I32 -> pack_value Types.Valkind.i32 Types.Val_repr.Of.i32 value
  | I64 -> pack_value Types.Valkind.i64 Types.Val_repr.Of.i64 value
  | F32 -> pack_value Types.Valkind.f32 Types.Val_repr.Of.f32 value
  | F64 -> pack_value Types.Valkind.f64 Types.Val_repr.Of.f64 value
  | AnyRef ->
      let (Ref ref) = value in
      pack_value Types.Valkind.anyref Types.Val_repr.Of.ref ref
  | FuncRef ->
      let (Ref ref) = value in
      pack_value Types.Valkind.funcref Types.Val_repr.Of.ref ref
