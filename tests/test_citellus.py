#!/usr/bin/env python
# encoding: utf-8


import os
import re
from unittest import TestCase

import pytest

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_runplugin_pass(self):
        returncode, out, err = citellus.execonshell(os.path.join(testplugins, 'exit_passed.sh'))
        returncode == citellus.RC_OKAY
        out.endswith(b'something on stdout\n')
        err.endswith(b'something on stderr\n')

    def test_runplugin_fail(self):
        returncode, out, err = citellus.execonshell(os.path.join(testplugins, 'exit_failed.sh'))
        returncode == citellus.RC_FAILED
        out.endswith(b'something on stdout\n')
        err.endswith(b'something on stderr\n')

    def test_runplugin_skip(self):
        returncode, out, err = citellus.execonshell(os.path.join(testplugins, 'exit_skipped.sh'))
        returncode == citellus.RC_SKIPPED
        out.endswith(b'something on stdout\n')
        err.endswith(b'something on stderr\n')

    def test_findplugins_positive_filter_include(self):
        plugins = citellus.findplugins([testplugins],
                                       include=['exit_passed'])

        assert len(plugins) == 1

    def test_findplugins_positive_filter_exclude(self):
        plugins = citellus.findplugins([testplugins],
                                       exclude=['exit_passed', 'exit_skipped'])

        for plugin in plugins:
            assert ('exit_passed' not in plugin and 'exit_skipped' not in plugin)

    def test_findplugins_positive(self):
        assert len(citellus.findplugins([testplugins])) != 0

    def test_findplugins_negative(self):
        assert citellus.findplugins('__does_not_exist__') == []

    def test_plugins_have_executable_bit(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins', 'core')]
        plugins = []
        for folder in pluginpath:
            for root, dirnames, filenames in os.walk(folder):
                for filename in filenames:
                    filepath = os.path.join(root, filename)
                    if ".citellus_tests" not in filepath:
                        plugins.append(filepath)
        plugins = sorted(set(plugins))
        pluginscit = []
        for plugin in citellus.findplugins(folders=pluginpath):
            pluginscit.append(plugin['plugin'])

        pluginscit = sorted(set(pluginscit))

        assert plugins == pluginscit

    @pytest.mark.last
    def test_plugins_have_description(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins', 'core')]
        pluginscit = []
        for plugin in citellus.findplugins(folders=pluginpath):
            pluginscit.append(plugin['plugin'])

        pluginscit = sorted(set(pluginscit))

        regexp = '\A# description:'

        plugins = []

        # Loop over plugins to store in the var the ones that have description
        for file in pluginscit:
            flag = 0
            with open(file, 'r') as f:
                for line in f:
                    if re.match(regexp, line):
                        flag = 1
            if flag == 1:
                plugins.append(file)
        f.close()
        assert plugins == pluginscit
