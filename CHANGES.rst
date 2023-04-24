Development Changelog
'''''''''''''''''''''

**NB:** The changelog for releases can be found at: https://tezos.gitlab.io/CHANGES.html


This file lists the changes added to each version of octez-node,
octez-client, and the other Octez executables. The changes to the economic
protocol are documented in the ``docs/protocols/`` directory; in
particular in ``docs/protocols/alpha.rst``.

When you make a commit on master, you can add an item in one of the
following subsections (node, client, …) to document your commit or the
set of related commits. This will ensure that this change is not
forgotten in the final changelog, which can be found in ``docs/CHANGES.rst``.
By having your commits update this file you also make it easy to find the
commits which are related to your changes using ``git log -p -- CHANGES.rst``.
Relevant items are moved to ``docs/CHANGES.rst`` after each release.

Only describe changes which affect users (bug fixes and new features),
or which will affect users in the future (deprecated features),
not refactorings or tests. Changes to the documentation do not need to
be documented here either.

General
-------

Node
----

- **Breaking Changes**: Improved a few lib_shell logs in default level by
  shortening the display to completion time only instead of the full status of
  the operation.

- Added an option ``daily-logs`` to file-descriptor sinks, enabling
  log rotation based on a daily frequency.

- Fixed a bug while reconstructing the storage after a snapshot import
  that would result in wrong context hash mapping for some blocks.

- Added an option ``create-dirs`` to file-descriptor sinks to allow
  the node to create the log directory and its parents if they don't exist.

- Added a default node configuration that enables disk logs as a
  file-descriptor-sink in the data directory of the node with a 7 days rotation.

- **Breaking Change**: Removed section in stdout logs lines

- Removed the ``indexing-strategy`` option from the ``TEZOS_CONTEXT``
  environment variable to prevent the usage of the ``always``
  indexing strategy. For now, only the ``minimal`` indexing strategy
  is allowed.

- **Breaking Change** Removed the ``--network limanet``
  built-in network aliases.

- Fixed a issue that may trigger unknown keys errors while reading the
  context on a read-only instance.

Client
------

Baker
-----

- Consensus operations that do not use the minimal slot of the delegate are
  not counted for the (pre)quorums. (MR :gl: `!8175`)

- Consensus operations with identical consensus-related contents but different
  ``branch`` fields are counted only once in the (pre)quorums. (MR :gl: `!8175`)

- Improved efficiency to solve the anti spam proof of work challenge.

Accuser
-------

- Fixed a bug that made the accuser start without waiting for its
  corresponding protocol.

- The accuser now denounces double consensus operations that have the same
  level, round, and delegate, but different slots. (MR :gl:`!8084`)

Signer
------

- Reordered the display of ``octez-client list connected ledgers``
  command. It is now ``Ed25519``, ``Secp256k1``, ``Secp256r1`` and
  ``Bip32_ed25519``.

Proxy Server
------------

Protocol Compiler And Environment
---------------------------------

Codec
-----

Docker Images
-------------

Smart Rollup node
-----------------

- Fixed inverted logic for playing a timeout move in a refutation game (MR
  :gl:`!7929`).

- Stopped the node when the operator deposit is slashed (MR :gl:`!7579`).

- Improved computations of refutation games’ dissections (MRs :gl:`!6948`,
  :gl:`!7751`, :gl:`!8059`, :gl:`!8382`).

- Improved WASM runtime performances (MR :gl:`!8252`).

- Made the Fast Execution aware of the newly introduced WASM PVM versionning
  (MR :gl:`!8079`).

- Fixed UX issues related to the rollup node configuration (MRs :gl:`!8148`,
  :gl:`!8254`, :gl:`!8156`).

- Quality of life improvements in the Layer 1 injector (MRs :gl:`!7579`, :gl:`!7673`, :gl:`!7675`, :gl:`!7685`, :gl:`!7681`, :gl:`!7846`, :gl:`!8106`).

- Fixed logs for kernel debug messages (MR :gl:`!7773`).

- Renamed run command to `legacy run` (MR :gl:`!8543`).

Smart Rollup client
-------------------

- Fixed a JSON decoding error for the command ``get proof for message ...`` (MR
  :gl:`!8000`).

Smart Rollup WASM Debugger
--------------------------

- Let the user select the initial version of the WASM PVM (MR :gl:`!8078`).

- Added commands to decode the contents of the memory and the durable storage
  (MRs :gl:`!7464`, :gl:`!7709`, :gl:`!8303`).

- Added the ``bench`` command (MR :gl:`!7551`).

- Added commands to inspect the structure of the durable storage (MRs
  :gl:`!7707`, :gl:`!8304`).

- Automatically ``load inputs`` when ``step inbox`` is called. (MR :gl:`!8444`)

Miscellaneous
-------------

- Removed binaries and mempool RPCs of Lima.
