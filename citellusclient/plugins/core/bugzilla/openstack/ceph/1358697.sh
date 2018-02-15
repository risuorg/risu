#!/bin/bash

# Copyright (C) 2017 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Old Ceph packages
# description: Checks for outdated ceph packages
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1358697
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
    VERSIONS=$(rpm -qa ceph-common* python-rbd* librados2* python-rados* | sed -n -r -e 's/.*-0.([0-9]+).([0-9]+)-([0-9]+).*$/\1-\2-\3/p')
elif [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    is_required_file "${CITELLUS_ROOT}/installed-rpms"
    VERSIONS=$(egrep 'ceph-common|python-rbd|librados2|python-rados' "${CITELLUS_ROOT}/installed-rpms"|awk '{print $1}'|sed -n -r -e 's/.*-0.([0-9]+).([0-9]+)-([0-9]+).*$/\1-\2-\3/p')
fi

exitoudated(){
    echo $"outdated ceph packages: https://bugzilla.redhat.com/show_bug.cgi?id=1358697" >&2
    exit ${RC_FAILED}
}


if [[ "x$VERSIONS" = "x" ]]; then
    echo "required packages not found" >&2
    exit ${RC_SKIPPED}
else
    # Affected versions are lower than ceph-0.94.5-15
    for package in ${VERSIONS}; do
        MAJOR=$(echo ${package}|cut -d "-" -f1)
        MID=$(echo ${package}|cut -d "-" -f2)
        MINOR=$(echo ${package}|cut -d "-" -f3)
        if [[ "${MAJOR}" -ge "94" ]]; then
            if [[ "${MID}" -ge "5" ]]; then
                if [[ "${MINOR}" -lt "15" ]]; then
                    exitoudated
                fi
            else
                exitoudated
            fi
        else
            exitoudated
        fi
    done
    exit ${RC_OKAY}
fi
