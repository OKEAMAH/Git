open Sigs
open Tezos_webassembly_interpreter.Instance

module Make (T : TreeS) : sig
  module Tree : sig
    include TreeS

    module Decoding : Tree_decoding.S with type tree = T.tree
  end

  (** [module_instance_encoding modules] allows you to decode a module instance.
      It requires a vector of previously decoded modules for references. *)
  val module_instance_decoding :
    module_inst Vector.t -> module_inst Tree.Decoding.t

  (** [module_instances_decoding] decodes module instances.  *)
  val module_instances_decoding : module_inst Vector.t Tree.Decoding.t
end
