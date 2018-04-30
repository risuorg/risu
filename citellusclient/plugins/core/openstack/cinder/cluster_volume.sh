#!/bin/bash
# Copyright (C) 2018   David Vallee Delisle (dvd@redhat.com)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: CinderVolume Cluster
# description: Checks if cinder-volume is started with systemd or pacemaker
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"


if is_process nova-compute; then
    echo "works only on controller node" >&2
    exit ${RC_SKIPPED}
fi
PATTERN="openstack-cinder-volume.service.*running[\s]+OpenStack Cinder Volume Server"
ERROR_MSG="openstack-cinder-volume service was started with systemd, not PCS"
MSG="cinder-volume is not started with systemd"
RC=${RC_OKAY}
if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    FILE=${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units
    is_required_file ${FILE}
    RC=${RC_OKAY}
    if grep -P "${PATTERN}" ${FILE};then
        MSG="${ERROR_MSG}"
        RC=${RC_FAILED}
    fi
else
    if systemctl list-units | grep -P "${PATTERN}"; then
        MSG="${ERROR_MSG}"
        RC=${RC_FAILED}
    fi
fi
echo $MSG >&2
exit ${RC}
