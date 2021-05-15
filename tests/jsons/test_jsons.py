#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import json
import os
import sys
from unittest import TestCase

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))
import risuclient.shell as risu
from maguiclient import magui

testplugins = os.path.join(risu.risudir, "plugins", "test")
risudir = risu.risudir


class RisuTest(TestCase):
    def test_jsons_for_missbehaviours(self):
        mypath = os.path.dirname(__file__)
        print(mypath)

        jsons = risu.findplugins(
            folders=[mypath], executables=False, fileextension=".json"
        )

        flag = 0
        for risujson in jsons:
            try:
                results = json.load(open(risujson["plugin"], "r"))["results"]
            except:
                print("Skipping json: %s as cannot be loaded by risu" % risujson)
                results = []

            for result in results:
                data = results[result]["result"]["out"]
                if data != "":
                    print("JSON: %s" % risujson["plugin"])
                    print("PLUGIN: %s" % results[result]["plugin"])
                    print("STDOUT: %s" % data)
                    flag = 1
                    # Force it to fail after we've printed so we can notice error failing
                    if "plugins/metadata" in results[result]["plugin"]:
                        # If it's a metadata plugin, it's expected to have STDOUT
                        flag = 0
        assert flag == 0

    def test_domagui_againstjsons(self):
        print("Running magui against set of jsons, might take a while...")
        # Find all jsons
        mypath = os.path.dirname(__file__)
        alljsons = risu.findplugins(
            folders=[mypath], executables=False, fileextension=".json"
        )
        jsons = []
        # Convert from plugin list to json list
        for jsonfile in alljsons:
            jsons.append(jsonfile["plugin"])

        # Call with no arguments
        res = magui.domagui(sosreports=jsons, risuplugins=[])
        assert res != {}

    def test_jsons_for_printresults(self):
        mypath = os.path.dirname(__file__)
        print(mypath)

        jsons = risu.findplugins(
            folders=[mypath], executables=False, fileextension=".json"
        )

        risujson = jsons[0]

        try:
            results = json.load(open(risujson["plugin"], "r"))["results"]
        except:
            print("Skipping json: %s as cannot be loaded by risu" % risujson)
            results = []

        options = risu.parse_args(default=True)
        risu.printresults(results, options)

        assert True
