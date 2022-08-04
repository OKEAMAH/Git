type ('k, 'a) t = ('k, 'a) Lazy_dict.t ref

let create ?origin ?produce_value string_of_key =
  ref (Lazy_dict.create ?origin ?produce_value string_of_key)

let get key dict = Lazy_dict.get key !dict

let set key v dict = dict := Lazy_dict.set key v !dict

let loaded_bindings dict = Lazy_dict.loaded_bindings !dict
