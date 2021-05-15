#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: This UT check that no test has echo $RC_
#
# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
# Copyright (C) 2020 stickler-ci <support@stickler-ci.com>

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
import random
import sys
from unittest import TestCase

import risuclient.shell as risu

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))


testplugins = os.path.join(risu.risudir, "plugins", "test")
plugins = os.path.join(risu.risudir, "plugins", "core")
folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), "setup")
uttest = risu.findplugins(folders=[folder])
citplugs = risu.findplugins(folders=[plugins])

okay = random.randint(10, 29)
failed = random.randint(30, 49)
skipped = random.randint(50, 69)
info = random.randint(70, 89)

# Setup commands and expected return codes
rcs = {"pass": okay, "fail": failed, "skipped": skipped, "info": info}


class RisuTest(TestCase):
    def test_plugins_no_echo_RC(self):
        for plugin in citplugs:
            result = risu.regexpfile(
                filename=plugin["plugin"], regexp=r".*echo \$RC_.*"
            )
            if result == "":
                print(plugin["plugin"])
                assert result == ""
