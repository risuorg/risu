#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: Verify preallocate images setting in nova.conf
# description: Verify preallocate images setting
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1554265
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"

imagetype="$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" libvirt images_type)"

if [[ "x${imagetype}" == "x" ]]; then
    imagetype="default"
elif [[ "x${imagetype}" == "xqcow2" ]]; then
    imagetype="default"
fi

cowimages="$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" DEFAULT use_cow_images)"

if [[ "x${cowimages}" == "x" ]]; then
    cowimages='true'
elif [[ "x${cowimages}" == "xqcow2" ]]; then
    cowimages='true'
fi

# If imagetype == default, we do use cow_images (other options, raw, qcow2, lvm, rbd)
# If cowimages == true we might be affected

allocation="$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" DEFAULT preallocate_images)"

if [[ "${allocation}" == 'space' ]]; then
    if [[ "${imagetype}" == "default" ]]; then
        if [[ "${cowimages}" == "true" ]]; then
            echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1554265" >&2
            exit ${RC_FAILED}
        else
            exit ${RC_OKAY}
        fi
    else
        exit ${RC_OKAY}
    fi
else
    exit ${RC_OKAY}
fi

