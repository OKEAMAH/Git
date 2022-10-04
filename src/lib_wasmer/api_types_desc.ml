module Types (S : Ctypes.TYPE) = struct
  open S

  module Declare_own (Desc : sig
    val name : string
  end) =
  struct
    include Desc

    type s

    type t = s Ctypes.structure

    let t : t typ =
      let name = "wasm_" ^ Desc.name ^ "_t" in
      typedef (structure name) name
  end

  module Declare_vec (Item : sig
    val name : string

    type t

    val t : t typ
  end) =
  struct
    type s

    type t = s Ctypes.structure

    let t : t typ =
      let name = "wasm_" ^ Item.name ^ "_vec_t" in
      typedef (structure name) name

    let size = field t "size" size_t

    let data = field t "data" (ptr Item.t)

    let () = seal t

    module Item = Item
  end

  module Ptr (Item : sig
    val name : string

    type t

    val t : t typ
  end) =
  struct
    include Item

    type t = Item.t Ctypes.ptr

    let t = ptr Item.t
  end

  module Wasmer = struct
    module Compiler = struct
      type s

      type t = CRANELIFT | LLVM | SINGLEPASS

      let t : t typ =
        enum
          "wasmer_compiler_t"
          [
            (CRANELIFT, constant "CRANELIFT" int64_t);
            (LLVM, constant "LLVM" int64_t);
            (SINGLEPASS, constant "SINGLEPASS" int64_t);
          ]
    end
  end

  module Config = Declare_own (struct
    let name = "config"
  end)

  module Engine = Declare_own (struct
    let name = "engine"
  end)

  module Store = Declare_own (struct
    let name = "store"
  end)

  module Module = Declare_own (struct
    let name = "module"
  end)

  module Byte = struct
    type t = Unsigned.uint8

    let t = uint8_t

    let name = "byte"
  end

  module Byte_vec = Declare_vec (Byte)

  module Name = struct
    include Byte_vec

    let name = "name"
  end

  module Message = struct
    include Name

    let name = "message"
  end

  module Ref_repr = struct
    type s

    type t = s Ctypes.structure

    let t : t Ctypes.typ = Ctypes.structure "wasm_ref_t"
  end

  module Ref = struct
    let name = "ref"

    type t = Ref_repr.s Ctypes.structure

    let t : t typ = S.lift_typ Ref_repr.t
  end

  module Valkind = struct
    type t = Unsigned.uint8

    let i32 = constant "WASM_I32" uint8_t

    let i64 = constant "WASM_I64" uint8_t

    let f32 = constant "WASM_F32" uint8_t

    let f64 = constant "WASM_F64" uint8_t

    let anyref = constant "WASM_ANYREF" uint8_t

    let funcref = constant "WASM_FUNCREF" uint8_t

    let t : t typ = uint8_t
  end

  (* The actual [Val.t] is an abstract representation of values.
     Unfortunately, it can't be properly represented using Ctypes' stubs
     functionality because it contains an anonymous union field.

     However, the default Ctypes functionality works fine here. The down side is
     that this is not sufficiently type checked, hence we must be careful with
     declarations below.

     Ultimately the [Val.t] is still the type to be used. The types described
     by this module are lifted within the [Val] module.
  *)
  module Val_repr = struct
    open Ctypes

    module Of = struct
      type s

      type t = s union

      let t : t typ = union ""

      let i32 = field t "i32" int32_t

      let i64 = field t "i64" int64_t

      let f32 = field t "f32" float

      let f64 = field t "f64" double

      let ref = field t "ref" (ptr Ref_repr.t)

      let () = seal t
    end

    type s

    type t = s structure

    let t : t typ = structure "wasm_val_t"

    let kind = field t "kind" uint8_t

    let of_ = field t "of" Of.t

    let () = seal t
  end

  module Val = struct
    let name = "val"

    type t = Val_repr.s Ctypes.structure

    let t : t typ = S.lift_typ Val_repr.t
  end

  module Val_vec = Declare_vec (Val)

  module Trap = Declare_own (struct
    let name = "trap"
  end)

  module Valtype = Declare_own (struct
    let name = "valtype"
  end)

  module Valtype_vec = Declare_vec (Ptr (Valtype))

  module Func_callback = struct
    let t =
      Foreign.funptr
        ~runtime_lock:true
          (* [runtime_lock=true] is required to unblock execution in other
             threads. Without it, we would deadlock. The description of [funptr]
             is a little confusing: it seems to suggest that it must be
             [runtime_lock=false] to work - but that seems false in experiments.
          *)
        (ptr Val_vec.t @-> ptr Val_vec.t @-> returning (ptr Trap.t))
  end

  module Func = Declare_own (struct
    let name = "func"
  end)

  module Memory = Declare_own (struct
    let name = "memory"
  end)

  module Extern = Declare_own (struct
    let name = "extern"
  end)

  module Extern_vec = Declare_vec (Ptr (Extern))

  module Instance = Declare_own (struct
    let name = "instance"
  end)

  module Functype = Declare_own (struct
    let name = "functype"
  end)

  module Functype_vec = Declare_vec (Ptr (Functype))

  module Globaltype = Declare_own (struct
    let name = "globaltype"
  end)

  module Globaltype_vec = Declare_vec (Ptr (Globaltype))

  module Tabletype = Declare_own (struct
    let name = "tabletype"
  end)

  module Tabletype_vec = Declare_vec (Ptr (Tabletype))

  module Memorytype = Declare_own (struct
    let name = "memorytype"
  end)

  module Limits = struct
    open Ctypes

    type s

    type t = s structure

    let t : t typ = structure "wasm_limits_t"

    let min = field t "min" uint32_t

    let max = field t "max" uint32_t

    let () = seal t
  end

  module Memorytype_vec = Declare_vec (Ptr (Memorytype))

  module Externkind = struct
    type t = Unsigned.uint8

    let func = constant "WASM_EXTERN_FUNC" uint8_t

    let global = constant "WASM_EXTERN_GLOBAL" uint8_t

    let table = constant "WASM_EXTERN_TABLE" uint8_t

    let memory = constant "WASM_EXTERN_MEMORY" uint8_t

    let t : t typ = uint8_t
  end

  module Externtype = Declare_own (struct
    let name = "externtype"
  end)

  module Externtype_vec = Declare_vec (Ptr (Externtype))

  module Exporttype = Declare_own (struct
    let name = "exporttype"
  end)

  module Exporttype_vec = Declare_vec (Ptr (Exporttype))

  module Importtype = Declare_own (struct
    let name = "importtype"
  end)

  module Importtype_vec = Declare_vec (Ptr (Importtype))
end
