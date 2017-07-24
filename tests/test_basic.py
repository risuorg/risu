#!/usr/bin/env python
# encoding: utf-8


from unittest import TestCase
import citellus


class CitellusTest(TestCase):
    def test_findplugins(self):
        self.assertEqual(citellus.findplugins('@#~@#æßð'), [])
