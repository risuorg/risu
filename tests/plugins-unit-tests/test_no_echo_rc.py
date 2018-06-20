#!/usr/bin/env python
# encoding: utf-8
#
# Description: This UT check that no test has echo $RC_
#
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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
from unittest import TestCase

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
plugins = os.path.join(citellus.citellusdir, 'plugins', 'core')
folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'setup')
uttest = citellus.findplugins(folders=[folder])
citplugs = citellus.findplugins(folders=[plugins])

okay = random.randint(10, 29)
failed = random.randint(30, 49)
skipped = random.randint(50, 69)
info = random.randint(70, 89)


# Setup commands and expected return codes
rcs = {"pass": okay,
       "fail": failed,
       "skipped": skipped,
       'info': info}


class CitellusTest(TestCase):
    def test_plugins_no_echo_RC(self):
        for plugin in citplugs:
            result = citellus.regexpfile(filename=plugin['plugin'], regexp='.*echo \$RC_.*')
            if result == '':
                print(plugin['plugin'])
                assert result == ''

