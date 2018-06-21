#!/usr/bin/env python
# encoding: utf-8

# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
from unittest import TestCase
import json
import citellusclient.shell as citellus

testplugins = os.path.join(citellus.citellusdir, 'plugins', 'test')
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_jsons_for_missbehaviours(self):
        mypath = os.path.dirname(__file__)
        print(mypath)

        jsons = citellus.findplugins(folders=[mypath], executables=False, fileextension='.json')

        flag = 0
        for citellusjson in jsons:
            try:
                results = json.load(open(citellusjson['plugin'], 'r'))['results']
            except:
                print("Skipping json: %s as cannot be loaded by citellus" % citellusjson)
                results = []

            for result in results:
                data = results[result]['result']['out']
                if data != '':
                    print("JSON: %s" % citellusjson['plugin'])
                    print("PLUGIN: %s" % results[result]['plugin'])
                    print("STDOUT: %s" % data)
                    flag = 1
                    # Force it to fail after we've printed so we can notize error failing
        assert flag == 0

