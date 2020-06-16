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

dbg_engine_dir="${SNAP_USER_COMMON}/flutter/bin/cache/artifacts/engine/linux-x64"
rls_engine_dir="${SNAP_USER_COMMON}/flutter/bin/cache/artifacts/engine/linux-x64-release"
pfl_engine_dir="${SNAP_USER_COMMON}/flutter/bin/cache/artifacts/engine/linux-x64-profile"
glfw_dbg_engine="${dbg_engine_dir}/libflutter_linux_glfw.so"
glfw_rls_engine="${rls_engine_dir}/libflutter_linux_glfw.so"
glfw_pfl_engine="${pfl_engine_dir}/libflutter_linux_glfw.so"

patch_glfw () {
  if ! "${FLUTTER}" config | grep enable-linux-desktop | grep true > /dev/null;
  then
    return
  fi

  # If the engine cache is not present, cache it now
  if [ ! -d "${dbg_engine_dir}" ] || [ ! -d "${rls_engine_dir}" ] || [ ! -d "${pfl_engine_dir}" ];
  then
    "${FLUTTER}" precache --linux --no-android --no-ios --no-web --no-macos --no-windows
  fi

  # There are no GLFW engines present, no need to patch
  if [ ! -f "${glfw_dbg_engine}" ] || [ ! -f "${glfw_rls_engine}" ] || [ ! -f "${glfw_pfl_engine}" ];
  then
    return
  fi

  # Patch the GLFW debug, release, and profile engines
  engines=(${glfw_dbg_engine} ${glfw_rls_engine} ${glfw_pfl_engine})
  snap_current="/snap/${SNAP_NAME}/current"
  for engine in "${engines[@]}"
  do
    if [ -f "${engine}" ]; then
      "${SNAP}"/usr/bin/patchelf \
        --set-rpath "${snap_current}/lib/x86_64-linux-gnu:${snap_current}/usr/lib/x86_64-linux-gnu" \
        "${engine}"
    fi
  done

  # We have to unpatch the engine from CMakeLists.txt in order for it to be usable
  # immediately following the build that occurs in `flutter run`
  echo 'INSTALL(CODE "execute_process( COMMAND' \
       'patchelf --set-rpath $ORIGIN ${INSTALL_BUNDLE_LIB_DIR}/libflutter_linux_glfw.so' \
       ')")' >> ./linux/CMakeLists.txt
}

unpatch_glfw () {
  if ! "${FLUTTER}" config | grep enable-linux-desktop | grep true > /dev/null;
  then
    return
  fi

  # There are no GLFW engines present, no need to unpatch
  if [ ! -f "${glfw_dbg_engine}" ] || [ ! -f "${glfw_rls_engine}" ] || [ ! -f "${glfw_pfl_engine}" ];
  then
    return
  fi

  sed -i '$ d' ./linux/CMakeLists.txt
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
  patch_glfw
  $FLUTTER "$@"
  unpatch_glfw
else
  $FLUTTER "$@"
fi
