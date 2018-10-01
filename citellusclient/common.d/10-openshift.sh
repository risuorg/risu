#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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

# Helper script to define location of various files.

discover_ocp_version(){
    if is_rpm atomic-openshift >/dev/null 2>&1; then
        RPMINSTALLED=$(is_rpm atomic-openshift)
        VERSION=$(echo ${RPMINSTALLED}|cut -d "-" -f 3|cut -d "." -f 1-2)
    else
        if is_rpm atomic-openshift-node >/dev/null 2>&1; then
            RPMINSTALLED=$(is_rpm atomic-openshift-node)
            VERSION=$(echo ${RPMINSTALLED}|cut -d "-" -f 4|cut -d "." -f 1-2)
        else
            VERSION="0"
        fi
    fi
    echo ${VERSION}
}
