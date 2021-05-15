#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Description: Plugin for reporting failed affinity on the faraday risu plugin
# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

import risuclient.shell as risu

# Load i18n settings from risu
_ = risu._

extension = "faraday"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for Plugin
    """

    triggers = risu.getids(include=["faraday/positive", "faraday/negative"])
    return triggers


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param data: data to process
    :param quiet: work in reduced noise mode
    :return: returncode, out, err
    """

    message = []
    returncode = risu.RC_OKAY
    for ourdata in data:
        # 'err' in this case should be always equal to the md5sum of the file so that we can report the problem
        err = []
        allskipped = True
        for sosreport in data[ourdata]["sosreport"]:
            err.append(data[ourdata]["sosreport"][sosreport]["err"])
            if data[ourdata]["sosreport"][sosreport]["rc"] != risu.RC_SKIPPED:
                allskipped = False

        if data[ourdata]["path"].strip() != "":
            if not allskipped:
                if "positive" in data[ourdata]["plugin"]:
                    if len(sorted(set(err))) != 1:
                        message.append(
                            _(
                                "%s contents differ across hosts, ensure proper behavior."
                            )
                            % data[ourdata]["path"].replace("${RISU_ROOT}", "")
                        )
                        returncode = risu.RC_FAILED

                if "negative" in data[ourdata]["plugin"]:
                    if len(sorted(set(err))) == 1:
                        message.append(
                            _(
                                "%s contents are the same across hosts, ensure proper behavior."
                            )
                            % data[ourdata]["path"].replace("${RISU_ROOT}", "")
                        )
                        returncode = risu.RC_FAILED

    out = ""
    err = "\n".join(message)

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "Plugin for reporting back files that should BE or NOT BE different across sosreports"
    )
    return commandtext
