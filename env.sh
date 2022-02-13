#!/bin/bash

SNAPCRAFT_ARCH_TRIPLET=<SNAPCRAFT_ARCH_TRIPLET>

SNAP=/snap/flutter/current
SNAP_USER_COMMON=$HOME/snap/flutter/common
SNAP_USER_DATA=$HOME/snap/flutter/current

export PATH=$SNAP/usr/bin:$SNAP/bin:$SNAP_USER_COMMON/flutter/bin:$PATH
export GIT_EXEC_PATH=$SNAP/usr/lib/git-core
export GIT_CONFIG_NOSYSTEM=1
export CURL_CA_BUNDLE=/snap/core18/current/etc/ssl/certs/ca-certificates.crt
export GIT_SSL_CAINFO=/snap/core18/current/etc/ssl/certs/ca-certificates.crt
export CPLUS_INCLUDE_PATH=$SNAP/usr/include/$SNAPCRAFT_ARCH_TRIPLET/c++/8:$SNAP/usr/include/c++/8:$SNAP/usr/include:$SNAP/usr/include/$SNAPCRAFT_ARCH_TRIPLET:$SNAP/usr/include/c++/8
export LIBRARY_PATH=$SNAP/usr/lib/gcc/$SNAPCRAFT_ARCH_TRIPLET/8:$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET:$SNAP/lib/$SNAPCRAFT_ARCH_TRIPLET:$SNAP/usr/lib
export LDFLAGS="-lblkid -lgcrypt -llzma -llz4 -lgpg-error -luuid -lpthread -ldl $LDFLAGS"
export LDFLAGS="-L$SNAP/usr/lib/gcc/$SNAPCRAFT_ARCH_TRIPLET/8 -L$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET -L$SNAP/lib/$SNAPCRAFT_ARCH_TRIPLET -L$SNAP/usr/lib/ $LDFLAGS"
export LDFLAGS="-B$SNAP/usr/lib/gcc/$SNAPCRAFT_ARCH_TRIPLET/8 -B$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET -B$SNAP/lib/$SNAPCRAFT_ARCH_TRIPLET -B$SNAP/usr/lib/ $LDFLAGS"
export PKG_CONFIG_PATH=$SNAP/usr/lib/pkgconfig:$SNAP/usr/share/pkgconfig:$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/pkgconfig:$PKG_CONFIG_PATH:/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig

# find the location of DRI drivers on the host (e.g. /usr/lib/<triplet>/dri, /usr/lib64/dri, /lib64/dri, ...)
# https://docs.mesa3d.org/faq.html#what-s-the-proper-place-for-the-libraries-and-headers
HOST_DRIVERS_PATH=
CLANG_SEARCH_DIRS=$(clang++ -print-search-dirs | awk -F = '/libraries: =/{print $NF}')
for d in ${CLANG_SEARCH_DIRS//:/$IFS}; do
    if [ -d "$d/dri" ]; then
        HOST_DRIVERS_PATH="$HOST_DIR_DIRS:$(realpath $d/dri)"
    fi
done
SNAP_DRIVERS_PATH=$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/dri
export LIBGL_DRIVERS_PATH=$SNAP_DRIVERS_PATH:$HOST_DRIVERS_PATH:$LIBGL_DRIVERS_PATH
export LIBGL_ALWAYS_SOFTWARE=1

# if any gdk-pixbuf variables are already set (e.g. from the VS Code snap), override them
if [ ! -z $GDK_PIXBUF_MODULE_FILE ] || [ ! -z $GDK_PIXBUF_MODULEDIR ]
then
    # Set cache folder to local path
    export XDG_CACHE_HOME=$SNAP_USER_COMMON/.cache
    if [[ -d $SNAP_USER_DATA/.cache && ! -e $XDG_CACHE_HOME ]]; then
        # the .cache directory used to be stored under $SNAP_USER_DATA, migrate it
        mv $SNAP_USER_DATA/.cache $SNAP_USER_COMMON/
    fi
    mkdir -p $XDG_CACHE_HOME

    # Create $XDG_RUNTIME_DIR if not exists (to be removed when LP: #1656340 is fixed)
    [ -n "$XDG_RUNTIME_DIR" ] && mkdir -p $XDG_RUNTIME_DIR -m 700

    # Gdk-pixbuf loaders
    export GDK_PIXBUF_MODULE_FILE=$XDG_CACHE_HOME/gdk-pixbuf-loaders.cache
    export GDK_PIXBUF_MODULEDIR=$SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/gdk-pixbuf-2.0/2.10.0/loaders
    rm -f $GDK_PIXBUF_MODULE_FILE
    if [ -f $SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders ]; then
        $SNAP/usr/lib/$SNAPCRAFT_ARCH_TRIPLET/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders > $GDK_PIXBUF_MODULE_FILE
    fi
fi
