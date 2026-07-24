#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -oue pipefail

mapfile -t INSTALLED_KERNELS < <(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core)
if [[ ${#INSTALLED_KERNELS[@]} -ne 1 || "${INSTALLED_KERNELS[0]}" != "$KERNEL" ]]; then
    echo "Expected kernel $KERNEL, found: ${INSTALLED_KERNELS[*]}"
    exit 1
fi

QUALIFIED_KERNEL="${INSTALLED_KERNELS[0]}"
test -d "/lib/modules/$QUALIFIED_KERNEL"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
test -s "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

echo "::endgroup::"
