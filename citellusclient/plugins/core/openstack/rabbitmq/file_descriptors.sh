#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# we can run this on fs snapshot or live system

# long_name: RabbitMQ File descriptors
# description: Check File Descriptors in RabbitMQ

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if is_process nova-compute;then
        echo "works only on controller node" >&2
        exit ${RC_SKIPPED}
fi

# Setup the file we'll be using for using similar approach on Live and non-live

if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
    which rabbitmqctl > /dev/null 2>&1
    RC=$?
    if [[ "x$RC" != "x0" ]]; then
        echo "rabbitmqctl not found" >&2
        exit ${RC_SKIPPED}
    fi
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT

    rabbitmqctl report > ${FILE}
    HN=${HOSTNAME}

elif [[ "x$CITELLUS_LIVE" = "x0" ]];then
    FILE="${CITELLUS_ROOT}/sos_commands/rabbitmq/rabbitmqctl_report"
    is_required_file ${FILE}
    HN=$(cat ${CITELLUS_ROOT}/hostname)
fi

if grep -q nodedown "${FILE}"; then
    echo "rabbitmq down" >&2
    exit ${RC_FAILED}
fi

FILE_DESCRIPTORS=$(awk -v target="$HN" '$4 ~ target { flag = 1 } \
flag = 1 && /total_limit/ { print ; exit }' \
"${FILE}" | egrep -o '[0-9]+')

USED_FILE_DESCRIPTORS=$(awk -v target="$HN" '$4 ~ target { flag = 1 } \
flag = 1 && /total_used/ { print ; exit }' \
"${FILE}" | egrep -o '[0-9]+')

if [[ -z ${FILE_DESCRIPTORS} ]]; then
    echo "couldn't get file descriptors from rabbitmqctl report" >&2
    exit ${RC_FAILED}
fi

if [[ -z ${USED_FILE_DESCRIPTORS} ]]; then
    echo "couldn't get used file descriptors from rabbitmqctl report" >&2
    exit ${RC_FAILED}
fi

if [[ "${FILE_DESCRIPTORS}" -lt  "65336" ]]; then
    echo "total ${FILE_DESCRIPTORS}" >&2
    flag=1
fi

AVAILABLE_FILE_DESCRIPTORS=$(( FILE_DESCRIPTORS - USED_FILE_DESCRIPTORS ))

if [[ "${AVAILABLE_FILE_DESCRIPTORS}" -lt "16000" ]]; then
    echo "total_used ${USED_FILE_DESCRIPTORS}" >&2
    echo "available ${AVAILABLE_FILE_DESCRIPTORS}" >&2
    flag=1
fi

[[ "x$flag" = "x" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
