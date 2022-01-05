Transaction Rollups
=====================

High-frequency transactions are hard to achieve in a blockchain that is
decentralized and open. For this reason, many blockchains offer the possibility
to define layer-2 solutions that relax some constraints in terms of consensus to
increase the transaction throughput. Such solutions rely on the layer-1 chain as a
gatekeeper and are "optimistic" in that they consider that economic incentives are sufficient to prevent
attacks.

Introduction
------------

Optimistic rollups are a popular layer-2 solution, *e.g.*, on the Ethereum
blockchain (Boba, Arbitrum, Optimism, etc.).

Definitions
************

A **rollup** is a **layer-2** solution for high-frequency transactions. A
**rollup** is characterized by a **rollup context** and a set of **rollup
operations**.

A **rollup node** is a software component running the rollup. By applying
**rollup operations**, a **rollup node** turns a **rollup context** into a new
one to make the rollup **progress**.

A **rollup user** interacts with the rollup through the rollup node and the
Tezos node. A **rollup participant** is a user that administrates a rollup node.

Note that several rollups can simultaneously be alive on the Tezos chain.

Overview
********

Optimistic rollups work as follows.

**Rollup operations** (signed by **rollup users**) are submitted to the layer-1
chain, a.k.a the Tezos chain. As a consequence, the consensus algorithm of the
layer-1 chain is used to set and order **rollup operations**, and nothing
more. In particular, **rollup operations** are not interpreted by the nodes of
the layer-1 chain.

**Rollup nodes** are daemons responsible for interpreting the **rollup
operations**, and computing the **rollup context**. This context is encoded in a
Merkle tree, a ubiquitous data structure in the blockchain universe with many
interesting properties. Two of these properties are significant in the context
of optimistic rollups:

#. A given Merkle tree is uniquely identified by a root hash, and
#. It is possible to prove the presence of a value in the tree without having to
   share the whole tree, by means of Merkle proofs.

Optimistic rollups implementations leverage these two properties. Firstly,
**rollup nodes** can submit **commitments** to the layer-1 chain, to advertise
the root hash of the **rollup context** after the application of a set of
**rollup operations**. Secondly, **rollup participants** can assert the
correctness of these **commitments**, and provide proofs asserting they are
incorrect, we call **rejections** thereafter. By verifying these proofs, the
layer-1 chain can reject an invalid **commitment** without the need to compute
the **rollup context** itself.

As a consequence, the correctness of the **rollup operations** application is
guaranteed as long as one honest **rollup node** is participating. By contrast,
in the absence of honest nodes, a malicious **rollup node** can commit an
invalid hash root, and take over the rollup.  This is the reason behind the
“optimistic” of optimistic rollups.

Transaction Rollups on Tezos
****************************

In some blockchains, optimistic rollups are usually implemented as smart
contracts on the layer-1 chain. That is, **rollup operations**, **commitments**,
and **rejections** are submitted as layer-1 transactions to a smart contract.

In Tezos, transaction rollups are implemented inside the economic
protocol. **Rollup users** interact with these rollups by means of a set of
dedicated manager operations. This design choice, permitted by the amendment
feature of Tezos, allows for a specialized, gas- and storage-efficient
implementation of optimistic rollups.


.. TODO: https://gitlab.com/tezos/tezos/-/issues/2154
   explain choosen ticket interaction and layer-2 operation.
   Transaction rollups can be used to exchange assets (encoded as tickets). A
   key feature of this implementation is that these exchanges can be grouped
   into formal trades (*i.e.*, sets of ticket transfers that need to happen
   atomically).

Commitments and rejections
**************************

In order to ensure that L2 transaction effects are correctly computed,
rollup nodes issue commitments.  A commitment is a layer-1 operation
which describes (using a Merkle tree hash) the state of a rollup after
each batch of a block.  A commitment also includes the predecessor
commitment's hash and level (except in the case of the first
commitment for a rollup).  There is exactly one valid commitment
possible for a given block.

When a commitment is processed, any pending final commitments are
first applied.  This allows finalization to be carbonated.  If no
commitments are made, it is possible for inboxes to pile up, possibly
leading to a large enough backlog that finalization would exceed the
gas limit.  To prevent this, if there are more than 100 inboxes with
messages but without commitments, no further messages are accepted on
the rollup until a commitment is finalized.

In order to issue a commitment, a bond is required.  One bond can
support any number of commitments on a single rollup (but only one per
block).  The bond is collected at the time that a given contract
creates its first commitment is on a rollup.  It may be refunded by
another manager operation, once the last commitment from its creator
has been finalized (that is, after its finality period).  The bond is
treated just like frozen balances for the purposes of delegation.

If a commitment is invalid, it may be rejected.  A rejection operation
for a commitment names one of the operations of the commitment, and
includes a Merkle proof of its wrongness.  A L1 node can then replay
just the transactions of a single batch to determine whether the
rejection is valid.  A rejection must be included in a block within
the finality period (30 blocks) of the block that the commitment is
included in.

In the case of a valid rejection, half of the commitment bond goes to
the rejector.  All commitments by the rejected commitment's contract
are then removed, as are all commitments which are transitive
successors of that commitment.  Since some of those commitments might
have been issued by different contracts, those contracts too must have
have all of their commitments removed, as well as their successors,
and so forth until the process reaches a fixed point.  In practice, we
do not expect this to ever happen, since commitment bonds are
expensive enough to discourage bad commitments.

Each rejection must be preceded by a prerejection. This is to prevent
bakers from front-running rejections.  A prerejection is a hash of:
#. The rejection
#. The contract which will submit the rejection
#. A nonce
The prerejection must be at least one block before the corresponding
rejection.  Rejections include the nonce so that their prerejections
can be verified.  Prerejections prevent bakers from front-running
rejections and getting bonds without doing their own verification. In
the case that multiple rejections reject the same commitment, the one
with the first pre-rejection gets the reward.

Getting Started
---------------

Originating a Transaction Rollup
********************************

The ``tezos-client`` has a dedicated command that any implicit account holder
can use to originate a transaction rollup.

.. code:: sh

    tezos-client originate tx rollup from <implicit account address>

where `tx` is an abbreviation for transaction.

.. TODO: https://gitlab.com/tezos/tezos/-/issues/2152

The origination of a transaction rollup burns ꜩ15.

A **transaction rollup address** is attributed to the new transaction
rollup. This address is derived from the hash of the Tezos operation with the
origination operation similarly to the smart contract origination. It is always
prefixed by ``tru1``. For instance,

::

   tru1HdK6HiR31Xo1bSAr4mwwCek8ExgwuUeHm

is a valid transaction rollup address.

When using the ``tezos-client`` to originate a transaction rollup, the client outputs
the address of the new rollup.

.. TODO: https://gitlab.com/tezos/tezos/-/issues/2154
