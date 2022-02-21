Contract event logging
======================

Contract event logging is a way for contracts to deliver event-like information to external application.
It is an important pattern in contract writing to allow external applications to respond to communication
from Tezos contracts to effect changes in application states outside Tezos.

Event address
-------------
An event schema and an event tag on the Tezos chain is uniquely identified with a Base58 address with checksum of
53 characters long, with a designated prefix of ``ev1``.
An address for a event schema is computed from a Base58 32-byte hash of the event tag string and the binary
serialization of the original Michelson node, with all annotations, separated by a ``0x05`` byte.
For instance, the following event schema declaration produces a unique address of
``ev14AhNYuH5iv4fvjweAdbpqcz67sdjKp9Vkxjq3cUt1A2DkfUbYq``, which is a Base58-encoded Blake2b hash of the string ``event``
followed by a ``0x05`` byte and then followed by the binary serialization of ``or (nat %int) (string %str)``
with all the annotations ``%int`` and ``%str``.

::
    %tag1 (or (nat %int) (string %str));


Sending events
--------------
Contract events can be emitted by invoking the Michelson instruciton ``EMIT``.
``EMIT %tag ty`` pops an item of type ``ty`` off the stack and pushes an ``operation`` onto the stack.

``EMIT`` has the following typing rule.

::
    EMIT %tag ty :: 'ty : 'S -> operation : 'S

To actually send out the events, most importantly, the produced ``operation``\s must be included into the list of
operations that the main contract code returns along with other ``operation``\s that this contract wants to effect.

Event
-----
A contract event entry in Tezos consists of the following data.

- An event ``data`` of a certain type ``event``.
- An event address associated with a certain event tag and data type.

Each successful contract execution attaches into the transaction receipt a list of contract events
arranged in the order of appearance in the resultant list of operations.
There, the events are made ready for consumption by services observing the chain.

Example
-------
Suppose a contract wants to emit events with the following type for the data attachment.

::
    event (or (nat %int) (string %str));

Then this contract may generate an event emission operation with the following instructions.

::
    PUSH string "right";
    RIGHT nat;
    EMIT %emit (or (nat %int) (string %str));


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
                  "address": "ev1....",                             // <~
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
