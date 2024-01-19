#!/usr/bin/env bash

SCRIPT_DIR=`dirname $0`
. $SCRIPT_DIR/env.sh

DART=$SNAP_USER_COMMON/flutter/bin/dart

if [ ! -d "$SNAP_USER_COMMON/flutter/.git" ]; then
    echo "Flutter not initialized, please run the flutter command once"
    exit
fi

if [ ! -x $DART ]; then
    echo "Could not find working copy of Dart"
    exit
fi

# Always copy over the bootstrap script in case of changes
cp $SCRIPT_DIR/env.sh $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
$DART "$@"
