#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2017, 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

import os
import sys
from unittest import TestCase

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))
import risuclient.shell as risu
from maguiclient import magui

testplugins = os.path.join(risu.risudir, "plugins", "test")


class MaguiTest(TestCase):
    def test_commonpath(self):
        res = magui.commonpath(["/etc/path", "/etc/common"])
        assert res == "/etc"

    def test_domagui(self):
        # Call with no arguments
        res = magui.domagui(sosreports=[], risuplugins=[])
        assert res == {}

    def test_parseargs(self):
        # Call with no arguments

        try:
            magui.parse_args()
        except:
            pass
        assert True

    def test_main(self):
        sys.argv = ["magui.py", "--list-plugins"]
        try:
            magui.main()
        except:
            pass

        assert True

    def test_help(self):
        sys.argv = ["magui.py", "--help"]
        try:
            magui.main()
        except:
            pass

        assert True
