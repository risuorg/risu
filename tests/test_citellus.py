#!/usr/bin/env python
# encoding: utf-8


import os
from unittest import TestCase

import pytest

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_runplugin_pass(self):
        plugins = citellus.findplugins(folders=[testplugins], include=['exit_passed.sh'])
        results = citellus.docitellus(plugins=plugins)
        assert results[0]['result']['rc'] == citellus.RC_OKAY
        assert results[0]['result']['out'].endswith('something on stdout\n')
        assert results[0]['result']['err'].endswith('something on stderr\n')

    def test_runplugin_fail(self):
        plugins = citellus.findplugins(folders=[testplugins], include=['exit_failed.sh'])
        results = citellus.docitellus(plugins=plugins)
        assert results[0]['result']['rc'] == citellus.RC_FAILED
        assert results[0]['result']['out'].endswith('something on stdout\n')
        assert results[0]['result']['err'].endswith('something on stderr\n')

    def test_runplugin_skip(self):
        plugins = citellus.findplugins(folders=[testplugins], include=['exit_skipped.sh'])
        results = citellus.docitellus(plugins=plugins)
        assert results[0]['result']['rc'] == citellus.RC_SKIPPED
        assert results[0]['result']['out'].endswith('something on stdout\n')
        assert results[0]['result']['err'].endswith('something on stderr\n')

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
        global extensions
        extensions, exttriggers = citellus.initExtensions()
        # get all plugins
        plugins = []
        
        # code
        for plugin in citellus.findplugins(folders=[os.path.join(citellus.citellusdir, 'plugins', 'core')]):
            plugins.append(plugin)
        
        # ansible
        for plugin in citellus.findplugins(executables=False, fileextension=".yml", extension='ansible',folders=[os.path.join(citellus.citellusdir, 'plugins', 'ansible')]):
            plugins.append(plugin)

        for plugin in plugins:
            if plugin['description'] == '':
                print(plugin)
            assert plugin['description'] != ''

    @pytest.mark.last
    def test_plugins_have_long_name(self):
        global extensions
        extensions, exttriggers = citellus.initExtensions()
        # get all plugins
        plugins = []
        
        # code
        for plugin in citellus.findplugins(folders=[os.path.join(citellus.citellusdir, 'plugins', 'core')]):
            plugins.append(plugin)
        
        # ansible
        for plugin in citellus.findplugins(executables=False, fileextension=".yml", extension='ansible',folders=[os.path.join(citellus.citellusdir, 'plugins', 'ansible')]):
            plugins.append(plugin)

        for plugin in plugins:
            if plugin['long_name'] == '':
                print(plugin)
            assert plugin['long_name'] != ''


    def test_which(self):
        assert citellus.which('/bin/sh') == '/bin/sh'

    def test_findplugins_ext(self):
        plugins = []
        folder = [os.path.join(citellus.citellusdir, 'plugins', 'core')]
        for each in citellus.findplugins(folders=folder, fileextension='.sh'):
            plugins.append(each)
        assert len(plugins) != 0

    def test_execonshellfailure(self):
        returncode, out, err = citellus.execonshell('/proc/cmdline')
        assert returncode == 3

    def test_readconfig(self):
        parsed = citellus.read_config()
        assert parsed == {}
