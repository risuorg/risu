#!/bin/bash

# Copyright (C) 2017 David Vallee Delisle (dvd@redhat.com)

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

# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1450223
#            https://bugs.launchpad.net/neutron/+bug/1589746

# long_name: Traceback from python-ryu package
# description: Checks python-ryu tracebacks
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1450223
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_rpm python-ryu || echo "no python-ryu package installed" >&2 &&  exit ${RC_SKIPPED}

# Extracting python-ryu's version
CITELLUS_PYTHON_RYU_VERSION=$(is_rpm python-ryu | grep -Po "python-ryu-\K[0-9\.]+")

CITELLUS_PYTHON_RYU_VERSION_VALIDATE=$(echo ${CITELLUS_PYTHON_RYU_VERSION}'<4.9' | bc -l)
if [[ ${CITELLUS_PYTHON_RYU_VERSION_VALIDATE} -lt 1 ]]; then
    echo "python-ryu version is $CITELLUS_PYTHON_RYU_VERSION >= 4.9" >&2
    exit ${RC_SKIPPED}
fi

is_required_file "${CITELLUS_ROOT}/var/log/neutron/openvswitch-agent.log"

# Here we look for a traceback from python-ryu with the KeyError message no more than 10 lines below
grep -Pzo "(?s)ERROR[\s]+ryu.lib.hub\N*Traceback\N*(\n\N*){2,10}KeyError: 'ofctl_service'" "${CITELLUS_ROOT}/var/log/neutron/openvswitch-agent.log" && echo $"possible python-ryu bug in ovs-agent https://bugzilla.redhat.com/show_bug.cgi?id=1450223" >&2 && exit ${RC_FAILED}

exit ${RC_OKAY}
