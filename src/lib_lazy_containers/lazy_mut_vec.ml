type 'a t = 'a Lazy_vec.t ref

let create ?origin ?produce_value len =
  ref (Lazy_vec.create ?origin ?produce_value len)

let num_elements vec = Lazy_vec.num_elements !vec

let get i vec = Lazy_vec.get i !vec

let set i v vec = vec := Lazy_vec.set i v !vec

let grow ~default size vec = vec := Lazy_vec.grow ~default size !vec

let alloc ?default len = ref (Lazy_vec.alloc ?default len)

let loading_bindings vec = Lazy_vec.loaded_bindings !vec
