#!/bin/bash

SCRIPT_DIR=`dirname $0`
. $SCRIPT_DIR/env.sh

FLUTTER=$SNAP_USER_COMMON/flutter/bin/flutter

reset_install () {
  echo "Resetting flutter repository"
  rm -rf $SNAP_USER_COMMON/flutter
  download_flutter
}

# Download stable via tarball
download_flutter () {
  # Determine URL for latest stable release
  if [ -z $FLUTTER_STORAGE_BASE_URL ]; then
    export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
  fi
  mkdir -p $SNAP_USER_COMMON
  cd $SNAP_USER_COMMON
  curl -s -o releases_linux.json $FLUTTER_STORAGE_BASE_URL/flutter_infra/releases/releases_linux.json
  base_url=$(cat releases_linux.json | jq -r '.base_url')
  stable=$(cat releases_linux.json | jq -r '.current_release' | jq '.stable')
  archive=$(cat releases_linux.json | jq -r --arg stable "$stable" '.releases[] | select(.hash=='$stable').archive')
  url=$base_url/$archive
  echo "Downloading $url"
  curl -o latest_stable.tar.xz --user-agent 'Flutter SDK Snap' $url
  tar xf latest_stable.tar.xz
  [ -d "$SNAP_USER_COMMON/flutter/.git" ] && rm -f latest_stable.tar.xz releases_linux.json
}

# Download stable via git
download_flutter_git () {
    git clone https://github.com/flutter/flutter.git -b stable $SNAP_USER_COMMON/flutter
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
    echo "Initializing Flutter"
    download_flutter
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

# Always copy over the bootstrap script in case of changes
cp $SCRIPT_DIR/env.sh $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh

$FLUTTER "$@"
