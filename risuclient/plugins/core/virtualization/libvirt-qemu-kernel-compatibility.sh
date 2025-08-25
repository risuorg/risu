#!/bin/bash

# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Kernel, QEMU and Libvirt compatibility
# description: Checks compatibility between libvirt, qemu and kernel packages
# priority: 910

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

# check if we are running against compute

if ! is_process nova-compute; then
    echo "works only on compute node" >&2
    exit ${RC_SKIPPED}
fi

# we know the exact kernel versions for RHEL7 from https://access.redhat.com/articles/3078

declare -A kernel_libvirt_qemu
kernel_libvirt_qemu=(["3.10.0-123"]="1.1.1 1.5.3 7.0"
    ["3.10.0-229"]="1.2.8 2.1.2 7.1"
    ["3.10.0-327"]="1.2.17 2.3.0 7.2"
    ["3.10.0-514"]="2.0.0 2.6.0 7.3"
    ["3.10.0-693"]="3.2.0 2.9.0 7.4")

redhat_release_version=$(grep -E -o '[0-9]+.[0-9]+' "${RISU_ROOT}/etc/redhat-release")

if [[ "x$RISU_LIVE" == "x0" ]]; then
    FILE="${RISU_ROOT}/uname"
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    uname -a >${FILE}
fi

is_required_file "$FILE"
kernel_version=$(cut -d" " -f3 "$FILE" | sed -r 's/(^([0-9]+\.){2}[0-9]+-[0-9]+).*$/\1/')

qemu_version=$(is_rpm qemu-kvm-rhev | sed -r 's/^[a-z-]*([0-9]\.[0-9]\.[0-9]).*$/\1/')
libvirt_version=$(is_rpm libvirt-daemon | sed -r 's/^[a-z-]*([0-9]\.[0-9]\.[0-9]).*$/\1/')

version="${kernel_libvirt_qemu[$kernel_version]}"
libvirt=$(echo "$version" | cut -d" " -f1)
qemu=$(echo "$version" | cut -d" " -f2)
redhat_release=$(echo "$version" | cut -d" " -f3)

if [[ $libvirt == "$libvirt_version" && $qemu == "$qemu_version" &&
    $redhat_release == "$redhat_release_version" ]]; then
    echo $"compatibility between libvirt, qemu and kernel" >&2
    exit ${RC_OKAY}
else
    echo $"detected running kernel: $kernel_version" >&2
    echo $"libvirt:  $libvirt_version expected $libvirt" >&2
    echo $"qemu-kvm: $qemu_version expected $qemu" >&2
    echo $"redhat-release: $redhat_release_version expected $redhat_release" >&2
    exit ${RC_FAILED}
fi
