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

# long_name: NATS streaming server configuration validation
# description: Validates NATS streaming server configuration and checks for common issues
# priority: 550

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for nats config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/nats /opt/nats -name "nats.conf" -o -name "nats-server.conf" 2>/dev/null)
    stan_config_files=$(find /etc/nats /opt/nats -name "nats-streaming.conf" -o -name "stan.conf" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/nats" "${RISU_ROOT}/opt/nats" -name "nats.conf" -o -name "nats-server.conf" 2>/dev/null)
    stan_config_files=$(find "${RISU_ROOT}/etc/nats" "${RISU_ROOT}/opt/nats" -name "nats-streaming.conf" -o -name "stan.conf" 2>/dev/null)
fi

if [[ -z $config_files && -z $stan_config_files ]]; then
    echo "No NATS configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

# Check NATS server configuration
for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking NATS config: $config_file" >&2

    # Check port configuration
    if grep -q "^port:" "$config_file"; then
        port=$(grep "^port:" "$config_file" | awk '{print $2}')
        echo "NATS port set to: $port in config: $config_file" >&2
    fi

    # Check host configuration
    if grep -q "^host:" "$config_file"; then
        host=$(grep "^host:" "$config_file" | awk '{print $2}')
        echo "NATS host set to: $host in config: $config_file" >&2
    fi

    # Check authentication
    if grep -q "^authorization:" "$config_file"; then
        echo "Authorization configured in NATS config: $config_file" >&2
    else
        echo "No authorization configured in NATS config: $config_file" >&2
    fi

    # Check TLS configuration
    if grep -q "^tls:" "$config_file"; then
        echo "TLS configured in NATS config: $config_file" >&2
    else
        echo "No TLS configured in NATS config: $config_file" >&2
    fi

    # Check cluster configuration
    if grep -q "^cluster:" "$config_file"; then
        echo "Cluster configuration found in NATS config: $config_file" >&2

        # Check cluster port
        if grep -A 10 "^cluster:" "$config_file" | grep -q "port:"; then
            cluster_port=$(grep -A 10 "^cluster:" "$config_file" | grep "port:" | awk '{print $2}')
            echo "Cluster port set to: $cluster_port in NATS config: $config_file" >&2
        fi

        # Check routes
        if grep -A 10 "^cluster:" "$config_file" | grep -q "routes:"; then
            echo "Cluster routes configured in NATS config: $config_file" >&2
        fi
    else
        echo "No cluster configuration in NATS config: $config_file" >&2
    fi

    # Check logging
    if grep -q "^log_file:" "$config_file"; then
        log_file=$(grep "^log_file:" "$config_file" | awk '{print $2}')
        echo "Log file set to: $log_file in NATS config: $config_file" >&2
    fi

    # Check debug and trace
    if grep -q "^debug:" "$config_file"; then
        debug=$(grep "^debug:" "$config_file" | awk '{print $2}')
        echo "Debug set to: $debug in NATS config: $config_file" >&2
    fi

    if grep -q "^trace:" "$config_file"; then
        trace=$(grep "^trace:" "$config_file" | awk '{print $2}')
        echo "Trace set to: $trace in NATS config: $config_file" >&2
    fi

    # Check max connections
    if grep -q "^max_connections:" "$config_file"; then
        max_conn=$(grep "^max_connections:" "$config_file" | awk '{print $2}')
        echo "Max connections set to: $max_conn in NATS config: $config_file" >&2
    fi

    # Check max payload
    if grep -q "^max_payload:" "$config_file"; then
        max_payload=$(grep "^max_payload:" "$config_file" | awk '{print $2}')
        echo "Max payload set to: $max_payload in NATS config: $config_file" >&2
    fi
done

# Check NATS Streaming configuration
for stan_config in $stan_config_files; do
    if [[ ! -f $stan_config ]]; then
        continue
    fi

    echo "Checking NATS Streaming config: $stan_config" >&2

    # Check cluster ID
    if grep -q "^cluster_id:" "$stan_config"; then
        cluster_id=$(grep "^cluster_id:" "$stan_config" | awk '{print $2}')
        echo "Cluster ID set to: $cluster_id in NATS Streaming config: $stan_config" >&2
    fi

    # Check store type
    if grep -q "^store:" "$stan_config"; then
        store=$(grep "^store:" "$stan_config" | awk '{print $2}')
        echo "Store type set to: $store in NATS Streaming config: $stan_config" >&2
    fi

    # Check data directory
    if grep -q "^dir:" "$stan_config"; then
        dir=$(grep "^dir:" "$stan_config" | awk '{print $2}')
        echo "Data directory set to: $dir in NATS Streaming config: $stan_config" >&2
    fi

    # Check file store options
    if grep -q "^file_store:" "$stan_config"; then
        echo "File store options configured in NATS Streaming config: $stan_config" >&2
    fi

    # Check SQL store options
    if grep -q "^sql_store:" "$stan_config"; then
        echo "SQL store options configured in NATS Streaming config: $stan_config" >&2
    fi

    # Check clustering
    if grep -q "^clustering:" "$stan_config"; then
        echo "Clustering configured in NATS Streaming config: $stan_config" >&2
    fi
done

# Check NATS service on live systems
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if pgrep -f "nats-server" >/dev/null 2>&1; then
        echo "NATS server is running" >&2

        # Check NATS connectivity
        if command -v nats >/dev/null 2>&1; then
            if nats server ping >/dev/null 2>&1; then
                echo "NATS server is responding to ping" >&2
            else
                echo "NATS server not responding to ping" >&2
                flag=1
            fi
        fi
    else
        echo "NATS server is not running" >&2
    fi

    if pgrep -f "nats-streaming-server" >/dev/null 2>&1; then
        echo "NATS Streaming server is running" >&2
    else
        echo "NATS Streaming server is not running" >&2
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
