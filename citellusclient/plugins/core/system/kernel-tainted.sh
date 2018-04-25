#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Checks if kernel has been tainted and reports value
# description: Checks kernel taint value
# priority: 100

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

# function for checking techpreview
function taintcheck {
TAINT=$1
TAINT_PROPRIETARY_MODULE=$(echo $((($TAINT & 0x1) != 0)))
TAINT_FORCED_MODULE=$(echo $((($TAINT & 0x2) != 0)))
TAINT_UNSAFE_SMP=$(echo $((($TAINT & 0x4) != 0)))
TAINT_FORCED_RMMOD=$(echo $((($TAINT & 0x8) != 0)))
TAINT_MACHINE_CHECK=$(echo $((($TAINT & 0x10) != 0)))
TAINT_BAD_PAGE=$(echo $((($TAINT & 0x20) != 0)))
TAINT_USER=$(echo $((($TAINT & 0x40) != 0)))
TAINT_DIE=$(echo $((($TAINT & 0x80) != 0)))
TAINT_OVERRIDDEN_ACPI_TABLE=$(echo $((($TAINT & 0x100) != 0)))
TAINT_WARN=$(echo $((($TAINT & 0x200) != 0)))
TAINT_CRAP=$(echo $((($TAINT & 0x400) != 0)))
TAINT_FIRMWARE_WORKAROUND=$(echo $((($TAINT & 0x800) != 0)))
TAINT_OOT_MODULE=$(echo $((($TAINT & 0x1000) != 0)))
TAINT_UNSIGNED_MODULE=$(echo $((($TAINT & 0x2000) != 0)))
TAINT_SOFTLOCKUP=$(echo $((($TAINT & 0x4000) != 0)))
TAINT_HARDWARE_UNSUPPORTED=$(echo $((($TAINT & 0x10000000) != 0)))
TAINT_TECH_PREVIEW=$(echo $((($TAINT & 0x20000000) != 0)))

if [[ "x$TAINT_PROPRIETARY_MODULE" = "x1" ]];then
    echo $"A kernel module with a non-GPL license has been loaded" >&2
fi
if [[ "x$TAINT_FORCED_MODULE" = "x1" ]];then
    echo $"A kernel module has been forcibly loaded" >&2
fi
if [[ "x$TAINT_UNSAFE_SMP" = "x1" ]];then
    echo $"The Linux kernel is running with Symmetric MultiProcessor support (SMP), but the CPUs in the system are not designed or certified for SMP use." >&2
fi
if [[ "x$TAINT_FORCED_RMMOD" = "x1" ]];then
    echo $"User forced a module unload. A module which was in use or was not designed to be removed has been forcefully removed from the running kernel " >&2
fi
if [[ "x$TAINT_MACHINE_CHECK" = "x1" ]];then
    echo $"A machine check exception occurred on the system. " >&2
fi
if [[ "x$TAINT_BAD_PAGE" = "x1" ]];then
    echo $"The system has hit bad_page, indicating a corruption of the virtual memory subsystem, possibly caused by malfunctioning RAM or cache memory." >&2
fi
if [[ "x$TAINT_USER" = "x1" ]];then
    echo $"The user has asked that the system be marked tainted"  >&2
fi
if [[ "x$TAINT_DIE" = "x1" ]];then
    echo $"Kernel has OOPSed before " >&2
fi
if [[ "x$TAINT_OVERRIDDEN_ACPI_TABLE" = "x1" ]];then
    echo $"ACPI table overridden" >&2
fi
if [[ "x$TAINT_WARN" = "x1" ]];then
    echo $"A kernel warning has occurred." >&2
fi
if [[ "x$TAINT_CRAP" = "x1" ]];then
    echo $"Modules from drivers/staging are loaded"  >&2
fi
if [[ "x$TAINT_FIRMWARE_WORKAROUND" = "x1" ]];then
    echo $"The kernel is working around a severe bug in the platform firmware (BIOS or similar)" >&2
fi
if [[ "x$TAINT_OOT_MODULE" = "x1" ]];then
    echo $"Out-of-tree kernel module has been loaded. " >&2
    if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
        if [[ -f "${CITELLUS_ROOT}/sos_commands/kernel/dmesg" ]];then
            grep "loading out-of-tree module taints kernel" "${CITELLUS_ROOT}/sos_commands/kernel/dmesg" >&2 ; echo >&2
        fi
    elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
        dmesg| grep  "loading out-of-tree module taints kernel"  >&2  ; echo >&2
    fi
fi
if [[ "x$TAINT_UNSIGNED_MODULE" = "x1" ]];then
    echo $"A kernel module was loaded which was unsigned." >&2
fi
if [[ "x$TAINT_SOFTLOCKUP" = "x1" ]];then
    echo $"A soft lockup has previously occurred on the system." >&2
fi
if [[ "x$TAINT_HARDWARE_UNSUPPORTED" = "x1" ]];then
    echo $"Hardware is unsupported " >&2
fi
if [[ "x$TAINT_TECH_PREVIEW" = "x1" ]]; then
    echo $"Tech preview kernel module has been loaded."  >&2
    if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
        if [[ -f  "${CITELLUS_ROOT}/sos_commands/kernel/dmesg" ]];then
            grep "TECH PREVIEW" "${CITELLUS_ROOT}/sos_commands/kernel/dmesg"  >&2 ; echo >&2
        fi
    elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
        dmesg| grep  "TECH PREVIEW"   >&2 ; echo >&2
    fi
fi
}

is_required_file ${CITELLUS_ROOT}/proc/sys/kernel/tainted
TAINT=$(cat ${CITELLUS_ROOT}/proc/sys/kernel/tainted)

if [[ "x$TAINT" = "x0" ]]; then
    exit ${RC_OKAY}
else
    echo $"Kernel is tainted" ${TAINT} >&2
    taintcheck ${TAINT}
    exit ${RC_FAILED}
fi


