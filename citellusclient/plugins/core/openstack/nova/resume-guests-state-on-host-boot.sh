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

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: Resume guests on host restart
# description: Check if compute is configured to restore guests running after reboot
# priority: 100

# check if we are running against compute

if ! is_process nova-compute; then
    echo "works only on compute node" >&2
    exit ${RC_SKIPPED}
fi

# this can run against live and also any sort of snapshot of the filesystem
config_files=( "${CITELLUS_ROOT}/etc/nova/nova.conf" "${CITELLUS_ROOT}/etc/sysconfig/libvirt-guests" )

is_required_file ${config_files[@]}

# check if nova is configured to resume guests power state at hypervisor startup
# adapted from https://github.com/citellusorg/citellus/issues/59

LIBVIRTCONF="${CITELLUS_ROOT}/etc/sysconfig/libvirt-guests"
NOVACONF="${CITELLUS_ROOT}/etc/nova/nova.conf"

LIBVIRTBOOT=$(awk -F "=" '/^ON_BOOT/ {gsub (" ", "", $0); print tolower($2)}' ${LIBVIRTCONF})
LIBVIRTOFF=$(awk -F "=" '/^ON_SHUTDOWN/ {gsub (" ", "", $0); print tolower($2)}' ${LIBVIRTCONF})
NOVASTRING=$(awk -F "=" '/^resume_guests_state_on_host_boot/ {gsub (" ", "", $0); print tolower($2)}' ${NOVACONF})

if is_enabled libvirt-guests; then
    LIBVIRTGUESTS="true"
fi

if [[ "$LIBVIRTBOOT" == "ignore" && "$LIBVIRTOFF" == "shutdown" && "$NOVASTRING" == "true" && "$LIBVIRTGUESTS" == "true" ]]; then
    echo $"compute node is configured to restore guests state at startup" >&2
    exit ${RC_OKAY}
else
    echo $"compute node is NOT configured to restore guests state at startup" >&2
    exit ${RC_FAILED}
fi
