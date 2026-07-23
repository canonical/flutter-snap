#!/bin/bash

# The snap's files and the user's writable snap directory.
SNAP=/snap/flutter/current
SNAP_USER_COMMON=$HOME/snap/flutter/common

# The core26 base snap, providing CA certificates.
CORE=/snap/core26/current

# Run the snap's bootstrap tools and the Flutter SDK before the host's.
# Building Linux apps uses the host's toolchain (clang, cmake, ninja,
# pkg-config, GTK development packages, ...), so the snap does not bundle it.
export PATH=$SNAP/usr/bin:$SNAP/bin:$SNAP_USER_COMMON/flutter/bin:$PATH

# Find git's helper executables inside the snap.
export GIT_EXEC_PATH=$SNAP/usr/lib/git-core

# Ignore the host's system-wide git config so builds behave consistently.
export GIT_CONFIG_NOSYSTEM=1

# CA certificate bundle for HTTPS, used by curl and git.
export CURL_CA_BUNDLE=$CORE/etc/ssl/certs/ca-certificates.crt
export GIT_SSL_CAINFO=$CORE/etc/ssl/certs/ca-certificates.crt
