#!/bin/bash
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
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

# long_name: Checks for OSP repos not for current version
# description: Checks for OSP repos not for current version
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check if we are running against compute
OSPRELEASE=$(discover_osp_version)

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/yum/yum_-C_repolist "
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    yum -C repolist > ${FILE} 2>&1
fi

is_required_file ${FILE}

# Check if we do have repos for openstack that are not for our current release
REPOS=$(cat ${FILE}|grep openstack|awk '{print $1}'|grep -v ${OSPRELEASE})

if [[ ! -z ${REPOS} ]]; then
    echo "Non current OSP repos detected:" >&2
    echo ${REPOS} >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
