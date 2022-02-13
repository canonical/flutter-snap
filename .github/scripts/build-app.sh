#!/bin/sh

set -e

WORKSPACE=${1:?"Pass workspace arg"}

docker cp $WORKSPACE snapc:/workspace

docker exec \
    -w /workspace \
    -e LDFLAGS="-Wl,--verbose" \
    snapc \
        flutter build linux -v
