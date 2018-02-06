#!/usr/bin/env python
# encoding: utf-8

from __future__ import print_function

import os
from unittest import TestCase
import pytest
import json
import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_jsons_for_missbehaviours(self):
        mypath = os.path.dirname(__file__)
        print(mypath)

        jsons = citellus.findplugins(folders=[mypath], executables=False, fileextension='.json')

        for citellusjson in jsons:
            try:
                results = json.load(open(citellusjson['plugin'], 'r'))['results']
            except:
                print("Skipping json: %s as cannot be loaded by citellus" % citellusjson)
                results = []

            for result in results:
                print("IRANZO")
                print(result)
                assert a==3
                data = results[result]['result']['out']
                if data != '':
                    print("JSON: %s" % citellusjson['plugin'])
                    print(results[result])
                    assert data == ''
