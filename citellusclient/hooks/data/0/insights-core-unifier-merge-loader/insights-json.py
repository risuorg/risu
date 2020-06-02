#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Hook for integrating insights execution json into citellus results
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
import json
import glob

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


def run(data, quiet=False, options=None):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    skipped = int(os.environ["RC_SKIPPED"])
    failed = int(os.environ["RC_FAILED"])

    jsons = glob.glob(os.path.join(os.environ["CITELLUS_ROOT"], "insights-*.json"))
    mydata = []
    for insijson in jsons:
        filenamewithpath = insijson
        if (
            os.path.exists(filenamewithpath)
            and os.path.isfile(filenamewithpath)
            and os.access(filenamewithpath, os.R_OK)
        ):
            with open(filenamewithpath) as json_file:
                for line in json_file.readlines():
                    try:
                        mydata = json.loads(line)
                    except:
                        citellus.LOG.debug(
                            "Error processing dataline in %s, skipping" % json_file
                        )
                if mydata and isinstance(mydata, dict):
                    pass
                else:
                    mydata = []

        else:
            mydata = []

        # Fill plugins with actual report received
        if "reports" in mydata:
            for plugin in mydata["reports"]:
                # Fake plugin entries to integrate into 'data' dictionary
                pluginid = citellus.calcid(plugin["component"])
                data[pluginid] = {}
                data[pluginid]["id"] = pluginid
                data[pluginid]["plugin"] = "%s.%s" % (insijson, plugin["component"])
                if "links" in plugin and "kcs" in plugin["links"]:
                    if isinstance(plugin["links"]["kcs"], str):
                        data[pluginid]["kb"] = plugin["links"]["kcs"].split()
                    elif isinstance(plugin["links"]["kcs"], list):
                        data[pluginid]["kb"] = " ".join(plugin["links"]["kcs"])
                else:
                    data[pluginid]["kb"] = ""
                data[pluginid]["category"] = "insights"
                data[pluginid]["hash"] = pluginid
                data[pluginid]["backend"] = "insights-core-unifier-merge-loader"
                data[pluginid]["name"] = "%s-%s" % (insijson, plugin["rule_id"])
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

        # Process plugins in skip to fake skipped entries
        if "skips" in mydata:
            for plugin in mydata["skips"]:
                pluginid = citellus.calcid(plugin["rule_fqdn"])
                data[pluginid] = {}
                data[pluginid]["id"] = pluginid
                data[pluginid]["plugin"] = "insights.%s" % plugin["rule_fqdn"]
                data[pluginid]["category"] = "insights"
                data[pluginid]["hash"] = pluginid
                data[pluginid]["backend"] = "insights-core-unifier-merge-loader"
                data[pluginid]["name"] = plugin["rule_fqdn"]
                data[pluginid]["result"] = {}
                data[pluginid]["result"]["err"] = "%s" % plugin["reason"]
                data[pluginid]["result"]["rc"] = skipped
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
                    "kb",
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
