.. Tezos documentation master file, created by
   sphinx-quickstart on Sat Nov 11 11:08:48 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


Welcome to the Tezos Developer Documentation!
=============================================

The Project
-----------

Tezos is a distributed consensus platform with meta-consensus
capability. Tezos not only comes to consensus about the state of its ledger,
like Bitcoin or Ethereum. It also attempts to come to consensus about how the
protocol and the nodes should adapt and upgrade.

 - Developer documentation is available online at https://tezos.gitlab.io/
   and is automatically generated from the master branch.
 - The website https://tezos.com/ contains more information about the project.
 - All development happens on GitLab at https://gitlab.com/tezos/tezos

The source code of Tezos is placed under the MIT Open Source License.


The Community
-------------

- The website of the `Tezos Foundation <https://tezos.foundation/>`_.
- `Tezos sub-reddit <https://www.reddit.com/r/tezos/>`_ is an
  important meeting point of the community.
- Several community-built block explorers are available:

    - https://tezos.id
    - https://mvp.tezblock.io/
    - https://teztracker.everstake.one/
    - https://tzkt.io/ (Baking focused Explorer)
    - https://mininax.cryptonomic.tech/mainnet
    - https://baking-bad.org/ (Reward Tracker)

- A few community-run websites collect useful Tezos links:

    - https://www.tezos.help
    - https://tezos.rocks

- More resources can be found in the :ref:`support` page.


The Networks
------------

Mainnet
~~~~~~~

The Tezos network is the current incarnation of the Tezos blockchain.
It runs with real tez that have been allocated to the
donors of July 2017 ICO (see :ref:`activate_fundraiser_account`).

The Tezos network has been live and open since June 30th 2018.

All the instructions in this documentation are valid for Mainnet
however we **strongly** encourage users to first try all the
introduction tutorials on some :ref:`test network <test-networks>` to familiarize themselves without
risks.

Babylonnet
~~~~~~~~~~

Tezos Babylonnet is a test network for the Tezos blockchain with a
faucet to obtain free tez (see :ref:`faucet`).
It is updated and rebooted rarely and it is running the same code as
the Mainnet.
It is the reference network for developers wanting to test their
software before going to beta and for users who want to familiarize
themselves with Tezos before using their real tez.

We offer support for Babylonnet on IRC.

The Tezos Babylonnet (test) network will be live as long as Mainnet will be running the Babylon protocol.

Zeronet
~~~~~~~

Zeronet is the most cutting-edge development network of Tezos. It is
restarted without notice, possibly several times a day.
This network is mostly used internally by the Tezos developers and may
have *different constants* from Babylonnet or Mainnet, for example it
has shorter cycles and a shorter interval between blocks.
We offer no support for the Zeronet.


Getting started
---------------

The best place to start exploring the project is following the How Tos
in the :ref:`introduction <howtoget>`.


.. toctree::
   :maxdepth: 2
   :caption: Introduction tutorials:

   introduction/howtoget
   introduction/howtouse
   introduction/howtorun
   introduction/test_networks
   introduction/support

.. toctree::
   :maxdepth: 2
   :caption: User documentation:

   user/key-management
   user/sandbox
   user/history_modes
   user/snapshots
   user/various
   user/glossary

.. toctree::
   :maxdepth: 2
   :caption: White doc:

   whitedoc/the_big_picture
   whitedoc/p2p
   whitedoc/validation
   whitedoc/michelson
   whitedoc/proof_of_stake
   whitedoc/voting

.. toctree::
   :maxdepth: 2
   :caption: Developer Tutorials:

   developer/rpc
   developer/data_encoding
   developer/error_monad
   developer/michelson_anti_patterns
   developer/entering_alpha
   developer/protocol_environment
   developer/proposal_testing
   developer/profiling
   developer/flextesa
   developer/python_testing_framework
   developer/contributing

.. toctree::
   :maxdepth: 2
   :caption: Protocols:

   protocols/003_PsddFKi3
   protocols/004_Pt24m4xi
   protocols/005_babylon

.. toctree::
   :maxdepth: 2
   :caption: Releases:

   releases/april-2019
   releases/may-2019
   releases/september-2019
   releases/october-2019

.. toctree::
   :maxdepth: 2
   :caption: APIs:

   README
   api/api-inline
   api/cli-commands
   api/rpc
   api/errors
   api/p2p


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
