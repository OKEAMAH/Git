/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use tezos_smart_rollup::michelson::MichelsonBytes;

/// What we accept in internal messages as payload (i.e. what is our parameter
/// type).
///
/// If you change this, then in the rollup origination command you should also
/// change the `type` CLI argument respectively.
pub type IncomingTransferParam = MichelsonBytes;
