open Ctypes
module Types = Api_types

module Functions (S : FOREIGN) = struct
  open S

  module Declare_own (Desc : sig
    val name : string

    type t

    val t : t typ
  end) =
  struct
    let delete =
      foreign ("wasm_" ^ Desc.name ^ "_delete") (ptr Desc.t @-> returning void)
  end

  module Declare_vec (Item : sig
    val name : string

    type t

    val t : t typ
  end) (Vector : sig
    type t

    val t : t typ
  end) =
  struct
    let new_empty =
      foreign
        ("wasm_" ^ Item.name ^ "_vec_new_empty")
        (ptr Vector.t @-> returning void)

    let new_ =
      foreign
        ("wasm_" ^ Item.name ^ "_vec_new")
        (ptr Vector.t @-> size_t @-> ptr Item.t @-> returning void)

    let new_uninitialized =
      foreign
        ("wasm_" ^ Item.name ^ "_vec_new_uninitialized")
        (ptr Vector.t @-> size_t @-> returning void)

    let delete =
      foreign
        ("wasm_" ^ Item.name ^ "_vec_delete")
        (ptr Vector.t @-> returning void)

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
      let is_available =
        foreign
          "wasmer_is_compiler_available"
          (Types.Wasmer.Compiler.t @-> returning bool)
    end
  end

  module Config = struct
    let new_ =
      foreign "wasm_config_new" (void @-> returning (ptr Types.Config.t))

    let set_compiler =
      foreign
        "wasm_config_set_compiler"
        (ptr Types.Config.t @-> Types.Wasmer.Compiler.t @-> returning void)

    let delete =
      foreign "wasm_config_delete" (ptr Types.Config.t @-> returning void)
  end

  module Engine = struct
    let new_with_config =
      foreign
        "wasm_engine_new_with_config"
        (ptr Types.Config.t @-> returning (ptr Types.Engine.t))

    let delete =
      foreign "wasm_engine_delete" (ptr Types.Engine.t @-> returning void)
  end

  module Store = struct
    let new_ =
      foreign
        "wasm_store_new"
        (ptr Types.Engine.t @-> returning (ptr Types.Store.t))

    let delete =
      foreign "wasm_store_delete" (ptr Types.Store.t @-> returning void)
  end

  module Module = struct
    let new_ =
      foreign
        "wasm_module_new"
        (ptr Types.Store.t @-> ptr Types.Byte_vec.t
        @-> returning (ptr Types.Module.t))

    let delete =
      foreign "wasm_module_delete" (ptr Types.Module.t @-> returning void)

    let imports =
      foreign
        "wasm_module_imports"
        (ptr Types.Module.t @-> ptr Types.Importtype_vec.t @-> returning void)

    let exports =
      foreign
        "wasm_module_exports"
        (ptr Types.Module.t @-> ptr Types.Exporttype_vec.t @-> returning void)
  end

  module Byte_vec = struct
    let new_ =
      foreign
        "wasm_byte_vec_new"
        (ptr Types.Byte_vec.t @-> Ctypes.size_t @-> Ctypes.string
       @-> returning void)

    let new_empty =
      foreign "wasm_byte_vec_new_empty" (ptr Types.Byte_vec.t @-> returning void)

    let delete =
      foreign "wasm_byte_vec_delete" (ptr Types.Byte_vec.t @-> returning void)
  end

  module Val_vec = Declare_vec (Types.Val) (Types.Val_vec)

  module Valtype = struct
    let new_ =
      foreign
        "wasm_valtype_new"
        (Types.Valkind.t @-> returning (ptr Types.Valtype.t))

    let kind =
      foreign
        "wasm_valtype_kind"
        (ptr Types.Valtype.t @-> returning Types.Valkind.t)
  end

  module Valtype_vec = Declare_vec (Ptr (Types.Valtype)) (Types.Valtype_vec)

  module Extern = struct
    let as_func =
      foreign
        "wasm_extern_as_func"
        (ptr Types.Extern.t @-> returning (ptr Types.Func.t))

    let as_memory =
      foreign
        "wasm_extern_as_memory"
        (ptr Types.Extern.t @-> returning (ptr Types.Memory.t))
  end

  module Extern_vec = Declare_vec (Ptr (Types.Extern)) (Types.Extern_vec)

  module Functype = struct
    let new_ =
      foreign
        "wasm_functype_new"
        (ptr Types.Valtype_vec.t @-> ptr Types.Valtype_vec.t
        @-> returning (ptr Types.Functype.t))

    let params =
      foreign
        "wasm_functype_params"
        (ptr Types.Functype.t @-> returning (ptr Types.Valtype_vec.t))

    let results =
      foreign
        "wasm_functype_results"
        (ptr Types.Functype.t @-> returning (ptr Types.Valtype_vec.t))
  end

  module Func = struct
    let new_ =
      foreign
        "wasm_func_new"
        (ptr Types.Store.t @-> ptr Types.Functype.t @-> Types.Func_callback.t
        @-> returning (ptr Types.Func.t))

    let as_extern =
      foreign
        "wasm_func_as_extern"
        (ptr Types.Func.t @-> returning (ptr Types.Extern.t))

    let call =
      foreign
        "wasm_func_call"
        (ptr Types.Func.t @-> ptr Types.Val_vec.t @-> ptr Types.Val_vec.t
        @-> returning (ptr Types.Trap.t))

    let param_arity =
      foreign "wasm_func_param_arity" (ptr Types.Func.t @-> returning size_t)

    let result_arity =
      foreign "wasm_func_result_arity" (ptr Types.Func.t @-> returning size_t)

    let type_ =
      foreign
        "wasm_func_type"
        (ptr Types.Func.t @-> returning (ptr Types.Functype.t))
  end

  module Memory = struct
    let data =
      foreign "wasm_memory_data" (ptr Types.Memory.t @-> returning (ptr uint8_t))

    let data_size =
      foreign "wasm_memory_data_size" (ptr Types.Memory.t @-> returning size_t)

    let type_ =
      foreign
        "wasm_memory_type"
        (ptr Types.Memory.t @-> returning (ptr Types.Memorytype.t))
  end

  module Memory_type = struct
    let limits =
      foreign
        "wasm_memorytype_limits"
        (ptr Types.Memorytype.t @-> returning (ptr Types.Limits.t))

    let delete =
      foreign
        "wasm_memorytype_delete"
        (ptr Types.Memorytype.t @-> returning void)
  end

  module Instance = struct
    let new_ =
      foreign
        "wasm_instance_new"
        (ptr Types.Store.t @-> ptr Types.Module.t @-> ptr Types.Extern_vec.t
        @-> ptr (ptr Types.Trap.t)
        @-> returning (ptr Types.Instance.t))

    let delete =
      foreign "wasm_instance_delete" (ptr Types.Instance.t @-> returning void)

    let exports =
      foreign
        "wasm_instance_exports"
        (ptr Types.Instance.t @-> ptr Types.Extern_vec.t @-> returning void)
  end

  module Name = Byte_vec
  module Message = Name

  module Trap = struct
    let new_ =
      foreign
        "wasm_trap_new"
        (ptr Types.Store.t @-> ptr Types.Message.t
        @-> returning (ptr Types.Trap.t))

    let message =
      foreign
        "wasm_trap_message"
        (ptr Types.Trap.t @-> ptr Types.Message.t @-> returning void)
  end

  module Externtype = struct
    let kind =
      foreign
        "wasm_externtype_kind"
        (ptr Types.Externtype.t @-> returning Types.Externkind.t)
  end

  module Importtype = struct
    let module_ =
      foreign
        "wasm_importtype_module"
        (ptr Types.Importtype.t @-> returning (ptr Types.Name.t))

    let name =
      foreign
        "wasm_importtype_name"
        (ptr Types.Importtype.t @-> returning (ptr Types.Name.t))

    let type_ =
      foreign
        "wasm_importtype_type"
        (ptr Types.Importtype.t @-> returning (ptr Types.Externtype.t))
  end

  module Importtype_vec =
    Declare_vec (Ptr (Types.Importtype)) (Types.Importtype_vec)

  module Exporttype = struct
    let name =
      foreign
        "wasm_exporttype_name"
        (ptr Types.Exporttype.t @-> returning (ptr Types.Name.t))

    let type_ =
      foreign
        "wasm_exporttype_type"
        (ptr Types.Exporttype.t @-> returning (ptr Types.Externtype.t))
  end

  module Exporttype_vec =
    Declare_vec (Ptr (Types.Exporttype)) (Types.Exporttype_vec)

  let wat2wasm =
    foreign
      "wat2wasm"
      (ptr Types.Byte_vec.t @-> ptr Types.Byte_vec.t @-> returning void)
end
