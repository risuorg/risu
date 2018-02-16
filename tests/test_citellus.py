#!/usr/bin/env python
# encoding: utf-8


import os
from unittest import TestCase

import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
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

    def test_which(self):
        assert citellus.which('/bin/sh') == '/bin/sh'

    def test_findplugins_ext(self):
        plugins = []
        folder = [os.path.join(citellus.citellusdir, 'plugins', 'core')]
        for each in citellus.findplugins(folders=folder, fileextension='.sh'):
            plugins.append(each)
        assert len(plugins) != 0

    def test_readconfig(self):
        parsed = citellus.read_config()
        assert parsed == {}
