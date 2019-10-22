#!/usr/bin/env python
# encoding: utf-8

# Copyright (C) 2017, 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

import os
from unittest import TestCase

from citellusclient.tools.dmidecode import *

class CitellusTest(TestCase):
    def test_dmidecode(self):
        with open("tests/other/dmidecode","r") as f:
            content = f.read()
            output = parse_dmi(content)
            assert output != "1"
