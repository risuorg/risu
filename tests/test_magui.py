#!/usr/bin/env python
# encoding: utf-8

# Copyright (C) 2017 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2017, 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

import os
from unittest import TestCase

import citellusclient.shell as citellus
from maguiclient import magui

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')


class MaguiTest(TestCase):
    def test_commonpath(self):
        res = magui.commonpath(['/etc/path', '/etc/common'])
        assert res == '/etc'

    def test_domagui(self):
        # Call with no arguments
        res = magui.domagui(sosreports=[], citellusplugins=[])
        assert res == {}

