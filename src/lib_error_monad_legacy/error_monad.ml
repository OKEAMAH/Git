(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

include
  Monad_maker.Make (Tezos_error_monad.TzCore) (Tezos_error_monad.TzTrace)
    (Tezos_error_monad.TzLwtreslib.Monad)
