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

# long_name: Check for filesystem corruption
# description: Check for filesystem corruption and errors (excludes legitimate read-only mounts)
# priority: 950

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

CORRUPTION_ISSUES=0

# Function to check if a filesystem is legitimately read-only
is_legitimate_readonly() {
    local mount_point="$1"
    local fs_type="$2"

    # Common legitimate read-only mounts
    case "$mount_point" in
    "/boot"* | "/sys"* | "/proc"* | "/dev"* | "/run"* | "/tmp"* | "/var/tmp"*)
        return 0
        ;;
    "/usr" | "/opt")
        # /usr and /opt are often read-only in hardened systems
        return 0
        ;;
    *"/ostree/"* | *"/.readonly"* | *"/sysroot"*)
        # CoreOS/OSTree related read-only mounts
        return 0
        ;;
    "/")
        # Root filesystem might be read-only in CoreOS/container systems
        if [[ $fs_type == "overlay" || $fs_type == "tmpfs" ]]; then
            return 0
        fi
        ;;
    esac

    # Container and overlay filesystems are often read-only
    case "$fs_type" in
    "overlay" | "tmpfs" | "squashfs" | "iso9660" | "udf")
        return 0
        ;;
    esac

    return 1
}

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check kernel messages for filesystem errors
    if command -v dmesg >/dev/null 2>&1; then
        DMESG_OUTPUT=$(dmesg -T 2>/dev/null || dmesg)

        # Check for actual filesystem corruption patterns (not just read-only remounts)
        FS_ERRORS=(
            "ext[234].*error"
            "xfs.*error"
            "btrfs.*error"
            "I/O error.*[Bb]lock"
            "filesystem.*corrupt"
            "bad block"
            "journal.*abort"
            "metadata.*corrupt"
            "superblock.*corrupt"
            "inode.*corrupt"
            "directory.*corrupt"
            "filesystem.*damaged"
            "ext[234].*check forced"
        )

        for pattern in "${FS_ERRORS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "WARNING: Found $COUNT instances of '$pattern' in kernel messages" >&2
                CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + COUNT))
            fi
        done

        # Check for emergency read-only remounts (due to errors, not intentional)
        ERROR_REMOUNT_PATTERNS=(
            "remount.*read-only.*error"
            "remount.*ro.*error"
            "emergency.*read-only"
            "filesystem.*remounted.*read-only.*error"
        )

        for pattern in "${ERROR_REMOUNT_PATTERNS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "WARNING: Found $COUNT emergency read-only remounts due to errors: '$pattern'" >&2
                CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + COUNT))
            fi
        done
    fi

    # Check mounted filesystems for unexpected read-only mounts
    if command -v mount >/dev/null 2>&1; then
        SUSPICIOUS_READONLY=0

        # Parse mount output to check each mount
        while IFS= read -r mount_line; do
            if [[ $mount_line == *"ro,"* ]]; then
                # Extract mount point and filesystem type
                mount_point=$(echo "$mount_line" | awk '{print $3}')
                fs_type=$(echo "$mount_line" | awk '{print $5}')

                # Check if this is a legitimate read-only mount
                if ! is_legitimate_readonly "$mount_point" "$fs_type"; then
                    echo "WARNING: Unexpected read-only mount: $mount_line" >&2
                    SUSPICIOUS_READONLY=$((SUSPICIOUS_READONLY + 1))
                fi
            fi
        done < <(mount)

        if [[ $SUSPICIOUS_READONLY -gt 0 ]]; then
            echo "WARNING: Found $SUSPICIOUS_READONLY unexpected read-only mounts" >&2
            CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + SUSPICIOUS_READONLY))
        fi
    fi
else
    # Check sosreport for filesystem issues
    if [[ -f "${RISU_ROOT}/dmesg" ]]; then
        DMESG_OUTPUT=$(cat "${RISU_ROOT}/dmesg")

        # Check for actual filesystem corruption patterns
        FS_ERRORS=(
            "ext[234].*error"
            "xfs.*error"
            "btrfs.*error"
            "I/O error.*[Bb]lock"
            "filesystem.*corrupt"
            "bad block"
            "journal.*abort"
            "metadata.*corrupt"
            "superblock.*corrupt"
            "inode.*corrupt"
            "directory.*corrupt"
            "filesystem.*damaged"
            "ext[234].*check forced"
        )

        for pattern in "${FS_ERRORS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "WARNING: Found $COUNT instances of '$pattern' in kernel messages" >&2
                CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + COUNT))
            fi
        done

        # Check for emergency read-only remounts (due to errors, not intentional)
        ERROR_REMOUNT_PATTERNS=(
            "remount.*read-only.*error"
            "remount.*ro.*error"
            "emergency.*read-only"
            "filesystem.*remounted.*read-only.*error"
        )

        for pattern in "${ERROR_REMOUNT_PATTERNS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "WARNING: Found $COUNT emergency read-only remounts due to errors: '$pattern'" >&2
                CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + COUNT))
            fi
        done
    fi

    # Check mounted filesystems for unexpected read-only mounts
    if [[ -f "${RISU_ROOT}/mount" ]]; then
        SUSPICIOUS_READONLY=0

        # Parse mount output to check each mount
        while IFS= read -r mount_line; do
            if [[ $mount_line == *"ro,"* ]]; then
                # Extract mount point and filesystem type
                mount_point=$(echo "$mount_line" | awk '{print $3}')
                fs_type=$(echo "$mount_line" | awk '{print $5}')

                # Check if this is a legitimate read-only mount
                if ! is_legitimate_readonly "$mount_point" "$fs_type"; then
                    echo "WARNING: Unexpected read-only mount: $mount_line" >&2
                    SUSPICIOUS_READONLY=$((SUSPICIOUS_READONLY + 1))
                fi
            fi
        done < <(cat "${RISU_ROOT}/mount")

        if [[ $SUSPICIOUS_READONLY -gt 0 ]]; then
            echo "WARNING: Found $SUSPICIOUS_READONLY unexpected read-only mounts" >&2
            CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + SUSPICIOUS_READONLY))
        fi
    fi
fi

# Check for filesystem check results
if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check for recent fsck failures
    if command -v journalctl >/dev/null 2>&1; then
        FSCK_ERRORS=$(journalctl -u "systemd-fsck*" --since "24 hours ago" -p err --no-pager 2>/dev/null | wc -l)
        if [[ $FSCK_ERRORS -gt 0 ]]; then
            echo "WARNING: Found $FSCK_ERRORS filesystem check errors in last 24 hours" >&2
            CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + FSCK_ERRORS))
        fi
    fi
else
    # Check sosreport for fsck output
    if [[ -f "${RISU_ROOT}/sos_commands/filesys/fsck_-l" ]]; then
        FSCK_OUTPUT=$(cat "${RISU_ROOT}/sos_commands/filesys/fsck_-l")
        if echo "$FSCK_OUTPUT" | grep -q "FAILED\|ERROR\|CORRUPTION"; then
            echo "WARNING: Filesystem check errors found in sosreport" >&2
            CORRUPTION_ISSUES=$((CORRUPTION_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $CORRUPTION_ISSUES -gt 5 ]]; then
    echo "CRITICAL: Multiple filesystem corruption issues found ($CORRUPTION_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $CORRUPTION_ISSUES -gt 0 ]]; then
    echo "WARNING: Filesystem corruption issues found ($CORRUPTION_ISSUES)" >&2
    exit $RC_FAILED
else
    echo "No filesystem corruption detected" >&2
    exit $RC_OKAY
fi
