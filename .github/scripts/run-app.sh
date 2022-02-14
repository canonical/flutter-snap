#!/bin/sh

set -e

docker exec \
    -w /workspace \
    -e LIBGL_DEBUG=verbose \
    snapc \
        xvfb-run -a -s "-screen 0 800x600x24 +extension GLX" \
        flutter run -v -d linux
