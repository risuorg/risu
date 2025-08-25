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

# long_name: Check process limits
# description: Check if system is approaching process limits
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

LIMIT_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current process count
    if command -v ps >/dev/null 2>&1; then
        PROCESS_COUNT=$(ps aux | wc -l)

        # Check max processes limit
        if [[ -f "/proc/sys/kernel/pid_max" ]]; then
            PID_MAX=$(cat /proc/sys/kernel/pid_max)
            USAGE_PERCENT=$(echo "scale=2; $PROCESS_COUNT * 100 / $PID_MAX" | bc 2>/dev/null || echo "0")
            USAGE_INT=$(echo "$USAGE_PERCENT" | cut -d. -f1)

            if [[ $USAGE_INT -gt 80 ]]; then
                echo "WARNING: Process count is ${USAGE_PERCENT}% of max ($PROCESS_COUNT/$PID_MAX)" >&2
                LIMIT_ISSUES=$((LIMIT_ISSUES + 1))
            fi
        fi
    fi

    # Check thread count
    if [[ -f "/proc/sys/kernel/threads-max" ]]; then
        THREADS_MAX=$(cat /proc/sys/kernel/threads-max)
        THREAD_COUNT=$(ps -eo nlwp | awk 'NR>1 {sum += $1} END {print sum}' 2>/dev/null || echo "0")

        if [[ $THREAD_COUNT -gt 0 ]]; then
            THREAD_USAGE=$(echo "scale=2; $THREAD_COUNT * 100 / $THREADS_MAX" | bc 2>/dev/null || echo "0")
            THREAD_USAGE_INT=$(echo "$THREAD_USAGE" | cut -d. -f1)

            if [[ $THREAD_USAGE_INT -gt 80 ]]; then
                echo "WARNING: Thread count is ${THREAD_USAGE}% of max ($THREAD_COUNT/$THREADS_MAX)" >&2
                LIMIT_ISSUES=$((LIMIT_ISSUES + 1))
            fi
        fi
    fi

    # Check ulimit settings
    if command -v ulimit >/dev/null 2>&1; then
        MAX_PROCESSES=$(ulimit -u)
        if [[ $MAX_PROCESSES != "unlimited" ]] && [[ $MAX_PROCESSES -lt 1024 ]]; then
            echo "WARNING: Maximum processes ulimit is low: $MAX_PROCESSES" >&2
            LIMIT_ISSUES=$((LIMIT_ISSUES + 1))
        fi

        MAX_OPEN_FILES=$(ulimit -n)
        if [[ $MAX_OPEN_FILES != "unlimited" ]] && [[ $MAX_OPEN_FILES -lt 1024 ]]; then
            echo "WARNING: Maximum open files ulimit is low: $MAX_OPEN_FILES" >&2
            LIMIT_ISSUES=$((LIMIT_ISSUES + 1))
        fi
    fi
else
    # Check sosreport for process limits
    if [[ -f "${RISU_ROOT}/ps" ]]; then
        PROCESS_COUNT=$(wc -l <"${RISU_ROOT}/ps")

        # Check max processes limit
        if [[ -f "${RISU_ROOT}/proc/sys/kernel/pid_max" ]]; then
            PID_MAX=$(cat "${RISU_ROOT}/proc/sys/kernel/pid_max")
            USAGE_PERCENT=$(echo "scale=2; $PROCESS_COUNT * 100 / $PID_MAX" | bc 2>/dev/null || echo "0")
            USAGE_INT=$(echo "$USAGE_PERCENT" | cut -d. -f1)

            if [[ $USAGE_INT -gt 80 ]]; then
                echo "WARNING: Process count was ${USAGE_PERCENT}% of max ($PROCESS_COUNT/$PID_MAX)" >&2
                LIMIT_ISSUES=$((LIMIT_ISSUES + 1))
            fi
        fi
    fi

    # Check thread count in sosreport
    if [[ -f "${RISU_ROOT}/proc/sys/kernel/threads-max" ]]; then
        THREADS_MAX=$(cat "${RISU_ROOT}/proc/sys/kernel/threads-max")

        if [[ -f "${RISU_ROOT}/ps_eLo_nlwp" ]]; then
            THREAD_COUNT=$(awk 'NR>1 {sum += $1} END {print sum}' "${RISU_ROOT}/ps_eLo_nlwp" 2>/dev/null || echo "0")

            if [[ $THREAD_COUNT -gt 0 ]]; then
                THREAD_USAGE=$(echo "scale=2; $THREAD_COUNT * 100 / $THREADS_MAX" | bc 2>/dev/null || echo "0")
                THREAD_USAGE_INT=$(echo "$THREAD_USAGE" | cut -d. -f1)

                if [[ $THREAD_USAGE_INT -gt 80 ]]; then
                    echo "WARNING: Thread count was ${THREAD_USAGE}% of max ($THREAD_COUNT/$THREADS_MAX)" >&2
                    LIMIT_ISSUES=$((LIMIT_ISSUES + 1))
                fi
            fi
        fi
    fi
fi

# Check results
if [[ $LIMIT_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple process limit issues found ($LIMIT_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $LIMIT_ISSUES -gt 1 ]]; then
    echo "WARNING: Process limit issues found ($LIMIT_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $LIMIT_ISSUES -gt 0 ]]; then
    echo "INFO: Minor process limit issues found ($LIMIT_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Process limits appear to be adequate" >&2
    exit $RC_OKAY
fi
