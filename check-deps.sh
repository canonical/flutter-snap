#!/bin/bash

# Building Linux applications relies on tools that are not part of the Flutter
# snap and must be installed on the host (see Flutter's Linux desktop setup
# instructions). This checks for them and, if any are missing, prints how to
# install them for the current distribution. It only warns; it never blocks.
check_flutter_linux_deps () {
    local missing=()

    command -v clang >/dev/null 2>&1 || missing+=("clang")
    command -v cmake >/dev/null 2>&1 || missing+=("cmake")
    command -v ninja >/dev/null 2>&1 || missing+=("ninja")
    command -v pkg-config >/dev/null 2>&1 || missing+=("pkg-config")
    pkg-config --exists gtk+-3.0 >/dev/null 2>&1 || missing+=("GTK 3 development files")

    [ ${#missing[@]} -eq 0 ] && return 0

    echo "" >&2
    echo "Building Linux applications requires some tools that are not included" >&2
    echo "in the Flutter snap and need to be installed on your system:" >&2
    echo "" >&2
    local m
    for m in "${missing[@]}"; do
        echo "  - $m" >&2
    done
    echo "" >&2

    # Identify the distribution to suggest an install command.
    local id="" like=""
    if [ -r /etc/os-release ]; then
        id=$(. /etc/os-release 2>/dev/null && echo "$ID")
        like=$(. /etc/os-release 2>/dev/null && echo "$ID_LIKE")
    fi

    local cmd=""
    case " $id $like " in
        *" ubuntu "*|*" debian "*)
            cmd="sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev" ;;
        *" fedora "*|*" rhel "*|*" centos "*)
            cmd="sudo dnf install clang cmake ninja-build pkgconf-pkg-config gtk3-devel" ;;
        *" opensuse "*|*" suse "*)
            cmd="sudo zypper install clang cmake ninja pkg-config gtk3-devel" ;;
        *" arch "*)
            cmd="sudo pacman -S --needed clang cmake ninja pkg-config gtk3" ;;
    esac

    if [ -n "$cmd" ]; then
        echo "To install them, run:" >&2
        echo "" >&2
        echo "  $cmd" >&2
    else
        echo "Please install the equivalent packages using your distribution's" >&2
        echo "package manager." >&2
    fi
    echo "" >&2

    return 1
}
