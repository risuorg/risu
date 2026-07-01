#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing nagios Risu plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2021, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
extension = "nagios"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class NagiosExtension(BaseExtension):
    """Extension for processing Nagios plugins with return code mapping"""

    extension_name = "nagios"

    def get_metadata(self, plugin):
        """Get metadata for plugin with nagios backend marker"""
        metadata = risu.generic_get_metadata(plugin=plugin)
        metadata["backend"] = "nagios"
        return metadata

    def run(self, plugin):
        """
        Execute plugin and map Nagios return codes to Risu codes
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        # Call exec to run plugin
        returncode, out, err = risu.execonshell(filename=plugin["plugin"])

        # Map Nagios return codes to Risu standards
        if returncode == 2:  # CRITICAL
            returncode = risu.RC_FAILED
        elif returncode == 0:  # OK
            returncode = risu.RC_OKAY
        elif returncode == 1:  # WARNING
            returncode = risu.RC_INFO
        elif returncode == 3:  # UNKNOWN
            returncode = risu.RC_SKIPPED

        # Convert stdout to stderr for risu handling
        err = out
        out = ""

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._("This extension proceses Risu nagios plugins")


# Create module-level exports for backward compatibility
_instance = NagiosExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
