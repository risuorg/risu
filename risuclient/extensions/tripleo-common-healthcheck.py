#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing tripleo-common-healthcheck playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018-2021, 2023, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
extension = "tripleo-common-healthcheck"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class TripleoCommonHealthcheckExtension(BaseExtension):
    """Extension for processing TripleO common healthcheck scripts"""

    extension_name = "tripleo-common-healthcheck"

    def get_metadata(self, plugin):
        """Get metadata for plugin with fixed priority"""
        description = ""

        metadata = risu.generic_get_metadata(plugin=plugin)
        metadata.update({"description": description, "priority": 333})

        return metadata

    def run(self, plugin):
        """
        Execute plugin (only on live systems)
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        if risu.RISU_LIVE == 1:
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

        command = "sh %s " % plugin["plugin"]

        # Call exec to run plugin
        returncode, out, err = risu.execonshell(filename=command)

        # Do formatting of results to adjust return codes to risu standards
        if returncode == 1:
            returncode = risu.RC_FAILED
        elif returncode == 0:
            returncode = risu.RC_OKAY

        # Convert stdout to stderr for risu handling
        err = out
        out = ""

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._(
            "This extension processes openstack-tripleo-common healthcheck scripts"
        )


# Create module-level exports for backward compatibility
_instance = TripleoCommonHealthcheckExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
