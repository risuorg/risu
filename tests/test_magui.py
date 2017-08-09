#!/usr/bin/env python
# encoding: utf-8


import os
from unittest import TestCase
from citellus import citellus
from citellus import magui

testplugins = os.path.join(citellus.citellusdir, 'testplugins')


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
        assert res == {'/exit_unknown.sh': {'host2': {'rc': 99, 'err': testplugins + u'/exit_unknown.sh something on stderr\n', 'out': testplugins + u'/exit_unknown.sh something on stdout\n'}, 'host1': {'rc': 99, 'err': testplugins + u'/exit_unknown.sh something on stderr\n', 'out': testplugins + u'/exit_unknown.sh something on stdout\n'}}, '/exit_failed.sh': {'host2': {'rc': 1, 'err': testplugins + u'/exit_failed.sh something on stderr\n', 'out': testplugins + u'/exit_failed.sh something on stdout\n'}, 'host1': {'rc': 1, 'err': testplugins + u'/exit_failed.sh something on stderr\n', 'out': testplugins + u'/exit_failed.sh something on stdout\n'}}}
