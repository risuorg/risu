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

# long_name: RabbitMQ node health
# description: Check RabbitMQ node health in container
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if is_process nova-compute;then
        echo "works only on controller node" >&2
        exit ${RC_SKIPPED}
fi

# Setup the file we'll be using for using similar approach on Live and non-live

is_required_containerized

if [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if docker_runit rabbitmq-bundle "rabbitmqctl node_health_check" 2>&1 | grep -q "Health check passed"; then
        echo $"no rabbitmq problems detected" >&2
        exit ${RC_OKAY}
    else
        echo $"rabbitmq problems detected" >&2
        exit ${RC_FAILED}
    fi
elif [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    # used to be ${CITELLUS_ROOT}/sos_commands/rabbitmq/rabbitmqctl_report"
    # missing now. Do nothing unless fixed.
    echo $"this info is not collected in containerized deployments" >&2
    exit ${RC_SKIPPED}
fi
