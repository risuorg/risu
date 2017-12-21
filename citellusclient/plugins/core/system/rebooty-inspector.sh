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
# url: https://github.com/ryran/Rebooty-inspector/blob/master/Rebooty-inspector


# Cloned + adapted from the code of Rebooty Inspector
# Rebooty-inspector v0.3.0 last mod 2015/07/23
# Latest version at <http://github.com/ryran/Rebooty-inspector>
# Ryan Sawhill Aroha <rsaw@redhat.com>

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# Defaults
: ${debug:=0}
: ${logFile:="/var/log/messages"}
: ${logFacility:="user"}
: ${logSuccessPrio:="info"}
: ${logFailPrio:="error"}
: ${logTag:="$app"}
: ${logSuccess:="Most recent boot follows graceful shutdown"}
: ${logFailure:="MOST RECENT BOOT FOLLOWS UNGRACEFUL SHUTDOWN"}
: ${tag_beginFile:="Reached beginning of input -- ran out of log entries"}
: ${tag_eventSeperator:="\n"}
: ${tag_noMatch:="Input contained 0 boot events matching regex:"}


usage=""
help=""


show_usage() {
    printf "${usage}"
}

show_help() {
    printf "${usage}${help}"
}

err() {
    printf "${@}\n" >&2
}


k='\033[0;30m'    # Black
r='\033[0;31m'    # Red
g='\033[0;32m'    # Green
y='\033[0;33m'    # Yellow
b='\033[0;34m'    # Blue
p='\033[0;35m'    # Purple
c='\033[0;36m'    # Cyan
w='\033[0;37m'    # White
K='\033[1;30m'    # Black
R='\033[1;31m'    # Red
G='\033[1;32m'    # Green
Y='\033[1;33m'    # Yellow
B='\033[1;34m'    # Blue
P='\033[1;35m'    # Purple
C='\033[1;36m'    # Cyan
W='\033[1;37m'    # White
D='\033[1;1m'     # Bold
Z='\033[0;0m'     # Zero colors


autodetect_rhel5_syslog_type() {
    local chkconfigOutput= rpmOutput= _type=
    if [[ -z ${rootDir} || ${rootDir} == / ]]; then
        chkconfigOutput=$(chkconfig --list syslog; chkconfig --list rsyslog)
        rpmOutput=$(rpm -q rsyslog rsyslog5 2>/dev/null)
    elif [[ -r ${rootDir}/chkconfig && -r ${rootDir}/installed-rpms ]]; then
        chkconfigOutput=$(gawk '$1 ~ /^r?syslog$/' <"${rootDir}"/chkconfig)
        rpmOutput=$(gawk '/^rsyslog(-3|5-)/' <"${rootDir}"/installed-rpms)
    else
        err "${app}: unable to read chkconfig/installed-rpms to determine syslog type!"
        exit 4
    fi
    _type=$(gawk '$5 ~ /on/ {print $1}' <<<"${chkconfigOutput}")
    case ${_type} in
        syslog)
            printf "${D}Log format detected as sysklogd${Z}\n"
            os=5
            ;;
        rsyslog)
            if grep -q '^rsyslog5-' <<<"${rpmOutput}"; then
                printf "${D}Log format detected as rsyslog5${Z}\n"
                os=5-rsyslog5
            elif grep -q '^rsyslog-3' <<<"${rpmOutput}"; then
                printf "${D}Log format detected as rsyslog3${Z}\n"
                os=5-rsyslog3
            else
                err "${app}: unknown rsyslog version (only rsyslog3 & rsyslog5 are implemented)"
                exit 4
            fi
            ;;
        *)
            err "${app}: unable to determine syslog type by looking for enabled 'r?syslog' in chkconfig!"
            exit 4
    esac
}


set_os_release() {
    # if grep -qs 'Red Hat Enterprise Linux .*Nahant' /etc/redhat-release; then
    #     err "OS detected as RHEL 4"
    #     os=4
    if grep -qs 'Red Hat Enterprise Linux .*Tikanga' "${rootDir}"/etc/redhat-release; then
        printf "${D}OS detected as RHEL 5${Z}\n"
        os=5
        autodetect_rhel5_syslog_type
        printf "\n"
    elif grep -qs 'Red Hat Enterprise Linux .*Santiago' "${rootDir}"/etc/redhat-release; then
        printf "${D}OS detected as RHEL 6${Z}\n\n"
        os=6
    elif grep -qs 'Red Hat Enterprise Linux .*Maipo' "${rootDir}"/etc/redhat-release; then
        printf "${D}OS detected as RHEL 7${Z}\n\n"
        os=7
    else
        printf "${D}OS not detected as RHEL 4-7${Z}\n\n"
        os=UNKNOWN
        return 1
    fi
}


parse_positional_params() {
    logit= all= desiredEvent= quiet= verbose= lines=1 os=auto rootDir= glob= nocolor=
    until [[ ${1} == -- ]]; do
        case "${1}" in
            -h|--help)      show_help ;;
            -l|--logit)     logit=1 ;;
            -a|--all)       all=1 ;;
            -e|--event)     shift; desiredEvent=${1} all=1 verbose=1 lines=40 ;;
            -q|--quiet)     quiet=1 ;;
            -v|--verbose)   verbose=1 ;;
            -n|--lines)     shift; lines=${1} verbose=1 ;;
            -o|--os)        shift; os=${1} ;;
            -f|--file)      shift; logFile=${1} ;;
            -g|--glob)      glob=1 ;;
            -x|--nocolor)   nocolor=1 ;;
        esac
        shift
    done
    shift
    rootDir=${@}
    if [[ -n ${rootDir} && ! -d ${rootDir} ]]; then
        err "${app}: specified root path is not a directory -- '${rootDir}'"
        exit 2
    fi
    case ${os} in
        auto)
            if ! set_os_release; then
                err "${app}: unable to auto-detect OS logtype based on ${rootDir}/etc/redhat-release"
                exit 3
            fi ;;
        4|5|5-rsyslog3|5-rsyslog5|6|7)
            printf "${D}OS logtype set as ${os}${Z}\n\n" ;;
        *)
            err "${app}: invalid os choice -- '${os}'"
            show_usage 1
    esac
    if [[ ! -r ${rootDir}${logFile} ]]; then
        err "${app}: unable to read specified log file -- '${rootDir}${logFile}'"
        exit 2
    fi
    if [[ -n ${quiet} && -n ${verbose} ]]; then
        err "${app}: mutually-exclusive options -- 'quiet' and 'verbose'"
        show_usage 1
    fi
    if [[ -n ${logit} && -n ${all} ]]; then
        err "${app}: mutually-exclusive options -- 'logit' and 'all'"
        show_usage 1
    fi
    if [[ -n ${lines} ]] && ! grep -q '^[1-9][0-9]*$' <<<"${lines}"; then
        err "${app}: invalid argument to lines option -- '${lines}'"
        show_usage 1
    fi
    if [[ -n ${desiredEvent} ]] && ! grep -q '^[1-9][0-9]*$' <<<"${desiredEvent}"; then
        err "${app}: invalid argument to event option -- '${desiredEvent}'"
        show_usage 1
    fi
    if [[ -n ${nocolor} ]]; then
        k= r= g= y= b= p= c= w= K= R= G= Y= B= P= C= W= Z=
    fi
}

# Setup temporary file for awk script
[[ -d /dev/shm && -w /dev/shm ]] && parent=/dev/shm || parent=/tmp
TMPDIR=$(mktemp -d -p ${parent})
gawkFile=${TMPDIR}/gawkFile
if [[ ${debug} == 1 ]]; then
    err "DEBUG: gawk script @ ${gawkFile}"
else
    trap "rm -rf ${TMPDIR} 2>/dev/null" INT TERM EXIT
fi

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
    else {
        printf "%sInvalid OS log type: %s%s\n", RED, logType, zero
        exit
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


# getopt options
shortOpts="hlae:qvn:o:f:gx"
longOpts="help,logit,all,event:,quiet,verbose,lines:,os:,file:,glob,nocolor"

# Check for bad options
getopt -Q --name=${app} -o ${shortOpts} -l ${longOpts} -- "${@}" || show_usage 1

# Parse options proper-like and set variables appropriately
parse_positional_params $(getopt -u --name=${app} -o ${shortOpts} -l ${longOpts} -- "${@}")

### MAIN ###

get_input() {
    # This is a separate function because bash<4 doesn't pipe when you do:
    #   COND && CMD1 || CMD2 | CMD3
    [[ -n ${glob} ]] && tac "${rootDir}${logFile}"* || tac "${rootDir}${logFile}"
}

get_input |
    gawk \
        -v logType=${os} \
        -v all=${all:-0} \
        -v desiredEvent=${desiredEvent:-0} \
        -v lines=${lines} \
        -v tag_beginFile="${tag_beginFile}" \
        -v tag_eventSeperator="${tag_eventSeperator}" \
        -v tag_noMatch="${tag_noMatch}" \
        -v logit=${logit:-0} \
        -v quiet=${quiet:-0} \
        -v verbose=${verbose:-0} \
        -v logSuccess="${logSuccess}" \
        -v logFailure="${logFailure}" \
        -v logFacility=${logFacility} \
        -v logSuccessPrio=${logSuccessPrio} \
        -v logFailPrio=${logFailPrio} \
        -v logTag=${logTag} \
        -v bold="${D}" \
        -v red="${r}" \
        -v RED="${R}" \
        -v green="${g}" \
        -v GREEN="${G}" \
        -v cyan="${c}" \
        -v CYAN="${C}" \
        -v purple="${p}" \
        -v PURPLE="${P}" \
        -v blue="${b}" \
        -v BLUE="${B}" \
        -v yellow="${y}" \
        -v YELLOW="${Y}" \
        -v zero="${Z}" \
        -f "${gawkFile}"
: