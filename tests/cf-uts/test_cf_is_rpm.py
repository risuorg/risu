#!/usr/bin/env python
# encoding: utf-8
#
# Description: This UT run scripts to validate CF
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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
import shutil
import subprocess
import tempfile
from unittest import TestCase

import citellusclient.shell as citellus

# To create your own test, update NAME with plugin name and copy this file to test_$NAME.py
NAME = "test_cf_is_rpm"

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
plugins = os.path.join(citellus.citellusdir, 'plugins', 'core')
folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'setup')
uttest = citellus.findplugins(folders=[folder], include=[NAME])[0]['plugin']
us = os.path.basename(uttest)
citplugs = citellus.findplugins(folders=[folder], include=[us])


# Setup commands and expected return codes
rcs = {"pass": citellus.RC_OKAY,
       "fail": citellus.RC_FAILED,
       "skipped": citellus.RC_SKIPPED}


def runtest(testtype='False'):
    """
    Actually run the test for UT
    :param testtype: argument to pass to setup script
    :return: returncode
    """

    # testtype will be 'pass', 'fail', 'skipped'

    # We're iterating against the different UT tests defined in UT-tests folder
    tmpdir = tempfile.mkdtemp(prefix='citellus-tmp')

    # Setup test for 'testtype'
    subprocess.check_output([uttest, uttest, testtype, tmpdir])

    # Run test against it
    res = citellus.docitellus(path=tmpdir, plugins=citplugs)

    plugid = citellus.getids(plugins=citplugs)[0]
    # Get Return code
    rc = res[plugid]['result']['rc']

    # Remove tmp folder
    shutil.rmtree(tmpdir)

    # Check if it passed
    return rc


class CitellusTest(TestCase):
    def test_pass(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'pass'
        assert runtest(testtype=testtype) == rcs[testtype]

    def test_fail(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'fail'
        assert runtest(testtype=testtype) == rcs[testtype]
