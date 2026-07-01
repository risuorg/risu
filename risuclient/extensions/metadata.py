#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for running and reporting metadata
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018-2021, 2023, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

import os

try:
    import risuclient.shell as risu
    from risuclient.extensions.base import SimpleShellExtension
except ImportError:
    import shell as risu
    from extensions.base import SimpleShellExtension

# Load i18n settings from risu (for backward compatibility)
_ = risu._

# Legacy module-level variables (for backward compatibility)
extension = "metadata"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class MetadataExtension(SimpleShellExtension):
    """Extension for running and reporting system metadata"""

    extension_name = "metadata"

    def help(self):
        """Returns help for plugin"""
        return self._(
            "This extension proceses Risu metadata plugins to fill details about system"
        )


# Create module-level exports for backward compatibility
_instance = MetadataExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
