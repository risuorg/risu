#!/bin/bash

# Copyright (C) 2017 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Investigate reboots in the server
# description: Reports reboots in a server either scheduled, unexpected, etc

# Cloned + adapted from the code of Rebooty Inspector
# Rebooty-inspector v0.3.0 last mod 2015/07/23
# Latest version at <http://github.com/ryran/Rebooty-inspector>
# Ryan Sawhill Aroha <rsaw@redhat.com>

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

if is_active rsyslog;then
    os=5
elif is_active syslog; then
    if is_rpm rsyslog5-.*; then
        os=5-rsyslog5
    elif is_rpm rsyslog-3; then
        os=5-rsyslog3
    fi
fi

gawkFile=${TMPDIR}/gawkFile

cat >${gawkFile} <<\EOF
function getline_err(id) {
    printf "    %s? %s %s%s\n", yellow, tag_beginFile, id, zero
}
function cprint(startColor, input) {
    printf "%s%s%s\n", startColor, input, zero
}
BEGIN {
    w = "[[:graph:]]+ +"
    if (logType == "5") {
        RE_first = "^" w w w w "syslogd " w "restart\\."
        RE_first_minus_1 = "^" w w w w "exiting on signal 15$"
    }
    else if (logType == "5-rsyslog3") {
        RE_first = "kernel: imklog " w "log source = /proc/kmsg started"
        RE_first_minus_1 = ""
        need_fuzzySearching = 1
        RE_fuzzy = "^" w w w w "shutdown\\[[0-9]+\\]: shutting down for system|(exiting on|received) signal 15"
    }
    else if (logType == "5-rsyslog5") {
        RE_first = "kernel: imklog .* log source = /proc/kmsg started"
        RE_first_minus_1 = "rsyslogd: .* exiting on signal 15\\.$"
    }
    else if (logType == "6") {
        RE_first = "kernel: imklog .* log source = /proc/kmsg started"
        RE_first_minus_1 = "rsyslogd: .* exiting on signal 15\\.$"
    }
    else if (logType == "7") {
        RE_first = "rsyslogd: .* start"
        RE_first_minus_1 = "rsyslogd:.*exiting on signal 15\\.$"
    }
    RE_kernelVers = "kernel: Linux version"
    eventNum = 0
    mostRecentMsg = " (most recent)"
    True = 1
    False = 0
}
$0 ~ RE_kernelVers {
    eventNum++
    kernelVersLogEntry = $0
    kernelVers = $8
    if (quiet == False) {
        if (desiredEvent > 0) {
            if (desiredEvent > eventNum)
                next
        }
        else if (eventNum == 2)
            mostRecentMsg = ""
    }
    n = 0
    while ($0 !~ RE_first) {
        if ((getline) < 1) {
            getline_err("prior to Linux version msg")
            next
        }
        if (n > 30) {
            printf "  %s❔ Debug 0: Could not find initial start string within 30 lines of Linux version string%s\n", YELLOW, zero
            next
        }
        n++
    }
    startLogEntry = $0
    hn = $4
    datetime_start = $1 " " $2 " " $3
    if (quiet == False)
        printf "%s#[%d] %s (%s) startup at %s%s\n", CYAN, eventNum, hn, kernelVers, datetime_start, mostRecentMsg, zero
    if ((getline) < 1) {
        getline_err("prior to initial startup msg")
        next
    }
    if (need_fuzzySearching == True) {
        while ($0 !~ RE_fuzzy) {
            if ((getline) < 1 || $0 ~ RE_first) {
                if (quiet == False)
                    printf "  %s✘ NOT PRECEDED BY CLEAN SHUTDOWN!%s\n", RED, zero
                logPrio = logFailPrio; logMsg = logFailure
                break
            }
        }
        if (quiet == False)
            printf "  %s✔ Preceded by clean shutdown%s\n", GREEN, zero
        logPrio = logSuccessPrio; logMsg = logSuccess
    }
    else if ($0 ~ RE_first_minus_1) {
        if (quiet == False)
            printf "  %s✔ Preceded by clean shutdown%s\n", GREEN, zero
        logPrio = logSuccessPrio; logMsg = logSuccess
    }
    else {
        if (quiet == False)
            printf "  %s✘ NOT PRECEDED BY CLEAN SHUTDOWN!%s\n", RED, zero
        logPrio = logFailPrio; logMsg = logFailure
    }
    if (verbose == True) {
        printf "  %sRelevant log(s):%s\n", BLUE, zero
        delete logEntries
        i = 0
        n = lines
        while (n > 0) {
            logEntries[i++] = $0
            if ((getline) < 1) {
                getline_err("prior to initial startup msg")
                break
            }
            n--
        }
        while (i--)
            printf "    %s%s%s\n", blue, logEntries[i], zero
        printf "    %s%s%s\n", purple, startLogEntry, zero
        printf "    %s%s%s\n", purple, kernelVersLogEntry, zero
    }
    if (logit == True) {
        if (verbose == True)
            printf "  Using logger to send message:\n    %s\n", logMsg
        system("logger -p " logFacility "." logPrio " -t " logTag " " logMsg)
    }
    if (all == False || desiredEvent == eventNum)
        exit
    else
        printf "%s", tag_eventSeperator
}
END {
    if (eventNum == 0) {
        printf "%s%s\n  %s%s\n", YELLOW, tag_noMatch, RE_first, zero
        exit(7)
    }
}
EOF

gawk \
    -v logType=${os} \
    -v all=${all:-0} \
    -v desiredEvent=${desiredEvent:-0} \
    -v lines=${lines} \
    -v tag_beginFile="${tag_beginFile}" \
    -v tag_eventSeperator="${tag_eventSeperator}" \
    -v tag_noMatch="${tag_noMatch}" \
    -f "${gawkFile}"