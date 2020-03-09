#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


import os
from unittest import TestCase

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, "plugins", "test")
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_plugins_have_executable_bit(self):
        pluginpath = [os.path.join(citellus.citellusdir, "plugins", "core")]
        plugins = []
        for folder in pluginpath:
            for root, dirnames, filenames in os.walk(folder, followlinks=True):
                for filename in filenames:
                    filepath = os.path.join(root, filename)
                    if ".citellus_tests" not in filepath:
                        plugins.append(filepath)
        plugins = sorted(set(plugins))
        pluginscit = []
        for plugin in citellus.findplugins(folders=pluginpath):
            pluginscit.append(plugin["plugin"])

        pluginscit = sorted(set(pluginscit))

        assert plugins == pluginscit
