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

# long_name: InfluxDB configuration validation
# description: Validates InfluxDB configuration files and checks for common issues
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for influxdb config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/influxdb /opt/influxdb -name "influxdb.conf" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/influxdb" "${RISU_ROOT}/opt/influxdb" -name "influxdb.conf" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No InfluxDB configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking InfluxDB config: $config_file" >&2

    # Check data directory
    data_dir=$(grep "^[[:space:]]*dir" "$config_file" | grep -v "^#" | head -1 | awk '{print $3}' | tr -d '"')
    if [[ -n $data_dir ]]; then
        echo "Data directory set to: $data_dir in InfluxDB config: $config_file" >&2
    fi

    # Check HTTP settings
    if grep -A 10 "^\[http\]" "$config_file" | grep -q "enabled = false"; then
        echo "HTTP interface disabled in InfluxDB config: $config_file" >&2
        flag=1
    fi

    # Check HTTPS settings
    if grep -A 10 "^\[http\]" "$config_file" | grep -q "https-enabled = true"; then
        echo "HTTPS enabled in InfluxDB config: $config_file" >&2
    else
        echo "HTTPS not enabled in InfluxDB config: $config_file" >&2
    fi

    # Check authentication
    if grep -A 10 "^\[http\]" "$config_file" | grep -q "auth-enabled = true"; then
        echo "Authentication enabled in InfluxDB config: $config_file" >&2
    else
        echo "Authentication not enabled in InfluxDB config: $config_file" >&2
        flag=1
    fi

    # Check retention policy
    if grep -A 10 "^\[retention\]" "$config_file" | grep -q "enabled = false"; then
        echo "Retention policy disabled in InfluxDB config: $config_file" >&2
    fi

    # Check WAL settings
    if grep -A 10 "^\[data\]" "$config_file" | grep -q "wal-dir"; then
        wal_dir=$(grep -A 10 "^\[data\]" "$config_file" | grep "wal-dir" | awk '{print $3}' | tr -d '"')
        echo "WAL directory set to: $wal_dir in InfluxDB config: $config_file" >&2
    fi

    # Check continuous queries
    if grep -A 10 "^\[continuous_queries\]" "$config_file" | grep -q "enabled = false"; then
        echo "Continuous queries disabled in InfluxDB config: $config_file" >&2
    fi

    # Check logging
    if grep -A 10 "^\[logging\]" "$config_file" | grep -q 'level = "debug"'; then
        echo "Debug logging enabled in InfluxDB config: $config_file" >&2
    fi

    # Check subscriber settings
    if grep -A 10 "^\[subscriber\]" "$config_file" | grep -q "enabled = true"; then
        echo "Subscriber service enabled in InfluxDB config: $config_file" >&2
    fi

    # Check UDP settings
    if grep -A 10 "^\[\[udp\]\]" "$config_file" | grep -q "enabled = true"; then
        echo "UDP service enabled in InfluxDB config: $config_file" >&2
    fi

    # Check Graphite settings
    if grep -A 10 "^\[\[graphite\]\]" "$config_file" | grep -q "enabled = true"; then
        echo "Graphite service enabled in InfluxDB config: $config_file" >&2
    fi

    # Check collectd settings
    if grep -A 10 "^\[\[collectd\]\]" "$config_file" | grep -q "enabled = true"; then
        echo "Collectd service enabled in InfluxDB config: $config_file" >&2
    fi

    # Check OpenTSDB settings
    if grep -A 10 "^\[\[opentsdb\]\]" "$config_file" | grep -q "enabled = true"; then
        echo "OpenTSDB service enabled in InfluxDB config: $config_file" >&2
    fi
done

# Check InfluxDB service on live systems
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if is_active influxdb; then
        echo "InfluxDB service is active" >&2

        # Check if InfluxDB is responding
        if command -v influx >/dev/null 2>&1; then
            if influx -execute "SHOW DATABASES" >/dev/null 2>&1; then
                echo "InfluxDB is responding to queries" >&2
            else
                echo "InfluxDB not responding to queries" >&2
                flag=1
            fi
        fi
    else
        echo "InfluxDB service is not active" >&2
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
