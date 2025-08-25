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

# long_name: Check Docker container health
# description: Check Docker containers health status
# priority: 720

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

DOCKER_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check if Docker is running
    if command -v docker >/dev/null 2>&1; then
        DOCKER_STATUS=$(systemctl is-active docker 2>/dev/null || echo "inactive")
        if [[ $DOCKER_STATUS != "active" ]]; then
            echo "WARNING: Docker service is not active ($DOCKER_STATUS)" >&2
            DOCKER_ISSUES=$((DOCKER_ISSUES + 1))
        else
            # Check container health
            UNHEALTHY_CONTAINERS=$(docker ps --filter "health=unhealthy" --format "table {{.Names}}" 2>/dev/null | tail -n +2 | wc -l)
            if [[ $UNHEALTHY_CONTAINERS -gt 0 ]]; then
                echo "CRITICAL: Found $UNHEALTHY_CONTAINERS unhealthy containers:" >&2
                docker ps --filter "health=unhealthy" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -n +2 >&2
                DOCKER_ISSUES=$((DOCKER_ISSUES + UNHEALTHY_CONTAINERS))
            fi

            # Check for exited containers
            EXITED_CONTAINERS=$(docker ps --filter "status=exited" --format "table {{.Names}}" 2>/dev/null | tail -n +2 | wc -l)
            if [[ $EXITED_CONTAINERS -gt 5 ]]; then
                echo "WARNING: Found $EXITED_CONTAINERS exited containers" >&2
                DOCKER_ISSUES=$((DOCKER_ISSUES + 1))
            fi

            # Check for restarting containers
            RESTARTING_CONTAINERS=$(docker ps --filter "status=restarting" --format "table {{.Names}}" 2>/dev/null | tail -n +2 | wc -l)
            if [[ $RESTARTING_CONTAINERS -gt 0 ]]; then
                echo "WARNING: Found $RESTARTING_CONTAINERS restarting containers:" >&2
                docker ps --filter "status=restarting" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -n +2 >&2
                DOCKER_ISSUES=$((DOCKER_ISSUES + RESTARTING_CONTAINERS))
            fi
        fi
    else
        echo "Docker not installed or not available" >&2
        exit $RC_OKAY
    fi
else
    # Check sosreport for Docker information
    if [[ -f "${RISU_ROOT}/docker_ps" ]]; then
        # Check for unhealthy containers
        UNHEALTHY_CONTAINERS=$(grep "unhealthy" "${RISU_ROOT}/docker_ps" | wc -l)
        if [[ $UNHEALTHY_CONTAINERS -gt 0 ]]; then
            echo "CRITICAL: Found $UNHEALTHY_CONTAINERS unhealthy containers in sosreport:" >&2
            grep "unhealthy" "${RISU_ROOT}/docker_ps" >&2
            DOCKER_ISSUES=$((DOCKER_ISSUES + UNHEALTHY_CONTAINERS))
        fi

        # Check for exited containers
        EXITED_CONTAINERS=$(grep "Exited" "${RISU_ROOT}/docker_ps" | wc -l)
        if [[ $EXITED_CONTAINERS -gt 5 ]]; then
            echo "WARNING: Found $EXITED_CONTAINERS exited containers in sosreport" >&2
            DOCKER_ISSUES=$((DOCKER_ISSUES + 1))
        fi

        # Check for restarting containers
        RESTARTING_CONTAINERS=$(grep "Restarting" "${RISU_ROOT}/docker_ps" | wc -l)
        if [[ $RESTARTING_CONTAINERS -gt 0 ]]; then
            echo "WARNING: Found $RESTARTING_CONTAINERS restarting containers in sosreport:" >&2
            grep "Restarting" "${RISU_ROOT}/docker_ps" >&2
            DOCKER_ISSUES=$((DOCKER_ISSUES + RESTARTING_CONTAINERS))
        fi
    else
        echo "Docker information not found in sosreport" >&2
        exit $RC_OKAY
    fi
fi

# Check results
if [[ $DOCKER_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple Docker container issues found ($DOCKER_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $DOCKER_ISSUES -gt 0 ]]; then
    echo "WARNING: Docker container issues found ($DOCKER_ISSUES)" >&2
    exit $RC_FAILED
else
    echo "Docker containers appear to be healthy" >&2
    exit $RC_OKAY
fi
