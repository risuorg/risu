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

# long_name: PostgreSQL configuration validation
# description: Validates PostgreSQL configuration files and checks for common issues
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for postgresql config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /etc/postgresql /var/lib/pgsql -name "postgresql.conf" 2>/dev/null)
    hba_files=$(find /etc/postgresql /var/lib/pgsql -name "pg_hba.conf" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/etc/postgresql" "${RISU_ROOT}/var/lib/pgsql" -name "postgresql.conf" 2>/dev/null)
    hba_files=$(find "${RISU_ROOT}/etc/postgresql" "${RISU_ROOT}/var/lib/pgsql" -name "pg_hba.conf" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No PostgreSQL configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking PostgreSQL config: $config_file" >&2

    # Check max connections
    max_conn=$(grep "^max_connections" "$config_file" | awk '{print $3}')
    if [[ -n $max_conn ]]; then
        if [[ $max_conn -lt 100 ]]; then
            echo "Max connections is low ($max_conn) in PostgreSQL config: $config_file" >&2
        elif [[ $max_conn -gt 1000 ]]; then
            echo "Max connections is very high ($max_conn) in PostgreSQL config: $config_file" >&2
        fi
    fi

    # Check shared buffers
    shared_buffers=$(grep "^shared_buffers" "$config_file" | awk '{print $3}')
    if [[ -n $shared_buffers ]]; then
        echo "Shared buffers set to: $shared_buffers in PostgreSQL config: $config_file" >&2
    else
        echo "Shared buffers not configured in PostgreSQL config: $config_file" >&2
    fi

    # Check checkpoint settings
    if ! grep -q "^checkpoint_completion_target" "$config_file"; then
        echo "Checkpoint completion target not configured in PostgreSQL config: $config_file" >&2
    fi

    # Check WAL settings
    if ! grep -q "^wal_level" "$config_file"; then
        echo "WAL level not configured in PostgreSQL config: $config_file" >&2
    fi

    # Check logging
    if ! grep -q "^log_destination" "$config_file"; then
        echo "Log destination not configured in PostgreSQL config: $config_file" >&2
    fi

    # Check log statement
    log_statement=$(grep "^log_statement" "$config_file" | awk '{print $3}')
    if [[ $log_statement == "all" ]]; then
        echo "All statements being logged - performance impact in PostgreSQL config: $config_file" >&2
    fi

    # Check autovacuum
    if grep -q "^autovacuum = off" "$config_file"; then
        echo "Autovacuum disabled in PostgreSQL config: $config_file" >&2
        flag=1
    fi

    # Check SSL
    if ! grep -q "^ssl = on" "$config_file"; then
        echo "SSL not enabled in PostgreSQL config: $config_file" >&2
    fi

    # Check work_mem
    work_mem=$(grep "^work_mem" "$config_file" | awk '{print $3}')
    if [[ -n $work_mem ]]; then
        echo "Work mem set to: $work_mem in PostgreSQL config: $config_file" >&2
    fi
done

# Check pg_hba.conf files
for hba_file in $hba_files; do
    if [[ ! -f $hba_file ]]; then
        continue
    fi

    echo "Checking PostgreSQL HBA config: $hba_file" >&2

    # Check for trust authentication
    if grep -q "trust" "$hba_file"; then
        echo "Trust authentication found in PostgreSQL HBA config: $hba_file" >&2
        flag=1
    fi

    # Check for password authentication without SSL
    if grep -q "password" "$hba_file"; then
        echo "Password authentication found - consider md5 or scram-sha-256 in PostgreSQL HBA config: $hba_file" >&2
    fi

    # Check for wide-open access
    if grep -q "0.0.0.0/0" "$hba_file"; then
        echo "Wide-open access (0.0.0.0/0) found in PostgreSQL HBA config: $hba_file" >&2
        flag=1
    fi

    # Check for local connections
    if ! grep -q "local" "$hba_file"; then
        echo "No local connections configured in PostgreSQL HBA config: $hba_file" >&2
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
