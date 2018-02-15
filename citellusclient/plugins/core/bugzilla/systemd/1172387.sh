#!/bin/bash

# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Libvirt instance start error
# description: This plugin checks libvirt affected of multiple instance start error
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1172387
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/messages"
is_required_rpm systemd

flag=0

if is_lineinfile "Did not receive a reply. Possible causes include: the remote application did not send a reply, the message bus security policy blocked the reply, the reply timeout expired, or the network connection was broken." "${CITELLUS_ROOT}/var/log/messages";then
    VERSION=$(is_rpm systemd)
    MAJOR=$(echo ${VERSION}|sed -n -r -e 's/.*-([0-9]+)-([0-9]+).*$/\1-\2/p'|cut -d "-" -f1)
    MINOR=$(echo ${VERSION}|sed -n -r -e 's/.*-([0-9]+)-([0-9]+).*$/\1-\2/p'|cut -d "-" -f2)

    # versions under systemd-219-1.el7 are affected
    if [[ ${MAJOR} -eq 219 ]];then
        if [[ ${MINOR} -lt 1 ]]; then
            flag=1
        fi
    elif [[ ${MAJOR} -lt 219 ]]; then
        flag=1
    fi
fi

if [[ ${flag} -eq 1 ]]; then
    echo $"systemd https://bugzilla.redhat.com/show_bug.cgi?id=1172387" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
