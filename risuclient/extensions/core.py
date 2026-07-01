#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing core Risu plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2017-2022, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
extension = "core"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class CoreExtension(SimpleShellExtension):
    """Extension for processing core Risu shell script plugins"""

    extension_name = "core"

    def help(self):
        """Returns help for plugin"""
        return self._("This extension processes Risu core plugins")


# Create module-level exports for backward compatibility
_instance = CoreExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
