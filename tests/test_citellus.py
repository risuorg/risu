#!/usr/bin/env python
# encoding: utf-8


import os
from unittest import TestCase
from citellus import citellus

testplugins = os.path.join(citellus.citellusdir, 'testplugins')


class CitellusTest(TestCase):
    def test_runplugin_pass(self):
        res = citellus.runplugin(os.path.join(testplugins, 'exit_passed.sh'))
        assert res['result']['rc'] == 0
        assert res['result']['out'].endswith('something on stdout\n')
        assert res['result']['err'].endswith('something on stderr\n')

    def test_runplugin_fail(self):
        res = citellus.runplugin(os.path.join(testplugins, 'exit_failed.sh'))
        assert res['result']['rc'] == 1
        assert res['result']['out'].endswith('something on stdout\n')
        assert res['result']['err'].endswith('something on stderr\n')

    def test_runplugin_skip(self):
        res = citellus.runplugin(os.path.join(testplugins, 'exit_skipped.sh'))
        assert res['result']['rc'] == 2
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
        assert results[0]['result']['rc'] == 0
