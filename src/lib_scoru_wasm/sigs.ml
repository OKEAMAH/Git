open Tezos_context_sigs

module type TreeS =
  Context.TREE with type key = string list and type value = bytes
