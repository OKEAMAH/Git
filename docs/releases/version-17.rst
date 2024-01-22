Version 17.3
============

Version 17.0 contains a new version (V9) of the protocol environment,
which is the set of functions that a protocol can call. This new version is used by protocol :doc:`Nairobi<../protocols/017_nairobi>`,
which is a proposal for the successor of Mumbai. This release also
contains Nairobi itself as well as its associated protocol-specific executable binaries (baker, accuser, etc).

The Smart Rollup executables first introduced with Octez v16.0 have been significantly improved, and thus they are no longer intended "for experimental usage only" on Tezos Mainnet.
Note that, as all the other protocol dependent executables, the Smart rollup node and client executables have different versions for Mumbai and Nairobi.

Octez v17 includes a significant improvement of Octez node logging output.
The node now outputs less verbose and clearer logs.
Only essential information is displayed, while a more detailed log is written to disk in the background.
More details can be found in a recent `blog post <https://research-development.nomadic-labs.com/introducing-new-octez-node-logs-for-better-ux.html>`_, and in the :doc:`Logging <../user/logging>` entry.

Version 17.1 fixes an issue causing file descriptor leaks for streamed RPCs.
In addition, it improves the performance of RPC responses when requesting older blocks.

Version 17.2 adds a filtering mechanism which enables the Octez baker to remove ill-formed operations.

Version 17.3 improves Nairobi protocol plugins to discard operations with invalid WASM proofs earlier.

Update Instructions
-------------------

To update from sources::

  git fetch
  git checkout v17.3
  make clean
  opam switch remove . # To be used if the next step fails
  make build-deps
  eval $(opam env)
  make

If you are using Docker instead, use the ``v17.3`` Docker images of Octez.

You can also install Octez using Opam by running ``opam install octez``.


Changelog
---------

- `Version 17.3 <../CHANGES.html#version-17-3>`_
- `Version 17.2 <../CHANGES.html#version-17-2>`_
- `Version 17.1 <../CHANGES.html#version-17-1>`_
- `Version 17.0 <../CHANGES.html#version-17-0>`_
- `Version 17.0~rc1 <../CHANGES.html#version-17-0-rc1>`_
