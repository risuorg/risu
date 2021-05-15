#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: This UT run scripts to validate CF
#
# Copyright (C) 2017, 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

import os
import shutil
import subprocess
import sys
import tempfile
from unittest import TestCase

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
import risuclient.shell as risu

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))


# To create your own test, update NAME with plugin name and copy this file to test_$NAME.py
NAME = "test_cf_is_process"

testplugins = os.path.join(risu.risudir, "plugins", "test")
plugins = os.path.join(risu.risudir, "plugins", "core")
folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), "setup")
uttest = risu.findplugins(folders=[folder], include=[NAME])[0]["plugin"]
us = os.path.basename(uttest)
citplugs = risu.findplugins(folders=[folder], include=[us])

# Setup commands and expected return codes
rcs = {
    "pass": risu.RC_OKAY,
    "fail": risu.RC_FAILED,
    "skipped": risu.RC_SKIPPED,
    "info": risu.RC_INFO,
}


def runtest(testtype="False"):
    """
    Actually run the test for UT
    :param testtype: argument to pass to setup script
    :return: returncode
    """

    # testtype will be 'pass', 'fail', 'skipped'

    # We're iterating against the different UT tests defined in UT-tests folder
    tmpdir = tempfile.mkdtemp(prefix="risu-tmp")

    # Setup test for 'testtype'
    subprocess.check_output([uttest, uttest, testtype, tmpdir])

    # Run test against it
    res = risu.dorisu(path=tmpdir, plugins=citplugs)

    plugid = risu.getids(plugins=citplugs)[0]
    # Get Return code
    if plugid in res:
        rc = res[plugid]["result"]["rc"]
    else:
        rc = testtype

    # Remove tmp folder
    shutil.rmtree(tmpdir)

    # Check if it passed
    return rc


class RisuTest(TestCase):
    def test_pass(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = "pass"
        result = runtest(testtype=testtype)
        if result != testtype:
            assert result == rcs[testtype]

    def test_fail(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = "fail"
        result = runtest(testtype=testtype)
        if result != testtype:
            assert result == rcs[testtype]
