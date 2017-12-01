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

kernel7=( "3.10.0-123" "3.10.0-229" "3.10.0-327" "3.10.0-514" "3.10.0-693" )

declare -A kernel_libvirt_qemu
kernel_libvirt_qemu=( ["3.10.0-123"]="1.1.1 1.5.3" \
                      ["3.10.0-229"]="1.2.8 2.1.2"\
                      ["3.10.0-327"]="1.2.17 2.3.0" \
                      ["3.10.0-514"]="2.0.0 2.6.0" \
                      ["3.10.0-693"]="3.2.0 2.9.0" )

kernel_version=$(cut -d" " -f3 "${CITELLUS_ROOT}/uname" | sed -r 's/(^([0-9]+\.){2}[0-9]+-[0-9]+).*$/\1/')
qemu_version=$(is_rpm qemu-kvm-rhev | sed -r 's/^[a-z-]*([0-9]\.[0-9]\.[0-9]).*$/\1/')
libvirt_version=$(is_rpm libvirt | sed -r 's/^[a-z-]*([0-9]\.[0-9]\.[0-9]).*$/\1/')

for kernel in "${kernel7[@]}"; do
    if [[ $kernel == $kernel_version ]]; then
        version=("${kernel_libvirt_qemu[$kernel]}")
        libvirt=$(echo "$version" | cut -d" " -f1)
        qemu=$(echo "$version" | cut -d" " -f2)
        if [[ "$libvirt" == "$libvirt_version" && "$qemu" == "$qemu_version" && "$kernel" == "$kernel_version" ]]; then
            echo $"compatibility between libvirt, qemu and kernel" >&2
            exit $RC_OKAY
        else
            echo $"detected kernel: $kernel_version" >&2
            echo $"libvirt:  $libvirt_version expected $libvirt" >&2
            echo $"qemu-kvm: $qemu_version expected $qemu" >&2
            exit $RC_FAILED
        fi
    fi
done
