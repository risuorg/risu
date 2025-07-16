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

# long_name: Redis cluster configuration validation
# description: Validates Redis cluster configuration and checks for common issues
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for redis config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/redis /opt/redis -name "redis.conf" -o -name "redis-*.conf" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/redis" "${RISU_ROOT}/opt/redis" -name "redis.conf" -o -name "redis-*.conf" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No Redis configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking Redis config: $config_file" >&2

    # Check cluster mode
    if grep -q "^cluster-enabled yes" "$config_file"; then
        echo "Cluster mode enabled in Redis config: $config_file" >&2
        cluster_enabled=true
    else
        echo "Cluster mode not enabled in Redis config: $config_file" >&2
        cluster_enabled=false
    fi

    # Check cluster configuration file
    if [[ $cluster_enabled == "true" ]]; then
        if ! grep -q "^cluster-config-file" "$config_file"; then
            echo "Cluster config file not specified in Redis config: $config_file" >&2
            flag=1
        fi

        # Check cluster node timeout
        if ! grep -q "^cluster-node-timeout" "$config_file"; then
            echo "Cluster node timeout not configured in Redis config: $config_file" >&2
        fi

        # Check cluster require full coverage
        if grep -q "^cluster-require-full-coverage no" "$config_file"; then
            echo "Cluster require full coverage disabled in Redis config: $config_file" >&2
        fi
    fi

    # Check bind address
    if grep -q "^bind 127.0.0.1" "$config_file"; then
        echo "Redis bound to localhost only in config: $config_file" >&2
    elif grep -q "^bind 0.0.0.0" "$config_file"; then
        echo "Redis bound to all interfaces in config: $config_file" >&2
    fi

    # Check protected mode
    if grep -q "^protected-mode no" "$config_file"; then
        echo "Protected mode disabled in Redis config: $config_file" >&2
        flag=1
    fi

    # Check authentication
    if grep -q "^requirepass" "$config_file"; then
        echo "Password authentication configured in Redis config: $config_file" >&2
    else
        echo "No password authentication in Redis config: $config_file" >&2
    fi

    # Check persistence
    if grep -q "^save" "$config_file"; then
        echo "RDB persistence configured in Redis config: $config_file" >&2
    else
        echo "No RDB persistence configured in Redis config: $config_file" >&2
    fi

    if grep -q "^appendonly yes" "$config_file"; then
        echo "AOF persistence enabled in Redis config: $config_file" >&2
    else
        echo "AOF persistence not enabled in Redis config: $config_file" >&2
    fi

    # Check memory policy
    maxmemory_policy=$(grep "^maxmemory-policy" "$config_file" | awk '{print $2}')
    if [[ -n $maxmemory_policy ]]; then
        echo "Max memory policy set to: $maxmemory_policy in Redis config: $config_file" >&2
    fi

    # Check max memory
    maxmemory=$(grep "^maxmemory" "$config_file" | awk '{print $2}')
    if [[ -n $maxmemory ]]; then
        echo "Max memory set to: $maxmemory in Redis config: $config_file" >&2
    fi

    # Check TCP keepalive
    tcp_keepalive=$(grep "^tcp-keepalive" "$config_file" | awk '{print $2}')
    if [[ -n $tcp_keepalive ]]; then
        echo "TCP keepalive set to: $tcp_keepalive in Redis config: $config_file" >&2
    fi

    # Check timeout
    timeout=$(grep "^timeout" "$config_file" | awk '{print $2}')
    if [[ -n $timeout ]]; then
        echo "Timeout set to: $timeout in Redis config: $config_file" >&2
    fi

    # Check slowlog
    slowlog_time=$(grep "^slowlog-log-slower-than" "$config_file" | awk '{print $2}')
    if [[ -n $slowlog_time ]]; then
        echo "Slowlog time set to: $slowlog_time microseconds in Redis config: $config_file" >&2
    fi

    # Check client output buffer limits
    if grep -q "^client-output-buffer-limit" "$config_file"; then
        echo "Client output buffer limits configured in Redis config: $config_file" >&2
    fi
done

# Check Redis service on live systems
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if pgrep -f "redis-server" >/dev/null 2>&1; then
        echo "Redis service is running" >&2

        # Check Redis cluster status
        if command -v redis-cli >/dev/null 2>&1; then
            # Try to connect to Redis
            if redis-cli ping >/dev/null 2>&1; then
                echo "Redis is responding to ping" >&2

                # Check cluster info
                cluster_info=$(redis-cli cluster info 2>/dev/null)
                if [[ -n $cluster_info ]]; then
                    echo "Redis cluster info available" >&2

                    # Check cluster state
                    cluster_state=$(echo "$cluster_info" | grep "cluster_state:" | cut -d':' -f2)
                    if [[ $cluster_state == "ok" ]]; then
                        echo "Redis cluster state is OK" >&2
                    else
                        echo "Redis cluster state is not OK: $cluster_state" >&2
                        flag=1
                    fi

                    # Check cluster slots
                    cluster_slots=$(echo "$cluster_info" | grep "cluster_slots_assigned:" | cut -d':' -f2)
                    if [[ $cluster_slots == "16384" ]]; then
                        echo "All cluster slots assigned" >&2
                    else
                        echo "Not all cluster slots assigned: $cluster_slots/16384" >&2
                        flag=1
                    fi
                fi
            else
                echo "Redis not responding to ping" >&2
                flag=1
            fi
        fi
    else
        echo "Redis service is not running" >&2
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
