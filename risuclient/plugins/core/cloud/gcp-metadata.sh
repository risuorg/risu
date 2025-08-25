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

# long_name: GCP Compute Engine metadata service availability
# description: Checks if GCP Compute Engine metadata service is accessible and responsive
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

# Test GCP metadata service availability
if curl -s --max-time 5 --connect-timeout 3 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/name" >/dev/null 2>&1; then
    instance_name=$(curl -s --max-time 5 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/name")
    machine_type=$(curl -s --max-time 5 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/machine-type")
    zone=$(curl -s --max-time 5 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone")

    echo "GCP metadata service accessible" >&2
    echo "Instance Name: $instance_name" >&2
    echo "Machine Type: ${machine_type##*/}" >&2
    echo "Zone: ${zone##*/}" >&2

    # Check service account
    if curl -s --max-time 5 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/" >/dev/null 2>&1; then
        service_account=$(curl -s --max-time 5 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email")
        echo "Service Account: $service_account" >&2
    else
        echo "No service account configured" >&2
    fi

    exit ${RC_OKAY}
else
    echo "Not running on GCP Compute Engine or metadata service unreachable" >&2
    exit ${RC_SKIPPED}
fi
