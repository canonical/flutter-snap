#!/bin/bash

set -e

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
  if ! curl -fSL -o releases_linux.json $FLUTTER_STORAGE_BASE_URL/flutter_infra_release/releases/releases_linux.json; then
    echo "Failed to download the list of Flutter releases" >&2
    cd ~-
    return 1
  fi
  base_url=$(cat releases_linux.json | jq -r '.base_url')
  stable=$(cat releases_linux.json | jq -r '.current_release' | jq '.stable')
  archive=$(cat releases_linux.json | jq -r --arg stable "$stable" '[.releases[] | select(.hash=='$stable')][0].archive')
  if [ -z "$base_url" ] || [ -z "$archive" ] || [ "$archive" == "null" ]; then
    echo "Failed to determine the latest Flutter release" >&2
    cd ~-
    return 1
  fi
  url=$base_url/$archive
  echo "Downloading $url"
  if ! curl -fSL -o latest_stable.tar.xz --user-agent 'Flutter SDK Snap' $url; then
    echo "Failed to download the Flutter SDK" >&2
    cd ~-
    return 1
  fi
  if ! tar xf latest_stable.tar.xz --no-same-owner; then
    echo "Failed to extract the Flutter SDK" >&2
    cd ~-
    return 1
  fi
  [ -d "$SNAP_USER_COMMON/flutter/.git" ] && rm -f latest_stable.tar.xz releases_linux.json
  cd ~-
}

# Download stable via git
download_flutter_git () {
    if ! git clone https://github.com/flutter/flutter.git -b stable $SNAP_USER_COMMON/flutter; then
      echo "Failed to clone the Flutter repository" >&2
      return 1
    fi
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
    init_failed=
    if [ "$CRAFT_ARCH_TRIPLET_BUILD_FOR" == "aarch64-linux-gnu" ]; then
        download_flutter_git || init_failed=1
    else
        download_flutter || init_failed=1
    fi
    if [ -z "$init_failed" ] && [ -x "$FLUTTER" ]; then
      echo "Flutter initialized"
      $FLUTTER --version || true
      if [ "$#" -eq 0 ]; then
        exit
      fi
    else
      echo "Flutter initialization failed" >&2
      if [ -n "$LD_PRELOAD" ]; then
        echo "LD_PRELOAD is set to '$LD_PRELOAD'; a preloaded host library may be incompatible with the snap. Try running without it." >&2
      fi
      exit 1
    fi
fi

if [ ! -x $FLUTTER ]; then
    echo "Could not find working copy of Flutter" >&2
    exit 1
fi

# Warn if the host tools needed to build Linux apps are missing.
case "$1" in
  run|test) NEEDS_LINUX_TOOLCHAIN=1 ;;
  build) if [ "$2" == "linux" ]; then NEEDS_LINUX_TOOLCHAIN=1; fi ;;
esac
if [ "$NEEDS_LINUX_TOOLCHAIN" == "1" ]; then
  . $SCRIPT_DIR/check-deps.sh
  check_flutter_linux_deps || true
fi

if [ "$1" == "sdk-path" ]; then
  echo $SNAP_USER_COMMON/flutter
elif [ "$1" == "upgrade" ]; then
  # Remove the bootstrap in case we're upgrading from stable to dev/master
  rm -f $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
  # Always restore the bootstrap script afterwards, even if the upgrade fails,
  # so we don't leave the SDK without it; propagate Flutter's exit status.
  status=0
  $FLUTTER "$@" || status=$?
  cp $SCRIPT_DIR/env.sh $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
  exit $status
else
  # Always copy over the bootstrap script in case of changes
  cp $SCRIPT_DIR/env.sh $SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh
  $FLUTTER "$@"
fi
