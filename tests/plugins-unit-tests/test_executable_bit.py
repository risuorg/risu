#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


import os
import sys
from unittest import TestCase

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))
import risuclient.shell as risu

testplugins = os.path.join(risu.risudir, "plugins", "test")
risudir = risu.risudir


class RisuTest(TestCase):
    def test_plugins_have_executable_bit(self):
        pluginpath = [os.path.join(risu.risudir, "plugins", "core")]
        plugins = []
        for folder in pluginpath:
            for root, dirnames, filenames in os.walk(folder, followlinks=True):
                for filename in filenames:
                    filepath = os.path.join(root, filename)
                    if ".risu_tests" not in filepath:
                        plugins.append(filepath)
        plugins = sorted(set(plugins))
        pluginscit = []
        for plugin in risu.findplugins(folders=pluginpath):
            pluginscit.append(plugin["plugin"])

        pluginscit = sorted(set(pluginscit))

        assert plugins == pluginscit
