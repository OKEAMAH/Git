/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

mod rollup;
use tezos_smart_rollup::kernel_entry;

kernel_entry!(rollup::kernel::kernel_entry);
