Protocol Alpha
==============

This page contains all the relevant information for protocol Alpha
(see :ref:`naming_convention`).

The code can be found in the :src:`src/proto_alpha` directory of the
``master`` branch of Tezos.

This page documents the changes brought by protocol Alpha with respect
to Protocol J.

.. contents::

Smart Contract Optimistic Rollups
---------------------------------

Rollups supporting execution of smart contracts. (MRs :gl:`!4933`, :gl:`!4812`)

Contract Event Logging
----------------------

Contracts may now emit events thanks to a new ``EMIT`` instruction.

Event emissions are denoted by internal operations that perform a contract call to a specific class of addresses starting with `ev1`. 

This new class of addresses can be computed with a newly introduced RPC at ``helpers/scripts/event_address``.

See :doc:`Event <../alpha/event>` for more information.
(MR :gl:`!4656`)

Breaking Changes
----------------

- Reveal operations can only occur at the head of a manager operation
  batch (MR :gl:`!5182`).

- Operations with non-deserializable scripts may now be propagated and
  included in blocks. If such an operation is in a block, its
  application will fail so the operation will have no effect, but its
  fees will still be taken. (MR :gl:`!5506`)

RPC Changes
-----------

- Add a new RPC for querying data found on the voting listings for a
  delegate, i.e. voting power, casted ballots and proposals in the
  current voting period.  (MR :gl:`!4577`)

  ``/chains/<chain_id>/blocks/<block>/context/delegates/<delegate_pkh>/voting_info``

- Add a new RPC to execute contracts' views offchain. (MR :gl:`!4810`)

  ``/chains/<chain_id>/blocks/<block>/helpers/scripts/run_script_view``

- Deprecate the ``endorsing_rights`` RPC for whole cycles, by deprecating the ``cycle`` parameter. (:gl:`!5082`)

- Some contract RPCs working on originated contracts only may return a different
  error than before on implicit accounts. (MR :gl:`!5373`)

Operation receipts
------------------

- Remove field ``consumed_gas``, deprecated in Jakarta. Use field ``consumed_milligas`` instead. (:gl:`!5536`)

Bug Fixes
---------

- Restore *all-or-nothing* semantics of manager operation batches by
  enforcing that failing reveal operations do not take effect (MR
  :gl:`!5182`).

- Consume constant gas `Michelson_v1_gas.Cost_of.manager_operation`
  during precheck: this fixes some cases of operations passing
  precheck even though they obviously do not have enough gas to apply
  the external operation, e.g. when `gas_limit = 0`. (MR :gl:`!5506`)

- Emptying an implicit account does not cost extra-gas anymore. (MR
  :gl:`!5566`)

Minor Changes
-------------

Internal
--------

- Make carbonated maps available to the Raw context (MRs :gl:`!4815`, `!4891`)

- Move Michelson representation modules above the Alpha_context abstraction
  barrier. (MR :gl:`!4418`)

- Further cleanup on Tenderbake code. (MR :gl:`!4513`)

- Add Raw_carbonated_map. (MR :gl:`!4815`)

- Other internal refactorings or documentation. (MRs :gl:`!4890`, :gl:`!4721`)

- Rename `run_view` into `run_tzip4_view` for consistency with
  `run_script_view`. Does not affect the existing `run_view` RPC.
  (MR :gl:`!4810`)

- Precheck no longer returns the gas it has consumed. Instead of
  "replaying" the gas from precheck, `apply_manager_contents` consumes
  the same gas again step by step. (MR :gl:`!5506`)

- Precheck no longer tries to deserialize scripts. It does still check
  that the operation has enough gas for these deserializations (by
  consuming an estimated gas cost based on the bytes size: this has
  not changed). (MR :gl:`!5506`)
