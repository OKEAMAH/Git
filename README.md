
# TODO

- Look as hans@scoru-wip-{23,24}
  - Useful things from there?
  - Adapt TLs test to tezt
       launching the L2 node
       see that L1 node and L2 node is running (indexer?)
       using the L2 CLI to originate a SCORU
       CLI to look at commitment production
       using CLI to observe execution state

  - Try to run some of these commands manually
  - Demo kernel compilation?
  - Visualize state transitions


----

Here is the plan for the demo:
Launching the L2 node
Using CLI to originate a SCORU
Using CLI to feed inputs (kernel chunks)
Using CLI to observe execution state in L2 node
Observing commitments on L1
Note:
Will use a minimal Test kernel, not the TX kernel
Run from a sandbox/locally - but functionality is in next Mondaynet





----

# Tezos Octez implementation

## Introduction

Tezos is a blockchain that offers both  _consensus_ and _meta-consensus_, by which we mean that Tezos comes to consensus both about the state of its ledger, and  _also_ about how the
protocol and the nodes should adapt and upgrade.
For more information about the project, see https://tezos.com.

## Getting started

Instructions to
[install](https://tezos.gitlab.io/introduction/howtoget.html), [start
using](https://tezos.gitlab.io/introduction/howtouse.html), and
[taking part in the
consensus](https://tezos.gitlab.io/introduction/howtorun.html) are
available at https://tezos.gitlab.io/.

## The Tezos software

This repository hosts **Octez**, an implementation of the Tezos blockchain.
**Octez** provides a node, a client, a baker, an endorser, an accuser, and other tools, distributed with the Tezos economic protocols of Mainnet for convenience.

In more detail, this git repository contains:
- the source code, in directory src/
- tests (mainly system tests):
  * in a Python testing and execution framework, under tests_python/
  * in an OCaml system testing framework for Tezos called Tezt, under tezt/
- the developer documentation of the Tezos software, under docs/
- a few third-party libraries, adapted for Tezos, under vendors/

The Tezos software may run either on the nodes of
the main Tezos network (mainnet) or on [various Tezos test
networks](https://tezos.gitlab.io/introduction/test_networks.html).

The documentation for developers, including developers of the Tezos software
and developer of Tezos applications and tools, is available
online at https://tezos.gitlab.io/. This documentation is always in
sync with the master branch which may however be slightly
desynchronized with the code running on the live networks.

The source code of Octez is placed under the [MIT Open Source
License](https://opensource.org/licenses/MIT).

## Contributing

### Development workflow

All development of the Tezos code happens on
GitLab at https://gitlab.com/tezos/tezos. Merge requests
(https://gitlab.com/tezos/tezos/-/merge_requests) should usually
target the `master` branch; see [the contribution
instructions](https://tezos.gitlab.io/developer/contributing.html).

The issue tracker at https://gitlab.com/tezos/tezos/issues can be used
to report bugs and to request new simple features. The [Tezos Agora
forum](https://forum.tezosagora.org/) is another great place to
discuss the future of Tezos with the community at large.

### Development of the Tezos protocol

The core of the Tezos software that implements the economic ruleset is
called the *protocol*. Unlike the rest of the source code, updates to the
protocol must be further adopted through the [Tezos
on-chain voting
procedure](https://tezos.gitlab.io/whitedoc/voting.html). Protocol
contributors are encouraged to synchronize their contributions to
minimize the number of protocol proposals that the stakeholders have
to study and to maximize the throughput of the voting procedure.

## Community

Links to community websites are gathered in the following community portals:
- https://www.tezos.help/
- https://developers.tezos.com/ (for developers of applications built on Tezos)
