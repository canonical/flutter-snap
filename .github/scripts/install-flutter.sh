#!/bin/sh

set -e

SNAPFILE=${1:?"Pass snap arg"}

if [ "$2" = "--docker" ]; then
    docker cp $SNAPFILE snapc:$SNAPFILE
    RUNNER="docker exec snapc"
else
    apt update
    DEBIAN_FRONTEND=noninteractive apt install -y snapd
fi

$RUNNER snap install --classic --dangerous $SNAPFILE
$RUNNER flutter config --enable-linux-desktop
$RUNNER flutter doctor -v
