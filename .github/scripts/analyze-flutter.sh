#!/bin/sh

set -e

mkdir -p /workspace/flutter_app
cd /workspace/flutter_app
# Ignore "Woah! You appear to be trying to run flutter as root..."
flutter create --platforms linux . 2>&1

# Request the linker to print verbose details of libraries and CRT objects
# referenced during the linking process.
#
# Examples:
# > attempt to open /snap/flutter/current/usr/lib/gcc/x86_64-linux-gnu/8/libgcc.so failed
# > attempt to open /usr/lib/gcc/x86_64-linux-gnu/11/crtend.o succeeded
# > ...
# > libuuid.so.1 needed by /snap/flutter/current/usr/lib/x86_64-linux-gnu/libblkid.so
# > attempt to open /snap/flutter/current/usr/lib/x86_64-linux-gnu/libuuid.so.1 failed
# > found libuuid.so.1 at //snap/core18/current/lib/x86_64-linux-gnu/libuuid.so.1
# > ...
# > attempt to open CMakeFiles/libgcc.dir/main.cc.o succeeded
# > attempt to open linux/flutter/ephemeral/libflutter_linux_gtk.so succeeded
LDFLAGS="-Wl,--verbose" flutter build linux -v 2>&1 | tee build.log

# Capture references to libraries and CRT objects.
output=$(grep "found\|succeeded\$" build.log)

# Filter out good references _inside_ the snap.
output=$(echo "$output" | grep -v "/snap")

# Filter out local app libraries and objects.
output=$(echo "$output" | grep -v "CMake\|flutter")

# The remaining system library and CRT object references _outside_ the snap are
# bad as they may cause glibc version conflicts, for example.
if [ -n "$output" ]; then
    echo "Reference outside /snap: $output" | sed -E "s/\[\s+\]\s+//" >&2
    exit 1
fi
