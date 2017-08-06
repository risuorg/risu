#!/usr/bin/env python
# encoding: utf-8


from unittest import TestCase
from citellus import citellus


class CitellusTest(TestCase):
    def test_numplugins(self):
        self.assertNotEqual(len(citellus.findplugins()), 0)
