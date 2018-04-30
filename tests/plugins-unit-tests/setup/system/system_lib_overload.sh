#!/usr/bin/env bash
# Description: This script creates a validation environment for running the
#              test named like this one against and check correct behavior
#
# Copyright (C) 2018  Renaud Métrich (rmetrich@redhat.com)
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
    pass1)
        # only system libraries
        mkdir -p ${FOLDER}/sos_commands/libraries
        cat > "${FOLDER}/sos_commands/libraries/ldconfig_-p_-N_-X" << EOF
28 libs found in cache '/etc/ld.so.cache'
        p11-kit-trust.so (libc6,x86-64) => /lib64/p11-kit-trust.so
        libzapojit-0.0.so.0 (libc6,x86-64) => /lib64/libzapojit-0.0.so.0
        libz.so.1 (libc6,x86-64) => /lib64/libz.so.1
        libz.so.1 (libc6) => /lib/libz.so.1
        libz.so (libc6,x86-64) => /lib64/libz.so
        libyubikey.so.0 (libc6,x86-64) => /lib64/libyubikey.so.0
        libykpers-1.so.1 (libc6,x86-64) => /lib64/libykpers-1.so.1
        libyelp.so.0 (libc6,x86-64) => /lib64/libyelp.so.0
        libyaml-0.so.2 (libc6,x86-64) => /lib64/libyaml-0.so.2
        libyajl.so.2 (libc6,x86-64) => /lib64/libyajl.so.2
        libx26410b.so.142 (libc6,x86-64) => /lib64/libx26410b.so.142
        libx265_main12.so.79 (libc6,x86-64) => /lib64/libx265_main12.so.79
        libx265_main12.so (libc6,x86-64) => /lib64/libx265_main12.so
        libx265_main10.so.79 (libc6,x86-64) => /lib64/libx265_main10.so.79
        libx265_main10.so (libc6,x86-64) => /lib64/libx265_main10.so
        libx265.so.79 (libc6,x86-64) => /lib64/libx265.so.79
        libx264.so.142 (libc6,x86-64) => /lib64/libx264.so.142
        libxvidcore.so.4 (libc6,x86-64) => /lib64/libxvidcore.so.4
        libxtables.so.10 (libc6,x86-64) => /lib64/libxtables.so.10
        libxslt.so.1 (libc6,x86-64) => /lib64/libxslt.so.1
        libxshmfence.so.1 (libc6,x86-64) => /lib64/libxshmfence.so.1
        libxshmfence.so.1 (libc6) => /lib/libxshmfence.so.1
        libBrokenLocale.so.1 (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so.1
        libBrokenLocale.so.1 (libc6, OS ABI: Linux 2.6.32) => /lib/libBrokenLocale.so.1
        libBrokenLocale.so (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so
        libAnacondaWidgets.so.2 (libc6,x86-64) => /lib64/libAnacondaWidgets.so.2
        ld-linux.so.2 (ELF) => /lib/ld-linux.so.2
        ld-linux-x86-64.so.2 (libc6,x86-64) => /lib64/ld-linux-x86-64.so.2
EOF
        ;;

    pass2)
        # some non-system libraries but not overloading system libraries (/my/path)
        mkdir -p ${FOLDER}/sos_commands/libraries
        cat > "${FOLDER}/sos_commands/libraries/ldconfig_-p_-N_-X" << EOF
28 libs found in cache '/etc/ld.so.cache'
        p11-kit-trust.so (libc6,x86-64) => /lib64/p11-kit-trust.so
        libzapojit-0.0.so.0 (libc6,x86-64) => /lib64/libzapojit-0.0.so.0
        libz.so.1 (libc6,x86-64) => /lib64/libz.so.1
        libz.so.1 (libc6) => /lib/libz.so.1
        libz.so (libc6,x86-64) => /lib64/libz.so
        libyubikey.so.0 (libc6,x86-64) => /lib64/libyubikey.so.0
        libykpers-1.so.1 (libc6,x86-64) => /lib64/libykpers-1.so.1
        libyelp.so.0 (libc6,x86-64) => /lib64/libyelp.so.0
        libyaml-0.so.2 (libc6,x86-64) => /lib64/libyaml-0.so.2
        libyajl.so.2 (libc6,x86-64) => /lib64/libyajl.so.2
        libx26410b.so.142 (libc6,x86-64) => /lib64/libx26410b.so.142
        libx265_main12.so.79 (libc6,x86-64) => /lib64/libx265_main12.so.79
        libx265_main12.so (libc6,x86-64) => /lib64/libx265_main12.so
        libx265_main10.so.79 (libc6,x86-64) => /lib64/libx265_main10.so.79
        libx265_main10.so (libc6,x86-64) => /lib64/libx265_main10.so
        libx265.so.79 (libc6,x86-64) => /my/path/lib64/libx265.so.79
        libx264.so.142 (libc6,x86-64) => /my/path/lib64/libx264.so.142
        libxvidcore.so.4 (libc6,x86-64) => /lib64/libxvidcore.so.4
        libxtables.so.10 (libc6,x86-64) => /lib64/libxtables.so.10
        libxslt.so.1 (libc6,x86-64) => /lib64/libxslt.so.1
        libxshmfence.so.1 (libc6,x86-64) => /lib64/libxshmfence.so.1
        libxshmfence.so.1 (libc6) => /lib/libxshmfence.so.1
        libBrokenLocale.so.1 (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so.1
        libBrokenLocale.so.1 (libc6, OS ABI: Linux 2.6.32) => /lib/libBrokenLocale.so.1
        libBrokenLocale.so (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so
        libAnacondaWidgets.so.2 (libc6,x86-64) => /lib64/libAnacondaWidgets.so.2
        ld-linux.so.2 (ELF) => /lib/ld-linux.so.2
        ld-linux-x86-64.so.2 (libc6,x86-64) => /lib64/ld-linux-x86-64.so.2
EOF
        ;;

    pass3)
        # some non-system libraries overloading system libraries but not
        # shipped by Red Hat (libdchtvm.so.8) but detected as such (may happen
        # on live system only
        mkdir -p ${FOLDER}/sos_commands/libraries
        cat > "${FOLDER}/sos_commands/libraries/ldconfig_-p_-N_-X" << EOF
28 libs found in cache '/etc/ld.so.cache'
        p11-kit-trust.so (libc6,x86-64) => /lib64/p11-kit-trust.so
        libzapojit-0.0.so.0 (libc6,x86-64) => /lib64/libzapojit-0.0.so.0
        libz.so.1 (libc6,x86-64) => /lib64/libz.so.1
        libz.so.1 (libc6) => /lib/libz.so.1
        libz.so (libc6,x86-64) => /lib64/libz.so
        libyubikey.so.0 (libc6,x86-64) => /lib64/libyubikey.so.0
        libykpers-1.so.1 (libc6,x86-64) => /lib64/libykpers-1.so.1
        libyelp.so.0 (libc6,x86-64) => /lib64/libyelp.so.0
        libyaml-0.so.2 (libc6,x86-64) => /lib64/libyaml-0.so.2
        libyajl.so.2 (libc6,x86-64) => /lib64/libyajl.so.2
        libx26410b.so.142 (libc6,x86-64) => /lib64/libx26410b.so.142
        libx265_main12.so.79 (libc6,x86-64) => /lib64/libx265_main12.so.79
        libx265_main12.so (libc6,x86-64) => /lib64/libx265_main12.so
        libx265_main10.so.79 (libc6,x86-64) => /lib64/libx265_main10.so.79
        libx265_main10.so (libc6,x86-64) => /lib64/libx265_main10.so
        libx265.so.79 (libc6,x86-64) => /my/path/lib64/libx265.so.79
        libx264.so.142 (libc6,x86-64) => /my/path/lib64/libx264.so.142
        libxvidcore.so.4 (libc6,x86-64) => /lib64/libxvidcore.so.4
        libxtables.so.10 (libc6,x86-64) => /lib64/libxtables.so.10
        libxslt.so.1 (libc6,x86-64) => /lib64/libxslt.so.1
        libdchtvm.so.8 (libc6,x86-64) => /opt/dell/srvadmin/lib64/libdchtvm.so.8
        libdchtvm.so.8 (libc6,x86-64) => /lib64/libdchtvm.so.8
        libBrokenLocale.so.1 (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so.1
        libBrokenLocale.so.1 (libc6, OS ABI: Linux 2.6.32) => /lib/libBrokenLocale.so.1
        libBrokenLocale.so (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so
        libAnacondaWidgets.so.2 (libc6,x86-64) => /lib64/libAnacondaWidgets.so.2
        ld-linux.so.2 (ELF) => /lib/ld-linux.so.2
        ld-linux-x86-64.so.2 (libc6,x86-64) => /lib64/ld-linux-x86-64.so.2
EOF
        mkdir -p ${FOLDER}/opt/dell/srvadmin/lib64
        touch ${FOLDER}/opt/dell/srvadmin/lib64/libdchtvm.so.8
        mkdir -p ${FOLDER}/lib64
        ln -s /opt/dell/srvadmin/lib64/libdchtvm.so.8 ${FOLDER}/lib64/libdchtvm.so.8
        ;;

    fail)
        # some non-system libraries overloading system libraries (libxml2)
        mkdir -p ${FOLDER}/sos_commands/libraries
        cat > "${FOLDER}/sos_commands/libraries/ldconfig_-p_-N_-X" << EOF
28 libs found in cache '/etc/ld.so.cache'
        p11-kit-trust.so (libc6,x86-64) => /lib64/p11-kit-trust.so
        libzapojit-0.0.so.0 (libc6,x86-64) => /lib64/libzapojit-0.0.so.0
        libxml2.so.2 (libc6,x86-64) => /usr/sap/H76/HDB00/exe/libxml2.so.2
        libxml2.so.2 (libc6,x86-64) => /lib64/libxml2.so.2
        libxml2.so (libc6,x86-64) => /usr/sap/H76/HDB00/exe/libxml2.so
        libyubikey.so.0 (libc6,x86-64) => /lib64/libyubikey.so.0
        libykpers-1.so.1 (libc6,x86-64) => /lib64/libykpers-1.so.1
        libyelp.so.0 (libc6,x86-64) => /lib64/libyelp.so.0
        libyaml-0.so.2 (libc6,x86-64) => /lib64/libyaml-0.so.2
        libyajl.so.2 (libc6,x86-64) => /lib64/libyajl.so.2
        libx26410b.so.142 (libc6,x86-64) => /lib64/libx26410b.so.142
        libx265_main12.so.79 (libc6,x86-64) => /lib64/libx265_main12.so.79
        libx265_main12.so (libc6,x86-64) => /lib64/libx265_main12.so
        libx265_main10.so.79 (libc6,x86-64) => /lib64/libx265_main10.so.79
        libx265_main10.so (libc6,x86-64) => /lib64/libx265_main10.so
        libx265.so.79 (libc6,x86-64) => /my/path/lib64/libx265.so.79
        libx264.so.142 (libc6,x86-64) => /my/path/lib64/libx264.so.142
        libxvidcore.so.4 (libc6,x86-64) => /lib64/libxvidcore.so.4
        libxtables.so.10 (libc6,x86-64) => /lib64/libxtables.so.10
        libxslt.so.1 (libc6,x86-64) => /lib64/libxslt.so.1
        libxshmfence.so.1 (libc6,x86-64) => /lib64/libxshmfence.so.1
        libxshmfence.so.1 (libc6) => /lib/libxshmfence.so.1
        libBrokenLocale.so.1 (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so.1
        libBrokenLocale.so.1 (libc6, OS ABI: Linux 2.6.32) => /lib/libBrokenLocale.so.1
        libBrokenLocale.so (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so
        libAnacondaWidgets.so.2 (libc6,x86-64) => /lib64/libAnacondaWidgets.so.2
        ld-linux.so.2 (ELF) => /lib/ld-linux.so.2
        ld-linux-x86-64.so.2 (libc6,x86-64) => /lib64/ld-linux-x86-64.so.2
EOF
        ;;

    falsepositive)
        # some non-system libraries overloading system libraries but not shipped by Red Hat (libdchtvm.so.8)
        mkdir -p ${FOLDER}/sos_commands/libraries
        cat > "${FOLDER}/sos_commands/libraries/ldconfig_-p_-N_-X" << EOF
28 libs found in cache '/etc/ld.so.cache'
        p11-kit-trust.so (libc6,x86-64) => /lib64/p11-kit-trust.so
        libzapojit-0.0.so.0 (libc6,x86-64) => /lib64/libzapojit-0.0.so.0
        libz.so.1 (libc6,x86-64) => /lib64/libz.so.1
        libz.so.1 (libc6) => /lib/libz.so.1
        libz.so (libc6,x86-64) => /lib64/libz.so
        libyubikey.so.0 (libc6,x86-64) => /lib64/libyubikey.so.0
        libykpers-1.so.1 (libc6,x86-64) => /lib64/libykpers-1.so.1
        libyelp.so.0 (libc6,x86-64) => /lib64/libyelp.so.0
        libyaml-0.so.2 (libc6,x86-64) => /lib64/libyaml-0.so.2
        libyajl.so.2 (libc6,x86-64) => /lib64/libyajl.so.2
        libx26410b.so.142 (libc6,x86-64) => /lib64/libx26410b.so.142
        libx265_main12.so.79 (libc6,x86-64) => /lib64/libx265_main12.so.79
        libx265_main12.so (libc6,x86-64) => /lib64/libx265_main12.so
        libx265_main10.so.79 (libc6,x86-64) => /lib64/libx265_main10.so.79
        libx265_main10.so (libc6,x86-64) => /lib64/libx265_main10.so
        libx265.so.79 (libc6,x86-64) => /my/path/lib64/libx265.so.79
        libx264.so.142 (libc6,x86-64) => /my/path/lib64/libx264.so.142
        libxvidcore.so.4 (libc6,x86-64) => /lib64/libxvidcore.so.4
        libxtables.so.10 (libc6,x86-64) => /lib64/libxtables.so.10
        libxslt.so.1 (libc6,x86-64) => /lib64/libxslt.so.1
        libdchtvm.so.8 (libc6,x86-64) => /opt/dell/srvadmin/lib64/libdchtvm.so.8
        libdchtvm.so.8 (libc6,x86-64) => /lib64/libdchtvm.so.8
        libBrokenLocale.so.1 (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so.1
        libBrokenLocale.so.1 (libc6, OS ABI: Linux 2.6.32) => /lib/libBrokenLocale.so.1
        libBrokenLocale.so (libc6,x86-64, OS ABI: Linux 2.6.32) => /lib64/libBrokenLocale.so
        libAnacondaWidgets.so.2 (libc6,x86-64) => /lib64/libAnacondaWidgets.so.2
        ld-linux.so.2 (ELF) => /lib/ld-linux.so.2
        ld-linux-x86-64.so.2 (libc6,x86-64) => /lib64/ld-linux-x86-64.so.2
EOF
        ;;

    skip)
        # no ldconfig file
        ;;

esac
