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

# long_name: Apache ActiveMQ configuration validation
# description: Validates Apache ActiveMQ configuration files and checks for common issues
# priority: 550

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for activemq config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /opt/activemq /etc/activemq -name "activemq.xml" 2>/dev/null)
    jetty_files=$(find /opt/activemq /etc/activemq -name "jetty.xml" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/opt/activemq" "${RISU_ROOT}/etc/activemq" -name "activemq.xml" 2>/dev/null)
    jetty_files=$(find "${RISU_ROOT}/opt/activemq" "${RISU_ROOT}/etc/activemq" -name "jetty.xml" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No ActiveMQ configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking ActiveMQ config: $config_file" >&2

    # Check broker name
    if ! grep -q "brokerName=" "$config_file"; then
        echo "Broker name not configured in ActiveMQ config: $config_file" >&2
    fi

    # Check persistent store
    if ! grep -q "persistenceAdapter" "$config_file"; then
        echo "Persistence adapter not configured in ActiveMQ config: $config_file" >&2
        flag=1
    fi

    # Check memory usage
    if grep -q "memoryUsage limit=" "$config_file"; then
        memory_limit=$(grep "memoryUsage limit=" "$config_file" | sed 's/.*limit="\([^"]*\)".*/\1/')
        echo "Memory usage limit set to: $memory_limit in ActiveMQ config: $config_file" >&2
    else
        echo "Memory usage limit not configured in ActiveMQ config: $config_file" >&2
    fi

    # Check store usage
    if grep -q "storeUsage limit=" "$config_file"; then
        store_limit=$(grep "storeUsage limit=" "$config_file" | sed 's/.*limit="\([^"]*\)".*/\1/')
        echo "Store usage limit set to: $store_limit in ActiveMQ config: $config_file" >&2
    else
        echo "Store usage limit not configured in ActiveMQ config: $config_file" >&2
    fi

    # Check temp usage
    if grep -q "tempUsage limit=" "$config_file"; then
        temp_limit=$(grep "tempUsage limit=" "$config_file" | sed 's/.*limit="\([^"]*\)".*/\1/')
        echo "Temp usage limit set to: $temp_limit in ActiveMQ config: $config_file" >&2
    else
        echo "Temp usage limit not configured in ActiveMQ config: $config_file" >&2
    fi

    # Check transport connectors
    if ! grep -q "transportConnectors" "$config_file"; then
        echo "Transport connectors not configured in ActiveMQ config: $config_file" >&2
        flag=1
    fi

    # Check SSL configuration
    if grep -q "ssl://" "$config_file"; then
        echo "SSL transport configured in ActiveMQ config: $config_file" >&2
    fi

    # Check network connectors
    if grep -q "networkConnectors" "$config_file"; then
        echo "Network connectors configured in ActiveMQ config: $config_file" >&2
    fi

    # Check authorization
    if grep -q "authorizationPlugin" "$config_file"; then
        echo "Authorization plugin configured in ActiveMQ config: $config_file" >&2
    else
        echo "No authorization plugin configured in ActiveMQ config: $config_file" >&2
    fi

    # Check authentication
    if grep -q "simpleAuthenticationPlugin" "$config_file"; then
        echo "Simple authentication plugin configured in ActiveMQ config: $config_file" >&2
    fi

    # Check JMX configuration
    if grep -q "managementContext" "$config_file"; then
        echo "Management context configured in ActiveMQ config: $config_file" >&2
    fi

    # Check advisory messages
    if grep -q 'advisorySupport="false"' "$config_file"; then
        echo "Advisory support disabled in ActiveMQ config: $config_file" >&2
    fi

    # Check message cursors
    if grep -q "vmCursor" "$config_file"; then
        echo "VM cursor configured in ActiveMQ config: $config_file" >&2
    fi

    # Check dead letter queue
    if grep -q "deadLetterStrategy" "$config_file"; then
        echo "Dead letter strategy configured in ActiveMQ config: $config_file" >&2
    fi
done

# Check Jetty configuration for web console
for jetty_file in $jetty_files; do
    if [[ ! -f $jetty_file ]]; then
        continue
    fi

    echo "Checking ActiveMQ Jetty config: $jetty_file" >&2

    # Check connector ports
    if grep -q "port=" "$jetty_file"; then
        port=$(grep "port=" "$jetty_file" | sed 's/.*port="\([^"]*\)".*/\1/')
        echo "Jetty port set to: $port in ActiveMQ Jetty config: $jetty_file" >&2
    fi

    # Check SSL configuration
    if grep -q "SslSocketConnector" "$jetty_file"; then
        echo "SSL socket connector configured in ActiveMQ Jetty config: $jetty_file" >&2
    fi
done

# Check ActiveMQ service on live systems
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if pgrep -f "activemq" >/dev/null 2>&1; then
        echo "ActiveMQ service is running" >&2

        # Check ActiveMQ web console
        if curl -s --max-time 5 --connect-timeout 3 http://localhost:8161/admin/ >/dev/null 2>&1; then
            echo "ActiveMQ web console is accessible" >&2
        fi
    else
        echo "ActiveMQ service is not running" >&2
    fi

    # Check JVM memory usage
    if pgrep -f "activemq" >/dev/null 2>&1; then
        activemq_pid=$(pgrep -f "activemq" | head -1)
        if [[ -n $activemq_pid ]]; then
            memory_usage=$(ps -o pid,vsz,rss,comm -p "$activemq_pid" 2>/dev/null)
            if [[ -n $memory_usage ]]; then
                echo "ActiveMQ memory usage: $memory_usage" >&2
            fi
        fi
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
