#!/bin/bash
PATCH=$1
BASE_ENV_NUMBER=$2
shift 2
PATCH_PATH=$(pwd)
for env in $@ ; do
    if [[ $env =~ [1-9][0-9]* ]]; then
        echo "applying patch $PATCH to proto $env"
        echo  "s/$BASE_ENV_NUMBER/$env/g"
        cat $PATCH | sed "s/$BASE_ENV_NUMBER/$env/g" > ${env}_${PATCH}
        cd ../../;
        patch -p1 < $PATCH_PATH/${env}_${PATCH}
        cd $PATCH_PATH
    else
        echo "ignoring $env; not a env number"
    fi
done
