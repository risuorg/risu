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

is_rpm() {
    if [ "x$RISU_LIVE" = "x1" ]; then
        rpm -qa *$1* | egrep ^"$1"-[0-9]
    elif [ "x$RISU_LIVE" = "x0" ]; then
        is_required_file "${RISU_ROOT}/installed-rpms"
        awk '{print $1}' "${RISU_ROOT}/installed-rpms" | egrep ^"$1"-[0-9]
    fi
}

is_required_rpm() {
    if [ "x$(discover_os)" != "xfedora" ]; then
        echo "Not running on RHEL family" >&2
        exit ${RC_FAILED}
    fi
    is_required_pkg $1
}

is_rpm_over() {
    if [ "x$(discover_os)" != "xfedora" ]; then
        echo "Not running on RHEL family" >&2
        exit ${RC_FAILED}
    fi

    is_pkg_over $*
}

is_required_rpm_over() {
    if [ "x$(discover_os)" != "xfedora" ]; then
        echo "Not running on RHEL family" >&2
        exit ${RC_FAILED}
    fi

    is_required_pkg_over $*
}
