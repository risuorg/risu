#!/usr/bin/env python
# encoding: utf-8

# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


import os
from unittest import TestCase

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_plugins_have_dual_brackets_for_if(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins', 'core')]
        pluginscit = []
        for plugin in citellus.findplugins(folders=pluginpath):
            filename = plugin['plugin']
            regexp = 'if \[ '
            if citellus.regexpfile(filename=filename, regexp=regexp):
                pluginscit.append(filename)

        assert len(pluginscit) == 0

    def test_plugins_have_dual_parenthesis_for_if(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins', 'core')]
        pluginscit = []
        for plugin in citellus.findplugins(folders=pluginpath):
            filename = plugin['plugin']
            regexp = 'if \( '
            if citellus.regexpfile(filename=filename, regexp=regexp):
                pluginscit.append(filename)

        assert len(pluginscit) == 0

