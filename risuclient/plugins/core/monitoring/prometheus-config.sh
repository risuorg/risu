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

# long_name: Prometheus configuration validation
# description: Validates Prometheus configuration files and checks for common issues
# priority: 350

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for prometheus config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/prometheus /opt/prometheus -name "prometheus.yml" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/prometheus" "${RISU_ROOT}/opt/prometheus" -name "prometheus.yml" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No Prometheus configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking Prometheus config: $config_file" >&2

    # Check if config file is valid YAML
    if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
        echo "Invalid YAML in Prometheus config: $config_file" >&2
        flag=1
        continue
    fi

    # Check for global section
    if ! grep -q "^global:" "$config_file"; then
        echo "Missing global section in Prometheus config: $config_file" >&2
        flag=1
    fi

    # Check scrape interval
    if ! grep -q "scrape_interval:" "$config_file"; then
        echo "No scrape_interval defined in Prometheus config: $config_file" >&2
        flag=1
    fi

    # Check for scrape configs
    if ! grep -q "^scrape_configs:" "$config_file"; then
        echo "Missing scrape_configs section in Prometheus config: $config_file" >&2
        flag=1
    fi

    # Check for evaluation interval
    if ! grep -q "evaluation_interval:" "$config_file"; then
        echo "No evaluation_interval defined in Prometheus config: $config_file" >&2
        flag=1
    fi

    # Check for rule files
    if grep -q "^rule_files:" "$config_file"; then
        echo "Rule files configured in Prometheus config: $config_file" >&2
    fi

    # Check for alerting configuration
    if grep -q "^alerting:" "$config_file"; then
        echo "Alerting configured in Prometheus config: $config_file" >&2
    else
        echo "No alerting configuration found in Prometheus config: $config_file" >&2
    fi

    # Check for basic authentication or TLS
    if grep -q "basic_auth\|tls_config" "$config_file"; then
        echo "Security configuration found in Prometheus config: $config_file" >&2
    else
        echo "No security configuration found in Prometheus config: $config_file" >&2
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
