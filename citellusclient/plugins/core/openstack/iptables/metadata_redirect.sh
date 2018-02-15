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

# we can run this against fs snapshot or live system

# long_name: Undercloud metadata server redirection
# description: Checks for iptables rules to allow instances to reach metadata server
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ -z $(is_rpm tripleo-heat-templates  > /dev/null 2>&1) && -z $(is_rpm python-tripleoclient  > /dev/null 2>&1) ]]; then
    echo "works on director node only" >&2
    exit ${RC_SKIPPED}
fi

if [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if iptables -t nat -vnL | grep -q "REDIRECT.*169.254.169.254" ; then
        exit ${RC_OKAY}
    else
        exit ${RC_FAILED}
    fi
elif [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    is_required_file "${CITELLUS_ROOT}/sos_commands/networking/iptables_-t_nat_-nvL"
    if grep -q "REDIRECT.*169.254.169.254" "${CITELLUS_ROOT}/sos_commands/networking/iptables_-t_nat_-nvL" ; then
        exit ${RC_OKAY}
    else
        echo $"No iptables rule defined for metadata access"
        exit ${RC_FAILED}
    fi
fi
