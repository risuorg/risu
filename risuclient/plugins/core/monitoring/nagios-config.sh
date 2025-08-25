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

# long_name: Nagios configuration validation
# description: Validates Nagios configuration files and checks for common issues
# priority: 350

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for nagios config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/nagios /usr/local/nagios/etc -name "nagios.cfg" 2>/dev/null)
    object_dirs=$(find /etc/nagios /usr/local/nagios/etc -type d -name "objects" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/nagios" "${RISU_ROOT}/usr/local/nagios/etc" -name "nagios.cfg" 2>/dev/null)
    object_dirs=$(find "${RISU_ROOT}/etc/nagios" "${RISU_ROOT}/usr/local/nagios/etc" -type d -name "objects" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No Nagios configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking Nagios config: $config_file" >&2

    # Check main configuration directives
    if ! grep -q "^cfg_dir=" "$config_file"; then
        echo "No cfg_dir directive found in Nagios config: $config_file" >&2
        flag=1
    fi

    # Check log file configuration
    if ! grep -q "^log_file=" "$config_file"; then
        echo "No log_file directive found in Nagios config: $config_file" >&2
        flag=1
    fi

    # Check object cache file
    if ! grep -q "^object_cache_file=" "$config_file"; then
        echo "No object_cache_file directive found in Nagios config: $config_file" >&2
        flag=1
    fi

    # Check command file
    if ! grep -q "^command_file=" "$config_file"; then
        echo "No command_file directive found in Nagios config: $config_file" >&2
        flag=1
    fi

    # Check retention file
    if ! grep -q "^state_retention_file=" "$config_file"; then
        echo "No state_retention_file directive found in Nagios config: $config_file" >&2
        flag=1
    fi

    # Check notification settings
    if grep -q "^enable_notifications=0" "$config_file"; then
        echo "Notifications disabled in Nagios config: $config_file" >&2
        flag=1
    fi

    # Check flap detection
    if grep -q "^enable_flap_detection=0" "$config_file"; then
        echo "Flap detection disabled in Nagios config: $config_file" >&2
    fi

    # Check performance data
    if grep -q "^process_performance_data=1" "$config_file"; then
        echo "Performance data processing enabled in Nagios config: $config_file" >&2
    fi

    # Check check result reaper frequency
    check_reaper=$(grep "^check_result_reaper_frequency=" "$config_file" | cut -d'=' -f2)
    if [[ -n $check_reaper && $check_reaper -gt 30 ]]; then
        echo "Check result reaper frequency is high ($check_reaper) in Nagios config: $config_file" >&2
    fi
done

# Check object configuration files
for obj_dir in $object_dirs; do
    if [[ -d $obj_dir ]]; then
        echo "Checking Nagios objects directory: $obj_dir" >&2

        # Check for required object files
        if [[ ! -f "$obj_dir/commands.cfg" ]]; then
            echo "No commands.cfg found in objects directory: $obj_dir" >&2
            flag=1
        fi

        if [[ ! -f "$obj_dir/contacts.cfg" ]]; then
            echo "No contacts.cfg found in objects directory: $obj_dir" >&2
            flag=1
        fi

        if [[ ! -f "$obj_dir/templates.cfg" ]]; then
            echo "No templates.cfg found in objects directory: $obj_dir" >&2
            flag=1
        fi

        # Check for host and service definitions
        host_files=$(find "$obj_dir" -name "*.cfg" -exec grep -l "define host" {} \; 2>/dev/null)
        if [[ -z $host_files ]]; then
            echo "No host definitions found in objects directory: $obj_dir" >&2
            flag=1
        fi

        service_files=$(find "$obj_dir" -name "*.cfg" -exec grep -l "define service" {} \; 2>/dev/null)
        if [[ -z $service_files ]]; then
            echo "No service definitions found in objects directory: $obj_dir" >&2
            flag=1
        fi
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
