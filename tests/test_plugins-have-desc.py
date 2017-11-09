#!/usr/bin/env python
# encoding: utf-8


import os
import re

from unittest import TestCase
from citellus import citellus
import pytest

testplugins = os.path.join(citellus.citellusdir, 'testplugins')


class CitellusTest(TestCase):

    @pytest.mark.last
    def test_plugins_have_description(self):
        pluginpath = [os.path.join(citellus.citellusdir, 'plugins')]
        pluginscit = citellus.findplugins(folders=pluginpath)

        REGEX = '\A# description:'

        plugins = []
        for file in pluginscit:
            with open(file, 'r') as f:
                for line in f:
                    if re.match(REGEX,line):
                        plugins.append(file)
        f.close()
        assert plugins == pluginscit
