#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing file-based metadata generators in a similar way to what Faraday does
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018-2021, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
# https://en.wikipedia.org/wiki/Winston_Smith
from __future__ import print_function

import os

try:
    import risuclient.shell as risu
    from risuclient.extensions.base import BaseExtension
except ImportError:
    import shell as risu
    from extensions.base import BaseExtension

# Load i18n settings from risu (for backward compatibility)
_ = risu._

# Legacy module-level variables (for backward compatibility)
extension = "winston"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class WinstonExtension(BaseExtension):
    """Extension for processing file-based metadata generators"""

    extension_name = "winston"
    file_extension = ".txt"
    executables_only = False

    def run(self, plugin):
        """
        Read file content for metadata generation
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        filename = plugin["path"]

        skipped = 0
        if os.environ["RISU_LIVE"] == 0 and risu.regexpfile(
            filename=filename, regexp="RISU_ROOT"
        ):
            # We're running in snapshot and winston file has RISU_ROOT
            skipped = 0
        else:
            if os.environ["RISU_LIVE"] == 1:
                if risu.regexpfile(
                    filename=plugin["plugin"], regexp="RISU_HYBRID"
                ) or not risu.regexpfile(filename=filename, regexp="RISU_ROOT"):
                    # We're running in Live mode and either plugin supports HYBRID or has no RISU_ROOT
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

        if "${RISU_ROOT}" in filename:
            filename = filename.replace("${RISU_ROOT}", os.environ["RISU_ROOT"])

        if os.access(filename, os.R_OK):
            # We can read the file, so let's return its content
            out = ""
            err = open(filename, "rb").read()
            returncode = risu.RC_OKAY
        else:
            returncode = risu.RC_SKIPPED
            out = ""
            err = "File %s is not accessible in read mode" % filename

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._(
            "This extension creates fake plugins based on affinity/antiaffinity file list for later processing"
        )


# Create module-level exports for backward compatibility
_instance = WinstonExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
