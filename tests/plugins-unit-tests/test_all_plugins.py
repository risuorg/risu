#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: This UT run all scripts to validate the rules/tests created
#
# Copyright (C) 2017, 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
import shutil
import subprocess
import sys
import tempfile
from unittest import TestCase

import maguiclient.magui as magui
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
    def test_all_plugins_snapshot(self):
        tmpdir = tempfile.mkdtemp(prefix="risu-tmp")
        tmpdir2 = tempfile.mkdtemp(prefix="risu-tmp")

        # Setup folder for all tests
        testtype = "pass"
        for test in uttest:
            subprocess.call([test["plugin"], test["plugin"], testtype, tmpdir])
            subprocess.call([test["plugin"], test["plugin"], testtype, tmpdir2])

        # Run risu once against them
        results = risu.dorisu(
            path=tmpdir,
            plugins=citplugs,
            okay=okay,
            failed=failed,
            skipped=skipped,
            info=info,
            web=True,
        )
        maguiresults = magui.domagui(sosreports=[tmpdir, tmpdir2], risuplugins=citplugs)

        # Check that risu.html has been copied
        assert os.access(os.path.join(tmpdir, "risu.json"), os.R_OK)
        assert os.access(os.path.join(tmpdir, "risu.html"), os.R_OK)
        assert maguiresults

        # Remove tmp folder
        shutil.rmtree(tmpdir)
        shutil.rmtree(tmpdir2)

        # Process plugin output from multiple plugins
        new_dict = []
        out_dict = []
        for item in results:
            rc = results[item]["result"]["rc"]
            if rc not in sorted({okay, failed, skipped, info}):
                print(results[item])
            assert rc in sorted({okay, failed, skipped, info})
            if rc == failed or rc == skipped:
                print(results[item])
                assert results[item]["result"]["err"] != ""
            new_dict.append(rc)
            if results[item]["result"]["out"] != "":
                print(results[item])
                assert results[item]["result"]["out"] == ""
            out_dict.append(results[item]["result"]["out"])

        for each in sorted(set(new_dict)):
            assert each in sorted({okay, failed, skipped, info})

    def test_all_plugins_live(self):
        # Run risu once against them
        results = risu.dorisu(
            live=True,
            plugins=citplugs,
            okay=okay,
            failed=failed,
            skipped=skipped,
            info=info,
        )

        # Process plugin output from multiple plugins
        new_dict = []
        out_dict = []
        for item in results:
            rc = results[item]["result"]["rc"]
            if rc not in sorted({okay, failed, skipped, info}):
                print(results[item])
            assert rc in sorted({okay, failed, skipped, info})
            if rc == failed or rc == skipped:
                print(results[item])
                assert results[item]["result"]["err"] != ""
            if results[item]["result"]["out"] != "":
                print(results[item])
                assert results[item]["result"]["out"] == ""
            out_dict.append(results[item]["result"]["out"])

            new_dict.append(rc)

        for each in sorted(set(new_dict)):
            assert each in sorted({okay, failed, skipped, info})
