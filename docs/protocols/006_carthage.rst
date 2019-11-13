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

TODO how to join the testnet

.. contents:: Summary of changes

Michelson
---------

Protocol 006 contains several improvements to the Michelson smart
contract language.

A summary of the main changes:

TODO


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

TODO add changelog
