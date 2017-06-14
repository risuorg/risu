#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

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

# Checking httpd
# Ref: None
REFNAME="httpd Module"



count_lines "${DIRECTORY}/var/log/httpd/error_log" "MaxRequestWorkers" \
" \_ Check /etc/httpd/prefork.conf values MaxClients and ServerLimit are set to value 512 - Ref: https://bugzilla.redhat.com/show_bug.cgi?id=1163516"

# Check httpd service is running and isn't failed

grep_file_rev "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all" "httpd.*failed"
