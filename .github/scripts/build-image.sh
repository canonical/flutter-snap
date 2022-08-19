#!/bin/sh
#
# based on https://github.com/ogra1/snapd-docker

set -e

DOCKERFILE=${1:?"Pass Dockerfile arg"}

cd $(dirname $DOCKERFILE)
docker build -t snapimg -f $(basename $DOCKERFILE) .

docker run \
    --name=snapc \
    -ti \
    --tmpfs /run \
    --tmpfs /run/lock \
    --tmpfs /tmp \
    --cap-add SYS_ADMIN \
    --device=/dev/fuse \
    --privileged \
    --security-opt apparmor:unconfined \
    --security-opt seccomp:unconfined \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v /lib/modules:/lib/modules:ro \
    -d snapimg

# wait for snapd to start
TIMEOUT=100
SLEEP=0.1
echo -n "Waiting up to $(($TIMEOUT/10)) seconds for snapd startup "
while [ "$(docker exec snapc sh -c 'systemctl status snapd.seeded >/dev/null 2>&1; echo $?')" != "0" ]; do
    echo -n "."
    sleep $SLEEP || exit 1
    if [ "$TIMEOUT" -le "0" ]; then
        echo " Timed out!"
        exit 1
    fi
    TIMEOUT=$(($TIMEOUT-1))
done
echo " done"

docker exec snapc snap install core --edge

docker exec snapc mount -o rw,nosuid,nodev,noexec,relatime securityfs -t securityfs /sys/kernel/security || true
