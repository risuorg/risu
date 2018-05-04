#!/bin/bash

# Copyright (C) 2017  Shatadru Bandyopadhyay (sbandyop@redhat.com)

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

# long_name: multipath failed/faulty/offline path detector
# description: This plugin checks multipath related issues
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_rpm device-mapper-multipath
is_required_file "${CITELLUS_ROOT}/etc/multipath.conf"
if is_enabled multipathd && ! is_active multipath ; then
    echo $"multipathd is enabled but not running, path failover will not work!" >&2
    flag=1
    if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
        echo $"multipathd status:"  >&2
        systemctl status multipathd  >&2
    else
        echo $"Check #systemctl status multipathd *or* journalctl -xe"  >&2
    fi
fi


if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    is_required_file "${CITELLUS_ROOT}/sos_commands/multipath/multipath_-v4_-ll"
    mpath_stat=$(egrep "failed|faulty|offline" ${CITELLUS_ROOT}/sos_commands/multipath/multipath_-v4_-ll )
elif [[ "x$CITELLUS_LIVE" = "x1" ]];  then
    mpath_stat=$(multipath -v4 -ll| egrep "failed|faulty|offline")
fi

if [[ ! -z "$mpath_stat" ]]; then
    flag=1
    echo $"faulty/failed/offline paths:" >&2
    echo "$mpath_stat"  >&2
fi
if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
