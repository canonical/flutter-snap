#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

FLUTTER="$SNAP_USER_COMMON/flutter/bin/flutter"

reset_install () {
  echo "Resetting flutter repository"
  rm -rf "$SNAP_USER_COMMON/flutter"
  download_flutter
}

# Download stable via tarball
download_flutter () {
  # Determine URL for latest stable release
  if [ -z "$FLUTTER_STORAGE_BASE_URL" ]; then
    export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
  fi
  mkdir -p "$SNAP_USER_COMMON"
  cd "$SNAP_USER_COMMON"
  if ! curl -fSL -o releases_linux.json "$FLUTTER_STORAGE_BASE_URL/flutter_infra_release/releases/releases_linux.json"; then
    echo "Failed to download the list of Flutter releases" >&2
    cd ~-
    return 1
  fi
  base_url=$(jq -r '.base_url' releases_linux.json)
  stable=$(jq -r '.current_release' releases_linux.json | jq '.stable')
  archive=$(jq -r --arg stable "$stable" '[.releases[] | select(.hash=='"$stable"')][0].archive' releases_linux.json)
  if [ -z "$base_url" ] || [ -z "$archive" ] || [ "$archive" == "null" ]; then
    echo "Failed to determine the latest Flutter release" >&2
    cd ~-
    return 1
  fi
  url=$base_url/$archive
  echo "Downloading $url"
  if ! curl -fSL -o latest_stable.tar.xz --user-agent 'Flutter SDK Snap' "$url"; then
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
    if ! git clone https://github.com/flutter/flutter.git -b stable "$SNAP_USER_COMMON/flutter"; then
      echo "Failed to clone the Flutter repository" >&2
      return 1
    fi
}

# Older revisions of this snap bundled the Linux build toolchain (ninja, and
# in the past clang, cmake, ...) inside the snap. When an app was built,
# CMake cached the absolute path to those tools (e.g.
# /snap/flutter/current/usr/bin/ninja) in the project's build/linux directory.
# The snap now uses the host toolchain and no longer ships these tools, so the
# cached paths point at files that no longer exist and CMake fails with e.g.
# "Running '/snap/flutter/current/usr/bin/ninja' '--version' failed". Detect
# such a stale build directory and tell the user to run "flutter clean" so the
# build is reconfigured against the host toolchain. This only warns; it never
# deletes anything itself.
warn_stale_cmake_cache () {
  [ -d build/linux ] || return 0
  local cache path
  while IFS= read -r cache; do
    while IFS= read -r path; do
      if [ -n "$path" ] && [ ! -e "$path" ]; then
        echo "" >&2
        echo "This project's Linux build was configured against a previous version of" >&2
        echo "the Flutter snap that bundled its own build tools. That toolchain is no" >&2
        echo "longer part of the snap, so the cached path:" >&2
        echo "" >&2
        echo "  $path" >&2
        echo "" >&2
        echo "no longer exists and the build will fail. Run 'flutter clean' to remove" >&2
        echo "the stale build configuration, then build again." >&2
        echo "" >&2
        return 0
      fi
    done < <(sed -n 's|^[^=]*=\(/snap/flutter/.*\)$|\1|p' "$cache")
  done < <(find build/linux -name CMakeCache.txt 2>/dev/null)
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
    # Flutter only publishes prebuilt SDK tarballs for x86_64, so fetch the SDK
    # via git on other architectures (e.g. arm64). Detect the running
    # architecture at runtime rather than relying on build-time variables.
    if [ "$(uname -m)" == "aarch64" ]; then
        download_flutter_git || init_failed=1
    else
        download_flutter || init_failed=1
    fi
    if [ -z "$init_failed" ] && [ -x "$FLUTTER" ]; then
      echo "Flutter initialized"
      "$FLUTTER" --version || true
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

if [ ! -x "$FLUTTER" ]; then
    echo "Could not find working copy of Flutter" >&2
    exit 1
fi

# Warn if the host tools needed to build Linux apps are missing.
case "$1" in
  run|test) NEEDS_LINUX_TOOLCHAIN=1 ;;
  build) if [ "$2" == "linux" ]; then NEEDS_LINUX_TOOLCHAIN=1; fi ;;
esac
if [ "$NEEDS_LINUX_TOOLCHAIN" == "1" ]; then
  # shellcheck source=check-deps.sh
  . "$SCRIPT_DIR/check-deps.sh"
  check_flutter_linux_deps || true
  warn_stale_cmake_cache
fi

if [ "$1" == "sdk-path" ]; then
  echo "$SNAP_USER_COMMON/flutter"
elif [ "$1" == "upgrade" ]; then
  # Remove the bootstrap in case we're upgrading from stable to dev/master
  rm -f "$SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh"
  # Always restore the bootstrap script afterwards, even if the upgrade fails,
  # so we don't leave the SDK without it; propagate Flutter's exit status.
  status=0
  "$FLUTTER" "$@" || status=$?
  cp "$SCRIPT_DIR/env.sh" "$SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh"
  exit "$status"
else
  # Always copy over the bootstrap script in case of changes
  cp "$SCRIPT_DIR/env.sh" "$SNAP_USER_COMMON/flutter/bin/internal/bootstrap.sh"
  "$FLUTTER" "$@"
fi
