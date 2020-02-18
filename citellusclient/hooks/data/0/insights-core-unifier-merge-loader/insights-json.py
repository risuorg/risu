#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for integrating insights execution json into citellus results
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
import json

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "__file__"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    return []


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    skipped = int(os.environ["RC_SKIPPED"])
    okay = int(os.environ["RC_OKAY"])
    failed = int(os.environ["RC_FAILED"])
    info = int(os.environ["RC_INFO"])

    jsons = ["insights-shared_rules.json", "insights-telemetry.json"]
    mydata = []
    for insijson in jsons:
        filenamewithpath = os.path.join(os.environ["CITELLUS_ROOT"], insijson)
        with open(filenamewithpath) as json_file:
            try:
                mydata = json.load(json_file)
            except:
                citellus.LOG.debug("Error processing data in %s, skipping" % json_file)
                mydata = []

        for plugin in mydata["reports"]:
            # Fake plugin entries to integrate into 'data' dictionary
            pluginid = citellus.calcid(plugin["component"])
            data[pluginid] = {}
            data[pluginid]['id'] = pluginid
            data[pluginid]["plugin"] = plugin["component"]
            data[pluginid]["kb"] = plugin["links"]["kcs"] or ""
            data[pluginid]["category"] = "insights"
            data[pluginid]["hash"] = pluginid
            data[pluginid]["backend"] = "insights-core-unifier-merge-loader"
            data[pluginid]["name"] = plugin["rule_id"]
            data[pluginid]["result"] = {}
            data[pluginid]["result"]["err"] = "%s" % plugin["details"]
            data[pluginid]["result"]["rc"] = failed
            data[pluginid]["result"]["out"] = ""
            data[pluginid]["priority"] = 666
            # Fill empty values for missing fields
            for key in [
                "description",
                "bugzilla",
                "path",
                "time",
                "long_name",
                "subcategory",
            ]:
                data[pluginid]["%s" % key] = ""

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This hook proceses insights json to integrate them in citellus results"
    )
    return commandtext
