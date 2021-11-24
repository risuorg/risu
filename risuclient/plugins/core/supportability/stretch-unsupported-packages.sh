#!/bin/bash

# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Report obsolete Debian Stretch packages
# description: Report obsolete Debian Stretch packages
# priority: 200
# kb: https://www.debian.org/releases/stretch/amd64/release-notes/ch-information.en.html#noteworthy-obsolete-packages

OS=$(discover_os)

if [[ $OS != "debian" ]]; then
    echo "Debian required" >&2
    exit ${RC_SKIPPED}
else
    echo $"The following installed packages have been deprecated as per release notes at https://www.debian.org/releases/stretch/amd64/release-notes/ch-information.en.html#noteworthy-obsolete-packages :" >&2
    flag=0
    for package in fpm2 kedpm nagios3 net-tools iscsitarget; do
        if is_pkg ${package} >&2; then
            flag=1
        fi
    done
    if [[ ${flag} == "1" ]]; then
        exit ${RC_FAILED}
    fi
fi
exit ${RC_OKAY}
