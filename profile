# shellcheck shell=sh

# Expand $PATH to include the bindir from the flutter snap
flutter_bin_path="/snap/flutter/current/usr/bin"
if [ -n "${PATH##*${flutter_bin_path}}" -a -n "${PATH##*${flutter_bin_path}:*}" ]; then
    export PATH=$PATH:${flutter_bin_path}
fi

export FLUTTER_ROOT=${FLUTTER_ROOT-${HOME}/snap/flutter/common/flutter}
