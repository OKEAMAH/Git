.. _006_carthage:

Protocol 006_<hash> Carthage
============================

This page contains all the relevant information for protocol 006 Carthage.
Each of the main changes is briefly described with links to relevant
external documentation and merge requests.
There are dedicated sections for all the changes to RPCs and
operations.
The changelog section contains the most significant commit messages
and instructions to regenerate the protocol sources from the
Gitlab branch.

**This protocol contains NO breaking changes with respect to Babylon.**

Test network Carthagenet is available to test Carthage.
See details in :ref:`Test Networks<test-networks>`
and instructions to join in :ref:`How to get Tezos<howtoget>`.

.. contents:: Summary of changes

Smart Contracts
---------------

The gas limit per block and per operation was increased by 30%. For
operations it changed from 800,000 to 1,040,000 and for blocks it
changed from 8,000,000 to 10,400,000.

Baking and Endorsing
--------------------

The formula to calculate baking and endorsing rewards was improved
in order to provide more accurate results.

Michelson
---------

Protocol 006 contains several improvements to the Michelson smart
contract language.

A summary of the main changes:
* Allow pairs to be comparable
* Remove dead code for an old peephole optimisation


Changes to RPCs
---------------

The RPC ``baking_rights`` is the only one affected, its behavior is
improved and compatible with the old one.
In Babylon the argument ``max_priority`` causes the RPC to return the
rights up to ``max_priority`` excluded, for example setting
``max_priority=0`` returns the empty list.
In Carthage the value of ``max_priority`` is included, for example
``max_priority=0`` returns the rights of priority zero.


Changes to the binary format of operations
------------------------------------------

There are **no changes** to the binary format of operations.


Changelog
---------

You can see the full git history on the branch `proto-006
<https://gitlab.com/nomadic-labs/tezos/commits/proto-006>`_.
In order to regenerate a protocol with the same hash as Carthage you
can run from this branch::

  $ ./scripts/snapshot_alpha.sh carthage_006 from babylon_005
  $ ls src/proto_006_<hash>

You can find the full changelog `here<https://hackmd.io/@adrianbrink/carthage_changelog>`_.
