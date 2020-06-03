#!/bin/bash

FLUTTER=$SNAP_USER_COMMON/flutter/bin/flutter

reset_install () {
  echo "Resetting flutter repository"
  rm -rf $SNAP_USER_COMMON/flutter
  download_flutter
}

# Download stable via tarball
download_flutter () {
  # Determine URL for latest stable release
  cd $SNAP_USER_COMMON
  curl -s -o releases_linux.json https://storage.googleapis.com/flutter_infra/releases/releases_linux.json
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

patch_engine () {
  if ! "${FLUTTER}" config | grep enable-linux-desktop | grep true > /dev/null;
  then
    return
  fi

  # Ideally patch once:
  debug_engine="${SNAP_USER_COMMON}/flutter/bin/cache/artifacts/engine/linux-x64/libflutter_linux_glfw.so"
  release_engine="${SNAP_USER_COMMON}/flutter/bin/cache/artifacts/engine/linux-x64-release/libflutter_linux_glfw.so"
  profile_engine="${SNAP_USER_COMMON}/flutter/bin/cache/artifacts/engine/linux-x64-profile/libflutter_linux_glfw.so"

  engines=(${debug_engine} ${release_engine} ${profile_engine})
  for engine in "${engines[@]}"
  do
    snap_current="/snap/${SNAP_NAME}/current"

    # If the engine isn't there, cache it.
    if [ ! -f "${engine}" ]; then
      "${FLUTTER}" precache --linux --no-android --no-ios --no-web --no-macos --no-windows
    fi

    if [ -f "${engine}" ]; then
      "${SNAP}"/usr/bin/patchelf \
        --set-rpath "${snap_current}/lib/x86_64-linux-gnu:${snap_current}/usr/lib/x86_64-linux-gnu" \
        "${engine}"
    fi
  done
}

if [ "$1" == "--reset" ];
then
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

if [ "$1" == "build" ] || [ "$1" == "run" ];
then
  patch_engine
fi

$FLUTTER "$@"

if [ "$1" == "create" ] && [ -d "${!#}" ];
then
  if "${FLUTTER}" config | grep enable-linux-desktop | grep true > /dev/null;
  then
    cd ${!#}/linux
    patch -Ni ${SNAP}/patches/fix-engine-install-rpath.diff -r /dev/null
  fi
fi
