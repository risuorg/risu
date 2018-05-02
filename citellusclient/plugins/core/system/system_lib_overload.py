#!/usr/bin/env python
# coding=utf-8

# Copyright (C) 2018  Renaud Métrich (rmetrich@redhat.com)

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

# long_name: System Libraries Overloaded
# description: List system libraries that are overloaded
# priority: 400

# Loading some modules
from __future__ import print_function
import re
import sys
import os
import subprocess

# Import the _() function
import gettext
localedir = os.environ['TEXTDOMAINDIR']
# This will use system defined LANGUAGE
trad = gettext.translation('citellus', localedir, fallback=True)

try:
    _ = trad.ugettext
except AttributeError:
    _ = trad.gettext

# Getting environment
root_path = os.getenv('CITELLUS_ROOT', '')
RC_OKAY = int(os.environ['RC_OKAY'])
RC_SKIPPED = int(os.environ['RC_SKIPPED'])
RC_FAILED = int(os.environ['RC_FAILED'])


def errorprint(*args, **kwargs):
    """
    Prints to stderr a string
    :type args: String to print
    """
    print(*args, file=sys.stderr, **kwargs)


# ldconfig_-p_-N_-X path (sosreport)
ldconfig = os.path.join(root_path, "sos_commands/libraries/ldconfig_-p_-N_-X")

# We validate if the file exists and is readable
if os.access(ldconfig, os.R_OK) is False:
    if root_path is not '':
        errorprint("File %s is not readable" % ldconfig)
        sys.exit(RC_SKIPPED)
    else:
        content = subprocess.check_output(["/usr/sbin/ldconfig", "-p", "-N", "-X"])
else:
    f = open(ldconfig, "r")
    content = f.read()
    f.close()


# Matches libc6[,(arch)][, xxx] with $1 == arch or 'native'
# e.g. "libc6" or "libc6,x86_64" or "libc6, OS ABI: Linux 2.6.32"
archregex = re.compile(r"libc6(?:,([^\s]+))?(?:,.*)?")

# Matches a ldconfig line
# e.g. "libEGL.so (libc6,x86-64) => /lib64/libEGL.so" with $1 == lib, $2 == arches, $3 == path
regex = re.compile(r"^\s+(\S+)\s\(([^\)]+)\)\s=>\s(.*)$")

# Matches system paths (/lib, /lib64, /usr/lib, /usr/lib64)
spregex = re.compile(r"(?:/usr)?/lib(?:64)?/")

# For each library found, record arch and path
libs = dict()

overloaded_libs = dict()

# Parse the content
for line in content.splitlines():
    m = regex.match(line)
    if m is None:
        # e.g. 1st line "1610 libs found in cache `/etc/ld.so.cache'"
        continue
    lib = m.group(1)
    a = archregex.match(m.group(2))
    if a is None:
        # e.g. "ld-linux.so.2 (ELF) => /lib/ld-linux.so.2"
        continue
    arch = a.group(1) or 'native'
    path = m.group(3)

    if lib not in libs:
        # New entry, skip if already a system lib
        if spregex.match(path):
            continue
        # New entry for non-system lib
        libs[lib] = dict()
        libs[lib][arch] = path
    elif arch not in libs[lib]:
        # New arch entry
        libs[lib][arch] = path
    else:
        # Collide with existing lib, check that overloaded lib is a system lib
        if not spregex.match(path):
            continue

        # Check also that this is a real system lib (and not a symlink to 'self')
        if root_path == '':
            if os.path.realpath(path) == libs[lib][arch]:
                # e.g. /lib64/libdchtvm.so.8 -> /opt/dell/srvadmin/lib64/libdchtvm.so.8
                continue
        elif os.path.realpath(os.path.join(root_path, path[1:])) == libs[lib][arch]:
            # Same as above, in a sosreport (unlikely to happen)
            # e.g. /lib64/libdchtvm.so.8 -> /opt/dell/srvadmin/lib64/libdchtvm.so.8
            continue

        if lib not in overloaded_libs:
            overloaded_libs[lib] = dict()
        overloaded_libs[lib][arch] = {"system": path, "used": libs[lib][arch]}

if not overloaded_libs:
    sys.exit(RC_OKAY)

errorprint(_(">>> Some system libraries are overloaded"))
for lib, entry in iter(overloaded_libs.items()):
    for arch, aentry in iter(entry.items()):
        errorprint("Library %s (%s), system path: %s, used path: %s"
                   % (lib, arch, aentry["system"], aentry["used"]))

sys.exit(RC_FAILED)
