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

- Bump RPCs ``POST ../helpers/parse/operations``, ``POST
  ../helpers/scripts/run_operation`` and ``POST
  ../helpers/scripts/simulate_operation`` default version to version ``1``.
  Version ``0`` can still be used with ``?version=0`` argument. (MR :gl:`!9840`)

- **Breaking change** Removed the deprecated ``endorsing_rights`` RPC,
  use ``attestation_rights`` instead. (MR :gl:`!9849`)

- Bump RPCs ``GET ../mempool/monitor_operations``, ``POST
  ../helpers/preapply/operations``, ``GET ../blocks/<block>``, ``GET
  ../blocks/<blocks>/metadata``. and ``GET ../blocks/<blocks>/operations``
  default version to version ``1``. Version ``0`` can still be used with
  ``?version=0`` argument. (MR :gl:`!9839`)

- Bump RPC ``GET ../mempool/pending_operations`` default version to version
  ``2``. Version ``0`` has been removed and version ``1`` can still be used
  with ``?version=1`` argument. (MR :gl:`!9839`)

- Added metrics about distributed data base messages sent, broadcasted or received

- **Breaking change** Removed the deprecated
  ``disable-mempool-precheck`` configuration flag and
  ``disable_precheck`` field of ``prevalidator`` in the shell limits
  of the configuration file. They already had no effect on the node
  anymore. (MR :gl:`!10030`)

- **Breaking change** Bumped the Octez snapshot version from ``5`` to
  ``6`` to explicit the incompatibility with previous version
  nodes. Also, improved the consistency of ``snapshot`` import errors
  messages (MR :gl:`!10138`)

Client
------

- For the protocols that support it, added an
  ``operation_with_legacy_attestation_name`` and
  ``operation_with_legacy_attestation_name.unsigned`` registered encodings that
  support legacy ``endorsement`` kind instead of ``attestation``. (MR
  :gl:`!9832`)

- Fixed indentation of the stacks outputted by the ``normalize stack``
  command. (MR :gl:`!9944`)

Baker
-----

Accuser
-------

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

- A new bailout mode that solely cements and defends existing
  commitments without publishing new ones. Recovers bonds when
  possible, after which the node exits gracefully. (MR :gl:`!9721`, MR
  :gl:`!9817`, MR :gl:`!9835`)

- RPC ``/global/block/<block-id>/simulate`` accepts inputs with a new optional
  field ``"log_kernel_debug_file"`` which allows to specify a file in which
  kernel logs should be written (this file is in
  ``<data-dir>/simulation_kernel_logs``). (MR :gl:`!9606`)

- Fixed an issue where the rollup node could forget to update its L2 head for a
  block. (MR :gl:`!9868`)

Smart Rollup client
-------------------

Smart Rollup WASM Debugger
--------------------------

- Added flag ``--no-kernel-debug`` to deactivate the kernel debug messages. (MR
  :gl:`!9813`)

- Partially support the installer configuration of the Smart Rollup SDK, i.e.
  support only the instruction ``Set``. The configuration can be passed to
  the debugger via the option ``--installer-config`` and will initialize the
  storage with this configuration. (MR :gl:`!9641`)

Data Availability Committee (DAC)
---------------------------------

Miscellaneous
-------------
