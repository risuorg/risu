#!/bin/bash

# Copyright (C) 2018   Martin Schuppert (mschuppert@redhat.com)

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

# long_name: RabbitMQ queues with no consumer
# description: Check rabbitmq queues with no consumers but messages

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

# get queue section from rabbitmq report +
# check if we have queues with no consumer $11 +
# AND message count > 0 $10
QUEUES_WITH_NO_MSG=$(sed -n '/^Queues/,/^Exchanges/p' "${FILE}" | \
awk '$11 == 0 && $10 > 0 { print $2" "$10" "$11; }')

if [[ -n ${QUEUES_WITH_NO_MSG} ]]; then
    echo "queue with no consumer found!" >&2
    echo "queue / messages / consumer" >&2
    echo "${QUEUES_WITH_NO_MSG}" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
