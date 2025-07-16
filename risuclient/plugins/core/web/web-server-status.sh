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

# long_name: Check web server status
# description: Check web server status and configuration
# priority: 500

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

WEB_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check common web servers
    WEB_SERVERS=("httpd" "apache2" "nginx" "lighttpd")

    for server in "${WEB_SERVERS[@]}"; do
        if systemctl is-active "$server" >/dev/null 2>&1; then
            echo "INFO: Web server $server is active" >&2

            # Check if web server is listening on expected ports
            if command -v netstat >/dev/null 2>&1; then
                HTTP_LISTENING=$(netstat -tln | grep -c ":80 ")
                HTTPS_LISTENING=$(netstat -tln | grep -c ":443 ")

                if [[ $HTTP_LISTENING -eq 0 ]]; then
                    echo "WARNING: No service listening on HTTP port 80" >&2
                    WEB_ISSUES=$((WEB_ISSUES + 1))
                fi

                if [[ $HTTPS_LISTENING -eq 0 ]]; then
                    echo "WARNING: No service listening on HTTPS port 443" >&2
                    WEB_ISSUES=$((WEB_ISSUES + 1))
                fi
            fi

            # Check web server error logs
            if [[ $server == "httpd" || $server == "apache2" ]]; then
                if [[ -f "/var/log/httpd/error_log" ]]; then
                    RECENT_ERRORS=$(tail -100 /var/log/httpd/error_log | grep -c "error\|critical\|alert\|emergency" || echo "0")
                    if [[ $RECENT_ERRORS -gt 10 ]]; then
                        echo "WARNING: Found $RECENT_ERRORS recent errors in Apache error log" >&2
                        WEB_ISSUES=$((WEB_ISSUES + 1))
                    fi
                fi
            elif [[ $server == "nginx" ]]; then
                if [[ -f "/var/log/nginx/error.log" ]]; then
                    RECENT_ERRORS=$(tail -100 /var/log/nginx/error.log | grep -c "error\|crit\|alert\|emerg" || echo "0")
                    if [[ $RECENT_ERRORS -gt 10 ]]; then
                        echo "WARNING: Found $RECENT_ERRORS recent errors in Nginx error log" >&2
                        WEB_ISSUES=$((WEB_ISSUES + 1))
                    fi
                fi
            fi
        fi
    done

    # Check if any web server is running
    WEB_RUNNING=0
    for server in "${WEB_SERVERS[@]}"; do
        if systemctl is-active "$server" >/dev/null 2>&1; then
            WEB_RUNNING=1
            break
        fi
    done

    if [[ $WEB_RUNNING -eq 0 ]]; then
        echo "INFO: No common web servers are running" >&2
    fi
else
    # Check sosreport for web server information
    WEB_SERVERS=("httpd" "apache2" "nginx" "lighttpd")

    for server in "${WEB_SERVERS[@]}"; do
        if [[ -f "${RISU_ROOT}/systemctl_is-active_${server}" ]]; then
            STATUS=$(cat "${RISU_ROOT}/systemctl_is-active_${server}" 2>/dev/null || echo "inactive")
            if [[ $STATUS == "active" ]]; then
                echo "INFO: Web server $server was active" >&2

                # Check web server error logs in sosreport
                if [[ $server == "httpd" || $server == "apache2" ]]; then
                    if [[ -f "${RISU_ROOT}/var/log/httpd/error_log" ]]; then
                        RECENT_ERRORS=$(tail -100 "${RISU_ROOT}/var/log/httpd/error_log" | grep -c "error\|critical\|alert\|emergency" || echo "0")
                        if [[ $RECENT_ERRORS -gt 10 ]]; then
                            echo "WARNING: Found $RECENT_ERRORS recent errors in Apache error log" >&2
                            WEB_ISSUES=$((WEB_ISSUES + 1))
                        fi
                    fi
                elif [[ $server == "nginx" ]]; then
                    if [[ -f "${RISU_ROOT}/var/log/nginx/error.log" ]]; then
                        RECENT_ERRORS=$(tail -100 "${RISU_ROOT}/var/log/nginx/error.log" | grep -c "error\|crit\|alert\|emerg" || echo "0")
                        if [[ $RECENT_ERRORS -gt 10 ]]; then
                            echo "WARNING: Found $RECENT_ERRORS recent errors in Nginx error log" >&2
                            WEB_ISSUES=$((WEB_ISSUES + 1))
                        fi
                    fi
                fi
            fi
        fi
    done

    # Check if ports were listening in sosreport
    if [[ -f "${RISU_ROOT}/netstat_-tln" ]]; then
        HTTP_LISTENING=$(grep -c ":80 " "${RISU_ROOT}/netstat_-tln" || echo "0")
        HTTPS_LISTENING=$(grep -c ":443 " "${RISU_ROOT}/netstat_-tln" || echo "0")

        if [[ $HTTP_LISTENING -eq 0 ]]; then
            echo "WARNING: No service was listening on HTTP port 80" >&2
            WEB_ISSUES=$((WEB_ISSUES + 1))
        fi

        if [[ $HTTPS_LISTENING -eq 0 ]]; then
            echo "WARNING: No service was listening on HTTPS port 443" >&2
            WEB_ISSUES=$((WEB_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $WEB_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple web server issues found ($WEB_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $WEB_ISSUES -gt 1 ]]; then
    echo "WARNING: Web server issues found ($WEB_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $WEB_ISSUES -gt 0 ]]; then
    echo "INFO: Minor web server issues found ($WEB_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Web servers appear to be healthy" >&2
    exit $RC_OKAY
fi
