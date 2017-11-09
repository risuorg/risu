#!/usr/bin/env python
# encoding: utf-8


import os
import pytest
import re

from unittest import TestCase
from citellus import citellus

testplugins = os.path.join(citellus.citellusdir, 'testplugins')


class CitellusTest(TestCase):
    def test_runplugin_pass(self):
        res = citellus.runplugin(os.path.join(testplugins, 'exit_passed.sh'))
        assert res['result']['rc'] == citellus.RC_OKAY
        assert res['result']['out'].endswith('something on stdout\n')
        assert res['result']['err'].endswith('something on stderr\n')

    def test_runplugin_fail(self):
        res = citellus.runplugin(os.path.join(testplugins, 'exit_failed.sh'))
        assert res['result']['rc'] == citellus.RC_FAILED
        assert res['result']['out'].endswith('something on stdout\n')
        assert res['result']['err'].endswith('something on stderr\n')

    def test_runplugin_skip(self):
        res = citellus.runplugin(os.path.join(testplugins, 'exit_skipped.sh'))
        assert res['result']['rc'] == citellus.RC_SKIPPED
        assert res['result']['out'].endswith('something on stdout\n')
        assert res['result']['err'].endswith('something on stderr\n')

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

    def test_docitellus(self):
        plugins = citellus.findplugins([testplugins],
                                       include=['exit_passed'])
        results = citellus.docitellus(plugins=plugins)
        assert len(results) == 1
        assert results[0]['result']['rc'] == citellus.RC_OKAY

    def test_plugins_have_executable_bit(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins')]
        plugins = []
        for folder in pluginpath:
            for root, dirnames, filenames in os.walk(folder):
                for filename in filenames:
                    filepath = os.path.join(root, filename)
                    if ".citellus_tests" not in filepath:
                        plugins.append(filepath)
        plugins = sorted(set(plugins))
        pluginscit = citellus.findplugins(folders=pluginpath)

        assert plugins == pluginscit

    @pytest.mark.last
    def test_plugins_have_description(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins')]
        pluginscit = citellus.findplugins(folders=pluginpath)

        REGEX = '\A# description:'

        plugins = []
        for file in pluginscit:
            flag = 1
            with open(file, 'r') as f:
                for line in f:
                    if re.match(REGEX, line):
                        flag = 0
            if flag == 1:
                plugins.append(file)
        f.close()
        assert plugins == pluginscit
