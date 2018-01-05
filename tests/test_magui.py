#!/usr/bin/env python
# encoding: utf-8

import os
from unittest import TestCase

import citellusclient.shell as citellus
import maguiclient.magui as magui

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
