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

# long_name: Azure VM Instance Metadata Service availability
# description: Checks if Azure VM instance metadata service is accessible and responsive
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

# Test Azure metadata service availability
if curl -s --max-time 5 --connect-timeout 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" >/dev/null 2>&1; then
    metadata=$(curl -s --max-time 5 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01")

    vm_id=$(echo "$metadata" | grep -o '"vmId":"[^"]*' | cut -d'"' -f4)
    vm_size=$(echo "$metadata" | grep -o '"vmSize":"[^"]*' | cut -d'"' -f4)
    location=$(echo "$metadata" | grep -o '"location":"[^"]*' | cut -d'"' -f4)

    echo "Azure metadata service accessible" >&2
    echo "VM ID: $vm_id" >&2
    echo "VM Size: $vm_size" >&2
    echo "Location: $location" >&2

    # Check managed identity endpoint
    if curl -s --max-time 5 -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" >/dev/null 2>&1; then
        echo "Managed identity endpoint accessible" >&2
    else
        echo "Managed identity not configured" >&2
    fi

    exit ${RC_OKAY}
else
    echo "Not running on Azure VM or metadata service unreachable" >&2
    exit ${RC_SKIPPED}
fi
