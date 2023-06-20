#!/bin/bash
PATCH=$1
PATCH_BASE=$(basename $1)
BASE_ENV_NUMBER=$2
shift 2
PATCHS_PATH=$(dirname "$0")
for env in $@ ; do
    if [[ $env =~ [1-9][0-9]* ]]; then
        echo "applying patch $PATCH to proto $env"
        echo  "s/$BASE_ENV_NUMBER/$env/g"
        cat $PATCH | sed "s/$BASE_ENV_NUMBER/$env/g" > $PATCHS_PATH/${env}_${PATCH_BASE}
        cd $PATCHS_PATH/../../;
        patch -p1 < ${PATCHS_PATH}/${env}_${PATCH_BASE}
        cd -
    else
        echo "ignoring $env; not a env number"
    fi
done
