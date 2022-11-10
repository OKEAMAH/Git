Protocol Alpha
==============

This page documents the changes brought by protocol Alpha with respect
to Lima (see :ref:`naming_convention`).

The code can be found in directory :src:`src/proto_alpha` of the ``master``
branch of Tezos.

.. contents::

New Environment Version (V8)
----------------------------

This protocol requires a different protocol environment version than Lima.
It requires protocol environment V8, compared to V7 for Lima. (MR :gl:`!6439`)

Smart Contract Optimistic Rollups (ongoing)
-------------------------------------------

Rollups supporting execution of smart contracts. (MRs :gl:`!6118`, :gl:`!6425`,
:gl:`!6252`, :gl:`!6396`, :gl:`!6364`, :gl:`!6413`, :gl:`!6545`, :gl:`!6543`,
:gl:`!6590`, :gl:`!6623`, :gl:`!6641`, :gl:`!6549`, :gl:`!6672`, :gl:`!6500`)

Data Availability Layer (ongoing)
---------------------------------

Distribution of rollup operations data off-chain. (MRs :gl:`!6174`, :gl:`!6388`,
:gl:`!6527`, :gl:`!6505`, :gl:`!6553`, :gl:`!6685`, :gl:`!6470`, :gl:`!6643`,
:gl:`!6704`, :gl:`!6683`, :gl:`!6702`, :gl:`!6728`, :gl:`!5905`)

Breaking Changes
----------------

RPC Changes
-----------

- Add RPC to get contract's balance of ticket with specified ticketer, content type, and content. Can be used for both implicit and originated contracts.
  ``POST /chains/<chain_id>/blocks/<block_id>/context/contracts/<contract_id>/ticket_balance``. (MR :gl:`!6488`)

- Add RPC to get the complete list of tickets owned by a given contract by scanning the contract's storage. Can only be used for originated contracts.
  ``POST /chains/<chain_id>/blocks/<block_id>/context/contracts/<contract_id>/all_ticket_balances``. (MR :gl:`!6712`)

Operation receipts
------------------

Bug Fixes
---------

Minor Changes
-------------

- Give a positive gas cost to the ``BALANCE`` instruction. (MR :gl:`!6564`)

Internal
--------

- Update migration for Lima. (MR :gl:`!6504`)

- Introduce local context access APIs to the indexed subcontext for optimized accesses with locality. (MR :gl:`!5922`)

- Optimized cleaning of implicit contract with 0 balance using local context accesses (MR :gl:`!5922`)

- Improve ex_ticket_size. (MR :gl:`!6209`)

- Clean up validation code. (MR :gl:`!6526`)

- Remove ``Script_typed_ir.comparable_option_t``. (MR :gl:`!6513`)

- Restrict functions to originated contracts. (MR :gl:`!6198`)

- Minor fixes for Consensus key. (MR :gl:`!6567`)

- Enrich execution traces with "just consumed gas". (MR :gl:`!6565`)

- Fix ignored values. (MRs :gl:`!6577`, :gl:`!6579`, :gl:`!6583`)

- Separate ``Generated_cost`` module. (MR :gl:`!6253`)

- Remove unused parameter in gas model for ``SPLIT_TICKET``. (MR :gl:`!6489`)

- Remove function for computing baking rights without cache update.
  (MR :gl:`!6605`)

- Move the definition of ``boxed_list`` to ``Script_list``. (MR :gl:`!5954`)

- Make ``counter`` an abstract type instead of an alias of ``Z.t``.
  (MRs :gl:`!6647`, :gl:`!6648`)

- Move interpreter logging to the plugin. (MR :gl:`!5778`)

- If they are not delegates, implicit accounts with zero balance and no frozen bonds are now deleted just after block application. Previously that could happen while an operation was in the process of being applied, and the consequences were less predictable. (MR :gl:`!6529`)
