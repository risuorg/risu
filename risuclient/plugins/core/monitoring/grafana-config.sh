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

# long_name: Grafana configuration validation
# description: Validates Grafana configuration files and checks for security issues
# priority: 350

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for grafana config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/grafana /opt/grafana -name "grafana.ini" -o -name "defaults.ini" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/grafana" "${RISU_ROOT}/opt/grafana" -name "grafana.ini" -o -name "defaults.ini" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No Grafana configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking Grafana config: $config_file" >&2

    # Check default admin password
    if grep -q "^admin_password = admin" "$config_file"; then
        echo "Default admin password detected in Grafana config: $config_file" >&2
        flag=1
    fi

    # Check if anonymous access is enabled
    if grep -A 5 "^\[auth.anonymous\]" "$config_file" | grep -q "^enabled = true"; then
        echo "Anonymous access enabled in Grafana config: $config_file" >&2
        flag=1
    fi

    # Check HTTP settings
    if grep -A 10 "^\[server\]" "$config_file" | grep -q "^protocol = http"; then
        echo "HTTP protocol configured (consider HTTPS) in Grafana config: $config_file" >&2
    fi

    # Check cookie secure setting
    if grep -A 10 "^\[security\]" "$config_file" | grep -q "^cookie_secure = false"; then
        echo "Cookie secure setting disabled in Grafana config: $config_file" >&2
        flag=1
    fi

    # Check for secret key
    if grep -A 10 "^\[security\]" "$config_file" | grep -q "^secret_key = SW2YcwTIb9zpOOhoPsMm"; then
        echo "Default secret key detected in Grafana config: $config_file" >&2
        flag=1
    fi

    # Check database configuration
    if grep -A 10 "^\[database\]" "$config_file" | grep -q "^type = sqlite3"; then
        echo "SQLite database configured in Grafana config: $config_file" >&2
    fi

    # Check logging configuration
    if grep -A 10 "^\[log\]" "$config_file" | grep -q "^level = debug"; then
        echo "Debug logging enabled in Grafana config: $config_file" >&2
    fi

    # Check session configuration
    if grep -A 10 "^\[session\]" "$config_file" | grep -q "^session_life_time = 86400"; then
        echo "Session lifetime configured to 24 hours in Grafana config: $config_file" >&2
    fi

    # Check for LDAP configuration
    if grep -q "^\[auth.ldap\]" "$config_file"; then
        echo "LDAP authentication configured in Grafana config: $config_file" >&2
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
