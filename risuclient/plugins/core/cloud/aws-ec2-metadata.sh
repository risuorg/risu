#!/bin/bash
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: AWS EC2 Instance Metadata Service availability
# description: Checks if EC2 instance metadata service is accessible and responsive
# priority: 70

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Only run on live systems
if [[ "x$RISU_LIVE" != "x1" ]]; then
    echo "This plugin only runs on live systems" >&2
    exit ${RC_SKIPPED}
fi

# Check if curl is available
is_required_command curl

# Test EC2 metadata service availability
if curl -s --max-time 5 --connect-timeout 3 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
    instance_id=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/instance-id)
    instance_type=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/instance-type)
    region=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/placement/region)

    echo "EC2 metadata service accessible" >&2
    echo "Instance ID: $instance_id" >&2
    echo "Instance Type: $instance_type" >&2
    echo "Region: $region" >&2

    # Check if IMDSv2 is enforced
    if curl -s --max-time 5 -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT http://169.254.169.254/latest/api/token >/dev/null 2>&1; then
        echo "IMDSv2 available" >&2
    else
        echo "IMDSv2 not available - security concern" >&2
        exit ${RC_FAILED}
    fi

    exit ${RC_OKAY}
else
    echo "Not running on AWS EC2 or metadata service unreachable" >&2
    exit ${RC_SKIPPED}
fi
