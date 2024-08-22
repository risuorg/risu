#!/usr/bin/env python
# coding=utf-8
# Copyright (C) 2022, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
# long_name: Page Type Available
# description: Display in a human readable format the content of /proc/pagetypeinfo
# priority: 0
# Loading some modules
from __future__ import print_function

import os
import re
import sys

# Getting environment
root_path = os.getenv("RISU_ROOT", "")
RC_OKAY = int(os.environ["RC_OKAY"])
RC_SKIPPED = int(os.environ["RC_SKIPPED"])


# PageTypeInfo path
pagetypeinfo = os.path.join(root_path, "/proc/pagetypeinfo")


def errorprint(*args, **kwargs):
    """
    Prints to stderr a string
    :type args: String to print
    """
    print(*args, file=sys.stderr, **kwargs)


# We validate if the file exists and is readable
if os.access(pagetypeinfo, os.R_OK) is False:
    errorprint("File %s is not readable" % pagetypeinfo)
    sys.exit(RC_SKIPPED)

# Parsing the file
with open(pagetypeinfo, "r") as file:
    for line in file:
        match = re.match(
            r"Node[\s]+([0-9]+), zone[\s]+([^,]+), type[\s]+([^\s]+) ([0-9\s]+)", line
        )
        if match:
            errorprint(
                "Node %-2s Zone %6s Type %-11s "
                % (match.group(1), match.group(2), match.group(3)),
                end="",
            )
            p = re.findall("([0-9]+)", match.group(4))
            # By default, PAGE_SIZE is 4Kb. If we want to change this, we need a custom kernel
            factor = 4

            # Initialization of total_size
            total_size = 0
            for i in p:
                size = int(i) * factor / 1024.0
                total_size += size
                errorprint("%8.2f Mb " % size, end="")
                factor *= 2

            errorprint("= %8.2f Mb" % total_size)

sys.exit(RC_OKAY)
