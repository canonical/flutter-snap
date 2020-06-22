#!/bin/bash

export SNAP=/snap/flutter/current
export SNAP_USER_COMMON=/home/marcustomlinson/snap/flutter/common
export SNAPCRAFT_ARCH_TRIPLET=x86_64-linux-gnu
export SNAPCRAFT_PROJECT_NAME=flutter

export PATH=${SNAP}/usr/bin:${SNAP}/bin:$PATH
export GIT_EXEC_PATH=${SNAP}/usr/lib/git-core
export GIT_CONFIG_NOSYSTEM=1
export CURL_CA_BUNDLE=/snap/core18/current/etc/ssl/certs/ca-certificates.crt
export GIT_SSL_CAINFO=/snap/core18/current/etc/ssl/certs/ca-certificates.crt
export CPLUS_INCLUDE_PATH=${SNAP}/usr/include/${SNAPCRAFT_ARCH_TRIPLET}/c++/8:${SNAP}/usr/include/c++/8:${SNAP}/usr/include:${SNAP}/usr/include/${SNAPCRAFT_ARCH_TRIPLET}:${SNAP}/usr/include/c++/8
export LIBRARY_PATH=${SNAP}/usr/lib/gcc/${SNAPCRAFT_ARCH_TRIPLET}/8:${SNAP}/usr/lib/${SNAPCRAFT_ARCH_TRIPLET}:${SNAP}/usr/lib
export LDFLAGS="${LDFLAGS} -L${SNAP}/usr/lib/gcc/${SNAPCRAFT_ARCH_TRIPLET}/8 -L${SNAP}/usr/lib/${SNAPCRAFT_ARCH_TRIPLET} -L${SNAP}/usr/lib/ ${LDFLAGS}"
export PKG_CONFIG_PATH=/snap/${SNAPCRAFT_PROJECT_NAME}/current/usr/lib/pkgconfig:/snap/${SNAPCRAFT_PROJECT_NAME}/current/usr/share/pkgconfig:/snap/${SNAPCRAFT_PROJECT_NAME}/current/usr/lib/${SNAPCRAFT_ARCH_TRIPLET}/pkgconfig:$PKG_CONFIG_PATH:/usr/lib/${SNAPCRAFT_ARCH_TRIPLET}/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig
