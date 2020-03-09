#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

import os
from unittest import TestCase

from citellusclient.tools.dmidecode import parse_dmi
from citellusclient.tools.dmidecode import _parse_handle_section
from citellusclient.tools.dmidecode import profile
from citellusclient.tools.dmidecode import _get_output
from citellusclient.tools.dmidecode import _show


class CitellusTest(TestCase):
    def test_dmidecode(self):
        with open("tests/other/dmidecode", "r") as f:
            content = f.read()
            output = parse_dmi(content)
            assert output != "1"
