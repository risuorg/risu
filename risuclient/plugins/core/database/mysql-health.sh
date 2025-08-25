#!/bin/bash

# Copyright (C) 2024 Pablo Iranzo Gómez (Pablo.Iranzo@gmail.com)

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

# long_name: Check MySQL/MariaDB health
# description: Check MySQL/MariaDB database health
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

DB_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check MySQL/MariaDB services
    DB_SERVICES=("mysql" "mariadb" "mysqld")

    for service in "${DB_SERVICES[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            echo "INFO: Database service $service is active" >&2

            # Check if database is listening on port 3306
            if command -v netstat >/dev/null 2>&1; then
                DB_LISTENING=$(netstat -tln | grep -c ":3306 ")
                if [[ $DB_LISTENING -eq 0 ]]; then
                    echo "WARNING: No service listening on MySQL port 3306" >&2
                    DB_ISSUES=$((DB_ISSUES + 1))
                fi
            fi

            # Check database error logs
            if [[ -f "/var/log/mysql/error.log" ]]; then
                RECENT_ERRORS=$(tail -100 /var/log/mysql/error.log | grep -c "ERROR\|CRITICAL\|FATAL" || echo "0")
                if [[ $RECENT_ERRORS -gt 5 ]]; then
                    echo "WARNING: Found $RECENT_ERRORS recent errors in MySQL error log" >&2
                    DB_ISSUES=$((DB_ISSUES + 1))
                fi
            elif [[ -f "/var/log/mariadb/mariadb.log" ]]; then
                RECENT_ERRORS=$(tail -100 /var/log/mariadb/mariadb.log | grep -c "ERROR\|CRITICAL\|FATAL" || echo "0")
                if [[ $RECENT_ERRORS -gt 5 ]]; then
                    echo "WARNING: Found $RECENT_ERRORS recent errors in MariaDB log" >&2
                    DB_ISSUES=$((DB_ISSUES + 1))
                fi
            fi

            # Check database connections if mysql client is available
            if command -v mysql >/dev/null 2>&1; then
                # Try to connect to database
                if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
                    echo "INFO: MySQL connection test successful" >&2
                else
                    echo "WARNING: Cannot connect to MySQL database" >&2
                    DB_ISSUES=$((DB_ISSUES + 1))
                fi
            fi
        fi
    done

    # Check if any database server is running
    DB_RUNNING=0
    for service in "${DB_SERVICES[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            DB_RUNNING=1
            break
        fi
    done

    if [[ $DB_RUNNING -eq 0 ]]; then
        echo "INFO: No MySQL/MariaDB servers are running" >&2
    fi
else
    # Check sosreport for database information
    DB_SERVICES=("mysql" "mariadb" "mysqld")

    for service in "${DB_SERVICES[@]}"; do
        if [[ -f "${RISU_ROOT}/systemctl_is-active_${service}" ]]; then
            STATUS=$(cat "${RISU_ROOT}/systemctl_is-active_${service}" 2>/dev/null || echo "inactive")
            if [[ $STATUS == "active" ]]; then
                echo "INFO: Database service $service was active" >&2

                # Check database error logs in sosreport
                if [[ -f "${RISU_ROOT}/var/log/mysql/error.log" ]]; then
                    RECENT_ERRORS=$(tail -100 "${RISU_ROOT}/var/log/mysql/error.log" | grep -c "ERROR\|CRITICAL\|FATAL" || echo "0")
                    if [[ $RECENT_ERRORS -gt 5 ]]; then
                        echo "WARNING: Found $RECENT_ERRORS recent errors in MySQL error log" >&2
                        DB_ISSUES=$((DB_ISSUES + 1))
                    fi
                elif [[ -f "${RISU_ROOT}/var/log/mariadb/mariadb.log" ]]; then
                    RECENT_ERRORS=$(tail -100 "${RISU_ROOT}/var/log/mariadb/mariadb.log" | grep -c "ERROR\|CRITICAL\|FATAL" || echo "0")
                    if [[ $RECENT_ERRORS -gt 5 ]]; then
                        echo "WARNING: Found $RECENT_ERRORS recent errors in MariaDB log" >&2
                        DB_ISSUES=$((DB_ISSUES + 1))
                    fi
                fi
            fi
        fi
    done

    # Check if port was listening in sosreport
    if [[ -f "${RISU_ROOT}/netstat_-tln" ]]; then
        DB_LISTENING=$(grep -c ":3306 " "${RISU_ROOT}/netstat_-tln" || echo "0")
        if [[ $DB_LISTENING -eq 0 ]]; then
            echo "WARNING: No service was listening on MySQL port 3306" >&2
            DB_ISSUES=$((DB_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $DB_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple database issues found ($DB_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $DB_ISSUES -gt 1 ]]; then
    echo "WARNING: Database issues found ($DB_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $DB_ISSUES -gt 0 ]]; then
    echo "INFO: Minor database issues found ($DB_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Database servers appear to be healthy" >&2
    exit $RC_OKAY
fi
