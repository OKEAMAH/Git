Transaction Rollups
=====================

High-frequency transactions are hard to achieve in a blockchain that is
decentralized and open. For this reason, many blockchains offer the possibility
to define layer-2 solutions that relax some constraints in terms of consensus to
increase the transaction throughput. They relies on the layer-1 chain as a
gatekeeper and are optimistic that economic incentives are sufficient to prevent
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
**rollup nodes** can submit **commitment** to the layer-1 chain, to advertise
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
----------------------------

In some blockchains, optimistic rollups are usually implemented as smart
contracts on the layer-1 chain. That is, **rollup operations**, **commitments**,
and **rejections** are submitted as layer-1 transactions to a smart contract.

In Tezos, transaction rollups are implemented inside the economic
protocol. **Rollup users** interact with these rollups by means of a set of
dedicated manager operations. This design choice, permitted by the amendment
feature of Tezos, allows for a specialized, gas- and storage-efficient
implementation of optimistic rollups.

Transaction rollups allow for exchanging financial assets, encoded as
`Michelson tickets
<https://tezos.gitlab.io/michelson-reference/#type-ticket>`, at a
higher throughput that what is possible on Tezos natively. The
expected workflow proceeds as follow. On the layer-1, smart contracts
can “deposit” tickets to a transaction rollup, for the benefit of a
layer-2 address. Owners of layer-2 address owning deposited tickets
can then exchanging them off-chain, that is, in the layer-2.

On the layer-1
**************

Anyone can originate a transaction rollup on Tezos. The origination is
the result of the Tezos operation ``Tx_rollup_origination``. Similarly
to smart contracts, transaction rollups are assigned an address,
prefixed by ``tru1``.

Initially, the layer-2 ledger of the newly created transaction rollup
is empty. This ledger needs to be provisioned with tickets, that are
deposited from the layer-2 by layer-1 smart contracts. They do so by
emitting layer-1 transactions to the transaction rollup address,
targeting more specifically the ``deposit`` entrypoint, whose
argument is a pair of

#. A ticket (of any type)
#. A layer-2 address (the type ``tx_rollup_l2_address`` in Michelson)

Only smart contracts can emit transaction targeting a transaction
rollup. An example of a minimal smart contract depositing ``unit``
tickets to a transaction rollup is::

    parameter (pair address tx_rollup_l2_address);
    storage (unit);
    code {
           # cast the address to contract type
           CAR;
           UNPAIR;
           CONTRACT %deposit (pair (ticket unit) tx_rollup_l2_address);

           IF_SOME {
                     SWAP;

                     # amount for transferring
                     PUSH mutez 0;
                     SWAP;

                     # create a ticket
                     PUSH nat 10;
                     PUSH unit Unit;
                     TICKET;

                     PAIR ;

                     # deposit
                     TRANSFER_TOKENS;

                     DIP { NIL operation };
                     CONS;

                     DIP { PUSH unit Unit };
                     PAIR;
                   }
                   { FAIL ; }
         }

When its ``default`` entrypoint is called, this smart contract emits
an internal transaction targeting a transaction rollup in order to
deposit 10 ``unit`` tickets for the benefit of a given layer-2
address.

Once a layer-2 address has been provisioned with a ticket, they can
transfer it to other layer-2 address, by means of layer-2 operations.
These operations can be submitted in batch to the layer-1 using the
``Tx_rollup_submit_batch`` layer-1 operation.

Thus, interactions between a transaction rollup and their participants
(*i.e.*, the deposit of a ticket and the submission of a batch of
layer-2 operations pass through the layer-1). However, it is prominent
to understand that the goal of the layer-1 at this point is simply to
keep the record of these interactions, **not** to try to assign a
particular semantics to them. More precisely, these interactions are
treated as messages addressed to the layer-2, and are stored in
inboxes (one per Tezos level).

The interpretation of these messages is delegated to the layer-2.

On the layer-2
**************

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
prefixed by ``tru1``. For instance,::

   tru1HdK6HiR31Xo1bSAr4mwwCek8ExgwuUeHm

is a valid transaction rollup address.

When using the ``tezos-client`` to originate a transaction rollup, it outputs
the newly created address.

Interacting with a Transaction Rollup using ``tezos-client``
************************************************************

The ``tezos-client`` provides dedicated commands to interact with a
transaction rollup. These commands are not indented to be used in a
daily workflow, but rather for testing and development purposes.

It is possible to use the ``tezos-client`` to submit a batch of
layer-2 operations.

.. code:: sh

    tezos-client submit tx rollup batch <batch content in hexadecimal notation> to <transaction rollup address> from <implicit account address>

It is also possible to retrieve the content of an inbox thanks
to a dedicated RPC of the ``tezos-node``.

.. code:: sh

    tezos-client rpc get /chains/main/blocks/<block>/context/tx_rollup/<transaction rollup address>/inbox/<offset>
