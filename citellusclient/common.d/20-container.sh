#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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

is_containerized(){
    RELEASE=$(discover_osp_version)
    [[ -d "${CITELLUS_ROOT}/var/log/containers" ]] && [[ -d "${CITELLUS_ROOT}/var/lib/config-data" ]]
}

is_required_containerized(){
    if ! is_containerized; then
        echo "the OSP${RELEASE} deployment seems to not be containerized" >&2
        exit ${RC_SKIPPED}
    fi
}

docker_runit(){
    # Run command in docker container
    # $1: container name
    # $2: command
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        if [[ -x "$(which docker)" ]]; then
            docker exec $(docker ps | grep "${1}" | cut -d" " -f1) sh -c "${@:2}"
        else
            echo "docker: command not found or executable" >&2
            exit ${RC_SKIPPED}
        fi
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        echo "docker: works only on live system" >&2
        exit ${RC_SKIPPED}
    fi
}
