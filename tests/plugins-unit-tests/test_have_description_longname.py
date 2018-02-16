#!/usr/bin/env python
# encoding: utf-8


import os
from unittest import TestCase

import pytest

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
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
        for plugin in citellus.findplugins(executables=False, fileextension=".yml", extension='ansible', folders=[os.path.join(citellus.citellusdir, 'plugins', 'ansible')]):
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
        for plugin in citellus.findplugins(executables=False, fileextension=".yml", extension='ansible', folders=[os.path.join(citellus.citellusdir, 'plugins', 'ansible')]):
            plugins.append(plugin)

        for plugin in plugins:
            if plugin['long_name'] == '':
                print(plugin)
            assert plugin['long_name'] != ''
