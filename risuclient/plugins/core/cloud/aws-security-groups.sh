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

# long_name: AWS Security Groups overly permissive rules
# description: Checks for security groups with overly permissive rules (0.0.0.0/0)
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Only run on live systems
if [[ "x$RISU_LIVE" != "x1" ]]; then
    echo "This plugin only runs on live systems" >&2
    exit ${RC_SKIPPED}
fi

# Check if aws CLI is available
is_required_command aws

# Check AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials not configured" >&2
    exit ${RC_SKIPPED}
fi

# Get security groups with overly permissive rules
flag=0
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName,IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]]' --output text 2>/dev/null | while IFS=$'\t' read -r group_id group_name permissions; do
    if [[ -n $permissions && $permissions != "None" ]]; then
        echo "Security group $group_id ($group_name) has overly permissive rules allowing 0.0.0.0/0" >&2
        flag=1
    fi
done

# Check for SSH access from anywhere
aws ec2 describe-security-groups --query 'SecurityGroups[?IpPermissions[?FromPort==`22` && IpRanges[?CidrIp==`0.0.0.0/0`]]].[GroupId,GroupName]' --output text 2>/dev/null | while IFS=$'\t' read -r group_id group_name; do
    if [[ -n $group_id ]]; then
        echo "Security group $group_id ($group_name) allows SSH (port 22) from anywhere" >&2
        flag=1
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
