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

# long_name: Check backup status
# description: Check backup jobs and status
# priority: 630

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

BACKUP_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check for backup directories
    BACKUP_DIRS=("/backup" "/var/backups" "/mnt/backup" "/opt/backup")
    BACKUP_FOUND=0

    for dir in "${BACKUP_DIRS[@]}"; do
        if [[ -d $dir ]]; then
            BACKUP_FOUND=1
            # Check if backup directory is mounted
            if mountpoint -q "$dir" 2>/dev/null; then
                echo "INFO: Backup directory $dir is mounted" >&2
            else
                echo "WARNING: Backup directory $dir exists but is not mounted" >&2
                BACKUP_ISSUES=$((BACKUP_ISSUES + 1))
            fi

            # Check if backup directory has recent files
            if [[ -n "$(find "$dir" -type f -mtime -7 2>/dev/null)" ]]; then
                echo "INFO: Recent backup files found in $dir" >&2
            else
                echo "WARNING: No recent backup files found in $dir" >&2
                BACKUP_ISSUES=$((BACKUP_ISSUES + 1))
            fi
        fi
    done

    if [[ $BACKUP_FOUND -eq 0 ]]; then
        echo "WARNING: No backup directories found" >&2
        BACKUP_ISSUES=$((BACKUP_ISSUES + 1))
    fi

    # Check for backup-related services
    BACKUP_SERVICES=("bacula-fd" "amanda" "rsync" "duplicity")

    for service in "${BACKUP_SERVICES[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            echo "INFO: Backup service $service is active" >&2
        fi
    done

    # Check for backup-related cron jobs
    if [[ -f "/etc/crontab" ]]; then
        BACKUP_CRONS=$(grep -c "backup\|rsync\|tar" /etc/crontab 2>/dev/null || echo "0")
        if [[ $BACKUP_CRONS -eq 0 ]]; then
            echo "WARNING: No backup-related cron jobs found in /etc/crontab" >&2
            BACKUP_ISSUES=$((BACKUP_ISSUES + 1))
        fi
    fi
else
    # Check sosreport for backup information
    if [[ -f "${RISU_ROOT}/mount" ]]; then
        # Check for mounted backup directories
        BACKUP_MOUNTS=$(grep -c "backup" "${RISU_ROOT}/mount" 2>/dev/null || echo "0")
        if [[ $BACKUP_MOUNTS -eq 0 ]]; then
            echo "WARNING: No backup directories were mounted" >&2
            BACKUP_ISSUES=$((BACKUP_ISSUES + 1))
        fi
    fi

    # Check for backup-related services in sosreport
    BACKUP_SERVICES=("bacula-fd" "amanda" "rsync" "duplicity")

    for service in "${BACKUP_SERVICES[@]}"; do
        if [[ -f "${RISU_ROOT}/systemctl_is-active_${service}" ]]; then
            STATUS=$(cat "${RISU_ROOT}/systemctl_is-active_${service}" 2>/dev/null || echo "inactive")
            if [[ $STATUS == "active" ]]; then
                echo "INFO: Backup service $service was active" >&2
            fi
        fi
    done

    # Check for backup-related cron jobs in sosreport
    if [[ -f "${RISU_ROOT}/etc/crontab" ]]; then
        BACKUP_CRONS=$(grep -c "backup\|rsync\|tar" "${RISU_ROOT}/etc/crontab" 2>/dev/null || echo "0")
        if [[ $BACKUP_CRONS -eq 0 ]]; then
            echo "WARNING: No backup-related cron jobs found in /etc/crontab" >&2
            BACKUP_ISSUES=$((BACKUP_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $BACKUP_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple backup issues found ($BACKUP_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $BACKUP_ISSUES -gt 1 ]]; then
    echo "WARNING: Backup issues found ($BACKUP_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $BACKUP_ISSUES -gt 0 ]]; then
    echo "INFO: Minor backup issues found ($BACKUP_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Backup configuration appears to be adequate" >&2
    exit $RC_OKAY
fi
