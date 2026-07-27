#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

DART="$SNAP_USER_COMMON/flutter/bin/dart"

if [ ! -d "$SNAP_USER_COMMON/flutter/.git" ]; then
    echo "Flutter not initialized, please run the flutter command once" >&2
    exit 1
fi

if [ ! -x "$DART" ]; then
    echo "Could not find working copy of Dart" >&2
    exit 1
fi

# Always copy over the bootstrap script in case of changes
cp "$SCRIPT_DIR/env.sh" "$SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh"
"$DART" "$@"
