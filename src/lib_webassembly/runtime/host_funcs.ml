type available_memories =
  | No_memories_during_init
  | Available_memories of Instance.memory_inst Instance.Vector.t

type page_index = {
  published_level : int32;
  slot_index : int32;
  page_index : int32;
}

type reveal =
  | Reveal_raw_data of string
  | Reveal_metadata
  | Reveal_dal of page_index

type reveal_destination = {base : int32; max_bytes : int32}

type ticks = Z.t

type reveal_func =
  available_memories ->
  Values.value list ->
  (reveal * reveal_destination, int32) result Lwt.t

type host_func =
  | Host_func of
      (Input_buffer.t ->
      Output_buffer.t ->
      Durable_storage.t ->
      available_memories ->
      Values.value list ->
      (Durable_storage.t * Values.value list * ticks) Lwt.t)
  | Reveal_func of reveal_func
  | Dal_reveal_fun of
      (available_memories ->
      Values.value list ->
      (page_index * reveal_destination, int32) result Lwt.t)

module Registry = Map.Make (String)

type builder = host_func Registry.t

let empty_builder = Registry.empty

let construct = ref

let with_host_function ~global_name ~implem builder =
  Registry.add global_name implem builder

type registry = builder ref

let empty () = construct empty_builder

let register ~global_name implem registry =
  registry := with_host_function ~global_name ~implem !registry

let lookup ~global_name registry = Registry.find global_name !registry
