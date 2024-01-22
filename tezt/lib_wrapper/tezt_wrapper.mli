(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>      *)
(*                                                                           *)
(*****************************************************************************)

(** Wrapper around Tezt to declare test dependencies. *)

include module type of Tezt

module Uses : sig
  (** Test dependencies.

      [Test.register] and [Regression.register] take an optional argument [?uses]
      that allows to declare that the test uses a given file.

      For instance, you can define:
      {[
        let data = Uses.make ~tag:"data" ~path:"data/file.dat"
      ]}
      You would then:
      - declare your test with [~uses:[data]];
      - use [Uses.path data] to get the path to your file.

      [~uses:[data]] adds the tag of [data] to the test tags.

      [Uses.path data] checks that the current test was declared with [data]
      in its [~uses]. And when you declare a test with [~uses:[data]],
      the test checks, at the end, that [Uses.path data] was called.
      This helps to maintain the invariant that a test that uses a given file
      has a given tag. *)

  (** Test dependencies. *)
  type t

  (** Make a test dependency.

      Multiple paths can be associated with the same tag,
      and the same paths can be associated with different tags. *)
  val make : tag:string -> path:string -> t

  (** Get the path of a test dependency. *)
  val path : t -> string

  (** Get the tag of a test dependency. *)
  val tag : t -> string
end

module Test : sig
  include module type of Tezt.Test

  (** Wrapper over [Tezt.Test.register] that checks test dependencies ([?uses]). *)
  val register :
    __FILE__:string ->
    title:string ->
    tags:string list ->
    ?uses:Uses.t list ->
    ?seed:seed ->
    (unit -> unit Lwt.t) ->
    unit
end

module Regression : sig
  include module type of Tezt.Regression

  (** Wrapper over [Tezt.Regression.register] that checks test dependencies ([?uses]). *)
  val register :
    __FILE__:string ->
    title:string ->
    tags:string list ->
    ?uses:Uses.t list ->
    ?file:string ->
    (unit -> unit Lwt.t) ->
    unit
end
