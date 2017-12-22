#!/usr/bin/env python
# encoding: utf-8

import os
from unittest import TestCase

import citellusclient.shell as citellus
from citellusclient import magui

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')


class MaguiTest(TestCase):
    def test_commonpath(self):
        res = magui.commonpath(['/etc/path', '/etc/common'])
        assert res == '/etc'

    def test_callcitellus(self):
        # Call with no arguments should return empty
        res = magui.callcitellus(path='_does_not_exist_', plugins=[])
        assert res == {}

    def test_domagui(self):
        # Call with no arguments
        res = magui.domagui(sosreports=[], citellusplugins=[])
        assert res == {}

    def test_maguiformat(self):
        res = magui.maguiformat(data={})
        assert res == {}

    def test_domaguiwithplugs(self):
        sosreports = ['host1', 'host2']

        plugins = []
        plugins.append(citellus.findplugins(folders=[testplugins], include='exit_passed.sh'))
        plugins.append(citellus.findplugins(folders=[testplugins], include='exit_failed.sh'))

        plugins = plugins[0]

        # Call with no arguments should return empty
        res = magui.maguiformat(magui.domagui(sosreports=sosreports, citellusplugins=plugins))
        compare = {'/exit_unknown.sh': {'sosreport': {'bugzilla': '', 'backend': 'core', 'long_name': '', 'sosreport': {'host1': {'err': testplugins + u'/exit_unknown.sh something on stderr\n', 'rc': 99, 'out': testplugins + u'/exit_unknown.sh something on stdout\n'}, 'host2': {'err': testplugins + u'/exit_unknown.sh something on stderr\n', 'rc': 99, 'out': testplugins + u'/exit_unknown.sh something on stdout\n'}}, 'description': ''}}, '/exit_failed.sh': {'sosreport': {'bugzilla': '', 'backend': 'core', 'long_name': '', 'sosreport': {'host1': {'err': testplugins + u'/exit_failed.sh something on stderr\n', 'rc': 20, 'out': testplugins + u'/exit_failed.sh something on stdout\n'}, 'host2': {'err': testplugins + u'/exit_failed.sh something on stderr\n', 'rc': 20, 'out': testplugins + u'/exit_failed.sh something on stdout\n'}}, 'description': ''}}}
        for elem in compare:
            assert compare[elem] == res[elem]
