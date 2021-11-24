#!/bin/bash

# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# This program is Free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Check Debian system Lifecycle status
# description: Checks Debian system Lifecycle status
# priority: 500
# kb: https://wiki.debian.org/es/DebianReleases

OS=$(discover_os)

declare -A DebianRD
DebianRD=(["8"]="2020-06-06")

if [[ $OS != "debian" ]]; then
    echo "Debian OS required" >&2
    exit ${RC_SKIPPED}
else
    DR=$(discover_release)
    if [[ ${DR} -lt 8 ]]; then
        echo $"Your Debian Release is already out of support phase: https://wiki.debian.org/es/DebianReleases" >&2
        exit ${RC_FAILED}
    else
        if is_date_over_today "${DebianRD[${DR}]}"; then
            exit ${RC_OKAY}
        else
            echo $"Your current Debian release is unsupported" >&2
            exit ${RC_FAILED}
        fi
    fi

fi
exit ${RC_OKAY}
