Protocol Alpha
==============

This page documents the changes brought by protocol Alpha with respect
to the Oxford protocol proposal (see :ref:`naming_convention`).

The code can be found in directory :src:`src/proto_alpha` of the ``master``
branch of Octez.

.. contents::

Environment Version
-------------------

This protocol requires a different protocol environment version than Oxford.
It requires protocol environment V11, compared to V10 for Oxford.

Smart Rollups
-------------

- The ``smart_rollup_originate`` operation now also takes an optional
  whitelist of public key hashes. This whitelist cannot be used yet
  (the ``sc_rollup.private_enable`` flag has to be set to true). (MR :gl:`!9401`)

- The ``transferring`` parameter from smart rollup client command
  ``get proof for message <index> of outbox at level <level>`` is now optional. (MR :gl:`!9461`)

- Enable the latest version of the WASM PVM (``2.0.0-r3``). Existing smart
  rollups will see their PVM automatically upgrade, and newly originated smart
  rollups will use this version directly (MR :gl:`!9735`)

- Added the updated whitelist for private rollups in the receipt of
  the outbox message execution receipt. (MR :gl:`!10095`)

- Add private rollups: smart rollup with an updatable whitelist stakers. Only stakers on the whitelist can publish commitment and participate in a refutation game. (MRs :gl:`!9823`, :gl:`!10104`, :gl:`!9823`, :gl:`!9572`, :gl:`!9427`, :gl:`!9472`, :gl:`!9439`, :gl:`!9401`)

Zero Knowledge Rollups (ongoing)
--------------------------------

Data Availability Layer (ongoing)
---------------------------------

Adaptive Issuance (ongoing)
----------------------------

Gas improvements
----------------

Breaking Changes
----------------

A DAL attestation operation now contains a new ``slot`` field, while the
``attestor`` field is removed. (MRs :gl:`!10183`, :gl:`!10294`, :gl:`!10317`)

RPC Changes
-----------

Operation receipts
------------------

Protocol parameters
-------------------

- The protocol constant ``max_slashing_period`` has been moved from parametric
  constants to fixed constants. (MR :gl:`!10451`)

Bug Fixes
---------

- Fix reporting of gas in traced execution of Michelson scripts. (MR :gl:`!6558`)

Minor Changes
-------------

- Arithmetic errors on Michelson ``mutez`` type have been exported so
  they can now be caught outside of the protocol. (MR :gl:`!9934`)

Internal
--------

- Register an error's encoding: ``WASM_proof_verification_failed``. It was
  previously not registered, making the error message a bit obscure. (MR :gl:`!9603`)
