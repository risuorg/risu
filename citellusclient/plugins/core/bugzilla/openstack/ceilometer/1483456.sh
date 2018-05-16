#!/bin/bash

# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Mismatch between nova host and hostname
# description: Checks missconfigured host in nova vs hostname
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1483456
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if is_process nova-compute; then
    is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"

    if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
        HOST=$(hostname)
    elif [[ "x$CITELLUS_LIVE" = "x0" ]];  then
        is_required_file "${CITELLUS_ROOT}/hostname"
        HOST=$(cat "${CITELLUS_ROOT}/hostname")
    fi

    NOVAHOST=$(grep ^host.* "${CITELLUS_ROOT}/etc/nova/nova.conf"|cut -d "=" -f2|tail -1)

    if [[ "$NOVAHOST" -eq "" ]]; then
        echo "nova.conf host= undefined" >&2
        exit ${RC_SKIPPED}
    fi

    if [[ "$HOST" != "$NOVAHOST" ]]; then
        echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1483456" >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
else
    echo "works only on compute node" >&2
    exit ${RC_SKIPPED}
fi
