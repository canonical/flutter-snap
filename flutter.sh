#!/bin/bash

SCRIPT_DIR=`dirname $0`
. $SCRIPT_DIR/env.sh

FLUTTER=$SNAP_USER_COMMON/flutter/bin/flutter

reset_install () {
  echo "Resetting flutter repository"
  rm -rf $SNAP_USER_COMMON/flutter
  download_flutter
}

# Download stable via git
download_flutter_git () {
    git -c "advice.detachedHead=false" clone https://github.com/flutter/flutter.git --single-branch -b $SNAPCRAFT_PROJECT_VERSION "$SNAP_USER_COMMON/flutter"
    
    # Make a specific branch for current stable release, tracking origin/stable
    git -C "$SNAP_USER_COMMON/flutter"  checkout -b $SNAPCRAFT_PROJECT_VERSION
    git -C "$SNAP_USER_COMMON/flutter" fetch origin stable:refs/remotes/origin/stable
    git -C "$SNAP_USER_COMMON/flutter" remote set-branches --add origin stable
    git -C "$SNAP_USER_COMMON/flutter" branch -u origin/stable $SNAPCRAFT_PROJECT_VERSION
}

if [ "$1" == "version" ]; then
  echo "WARNING: Flutter version command has been removed, using latest from channel"
  exit
fi

if [ "$1" == "--reset" ]; then
  reset_install
  exit
fi

if [ ! -d "$SNAP_USER_COMMON/flutter/.git" ]; then
    echo "Initializing Flutter..."
    download_flutter_git

    if [ -x $FLUTTER ]; then
      echo "Flutter downloaded."
      
      $FLUTTER --version

      # Update stamp to let Flutter know we are on stable channel 
      jq '.channel = "stable" | .repositoryUrl = "https://github.com/flutter/flutter.git"' "$SNAP_USER_COMMON/flutter/bin/cache/flutter.version.json" > "$SNAP_USER_COMMON/flutter.version.json"
      cp "$SNAP_USER_COMMON/flutter.version.json" "$SNAP_USER_COMMON/flutter/bin/cache/flutter.version.json"

      echo "Flutter initialized."

      $FLUTTER --version
      if [ "$#" -eq 0 ]; then
        exit
      fi
    else
      echo "Flutter initialization failed."
    fi
fi

if [ ! -x $FLUTTER ]; then
    echo "Could not find working copy of Flutter"
    exit
fi

if [ "$1" == "sdk-path" ]; then
  echo $SNAP_USER_COMMON/flutter
elif [ "$1" == "upgrade" ]; then
  # Remove the bootstrap in case we're upgrading from stable to dev/master
  rm -f $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
  $FLUTTER "$@"
  cp $SCRIPT_DIR/env.sh $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
else
  # Always copy over the bootstrap script in case of changes
  cp $SCRIPT_DIR/env.sh $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
  $FLUTTER "$@"
fi
