#!/bin/bash

FLUTTER=$SNAP_USER_COMMON/flutter/bin/flutter

if [ ! -d "$SNAP_USER_COMMON/flutter" ]; then
    echo "Initializing Flutter"
    git clone https://github.com/flutter/flutter.git -b stable $SNAP_USER_COMMON/flutter
    if [ -x $FLUTTER ]; then
      echo "Flutter initialized"
      $FLUTTER --version
      if [ "$#" -eq 0 ]; then
        exit
      fi
    else
      echo "Flutter initialization failed"
    fi
fi

if [ ! -x $FLUTTER ]; then
    echo "Could not find working copy of Flutter"
    exit
fi

$FLUTTER "$@"
