#!/bin/bash
PATCH=$1
shift
PATCH_PATH=$(pwd)
for proto in $@; do
    echo "applying patch $PATCH to proto $proto"
    cd $proto;
    patch -p3 < $PATCH_PATH/${PATCH}
    cd $PATCH_PATH
done
