#!/usr/bin/env bash
# Description: This script creates a validation environment for running the
#              test named like this one against and check correct behavior
#
# Copyright (C) 2018  Benoit Welterlen (bwelterl@redhat.com)
#
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


# The way we're executed, $1 is the script name, $2 is the mode and $3 is the folder
FOLDER=$3

case $2 in
    pass)
        # Default limits configuration files
        mkdir -p ${FOLDER}/etc/security/limits.d/
        cat > "${FOLDER}/etc/security/limits.conf" << EOF
*               soft    core            0
*               hard    rss             10000
@student        hard    nproc           20
@faculty        soft    nproc           20
@faculty        hard    nproc           50
ftp             hard    nproc           0
EOF
        cat > "${FOLDER}/etc/security/limits.d/90-nofile.conf" << EOF
soft    nproc     4096
root       soft    nproc     unlimited
EOF
        ;;

    fail1)
        # non ASCII characters in limits.conf
        mkdir -p ${FOLDER}/etc/security/
        cat > "${FOLDER}/etc/security/limits.conf" << EOF
tomcat     soft    nofile      1480
tomcat     hard    nofile      1480
tomcat     soft    nproc       1096
EOF
        ;;

    fail2)
        # non ASCII characters in /etc/security/limits.d/90-nofile.conf
        mkdir -p ${FOLDER}/etc/security/limits.d/
        touch "${FOLDER}/etc/security/limits.conf"
        cat > "${FOLDER}/etc/security/limits.d/90-nofile.conf" << EOF
tomcat      soft    nofile      2480
tomcat      hard    nofile      2480
tomcat      soft    nproc       1096
EOF
        ;;

    fail3)
        # non ASCII characters on both limits.conf and  /etc/security/limits.d/90-nofile.conf
        mkdir -p ${FOLDER}/etc/security/limits.d/
        cat > "${FOLDER}/etc/security/limits.conf" << EOF
tomcat      soft    nofile      1480
tomcat      hard    nofile      1480
tomcat      soft    nproc       1096
EOF
        cat > "${FOLDER}/etc/security/limits.d/90-nofile.conf" << EOF
tomcat      soft    nofile      2480
tomcat      hard    nofile      2480
tomcat      soft    nproc       1096
EOF
        ;;

esac
