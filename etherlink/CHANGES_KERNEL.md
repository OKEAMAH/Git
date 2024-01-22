# Changelog

## Version Next

### Features

### Bug fixes

- Fix minimum gas price used for charging fees: should be `base_fee_per_gas`, instead of `1 wei`. (!11509)
- Fix an overflow bug when prepaying transactions/repaying gas. (!11545)

### Breaking changes

### Internal

## Version 9978f3a5f8bee0be78686c5c568109d2e6148f13

### Features

- Fix contract code storage cost (!10356)
- Fix contract creation gas cost and transaction data cost. (!10349)
- Implementation of EIP-3541, new code starting with the 0xEF byte cannot be
deployed. (!11225)
- Implement EIP-684: Prevent create collision. Reject contract creation to non-empty address (!11150)
- Smart contract starts at nonce 1 following EIP-161. (!11276)
- Support signature of transactions pre EIP-155. (!11281)
- Prevent collision when creating a contract at the same level it was self-
  destructed. (!11474)

### Bug fixes

- Prevent fatal errors when an intermediate call/transaction runs out of gas during an execution. (!11290)
- Completely remove fatal error promotion between intermediate call/transactions. (!11334)
- Prevent fatal errors on transfers in connection with calls. (!11365)
- Prevent panics when BLOCKHASH opcode is used. (!11366)
- Compute gas cost for SSTORE and SLOAD using hot/cold storage. (!11580)

### Breaking changes

### Internal

- Added support for multi-testing to the `evm-evaluation`. (!11223)
- Blueprints are now stored, the Queue is simplified. New storage version (3). (!11131)

## Version 32f957d52ace920916d54b9f02a2d32ee30e16b3

### Features

- Support precompiled contract `ecrecover`. (!10926)

### Bug fixes

- Fix the memory limit of the runtime, which is now of the maximum size
  addressable considering the limits of the WASM PVM (32bits, which means `2^32`
  bytes addressable). (!10988)
- Nested contract creation correctly limit gas according to EIP-150. (!10352)

### Breaking changes

### Internal

- Add a debug feature flag to the log crate for optional debug traces. (!10692)
- Blueprints include timestamp, instead of retrieving it at block finalization. (!10822)
