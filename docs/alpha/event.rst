Contract event logging
======================

Contract event logging is a way for contracts to deliver event-like information to external application.
It is an important pattern in contract writing to allow external applications to respond to communication
from Tezos contracts to effect changes in application states outside Tezos.
There is blossoming use of event logs in basic indexing services and cross-chain bridges or applications.
In this document, we will explain how event logs are supported in Tezos contract on the Michelson level.

Event
-----
A contract event entry in Tezos consists of the following data.

- An event ``tag`` of type ``string``, which is an express way to deliver human-readable message to indexers
  and off-chain consumers
- An event ``data`` of type ``event``
  which is declared by the emitting contract in a similar way to declaration of ``storage`` and ``parameter``

Each contract can specify one *event schema* by adding a Michelson instruction at the top level,
with the ``event`` primitive and one argument for the type of the event data attachment.
For instance, the following ``event`` declaration provide the type for the event schema which a contract
may use to transmit information about each transaction being a mint operation or a burn operation of an asset.

::
    event (or (nat %mint) (nat %burn))

Each successful contract execution attaches a list of contract events arranged in the chronological order
to the transaction receipt made ready for consumption by services observing the chain.

Event address
-------------
An event schema of a contract on the Tezos chain is uniquely identified with a Base58 address of 53 characters long,
with a designated prefix of ``ev1``.
An address for a event schema is computed from a Base58 32-byte hash of a ``0x05`` byte followed by the binary
serialization of the original Michelson node, with all annotations, at the first argument position of the ``event``
primitive.
For instance, the following event schema declaration produces a unique address of
``ev12m5E1yW14mc9rsrcdGAWVfDSdmRGuctykrVU55bHZBGv9kmdhW``, which is a Base58 hash of a ``0x05`` byte followed by
the binary serialization of ``or (nat %int) (string %str)``.

::
    event (or (nat %int) (string %str));

As for an existing contract without an event schema declaration, the schema defaults to ``unit``.

Sending events
--------------
A contract can send an event throught the ``TRANSFER_TOKEN`` instruction.
It can first obtain a handle to the "event sink" of type ``contract (string * ty)`` using the ``CONTRACT`` instruction,
where ``ty`` is a type, with or without annotation, that is equal to the declared event type and the address
is the address associated with the original event schema.
The entrypoint to the "event sink" is ignored.
Note that the ``parameter`` type of this "event sink" is of type ``string * ty`` where the first coordinate of an input
parameter will be the ``string`` tag of the event and the second coordinate will be the event data attachment.

To actually send out the events, most importantly, the produced ``operation``\s must be included into the list of
operations that the main contract code returns along with other ``operation``\s that this contract wants to effect.

The transfer amount must be zero. Event sinks cannot hold any asset.

Example
-------
Suppose a contract has the following top-level declaration.

::
    event (or (nat %int) (string %str));

Then this contract may obtain the handle to its event sink and generate an event emission operation
with the following instructions.

::
    PUSH address "ev12m5E1yW14mc9rsrcdGAWVfDSdmRGuctykrVU55bHZBGv9kmdhW";
    CONTRACT %emit (pair string (or nat string));
    PUSH mutez 0;
    PUSH string "right";
    RIGHT nat;
    PUSH string "tag1";
    PAIR;
    TRANSFER_TOKENS;


Retrieving events
-----------------
Events successfully emitted can be read off directly from transaction results.
This is typically achieved by making JSON RPCs to the block service.
It will return a list of operations, each including the event entries with the information above.

Here is a sample result from a call.

::

    {
      "protocol": "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK",
      "hash": "opNX59asPwNZGu2kFiHFVJzn7QwtyaExoLtxdZSm3Q3o4jDdSmo",
      // ... fields elided for brevity
      "contents": [
        {
          "kind": "transaction",
          // ... fields elided for brevity
          "metadata": {
            // ... fields elided for brevity
            "operation_result": {
              "status": "applied",
              // ... fields elided for brevity
              "events": [                                           // <~
                {                                                   // <~
                  "tag": "tag1",                                    // <~
                  "data": {                                         // <~
                    "prim": "Right",                                // <~
                    "args": [                                       // <~
                      {                                             // <~
                        "string": "right"                           // <~
                      }                                             // <~
                    ]                                               // <~
                  }                                                 // <~
                }                                                   // <~
              ]                                                     // <~
            }
          }
        }
      ]
    }

Similarly, event type declarations can be extracted by interfacing with the contract RPC,
which is available in the Michelson script of the contract under the `event` primitive.
