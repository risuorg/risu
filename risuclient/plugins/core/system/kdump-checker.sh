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

# we can run this against fs snapshot or live system

# long_name: KDump configuration
# description: This plugin check kdump configuration
# priority: 100

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_rpm kexec-tools

if ! is_active kdump; then
    echo $"kdump is not running on this node" >&2
    exit ${RC_FAILED}
fi

is_required_file "${RISU_ROOT}/etc/kdump.conf"

grubs=("${RISU_ROOT}"/boot/grub2/grub.cfg
    "${RISU_ROOT}"/boot/grub/grub.conf
    "${RISU_ROOT}"/etc/grub2.cfg
    "${RISU_ROOT}"/etc/grub.conf
    "${RISU_ROOT}"/boot/efi/EFI/redhat/grub.cfg)

for f in "${grubs[@]}"; do
    [ -f "$f" ] && grub_conf="$f" && break
done
[ -z "$grub_conf" ] && echo "Could not locate grub configuration. Skipping" && exit ${RC_SKIPPED}

kdump_conf="${RISU_ROOT}/etc/kdump.conf"

if ! is_lineinfile "vmlinuz.*crashkernel=(auto|[0-9]+[mM]@[0-9]+*[mM]|[0-9]+*[mM])" ${grub_conf}; then
    echo $"missing crashkernel from kernel cmdline in grub configuration" >&2
    flag=1
fi
if ! is_lineinfile "^path" ${kdump_conf}; then
    echo $"missing path in kdump.conf" >&2
    flag=1
fi
if ! is_lineinfile "^core_collector" ${kdump_conf}; then
    echo $"missing core_collector in kdump.conf" >&2
    flag=1
fi

if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
