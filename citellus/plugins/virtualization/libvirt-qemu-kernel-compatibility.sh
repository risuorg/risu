#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# description: Checks compatibility between libvirt, qemu and kernel packages

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system
# we know the exact kernel versions for RHEL7 from https://access.redhat.com/articles/3078

declare -A kernel_libvirt_qemu
kernel_libvirt_qemu=( ["3.10.0-123"]="1.1.1 1.5.3 7.0" \
                      ["3.10.0-229"]="1.2.8 2.1.2 7.1"\
                      ["3.10.0-327"]="1.2.17 2.3.0 7.2" \
                      ["3.10.0-514"]="2.0.0 2.6.0 7.3" \
                      ["3.10.0-693"]="3.2.0 2.9.0 7.4" )

redhat_release_version=$(egrep -o '[0-9]+.[0-9]+' "${CITELLUS_ROOT}/etc/redhat-release")

if [ "x$CITELLUS_LIVE" = "x1" ]; then
    kernel_version=$(uname -a | cut -d" " -f3 | sed -r 's/(^([0-9]+\.){2}[0-9]+-[0-9]+).*$/\1/')
elif [ "x$CITELLUS_LIVE" = "x0" ]; then
    kernel_version=$(cut -d" " -f3 "${CITELLUS_ROOT}/uname" | sed -r 's/(^([0-9]+\.){2}[0-9]+-[0-9]+).*$/\1/')
fi

is_required_file "${CITELLUS_ROOT}/uname"
is_required_file "${CITELLUS_ROOT}/installed-rpms"

qemu_version=$(is_rpm qemu-kvm-rhev | sed -r 's/^[a-z-]*([0-9]\.[0-9]\.[0-9]).*$/\1/')
libvirt_version=$(is_rpm libvirt | sed -r 's/^[a-z-]*([0-9]\.[0-9]\.[0-9]).*$/\1/')

version=("${kernel_libvirt_qemu[$kernel_version]}")
libvirt=$(echo "$version" | cut -d" " -f1)
qemu=$(echo "$version" | cut -d" " -f2)
redhat_release=$(echo "$version" | cut -d" " -f3)

if [[ "$libvirt" == "$libvirt_version" && "$qemu" == "$qemu_version" \
    && "$kernel" == "$kernel_version" && "$redhat_release" == "$redhat_release_version" ]]; then
    echo $"compatibility between libvirt, qemu and kernel" >&2
    exit $RC_OKAY
else
    echo $"detected kernel: $kernel_version" >&2
    echo $"libvirt:  $libvirt_version expected $libvirt" >&2
    echo $"qemu-kvm: $qemu_version expected $qemu" >&2
    echo $"redhat-release: $redhat_release_version expected $redhat_release" >&2
    exit $RC_FAILED
fi
