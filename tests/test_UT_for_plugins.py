#!/usr/bin/env python
# encoding: utf-8
#
# Description: This UT run scripts to validate the rules/tests created for citellus tests
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
from unittest import TestCase
import citellusclient.shell as citellus

plugins = os.path.join(citellus.citellusdir, 'plugins')

# Setup commands and expected return codes
rcs = {"pass": citellus.RC_OKAY,
       "fail": citellus.RC_FAILED,
       "skipped": citellus.RC_SKIPPED}


class CitellusTest(TestCase):
    def test_UT_for_every_plugin(self):
        # Build folder of tests
        folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'plugins-unit-tests')

        # Iterate over each citellus plugin and fail if there's no UT for it
        for plugin in citellus.findplugins(folders=[plugins]):
            us = os.path.splitext(os.path.basename(plugin['plugin']))[0]

            # Find plugins that match
            citplugs = len(citellus.findplugins(folders=[folder], include=[us]))

            # Check if it passes, fails if there's no UT for test
            print("Test for plugin: %s" % plugin)
            assert citplugs != 0
