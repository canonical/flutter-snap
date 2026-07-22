#!/bin/bash

# Architecture triplet (e.g. x86_64-linux-gnu), substituted in at build time.
CRAFT_ARCH_TRIPLET=<CRAFT_ARCH_TRIPLET>

# The snap's files and the user's writable snap directories.
SNAP=/snap/flutter/current
SNAP_USER_COMMON=$HOME/snap/flutter/common
SNAP_USER_DATA=$HOME/snap/flutter/current

# The core22 base snap, providing runtime libraries and CA certificates.
CORE=/snap/core22/current

# Run the snap's tools, and any Flutter SDK the user installs, before the host's.
export PATH=$SNAP/usr/bin:$SNAP/bin:$SNAP_USER_COMMON/flutter/bin:$PATH

# Find git's helper executables inside the snap.
export GIT_EXEC_PATH=$SNAP/usr/lib/git-core

# Ignore the host's system-wide git config so builds behave consistently.
export GIT_CONFIG_NOSYSTEM=1

# CA certificate bundle for HTTPS, used by curl and git.
export CURL_CA_BUNDLE=$CORE/etc/ssl/certs/ca-certificates.crt
export GIT_SSL_CAINFO=$CORE/etc/ssl/certs/ca-certificates.crt

# Load GIO modules from the snap so we don't pick up host modules built
# against a newer glibc than the one the snap ships.
export GIO_MODULE_DIR=$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET/gio/modules

# Let the bundled compiler find the snap's C++ and system headers.
export CPLUS_INCLUDE_PATH=$SNAP/usr/include/$CRAFT_ARCH_TRIPLET/c++/10:$SNAP/usr/include/c++/10:$SNAP/usr/include:$SNAP/usr/include/$CRAFT_ARCH_TRIPLET:$SNAP/usr/include/c++/10

# Let the bundled compiler find the snap's libraries.
export LIBRARY_PATH=$SNAP/usr/lib/gcc/$CRAFT_ARCH_TRIPLET/10:$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET:$SNAP/lib/$CRAFT_ARCH_TRIPLET:$SNAP/usr/lib

# Linker flags, applied so builds link against the snap's own libraries rather
# than the host's, keeping them self-contained and independent of the host's
# glibc:
#   -l           the libraries the Flutter toolchain needs to link against
#   -L           directories to search for those libraries
#   -rpath-link  resolve the indirect (DT_NEEDED) dependencies of prebuilt
#                shared libraries, which -L does not cover
#   -B           find the toolchain's own support files (crt objects, etc.)
export LDFLAGS="-lblkid -lgcrypt -llzma -llz4 -lgpg-error -luuid -lpthread -ldl -lepoxy -lfontconfig $LDFLAGS"
export LDFLAGS="-L$SNAP/usr/lib/gcc/$CRAFT_ARCH_TRIPLET/10 -L$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET -L$SNAP/lib/$CRAFT_ARCH_TRIPLET -L$SNAP/usr/lib/ $LDFLAGS"
export LDFLAGS="-Wl,-rpath-link=$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET:$SNAP/lib/$CRAFT_ARCH_TRIPLET:$CORE/usr/lib/$CRAFT_ARCH_TRIPLET:$CORE/lib/$CRAFT_ARCH_TRIPLET $LDFLAGS"
export LDFLAGS="-B$SNAP/usr/lib/gcc/$CRAFT_ARCH_TRIPLET/10 -B$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET -B$SNAP/lib/$CRAFT_ARCH_TRIPLET -B$SNAP/usr/lib/ $LDFLAGS"

# Let pkg-config find the snap's .pc files, falling back to the host's.
export PKG_CONFIG_PATH=$SNAP/usr/lib/pkgconfig:$SNAP/usr/share/pkgconfig:$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET/pkgconfig:$PKG_CONFIG_PATH:/usr/lib/$CRAFT_ARCH_TRIPLET/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig

# find the location of DRI drivers on the host (e.g. /usr/lib/<triplet>/dri, /usr/lib64/dri, /lib64/dri, ...)
# https://docs.mesa3d.org/faq.html#what-s-the-proper-place-for-the-libraries-and-headers
HOST_DRIVERS_PATH=
CLANG_SEARCH_DIRS=$(clang++ -print-search-dirs | awk -F = '/libraries: =/{print $NF}')
for d in ${CLANG_SEARCH_DIRS//:/$IFS}; do
    if [ -d "$d/dri" ]; then
        if [[ "$d" == /snap/flutter/* ]]; then
            SNAP_DRIVERS_PATH="$SNAP_DRIVERS_PATH:$(realpath $d/dri)"
        else
            HOST_DRIVERS_PATH="$HOST_DRIVERS_PATH:$(realpath $d/dri)"
        fi
    fi
done
SNAP_DRIVERS_PATH="$SNAP_DRIVERS_PATH:$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET/dri"

# Search both the host's and the snap's DRI driver directories.
export LIBGL_DRIVERS_PATH=$HOST_DRIVERS_PATH:$SNAP_DRIVERS_PATH:$LIBGL_DRIVERS_PATH

# Force software rendering, avoiding failures with the host's GPU drivers.
export LIBGL_ALWAYS_SOFTWARE=1

# if any gdk-pixbuf variables are already set (e.g. from the VS Code snap), override them
if [ ! -z $GDK_PIXBUF_MODULE_FILE ] || [ ! -z $GDK_PIXBUF_MODULEDIR ]
then
    # gdk-pixbuf needs a writable cache; point the XDG cache at the snap's data.
    export XDG_CACHE_HOME=$SNAP_USER_COMMON/.cache
    if [[ -d $SNAP_USER_DATA/.cache && ! -e $XDG_CACHE_HOME ]]; then
        # the .cache directory used to be stored under $SNAP_USER_DATA, migrate it
        mv $SNAP_USER_DATA/.cache $SNAP_USER_COMMON/
    fi
    mkdir -p $XDG_CACHE_HOME

    # Create $XDG_RUNTIME_DIR if not exists (to be removed when LP: #1656340 is fixed)
    [ -n "$XDG_RUNTIME_DIR" ] && mkdir -p $XDG_RUNTIME_DIR -m 700

    # Load gdk-pixbuf image loaders from the snap, caching the generated list.
    export GDK_PIXBUF_MODULE_FILE=$XDG_CACHE_HOME/gdk-pixbuf-loaders.cache
    export GDK_PIXBUF_MODULEDIR=$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET/gdk-pixbuf-2.0/2.10.0/loaders
    rm -f $GDK_PIXBUF_MODULE_FILE
    if [ -f $SNAP/usr/lib/$CRAFT_ARCH_TRIPLET/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders ]; then
        $SNAP/usr/lib/$CRAFT_ARCH_TRIPLET/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders > $GDK_PIXBUF_MODULE_FILE
    fi
fi
