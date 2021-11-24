#!/usr/bin/env bash
# Description: This script contains common functions to be used by risu plugins
#
# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
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

is_pkg() {
    OSVERSION=$(discover_os)
    if [ "${OSVERSION}" = "fedora" ]; then
        is_rpm $*
    elif [ "${OSVERSION}" = "debian" ]; then
        is_dpkg $*
    fi
}

is_required_pkg() {
    if ! is_pkg $1 >/dev/null 2>&1; then
        echo "required package $1 not found." >&2
        exit ${RC_SKIPPED}
    fi
}

is_pkg_over() {
    is_required_pkg $1
    VERSION=$(is_pkg $1 | sort -V | tail -1)
    LATEST=$(echo ${VERSION} $2 | tr " " "\n" | sort -V | tail -1)

    if [ "$(echo ${VERSION} $2 | tr " " "\n" | sort -V | uniq | wc -l)" == "1" ]; then
        # Version and $2 are the same (only one line, so we're on latest)
        return 0
    fi

    if [ "$VERSION" != "$LATEST" ]; then
        # "package $1 version $VERSION is lower than required ($2)."
        return 1
    fi
    return 0
}

is_required_pkg_over() {
    is_required_pkg $1
    VERSION=$(is_pkg $1 2>&1 | sort -V | tail -1)
    if ! is_pkg_over "${@}"; then
        echo "package $1 version $VERSION is lower than required ($2)." >&2
        exit ${RC_SKIPPED}
    fi
}
