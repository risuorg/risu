#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Hook for making as failed faraday plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018-2021, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

import os

try:
    import risuclient.shell as risu
except:
    import shell as risu

# Load i18n settings from risu
_ = risu._

extension = "__file__"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


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

    # data is a matrix of grouped[plugin][sosreport] and then [text] [out] [err] [rc]

    for plugin in data:
        if "plugin" in data[plugin] and "faraday/" in data[plugin]["plugin"]:
            results = [
                data[plugin]["sosreport"][sosreport]["err"]
                for sosreport in data[plugin]["sosreport"]
            ]

            makeitfail = False
            results = sorted(set(results))

            if len(results) > 1 and "positive" in data[plugin]["plugin"]:
                makeitfail = True
            if (
                len(results) < len(data[plugin]["sosreport"])
                and "negative" in data[plugin]["plugin"]
            ):
                makeitfail = True

            if makeitfail:
                for sosreport in data[plugin]["sosreport"]:
                    data[plugin]["sosreport"][sosreport].update({"rc": risu.RC_FAILED})

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This hook proceses faraday results and marks them as failed as needed"
    )
    return commandtext
