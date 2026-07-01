#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing rhv-log-collector-analizer
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018-2021, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

import os

try:
    import yaml
except ImportError:
    yaml = None

try:
    import risuclient.shell as risu
    from risuclient.extensions.base import BaseExtension
except ImportError:
    import shell as risu
    from extensions.base import BaseExtension

# Load i18n settings from risu (for backward compatibility)
_ = risu._

# Legacy module-level variables (for backward compatibility)
extension = "rhv-log-collector-analyzer"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class RhvLogCollectorAnalyzerExtension(BaseExtension):
    """Extension for processing RHV log collector analyzer"""

    extension_name = "rhv-log-collector-analyzer"
    file_extension = ".txt"
    executables_only = False

    def get_metadata(self, plugin):
        """
        Get metadata for plugin with YAML parsing
        :param plugin: plugin object
        :return: metadata dict for that plugin
        """
        if yaml is None:
            # YAML not available, return basic metadata
            metadata = risu.generic_get_metadata(plugin=plugin)
            return metadata

        with open(plugin["plugin"], "r") as stream:
            try:
                doc = yaml.safe_load(stream)
            except (yaml.YAMLError, AttributeError):
                doc = ""

        try:
            description = doc[0]["vars"]["metadata"]["description"]
        except (KeyError, TypeError, IndexError):
            description = ""

        metadata = risu.generic_get_metadata(plugin=plugin)
        metadata.update({"description": description})

        return metadata

    def run(self, plugin):
        """
        Execute rhv-log-collector-analyzer-live
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        rhvlc = risu.which("rhv-log-collector-analyzer-live")
        if not rhvlc:
            return (
                risu.RC_SKIPPED,
                "",
                self._("rhv-log-collector-analyzer-live support not found"),
            )

        if risu.RISU_LIVE == 0:
            # We're running in snapshot
            skipped = 1
        elif risu.RISU_LIVE == 1:
            # We're running in Live mode
            skipped = 0
        else:
            # We do not satisfy conditions, exit early
            skipped = 1

        if skipped == 1:
            return (
                risu.RC_SKIPPED,
                "",
                self._("Plugin does not satisfy conditions for running"),
            )

        command = "%s --json" % rhvlc

        # Call exec to run analyzer
        returncode, out, err = risu.execonshell(filename=command)

        # Do formatting of results and adjust return codes to risu standards
        if returncode == 2:
            returncode = risu.RC_FAILED
        elif returncode == 0:
            returncode = risu.RC_OKAY

        # Convert stdout to stderr for risu handling
        try:
            err = out
        except (TypeError, AttributeError):
            err = "Failed to convert output from log-analyzer"
            returncode = risu.RC_SKIPPED

        out = ""

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._("This extension processes rhv-log-collector-analyzer output")


# Create module-level exports for backward compatibility
_instance = RhvLogCollectorAnalyzerExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
