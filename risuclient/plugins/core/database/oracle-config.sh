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

# long_name: Oracle Database configuration validation
# description: Validates Oracle Database configuration and checks for common issues
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for Oracle environment
if [[ "x$RISU_LIVE" == "x1" ]]; then
    oracle_homes=$(find /opt/oracle /u01/app/oracle -type d -name "db_*" 2>/dev/null | head -5)
    tnsnames_files=$(find /opt/oracle /u01/app/oracle -name "tnsnames.ora" 2>/dev/null)
    listener_files=$(find /opt/oracle /u01/app/oracle -name "listener.ora" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    oracle_homes=$(find "${RISU_ROOT}/opt/oracle" "${RISU_ROOT}/u01/app/oracle" -type d -name "db_*" 2>/dev/null | head -5)
    tnsnames_files=$(find "${RISU_ROOT}/opt/oracle" "${RISU_ROOT}/u01/app/oracle" -name "tnsnames.ora" 2>/dev/null)
    listener_files=$(find "${RISU_ROOT}/opt/oracle" "${RISU_ROOT}/u01/app/oracle" -name "listener.ora" 2>/dev/null)
fi

if [[ -z $oracle_homes && -z $tnsnames_files && -z $listener_files ]]; then
    echo "No Oracle Database installation found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

# Check Oracle environment variables
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if [[ -z $ORACLE_HOME ]]; then
        echo "ORACLE_HOME environment variable not set" >&2
    fi

    if [[ -z $ORACLE_SID ]]; then
        echo "ORACLE_SID environment variable not set" >&2
    fi
fi

# Check TNS Names files
for tnsnames_file in $tnsnames_files; do
    if [[ ! -f $tnsnames_file ]]; then
        continue
    fi

    echo "Checking Oracle TNS Names file: $tnsnames_file" >&2

    # Check for basic syntax
    if ! grep -q "=" "$tnsnames_file"; then
        echo "No service definitions found in TNS Names file: $tnsnames_file" >&2
        flag=1
    fi

    # Check for protocol entries
    if ! grep -q "PROTOCOL" "$tnsnames_file"; then
        echo "No protocol entries found in TNS Names file: $tnsnames_file" >&2
        flag=1
    fi

    # Check for host entries
    if ! grep -q "HOST" "$tnsnames_file"; then
        echo "No host entries found in TNS Names file: $tnsnames_file" >&2
        flag=1
    fi

    # Check for service names
    if ! grep -q "SERVICE_NAME" "$tnsnames_file"; then
        echo "No service names found in TNS Names file: $tnsnames_file" >&2
    fi
done

# Check Listener files
for listener_file in $listener_files; do
    if [[ ! -f $listener_file ]]; then
        continue
    fi

    echo "Checking Oracle Listener file: $listener_file" >&2

    # Check listener configuration
    if ! grep -q "LISTENER" "$listener_file"; then
        echo "No listener definition found in Listener file: $listener_file" >&2
        flag=1
    fi

    # Check for descriptions
    if ! grep -q "DESCRIPTION" "$listener_file"; then
        echo "No description entries found in Listener file: $listener_file" >&2
        flag=1
    fi

    # Check for port configuration
    if ! grep -q "PORT" "$listener_file"; then
        echo "No port configuration found in Listener file: $listener_file" >&2
        flag=1
    fi

    # Check for SSL configuration
    if grep -q "SSL" "$listener_file"; then
        echo "SSL configuration found in Listener file: $listener_file" >&2
    fi
done

# Check Oracle processes (on live systems)
if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check for Oracle processes
    if pgrep -f "ora_" >/dev/null 2>&1; then
        echo "Oracle background processes found" >&2

        # Check for specific processes
        if ! pgrep -f "ora_pmon" >/dev/null 2>&1; then
            echo "Oracle PMON process not found" >&2
            flag=1
        fi

        if ! pgrep -f "ora_smon" >/dev/null 2>&1; then
            echo "Oracle SMON process not found" >&2
            flag=1
        fi

        if ! pgrep -f "ora_lgwr" >/dev/null 2>&1; then
            echo "Oracle LGWR process not found" >&2
            flag=1
        fi
    else
        echo "No Oracle background processes found" >&2
    fi

    # Check listener process
    if ! pgrep -f "tnslsnr" >/dev/null 2>&1; then
        echo "Oracle listener process not found" >&2
    fi
fi

# Check for Oracle alert logs
if [[ "x$RISU_LIVE" == "x1" ]]; then
    alert_logs=$(find /opt/oracle /u01/app/oracle -name "alert_*.log" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    alert_logs=$(find "${RISU_ROOT}/opt/oracle" "${RISU_ROOT}/u01/app/oracle" -name "alert_*.log" 2>/dev/null)
fi

for alert_log in $alert_logs; do
    if [[ -f $alert_log ]]; then
        echo "Oracle alert log found: $alert_log" >&2

        # Check for recent errors
        if tail -100 "$alert_log" | grep -i "error\|ora-" >/dev/null 2>&1; then
            echo "Recent errors found in Oracle alert log: $alert_log" >&2
            flag=1
        fi
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
