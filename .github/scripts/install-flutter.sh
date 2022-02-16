#!/bin/sh

set -e

DOCKER=0
SNAP="flutter"
ARGS="--classic"

while [ $# -gt 0 ]; do
    case "$1" in
        --docker)
            DOCKER=1
            ;;
        -*)
            ARGS="$ARGS $1"
            ;;
        *)
            SNAP="$1"
            ;;
    esac
    shift
done

if [ $DOCKER -eq 1 ]; then
    RUNNER="docker exec snapc"

    # copy if it's a .snap file
    if [ "$(basename $SNAP .snap)" != "$SNAP" ]; then
        docker cp $SNAP snapc:$SNAP
    fi
fi

$RUNNER snap install $ARGS $SNAP
$RUNNER flutter config --enable-linux-desktop
$RUNNER flutter doctor -v
