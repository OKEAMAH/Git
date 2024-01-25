EVM node
========

This page describes the Octez evm node, an executable used by an Etherlink
operator in conjunction with the :doc:`smart_rollup_node`.

Just like the Octez rollup node, the Octez evm node provides an :doc:`RPC
interface<../api/openapi>`. The services of this interface can be called
directly with HTTP requests, and is compatible with ethereum tooling.

Etherlink, an evm compatible rollup, has been deployed on ghostnet.
Documentation targetted at solidity developers can be found on `the Etherlink
website <https://docs.etherlink.com/>`_. It also includes informations about the
`Ghostnet instance of Etherlink
<https://docs.etherlink.com/get-started/connect-your-wallet-to-etherlink/>`_.

Another EVM compatible rollup is deployed on
`weeklynet <https://teztnets.com/weeklynet-about>`_ . It uses the latest version
of the kernel.


Prerequisites
-------------

To experiment with the commands described in this section, we use
the `Ghostnet <https://teztnets.com/ghostnet-about>`_.

An Octez evm node needs an Octez rollup node running an evm kernel to run.
We assume that an Octez rollup node has been launched locally.

Run as proxy
-------------

Run as sequencer
----------------

Kernel upgrade
--------------

Chunk transaction
-----------------