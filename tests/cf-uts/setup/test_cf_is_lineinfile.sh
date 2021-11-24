#!/usr/bin/env bash
# Description: This script creates a validation environment for running the
#              test named like this one against and check correct behavior
#
# Copyright (C) 2017, 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# The way we're executed, $1 is the script name, $2 is the mode and $3 is the folder
FOLDER=$3

case $2 in
pass)
    mkdir -p ${FOLDER}
    echo test-my-rpm-1.2.23.noarch >${FOLDER}/installed-rpms
    exit 0
    ;;

fail)
    mkdir -p ${FOLDER}
    echo >${FOLDER}/installed-rpms
    exit 0
    ;;

*)
    # Load common functions
    [ -f "${RISU_BASE}/common-functions.sh" ] && . "${RISU_BASE}/common-functions.sh"

    # When no pass or fail is passed we're running the test for common function
    is_lineinfile test-my-rpm "${RISU_ROOT}/installed-rpms" && exit ${RC_OKAY} || exit ${RC_FAILED}
    ;;
esac

exit ${RC_SKIPPED}
