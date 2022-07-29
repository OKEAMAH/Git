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

Breaking Changes
----------------

- The Baking rights RPC, when called with a list of levels, now has a
  limit of (by default) 128 levels.  This should not affect most users,
  since most users will want either a small number of levels, or a full
  cycle (and in this latter case, they can still use the whole cycle API).

RPC Changes
-----------

- Add a new RPC for querying data found on the voting listings for a
  delegate, i.e. voting power, casted ballots and proposals in the
  current voting period.  (MR :gl:`!4577`)

  ``/chains/<chain_id>/blocks/<block>/context/delegates/<delegate_pkh>/voting_info``

- Add a new RPC to execute contracts' views offchain. (MR :gl:`!4810`)

  ``/chains/<chain_id>/blocks/<block>/helpers/scripts/run_script_view``

- Deprecate the ``endorsing_rights`` RPC for whole cycles, by deprecating the ``cycle`` parameter. (:gl:`!5082`)

Bug Fixes
---------

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
