#!/bin/bash
set -u
set -e

#avoid running as root on instance...
# not the nicest solution but
whoami
if [ $UID -eq 0 ]; then
    CMD=$0
    chmod a+rwx $CMD
    echo "Change script to run as snoop user"
    exec runuser -u snoop -- $CMD
fi

cd $HOME
wget https://sh.rustup.rs/rustup-init.sh
chmod +x rustup-init.sh
./rustup-init.sh --profile minimal --default-toolchain 1.52.1 -y
source "$HOME/.cargo/env"

git clone --branch frejsoya@3582-snoop-setup-aws https://gitlab.com/tezos/tezos.git
cd tezos
# Always install depexts
export OPAMCONFIRMLEVEL=unsafe-yes
opam init -y --bare
eval $(opam env)
#Do not compile BLST with cpu specific instructions for benchmarking.
BLST_PORTABLE=y make build-dev-deps
eval $(opam env)
PROFILE=release make


export PATH=$HOME/tezos/_build/install/default/bin/:$PATH
tezos-snoop