#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import json
import os
from unittest import TestCase

import citellusclient.shell as citellus
from maguiclient import magui

testplugins = os.path.join(citellus.citellusdir, "plugins", "test")
citellusdir = citellus.citellusdir


class CitellusTest(TestCase):
    def test_jsons_for_missbehaviours(self):
        mypath = os.path.dirname(__file__)
        print(mypath)

        jsons = citellus.findplugins(
            folders=[mypath], executables=False, fileextension=".json"
        )

        flag = 0
        for citellusjson in jsons:
            try:
                results = json.load(open(citellusjson["plugin"], "r"))["results"]
            except:
                print(
                    "Skipping json: %s as cannot be loaded by citellus" % citellusjson
                )
                results = []

            for result in results:
                data = results[result]["result"]["out"]
                if data != "":
                    print("JSON: %s" % citellusjson["plugin"])
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
        alljsons = citellus.findplugins(
            folders=[mypath], executables=False, fileextension=".json"
        )
        jsons = []
        # Convert from plugin list to json list
        for jsonfile in alljsons:
            jsons.append(jsonfile["plugin"])

        # Call with no arguments
        res = magui.domagui(sosreports=jsons, citellusplugins=[])
        assert res != {}

    def test_jsons_for_printresults(self):
        mypath = os.path.dirname(__file__)
        print(mypath)

        jsons = citellus.findplugins(
            folders=[mypath], executables=False, fileextension=".json"
        )

        citellusjson = jsons[0]

        try:
            results = json.load(open(citellusjson["plugin"], "r"))["results"]
        except:
            print("Skipping json: %s as cannot be loaded by citellus" % citellusjson)
            results = []

        options = citellus.parse_args(default=True)
        citellus.printresults(results, options)

        assert True
