#!/bin/bash

# Copyright (C) 2018 Robin Černín <rcernin@redhat.com>

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

# long_name: Finds matches of blk_update_request: critical target error
# description: Finds matches of error blk_update_request: critical target error

REGEXP="blk_update_request: critical target error"

# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    journal="$journalctl_file"
else
    journal="$(mktemp)"
    trap "/bin/rm ${journal}" EXIT
    journalctl -t systemd --no-pager --boot > ${journal}
fi

if is_lineinfile "${REGEXP}" ${journal} ${CITELLUS_ROOT}/var/log/messages ; then
    events=$(grep -i "${REGEXP}" ${log_file} | egrep -o '^([a-Z]+\ [0-9]+)|^([0-9\-]+)' | uniq -c | tail)
    if [[ -n "${events}" ]]; then
        # to remove the ${CITELLUS_ROOT} from the stderr.
        echo -e "${events}\n" >&2
        exit ${RC_FAILED}
    fi
else
    exit ${RC_OKAY}
fi

