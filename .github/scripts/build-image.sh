#!/bin/sh
#
# based on https://github.com/ogra1/snapd-docker

set -e

DOCKERFILE=${1:?"Pass Dockerfile arg"}

cd "$(dirname "$DOCKERFILE")"
docker build -t snapimg -f "$(basename "$DOCKERFILE")" .

docker run \
    --name=snapc \
    -ti \
    --tmpfs /run \
    --tmpfs /run/lock \
    --tmpfs /tmp \
    --cap-add SYS_ADMIN \
    --device=/dev/fuse \
    --privileged \
    --cgroupns=host \
    --security-opt apparmor:unconfined \
    --security-opt seccomp:unconfined \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v /lib/modules:/lib/modules:ro \
    -d snapimg

# wait for snapd to start
TIMEOUT=600
SLEEP=0.1
echo "Waiting up to $((TIMEOUT/10)) seconds for snapd startup "
while [ "$(docker exec snapc sh -c 'systemctl status snapd.seeded >/dev/null 2>&1; echo $?')" != "0" ]; do
    printf '.'
    sleep "$SLEEP" || exit 1
    if [ "$TIMEOUT" -le "0" ]; then
        echo " Timed out!"
        echo "Container status:"
        docker ps -a --filter name=snapc
        echo "Container logs:"
        docker logs snapc || true
        exit 1
    fi
    TIMEOUT=$((TIMEOUT-1))
done
echo " done"

# Hold automatic refreshes so snapd does not spontaneously refresh (and
# restart) itself during the tests, which can transiently fail with
# "snapd rollback across the restart".
docker exec snapc snap refresh --hold

# Wait for snapd to answer API requests, (re)starting it if a self-restart
# left it down.
wait_snapd() {
    TRIES=30
    until docker exec snapc snap wait system seed.loaded >/dev/null 2>&1; do
        TRIES=$((TRIES-1))
        if [ "$TRIES" -le "0" ]; then
            echo "snapd did not recover"
            docker exec snapc systemctl status --no-pager snapd.socket snapd.service || true
            return 1
        fi
        docker exec snapc systemctl reset-failed snapd.socket snapd.service || true
        docker exec snapc systemctl start snapd.socket snapd.service || true
        sleep 2
    done
}

# Installing some snaps (notably the snapd snap) makes snapd restart itself,
# which in a container occasionally fails with "snapd rollback across the
# restart" or leaves snapd down. Retry until the install sticks.
snap_install() {
    for ATTEMPT in 1 2 3; do
        if docker exec snapc snap install "$@"; then
            wait_snapd
            return 0
        fi
        echo "snap install $* failed (attempt $ATTEMPT), waiting for snapd to recover"
        wait_snapd
    done
    return 1
}

snap_install core --edge

# Install the prerequisites of the Flutter snap up front, so the snapd
# restart they trigger happens here (with retries) rather than in the test.
snap_install snapd
snap_install core26

docker exec snapc mount -o rw,nosuid,nodev,noexec,relatime securityfs -t securityfs /sys/kernel/security || true
