#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: This UT will check all core scripts to validate that common functions is loaded
#
# Copyright (C) 2017, 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

import os
import re
from unittest import TestCase

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, "plugins", "test")
pluginsdir = os.path.join(citellus.citellusdir, "plugins", "core")
plugins = citellus.findplugins(folders=[pluginsdir])


class CitellusTest(TestCase):
    def test_ut_sourced_if_used(self):

        # Check list of plugins for regexp sourcing common functions and skip them
        nonsourcing = []
        for plugin in plugins:
            if not citellus.regexpfile(
                filename=plugin["plugin"], regexp=".*common-functions"
            ):
                nonsourcing.append(plugin["plugin"])

        commonfunctions = []

        for script in citellus.findplugins(
            folders=[os.path.join(citellus.citellusdir, "common.d")],
            fileextension=".sh",
        ):
            filename = script["plugin"]
            with open(filename, "r") as f:
                for line in f:
                    find = re.match("^(([a-z]+_+)+[a-z]*)", line)
                    if find and find.groups()[0] != "":
                        commonfunctions.append(find.groups()[0])

        usingcf = []
        for plugin in nonsourcing:
            for func in commonfunctions:
                if citellus.regexpfile(filename=plugin, regexp=".*%s" % func):
                    usingcf.append(plugin)

        assert sorted(set(usingcf)) == []
