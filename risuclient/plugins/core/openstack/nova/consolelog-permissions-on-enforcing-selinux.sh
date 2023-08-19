#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: SELinux console.log permission
# description: Checks for SELinux errors on console.log access on computes
# priority: 400
# kb: https://access.redhat.com/solutions/3215031 , https://access.redhat.com/solutions/3175381

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# check if we are running against compute

if is_process nova-compute; then
    echo "works only on controller node" >&2
    exit ${RC_SKIPPED}
fi

# Exit if not OSP node
is_required_rpm openstack-nova-common

MESSAGE=$"AVC denial for console.log: https://bugzilla.redhat.com/show_bug.cgi?id=1501957 https://bugzilla.redhat.com/show_bug.cgi?id=1491767"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    if [[ -z ${journalctl_file} ]]; then
        echo "file /sos_commands/logs/journalctl_--no-pager_--boot not found." >&2
        echo "file /sos_commands/logs/journalctl_--all_--this-boot_--no-pager not found." >&2
        exit ${RC_SKIPPED}
    fi
    is_lineinfile '.*avc:.*denied.*unlink.*virtlogd.*name="console.log".*' ${journalctl_file} && echo "$MESSAGE" >&2 && exit ${RC_FAILED}
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    if journalctl --no-pager --boot | grep -qe '.*avc:.*denied.*unlink.*virtlogd.*name="console.log".*'; then
        echo "$MESSAGE" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
