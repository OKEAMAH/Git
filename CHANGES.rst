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

- Changed the bounding specification of valid operations in the mempool:

  + Before, the number of valid **manager operations** in the mempool
    was at most ``max_prechecked_manager_operations`` (default 5_000),
    with no other constraints. (Operations to keep were selected
    according to a "weight" that consists in the ratio of fee over
    "resources"; the latter is the maximum between the following
    ratios: operation gas over maximal allowed gas, and operation size
    over maximal allowed size. The baker uses the same notion of
    "weight" to select operations.)

  + Now, the number of valid **operations of any kind** is at most
    ``max_operations`` (default 10_000), and also the **sum of the
    sizes in bytes** of all valid operations is at most
    ``max_total_bytes`` (default 10_000_000). See
    [src/lib_shell/prevalidator_bounding.mli] for the reasoning behind
    the default values. (Operations are selected according to the
    protocol's ``compare_operations`` function, which currently orders
    operations according to their validation pass (consensus is
    highest and manager is lowest); note that two manager operations
    are ordered using their fee over gas ratio.)

  The values of ``max_operations`` and ``max_total_bytes`` can be
  retrieved with ``GET /chains/<chain>/mempool/filter`` and configured
  with ``POST /chains/<chain>/mempool/filter`` (just as
  ``max_prechecked_manager_operations`` used to be). As a result, the
  JSON format of the outputs of these two RPCs and the input of the
  second one have slightly changed; see their updated descriptions.
  (MR :gl:`!6787`)

- Errors ``prefilter.fees_too_low_for_mempool`` and
  ``plugin.removed_fees_too_low_for_mempool`` have been replaced with
  ``node.mempool.rejected_by_full_mempool`` and
  ``node.mempool.removed_from_full_mempool`` with different
  descriptions and messages. The ``rejected_by_full_mempool`` error
  still indicates the minimal fee that the operation would need to be
  accepted by the full mempool, provided that such a fee exists. If
  not, the error now states that the operation cannot be included no
  matter its fee (e.g. if it is a non-manager operation). (MRs
  :gl:`!6787`, :gl:`!8640`)

- Updated the message of the mempool's
  ``prevalidation.operation_conflict`` error. It now provides the
  minimal fee that the operation would need to replace the
  pre-existing conflicting operation, when such a fee exists. (This
  fee indication used to be available before V16-rc1, where it had
  been removed for technical reasons.) (MR :gl:`!9016`)

- RPC ``/helpers/forge/operations`` can now take JSON formatted operations with
  ``attestation``, ``preattestation``, ``double_attestation_evidence`` and
  ``double_preattestation_evidence`` kinds. Note that the existing kinds
  ``endorsement``, ``preendorsement``, ``double_endorsement_evidence``, and
  ``double_preendorsement_evidence`` are still accepted. (MR :gl:`!8746`)

- Simplified the peer to peer messages at head switch. The node now
  systematically broadcasts only its new head (instead of sometime
  broadcasting a sparse history of the chain).

- Added version ``1`` to RPC ``POST ../helpers/parse/operations``. It can be
  used by calling the RPC with the parameter ``?version=1`` (default version is
  still ``0``). Version ``1`` allows the RPC to output ``attestation``,
  ``preattestation``, ``double_attestation_evidence`` and
  ``double_preattestation_evidence`` kinds in the JSON result. (MR :gl:`!8840`)

- Added version ``2`` to RPC ``GET ../mempool/pending_operations``. It can be
  used by calling the RPC with the parameter ``?version=2`` (default version is
  still ``1``). Version ``2`` allows the RPC to output ``attestation``,
  ``preattestation``, ``double_attestation_evidence`` and
  ``double_preattestation_evidence`` kinds in the JSON result. This version
  also renames the ``applied`` field of the result to ``validated``
  (MRs :gl:`!8960`, :gl:`!9143`)

- RPCs ``/helpers/scripts/run_operation`` and
  ``/helpers/scripts/simulate_operation`` can now take JSON formatted operations
  with ``double_attestation_evidence`` and ``double_preattestation_evidence``
  kinds. Even though consensus operations are not supported by the RPCs,
  ``attestation`` and ``preattestation`` are accepted in the input JSON. (MR
  :gl:`!8768`)

- Removed ``lwt-log`` from the dependencies. The default logger has been updated
  to use the ``file-descriptor-stdout`` sink instead of the previous ``lwt-log``
  sink. This change has resulted in the removal of certain features from the log
  implementation that were specific to "lwt-log". Some features, such as log
  rules, syslog, and the output format, have been replaced with alternative
  implementations. Additionally, the previous implementation of "syslog" had
  some issues, including duplicated log headers or cropped messages, depending
  on the file output. These issues have been addressed, and the new
  implementation should now work correctly.

- Removed ``template`` field from ``log`` configuration with the removal of
  ``lwt-log`` library. Since it was believed to have low usage, no alternative
  implementation has been provided.

- The configuration flag ``disable-mempool-precheck`` is now
  deprecated, as well as the ``disable_precheck`` field of
  ``prevalidator`` in the shell limits of the configuration file. They
  already didn't do anything since V16-rc1. (MR :gl:`!8963`)

- Added version ``1`` to RPCs ``POST ../helpers/scripts/run_operation`` and
  ``POST ../helpers/scripts/simulate_operation``. It can be used by calling the
  RPC with the parameter ``?version=1`` (default version is still ``0``).
  Version ``1`` allows the RPC to output ``attestation``, ``preattestation``,
  ``double_attestation_evidence`` and ``double_preattestation_evidence`` kinds
  in the JSON result. (MR :gl:`!8949`)

- The error message when the local injection of an operation fails now
  begins with ``Error while validating injected operation`` instead of
  ``Error while applying operation``. (MR :gl:`!8857`)

- Updated the description of the ``ban_operation`` RPC to better
  reflect its behavior, which is unchanged. (More precisely, removed
  the "reverting its effect if it was applied" part since operations
  are never applied.) (MR :gl:`!8857`)

- Added version ``1`` to RPC ``GET ../mempool/monitor_operations``. It can be
  used by calling the RPC with the parameter ``?version=1`` (default version is
  still ``0``). Version ``1`` allows the RPC to output ``attestation``,
  ``preattestation``, ``double_attestation_evidence`` and
  ``double_preattestation_evidence`` kinds in the JSON result. (MR :gl:`!8980`)

- Improved the performances of JSON RPC calls by optimizing the
  serialization to JSON. (MR :gl:`!9072`)

- Fixed the ``validation_pass`` argument usage of ``monitor_operations`` RPC.
  Only operation that were in the mempool before the RPC call were filtered by
  validation passes. (MR :gl:`!9012`)

- **Breaking change** Removed the ``octez_mempool_pending_applied``
  metric, and renamed the ``octez_mempool_pending_prechecked`` one to
  ``octez_mempool_pending_validated``. (MR :gl:`!9137`)

- Added version ``1`` to RPC ``POST ../helpers/preapply/operations``. It can be
  used by calling the RPC with the parameter ``?version=1`` (default version is
  still ``0``). Version ``1`` allows the RPC to output ``attestation``,
  ``preattestation``, ``double_attestation_evidence`` and
  ``double_preattestation_evidence`` kinds in the JSON result. (MR :gl:`!8891`)

- Changed default stdout logs by adding simple coloration. The log header
  header is now bold and warning and errors are highlighted. The
  ``--log-coloring`` command line argument can be used to enable or
  disable logs coloration on default stdout logs; it is enabled by
  default. (MR :gl:`!8685`)

- Improved the performance of block validation: the block validation time has
  been reduced by half on average, resulting in a reduced propagation time
  through the network. (MR :gl:`!9100`)

- Added ``validated`` argument for ``GET ../mempool/monitor_operations`` and
  ``GET ../mempool/pending_operations``. ``applied`` argument of these RPCs is
  deprecated. (MR :gl:`!9143`)

- Added version ``1`` to RPCs ``GET ../blocks/<block>``, and ``GET
  ../blocks/<blocks>/operations``. It can be used by calling the RPC with the
  parameter ``?version=1`` (default version is still ``0``). Version ``1``
  allows the RPC to output ``attestation``, ``preattestation``,
  ``double_attestation_evidence`` and ``double_preattestation_evidence`` kinds
  in the JSON result. (MR :gl:`!9008`)

- When an operation in the mempool gets replaced with a better
  conflicting operation (e.g. an operation from the same manager with
  higher fees), the replaced operation is now reclassified as
  ``branch_delayed`` instead of ``outdated``. The associated error
  ``prevalidation.operation_replacement`` is otherwise unchanged. This
  makes it consistent with the reverse situation: when the new
  operation is worse than the old conflicting one, the new operation
  is classified as ``branch_delayed`` with the
  ``prevalidation.operation_conflict`` error. (MR :gl:`!9314`)

- In RPC ``/protocol_data``, ``"per_block_votes"`` replaces ``"liquidity_baking_toggle_vote"``;
  ``"per_block_votes"`` has two properties ``"liquidity_baking_vote"`` and ``"adaptive_issuance_vote"``.
  A vote is one of ``"on"``, ``"off"``, ``"pass"``.

- Added version ``1`` to RPC ``GET ../blocks/<blocks>/metadata``. It can be used
  by calling the RPC with the parameter ``?version=1`` (default version is still
  ``0``). Version ``1`` of this RPC and ``GET ../blocks/<block>`` allow the RPC
  to output ``attesting rewards`` and ``lost attesting rewards`` kinds in the
  JSON result. (MR :gl:`!9253`)

- Fixed a behavior where each time a new data was received from a
  peer, a new p2p request would be triggered instead of waiting for
  the delayed retry. (MR :gl:`!9470`)

- Renamed RPC server events: Added section ``rpc_server`` and changed
  names from ``legacy_logging_event-rpc_http_event-<level>`` into
  ``rpc_http_event_<level>``.

- Reduced the workload of the mempool by preventing unnecessary worker
  requests to be made and fixed a data-race that would request a
  resource that was already received. (MR :gl:`!9520`)

- Event ``block.validation.protocol_filter_not_found`` renamed to
  ``block.validation.validation_plugin_not_found`` with updated
  message ``no validation plugin found for protocol
  <protocol_hash>``. (MR :gl:`!9583`)

- Add RPC to get smart rollup's balance of ticket with specified ticketer, content type, and content:
  ``POST chains/<chain>/blocks/<block>/context/smart_rollups/smart_rollup/<smart_rollup_address>/ticket_balance``
  (MR :gl:`!9535`)

- **Breaking change** Removed ``mumbainet`` network alias. (MR :gl:`!9694`)

- Removed Mumbai mempool plugin. (MR :gl:`!9696`)

- Operations posting invalid WASM proofs are now discarded earlier by the
  Nairobi mempool plugin. (MR :gl:`!`)

- **Breaking change** Bumped the Octez snapshot version from ``5`` to
  ``6`` to explicit the incompatibility with previous version
  nodes. Also, improved the consistency of ``snapshot`` import errors
  messages (MR :gl:`!10138`)

Client
------
- Adding client commands to generate, open and verify a time-lock.

- The ``typecheck script`` command can now be used to typecheck several scripts.

- From protocol ``alpha`` operation receipt output ``attestation`` instead of
  ``endorsement``. For example ``double preendorsement evidence`` become
  ``double preattesation evidence``, ``lost endorsing rewards`` become ``lost
  attesting rewards``. (MR :gl:`!9232`)

- Add ``attest for`` and ``preattest for`` commands. ``endorse for`` and
  ``preendorse for`` are now deprecated. (MR :gl:`!9494`)

- **Breaking change** Removed read-write commands specific to Mumbai (MR :gl:`!9695`)

- Added new client commands related to the new staking mechanisms:
  ``stake``, ``unstake``, ``finalize unstake``, ``set delegate parameters``,
  ``get full balance`` and ``get staked balance``. (MR :gl:`!9642`)

Baker
-----

- Changed the baker liquidity baking vote file
  ``per_block_votes.json`` lookup so that it also considers its client
  data directory when searching an existing file. The previous
  semantics, which looks for this file in the current working
  directory, takes predecence.

- Bakers are now asked (but not required) to set their votes for the adoption of the
  adaptive issuance feature. They may use the CLI option ``--adaptive-issuance-vote``
  or the per-block votes file (which is re-read at each block, and overrides the CLI option).
  Absence of vote is equivalent to voting "pass".

- **Breaking change** Rename ``liquidity_baking_toggle_vote`` into
  ``read_liquidity_baking_toggle_vote`` (MR :gl:`!9464`)
  and ``reading_per_block`` into ``reading_per_block_votes`` (MR :gl:`!8661`),
  for baker events.

- **Breaking change** Rename ``endorsement`` into ``attestation`` for baker errors and events.
  (MR :gl:`!9195`)

- Cached costly RPC calls made when checking if nonces need to be
  revealed. (MR :gl:`!9601`)

Accuser
-------

- **Breaking change** Rename ``endorsement`` into ``attestation`` for accuser errors and events.
  (MR :gl:`!9196`)

Signer
------

Proxy Server
------------

- Redirected not found replies (HTTP 404 answers) to the underlying
  octez-node itself. Public visibility of the node is not required
  anymore.

Protocol Compiler And Environment
---------------------------------

- Added a new version of the protocol environment (V10)

  - Exposed a limited API to manipulate an Irmin binary tree within the
    protocol.

  - Expose encoding with legacy attestation name. (MR :gl:`!8620`)

Codec
-----

Docker Images
-------------

-  Bump up base image to ``alpine:3.17``. In particular, this changes Rust
   version to 1.64.0.

Smart Rollup node
-----------------

- Faster bootstrapping process. (MR :gl:`!8618`, MR :gl:`!8767`)
- Single, protocol-agnostic, rollup node binary. The rollup node
  ``octez-smart-rollup-node`` works with any protocol and supports protocol
  upgrades. The other protocol specific rollup nodes still exist but will be
  deprecated. (MR :gl:`!9105`)

- Added a new metrics ``head_inbox_process_time`` to report the time the rollup
  node spent to process a new Layer 1 head. (MR :gl:`!8971`)

- **Breaking change** Field ``"messages"`` of RPC ``/global/block/{block_id}``
  now contains *serialized* messages (external messages start with ``01`` and
  internal start with ``00``). (MR :gl:`!8876`)

- **Breaking change** RPC ``/global/helpers/proof/outbox`` is moved to
  ``/global/block/head/helpers/proof/outbox``. (MR :gl:`!9233`)

- Fixed an issue where the rollup node could forget to update its L2 head for a
  block. (MR :gl:`!9868`)

Smart Rollup client
-------------------

Smart Rollup WASM Debugger
--------------------------
- Changed the syntax for the ``octez-smart-rollup-wasm-debugger`` to have the ``--kernel``
  argument before the kernel file. (MR :gl:`!9318`)

- ``profile`` commands now profiles the time spent in each steps of a PVM
  execution. It can be disabled with the option ``--without-time`` (MR
  :gl:`!9335`).
- Added option ``--no-reboot`` to the ``profile`` command to profile a single
  ``kernel_run``.
- Improved profiling output for consecutive kernel runs.
- Allow serialized messages in inputs: ``{ "serialized": "01..." }``, instead
  of only external and internal transfers. This allows to inject arbitrary
  messages in the rollup. (MR :gl:`!9613`)

Data Availability Committee (DAC)
----------------------------------
- Released Data Availability Committee executables which include ``octez-dac-node``
  and ``octez-dac-client`` as part of an experimental release. Users can experiment
  with operating and using DAC in their Smart Rollup workflow to achieve higher data
  throughput. It is not recommended to use DAC on Mainnet but instead on testnets
  and lower environments.

Miscellaneous
-------------

- Updating and re-enabling the time-lock Michelson commands.

- Recommend rust version 1.64.0 instead of 1.60.0.

- Sapling parameters files are installed by ``make build-deps`` via opam

- Removed binaries of Mumbai (MR :gl:`!9693`)
