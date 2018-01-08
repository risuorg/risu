#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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


discover_rhrelease(){
    FILE="${CITELLUS_ROOT}/etc/redhat-release"
    is_required_file ${FILE}
    VERSION=$(cat ${FILE}|egrep -o "\(.*\)"|tr -d "()")
    case ${VERSION} in
        Maipo) echo 7 ;;
        Santiago) echo 6 ;;
        Tikanga) echo 5 ;;
        Nahant) echo 4 ;;
        Taroon) echo 3 ;;
        *) echo 0 ;;
    esac
}

