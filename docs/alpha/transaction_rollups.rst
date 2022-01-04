Transaction Rollups
=====================

High-frequency transactions are hard to achieve in a blockchain that
is decentralized and open. For this reason, many blockchains offer the
possibility to define **layer-2** solutions that relax some
constraints in terms of consensus to increase the transaction
throughput. They rely on the **layer-1** chain (the main blockchain)
as a gatekeeper and on economic incentives to prevent attacks.

Introduction
------------

**Optimistic rollups** are a popular layer-2 solution, *e.g.*, on the
Ethereum blockchain (Boba, Arbitrum, Optimism, etc.). Similarly to the
layer-1 it uses at its gatekeeper, a layer-2 is characterized by a set
of operations (**layer-2 operations**), a context (**layer-2
context**), and a semantics for the application of layer-2 operations
on top of a layer-2 context. They work as follows:

#. Certain layer-1 operations allow to store layer-2 operations in the
   layer-1 context, which means the consensus of the layer-1 decides
   which layer-2 operations are to be applied, and in which order.
#. The layer-2 context is updated off-chain, using the semantics of
   the layer-2 operations.
#. A layer-1 operation allows to post the hash of the layer-2 context
   after the execution of the layer-2 operations in the layer-1
   context.
#. The layer-1 implements a procedure to reject erroneous hashes of
   the layer-2 context (*e.g.*, submitted by an attacker)
#. After a period of time specific to each rollup implementation, and
   in the absence of a dispute, the hashes of the layer-2 context
   becomes **final**, meaning they cannot be rejected. We call
   **finality period** the time necessary for a hash to become final.

The layer-2 context is encoded in a Merkle tree, a ubiquitous data
structure in the blockchain universe with many interesting
properties. One of these properties are significant in the context of
optimistic rollups: it is possible to prove the presence of a value in
the tree without having to share the whole tree, by means of Merkle
proofs. This property ensures that the procedure to reject a hash does
not require to compute the whole layer-2 context.

The **rollup node** is the software component responsible for applying
the layer-2 operations (as stored in the layer-1 context) onto the
layer-2 context, and to post the resulting hashes in the layer-1. The
word “optimistic” in “optimistic rollup” refers to the assumption that
at least one honest rollup node will always to be active to reject
erroneous hash. In its absence, nothing prevent a rogue node to post a
malicious hash, referring to a tampered layer-2 context.

The transaction rollups implemented in Tezos are optimistic rollups
characterized by the following principles:

#. The semantics of the layer-2 operations is limited to the transfer
   of assets between layer-2 addresses.
#. The procedure to reject erroneous hashes allows for a short
   finality period of 30 blocks.

Besides, transaction rollups are implemented as part of the economic
protocol, not as smart contracts like Arbitrum for instance. This
design choice, permitted by the amendment feature of Tezos allows for
a specialized, gas- and storage-efficient implementation of rollups.

Note that it is possible to create more than one transaction rollup on
Tezos. They are identified with **transaction rollup addresses**,
assigned by the layer-1 at their respective creation (called
origination in Tezos to mimic the terminology of smart contract).

Workflow Overview
-----------------

Transaction rollups allow for exchanging financial assets, encoded as
`Michelson tickets
<https://tezos.gitlab.io/michelson-reference/#type-ticket>`, at a
higher throughput that what is possible on Tezos natively.

The expected workflow proceeds as follow.

#. Layer-1 smart contracts can **deposit** tickets for the benefit of
   a **layer-2 address** to a transaction rollup.
#. A layer-2 address is associated to a cryptograhic public key, and
   the owner of the companion secret key (called “the owner of the
   layer-2 address” afterwards) can sign layer-2 operations to

   - **transfer** tickets for the benefit of another layer-2 address.
   - **withdraw** their assets outside of the transaction rollup, for
     the benefit of a layer-1 address.

To be considered by the rollup, transfer and withdraw orders have to
be signed by (1) a valid layer-2 address, and (2) a valid layer-1
address. This is because they are wrapped in a dedicated layer-1
operation.

While owners of layer-2 address who also owns a layer-1 address can
submit their transfer and withdraw orders themselves, the expected
workflow is that they delegate this to a trusted rollup node, which
can batch together several layer-2 operations signed by several owners
of layer-2 address and submit only one layer-1 operation.

Implementation Overview
-----------------------

We now dive in more details into the concrete implementation of
transaction rollups in Tezos.

Origination
***********

Anyone can originate a transaction rollup on Tezos, as the result of
the layer-1 operation ``Tx_rollup_origination``. Similarly to smart
contracts, transaction rollups are assigned an address, prefixed by
``tru1``.

Ticket Deposit
**************

Initially, the layer-2 ledger of the newly created transaction rollup
is empty. This ledger needs to be provisioned with tickets, that are
deposited into layer-2 by layer-1 smart contracts. They do so by
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

Exchanging Tickets
******************

Once a layer-2 address has been provisioned with a ticket, the owner
of this address can transfer it to other layer-2 addresses.  They are
identified by a ticket hash, which can be retrieved from the layer-1
operation’s receipt responsible for the deposit.

Layer-2 operations which can be issued by owners of layer-2 addresses
share the following information:

#. The layer-2 account spearheading the operation, also called its
   *signer* or its *author*.
#. The counter associated to this layer-2 address, which is an
   anti-replay measure. It's the same mechanism as in Tezos, see
   `Tezos documentation
   <https://tezos.gitlab.io/introduction/howtouse.html>`_ for more
   information. The counter is encoded as a ``int64`` value. The use
   of a bounded integer for the counter theoretically exposes the
   chain to a replay attack **if and only if** an integer overflow
   happen. However, even with an largely overestimated growth of the
   counter, it would take several thousands of centuries for the
   situation to happen.
#. The payload of the operation.

The ``Transfer`` l2-operation comprises the following information:

#. The layer-2 address targeted by the operation; it becomes the new
   owner of the ticket.
#. A ticket hash identifying the asset to exchange.
#. The quantity of the tickets being exchanged, encoded as ``int64``
   value.

The application of a ``Transfer`` will fail in the following cases:

#. If the signer of the operation does not own the required
   quantity of the ticket.
#. If the new balance of the beneficiary of the transfer after the
   application of the operation overflows. The quantity of the ticket
   a layer-2 address owns is encoded using a ``int64`` value. This is
   a known limitation of the transaction rollups, made necessary to
   bound the size of the payload necessary to make a rejection.

Transfer can be grouped inside a *transaction**. A transaction is
atomic: if any operation of the transaction fails, then the whole
transaction fails and leaves the balances of the related addresses
unchanged. This can be useful to implement trades. For instance, two
parties can agree upon exchanging two tickets without having to trust
each other for the emission of the counter-part operation. For a
transaction to be valid, it needs to be signed by the authors of the
transfers it encompasses.

The application of a transaction can fail if and only if the application of
an transfer within the transaction fails.

If this happen, the transfers of the transaction are ignored, but the
counters of their signers are updated nonetheless. This means the
transaction will need to be submitted again, with updated counters, if the
error is involuntary.

Transactions are submitted in **batches** to the layer-1, *via* the
``Tx_rollup_submit_batch`` layer-1 operation. A batch of transactions
comprises the following data:

#. The list of transactions batched together.
#. A BLS signature that aggregates together all the signatures
   of all the transactions contained by the batch.

The application (in the layer-2) of a batch of transactions will fail
if the aggregated BLS signature is incorrect. In such a case, the
batch is discarded by the rollup node, and the counter of the signers
of its operations are not incremented.

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
transaction rollup. These commands are not intended to be used in a
daily workflow, but rather for testing and development purposes.

It is possible to use the ``tezos-client`` to submit a batch of
layer-2 operations.

.. code:: sh

    tezos-client submit tx rollup batch <batch content in hexadecimal notation> to <transaction rollup address> from <implicit account address>

It is also possible to retrieve the content of an inbox thanks
to a dedicated RPC of the ``tezos-node``.

.. code:: sh

    tezos-client rpc get /chains/main/blocks/<block>/context/tx_rollup/<transaction rollup address>/inbox/<offset>
