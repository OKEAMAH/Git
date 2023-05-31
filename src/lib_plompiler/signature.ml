(* Trying & failing at unifying Eddsa & schnorr’s interfaces *)

(* module type S = sig
     module Curve : Mec.CurveSig.AffineEdwardsT

     module P : sig

       type pk = Curve.t

       type signature

       type sk = Curve.Scalar.t

       type msg = Lang_core.S.t

       type sign_parameters
       type sig_encoding


       val neuterize : sk -> pk

       val sign :
         ?compressed:bool -> sign_parameters -> msg -> signature

       val verify :
         ?compressed:bool ->
         msg:Lang_core.S.t ->
         pk:pk ->
         signature:signature ->
         unit ->
         bool
     end

     module V : functor (L : Lang_stdlib.LIB) -> sig
       open L
       open Gadget_edwards.MakeAffine(Curve)(L)

       (* TODO make abstract once compression is done with encodings *)
       type pk = point

       type signature

       module Encoding : sig
         open Encoding.Encodings(L)

         val pk_encoding : (Curve.t, pk repr, pk) encoding
         val signature_encoding :
        (P.signature, signature, P.sig_encoding) encoding

         (* val encoding_input : ('a, 'b, 'c) encoding -> 'a -> 'c Input.input *)
       end

       val verify :
         ?compressed:bool ->
         g:point repr ->
         msg:scalar repr ->
         pk:pk repr ->
         signature:signature ->
         unit ->
         bool repr t
     end
   end *)
