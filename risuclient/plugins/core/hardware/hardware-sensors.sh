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

# long_name: Check hardware sensors
# description: Check hardware sensors for temperature and fan issues
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

SENSOR_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check hardware sensors
    if command -v sensors >/dev/null 2>&1; then
        SENSOR_OUTPUT=$(sensors 2>/dev/null)

        # Check for high temperatures
        TEMP_WARNINGS=$(echo "$SENSOR_OUTPUT" | grep -c "high\|ALARM\|CRITICAL")
        if [[ $TEMP_WARNINGS -gt 0 ]]; then
            echo "WARNING: Hardware sensor temperature warnings detected ($TEMP_WARNINGS)" >&2
            echo "$SENSOR_OUTPUT" | grep "high\|ALARM\|CRITICAL" >&2
            SENSOR_ISSUES=$((SENSOR_ISSUES + TEMP_WARNINGS))
        fi

        # Check for fan issues
        FAN_ISSUES=$(echo "$SENSOR_OUTPUT" | grep -c "fan.*0 RPM\|fan.*ALARM")
        if [[ $FAN_ISSUES -gt 0 ]]; then
            echo "CRITICAL: Hardware fan issues detected ($FAN_ISSUES)" >&2
            echo "$SENSOR_OUTPUT" | grep "fan.*0 RPM\|fan.*ALARM" >&2
            SENSOR_ISSUES=$((SENSOR_ISSUES + FAN_ISSUES * 2))
        fi
    fi

    # Check thermal zones
    if [[ -d "/sys/class/thermal" ]]; then
        for zone in /sys/class/thermal/thermal_zone*/temp; do
            if [[ -f $zone ]]; then
                TEMP=$(cat "$zone" 2>/dev/null || echo "0")
                # Convert millicelsius to celsius
                TEMP_C=$((TEMP / 1000))
                if [[ $TEMP_C -gt 80 ]]; then
                    echo "WARNING: Thermal zone temperature high: ${TEMP_C}°C" >&2
                    SENSOR_ISSUES=$((SENSOR_ISSUES + 1))
                fi
            fi
        done
    fi
else
    # Check sosreport for hardware sensor information
    if [[ -f "${RISU_ROOT}/sensors" ]]; then
        SENSOR_OUTPUT=$(cat "${RISU_ROOT}/sensors")

        # Check for high temperatures
        TEMP_WARNINGS=$(echo "$SENSOR_OUTPUT" | grep -c "high\|ALARM\|CRITICAL")
        if [[ $TEMP_WARNINGS -gt 0 ]]; then
            echo "WARNING: Hardware sensor temperature warnings detected ($TEMP_WARNINGS)" >&2
            echo "$SENSOR_OUTPUT" | grep "high\|ALARM\|CRITICAL" >&2
            SENSOR_ISSUES=$((SENSOR_ISSUES + TEMP_WARNINGS))
        fi

        # Check for fan issues
        FAN_ISSUES=$(echo "$SENSOR_OUTPUT" | grep -c "fan.*0 RPM\|fan.*ALARM")
        if [[ $FAN_ISSUES -gt 0 ]]; then
            echo "CRITICAL: Hardware fan issues detected ($FAN_ISSUES)" >&2
            echo "$SENSOR_OUTPUT" | grep "fan.*0 RPM\|fan.*ALARM" >&2
            SENSOR_ISSUES=$((SENSOR_ISSUES + FAN_ISSUES * 2))
        fi
    fi

    # Check thermal zones in sosreport
    if [[ -d "${RISU_ROOT}/sys/class/thermal" ]]; then
        for zone in "${RISU_ROOT}"/sys/class/thermal/thermal_zone*/temp; do
            if [[ -f $zone ]]; then
                TEMP=$(cat "$zone" 2>/dev/null || echo "0")
                # Convert millicelsius to celsius
                TEMP_C=$((TEMP / 1000))
                if [[ $TEMP_C -gt 80 ]]; then
                    echo "WARNING: Thermal zone temperature was high: ${TEMP_C}°C" >&2
                    SENSOR_ISSUES=$((SENSOR_ISSUES + 1))
                fi
            fi
        done
    fi
fi

# Check results
if [[ $SENSOR_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple hardware sensor issues found ($SENSOR_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $SENSOR_ISSUES -gt 0 ]]; then
    echo "WARNING: Hardware sensor issues found ($SENSOR_ISSUES)" >&2
    exit $RC_FAILED
else
    echo "Hardware sensors appear to be within normal ranges" >&2
    exit $RC_OKAY
fi
