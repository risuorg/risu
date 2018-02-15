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

# this can run against live only as we don't collect /usr/share

# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1519057

# long_name: Keystone LDAP Domain integration
# description: Checks for keystone LDAP domain template problem
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1519057
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    echo "works on live-system only" >&2
    exit ${RC_SKIPPED}
fi

# Find release
RELEASE=$(discover_osp_version)

if [[ "${RELEASE}" -ge "12" ]]; then

    if [[ -z $(is_rpm tripleo-heat-templates) && -z $(is_rpm python-tripleoclient) ]]; then
        echo "works on director node only" >&2
        exit ${RC_SKIPPED}
    fi

    FILE="/usr/share/openstack-tripleo-heat-templates/docker/services/keystone.yaml"
    is_required_file ${FILE}

    RC=${RC_OKAY}

    COUNT=$(awk '/config_volume: keystone/ { getline; print $0}' ${FILE} | grep -c keystone_domain_config)
    if [[ ${COUNT} -eq 0 ]]; then
        echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1519057" >&2
        RC=${RC_FAILED}
    fi

    exit ${RC}
else
    echo "works only on OSP12 and later" >&2
    exit ${RC_SKIPPED}
fi
