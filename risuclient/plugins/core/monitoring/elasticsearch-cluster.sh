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

# long_name: Elasticsearch cluster health validation
# description: Checks Elasticsearch cluster health and configuration
# priority: 350

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Only run on live systems for API checks
if [[ "x$RISU_LIVE" != "x1" ]]; then
    echo "This plugin only runs on live systems" >&2
    exit ${RC_SKIPPED}
fi

# Check if curl is available
is_required_command curl

# Common Elasticsearch endpoints
ES_ENDPOINTS=(
    "http://localhost:9200"
    "http://127.0.0.1:9200"
    "https://localhost:9200"
)

flag=0
es_available=false

for endpoint in "${ES_ENDPOINTS[@]}"; do
    if curl -s --max-time 5 --connect-timeout 3 "$endpoint" >/dev/null 2>&1; then
        es_available=true
        echo "Elasticsearch available at: $endpoint" >&2

        # Check cluster health
        health=$(curl -s --max-time 10 "$endpoint/_cluster/health" 2>/dev/null)
        if [[ -n $health ]]; then
            status=$(echo "$health" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
            echo "Cluster status: $status" >&2

            if [[ $status == "red" ]]; then
                echo "Cluster status is RED - critical issue" >&2
                flag=1
            elif [[ $status == "yellow" ]]; then
                echo "Cluster status is YELLOW - warning" >&2
            fi

            # Check node count
            nodes=$(echo "$health" | grep -o '"number_of_nodes":[0-9]*' | cut -d':' -f2)
            echo "Number of nodes: $nodes" >&2

            if [[ $nodes -lt 3 ]]; then
                echo "Less than 3 nodes in cluster - no high availability" >&2
            fi
        fi

        # Check indices
        indices=$(curl -s --max-time 10 "$endpoint/_cat/indices?v" 2>/dev/null)
        if [[ -n $indices ]]; then
            red_indices=$(echo "$indices" | grep -c "red")
            if [[ $red_indices -gt 0 ]]; then
                echo "Found $red_indices red indices" >&2
                flag=1
            fi
        fi

        # Check shards
        shards=$(curl -s --max-time 10 "$endpoint/_cat/shards?v" 2>/dev/null)
        if [[ -n $shards ]]; then
            unassigned_shards=$(echo "$shards" | grep -c "UNASSIGNED")
            if [[ $unassigned_shards -gt 0 ]]; then
                echo "Found $unassigned_shards unassigned shards" >&2
                flag=1
            fi
        fi

        # Check disk usage
        disk_usage=$(curl -s --max-time 10 "$endpoint/_cat/allocation?v" 2>/dev/null)
        if [[ -n $disk_usage ]]; then
            echo "Disk usage information retrieved" >&2
            high_disk_usage=$(echo "$disk_usage" | awk 'NR>1 && $4 > 85 {print $1, $4}')
            if [[ -n $high_disk_usage ]]; then
                echo "High disk usage detected on nodes: $high_disk_usage" >&2
                flag=1
            fi
        fi

        break
    fi
done

if [[ $es_available == "false" ]]; then
    echo "Elasticsearch not available on common endpoints" >&2
    exit ${RC_SKIPPED}
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
