#!/bin/bash

export SNAPCRAFT_ARCH_TRIPLET=<SNAPCRAFT_ARCH_TRIPLET>

if [ -z "$SNAP" ]
then
  export SNAPCRAFT_PROJECT_NAME=<SNAPCRAFT_PROJECT_NAME>
  export SNAP=/snap/$SNAPCRAFT_PROJECT_NAME/current
  export SNAP_USER_COMMON=$HOME/snap/$SNAPCRAFT_PROJECT_NAME/common
fi

export PATH=$SNAP/usr/bin:$SNAP/bin:$PATH
export GIT_EXEC_PATH=$SNAP/usr/lib/git-core
export GIT_CONFIG_NOSYSTEM=1
export CURL_CA_BUNDLE=/snap/core18/current/etc/ssl/certs/ca-certificates.crt
export GIT_SSL_CAINFO=/snap/core18/current/etc/ssl/certs/ca-certificates.crt
export CPLUS_INCLUDE_PATH=$SNAP/usr/include/$SNAPCRAFT_ARCH_TRIPLET/c++/8:$SNAP/usr/include/c++/8:$SNAP/usr/include:$SNAP/usr/include/$SNAPCRAFT_ARCH_TRIPLET:$SNAP/usr/include/c++/8
export LIBRARY_PATH=$SNAP/usr/lib/gcc/$SNAPCRAFT_ARCH_TRIPLET/8:$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET:$SNAP/usr/lib
export LDFLAGS="$LDFLAGS -L$SNAP/usr/lib/gcc/$SNAPCRAFT_ARCH_TRIPLET/8 -L$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET -L$SNAP/usr/lib/ $LDFLAGS"
export PKG_CONFIG_PATH=$SNAP/usr/lib/pkgconfig:$SNAP/usr/share/pkgconfig:$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/pkgconfig:$PKG_CONFIG_PATH:/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig
