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

# long_name: Debian Stretch doesn't support FTP sources
# description: Debian hosted mirrors will not provide ftp server
# priority: 200
# kb: https://www.debian.org/releases/stretch/amd64/release-notes/ch-information.en.html#deprecation-of-ftp-apt-mirrors

OS=$(discover_os)

if [[ $OS != "debian" ]]; then
    echo "Non Debian system" >&2
    exit ${RC_SKIPPED}
else
    is_required_file ${RISU_ROOT}/etc/apt/sources.list
    if is_lineinfile "^deb ftp:.*debian.org" "${RISU_ROOT}/etc/apt/sources.list"; then
        echo $"Debian Stretch (9) doesn't provide FTP services for packages, update your sources.list" >&2
        echo $"https://www.debian.org/releases/stretch/amd64/release-notes/ch-information.en.html#deprecation-of-ftp-apt-mirrors" >&2
        exit ${RC_FAILED}
    fi
fi
exit ${RC_OKAY}
