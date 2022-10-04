open Api

module Make_vector (Vector_type : sig
  type s

  type t = s Ctypes.structure

  val t : t Ctypes.typ

  module Item : sig
    type t

    val t : t Ctypes.typ
  end

  val size : (Unsigned.size_t, t) Ctypes.field

  val data : (Item.t Ctypes.ptr, t) Ctypes.field
end) (Vector_funs : sig
  val new_ :
    Vector_type.t Ctypes.ptr ->
    Unsigned.Size_t.t ->
    Vector_type.Item.t Ctypes.ptr ->
    unit

  val new_uninitialized : Vector_type.t Ctypes.ptr -> Unsigned.Size_t.t -> unit

  val new_empty : Vector_type.t Ctypes.ptr -> unit
end) =
struct
  type item = Vector_type.Item.t

  type t = Vector_type.t

  let init_empty vec = Vector_funs.new_empty vec

  let empty () =
    let vec = Ctypes.make Vector_type.t in
    init_empty (Ctypes.addr vec) ;
    vec

  let uninitialized len =
    if Unsigned.Size_t.(compare len zero > 0) then (
      let vec = Ctypes.make Vector_type.t in
      Vector_funs.new_uninitialized (Ctypes.addr vec) len ;
      vec)
    else empty ()

  let init_from_list vec items =
    let len = List.length items in
    let buffer = Ctypes.CArray.of_list Vector_type.Item.t items in
    Vector_funs.new_
      vec
      (Unsigned.Size_t.of_int len)
      (Ctypes.CArray.start buffer)

  let init_from_array vec items =
    let count = Array.length items in
    let buffer = Ctypes.allocate_n ~count Vector_type.Item.t in
    Array.iteri
      Ctypes.(
        fun i item ->
          let ptr = buffer +@ i in
          ptr <-@ item)
      items ;
    Vector_funs.new_ vec (Unsigned.Size_t.of_int count) buffer

  let init_uninitialized vec len = Vector_funs.new_uninitialized vec len

  let from_list items =
    let vec = Ctypes.make Vector_type.t in
    init_from_list (Ctypes.addr vec) items ;
    vec

  let from_array items =
    let vec = Ctypes.make Vector_type.t in
    init_from_array (Ctypes.addr vec) items ;
    vec

  let length vec = Ctypes.getf vec Vector_type.size

  let to_list vec =
    let data = Ctypes.getf vec Vector_type.data in
    List.init
      (length vec |> Unsigned.Size_t.to_int)
      Ctypes.(
        fun i ->
          let ptr = data +@ i in
          !@ptr)

  let to_array vec =
    let data = Ctypes.getf vec Vector_type.data in
    Array.init
      (length vec |> Unsigned.Size_t.to_int)
      Ctypes.(
        fun i ->
          let ptr = data +@ i in
          !@ptr)

  let set vec i value =
    let data = Ctypes.getf vec Vector_type.data in
    Ctypes.(data +@ i <-@ value)

  let get vec i =
    let data = Ctypes.getf vec Vector_type.data in
    Ctypes.(!@(data +@ i))
end

module Value_type_vector =
  Make_vector (Types.Valtype_vec) (Functions.Valtype_vec)
module Value_vector = Make_vector (Types.Val_vec) (Functions.Val_vec)
module Extern_vector = Make_vector (Types.Extern_vec) (Functions.Extern_vec)
module Export_type_vector =
  Make_vector (Types.Exporttype_vec) (Functions.Exporttype_vec)
module Import_type_vector =
  Make_vector (Types.Importtype_vec) (Functions.Importtype_vec)

module Byte_vector = struct
  let from_string str =
    let byte_vec = Ctypes.make Types.Byte_vec.t in
    Functions.Byte_vec.new_
      (Ctypes.addr byte_vec)
      (String.length str |> Unsigned.Size_t.of_int)
      str ;
    byte_vec

  let empty () =
    let byte_vec = Ctypes.make Types.Byte_vec.t in
    Functions.Byte_vec.new_empty (Ctypes.addr byte_vec) ;
    byte_vec

  let delete vec = Functions.Byte_vec.delete (Ctypes.addr vec)

  let to_string vec =
    let length = Unsigned.Size_t.to_int (Ctypes.getf vec Types.Byte_vec.size) in
    let data = Ctypes.getf vec Types.Byte_vec.data in
    Ctypes.string_from_ptr Ctypes.(coerce (ptr uint8_t) (ptr char) data) ~length
end

module Name = Byte_vector
module Message = Name
