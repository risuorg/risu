#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing ansible playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2017-2022, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
extension = "ansible"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class AnsibleExtension(BaseExtension):
    """Extension for processing Ansible playbook plugins"""

    extension_name = "ansible"
    file_extension = ".yml"
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

        try:
            long_name = doc[0]["vars"]["metadata"]["long_name"]
        except (KeyError, TypeError, IndexError):
            long_name = ""

        metadata = risu.generic_get_metadata(plugin=plugin)
        metadata.update({"description": description})
        metadata.update({"long_name": long_name})

        return metadata

    def run(self, plugin):
        """
        Execute ansible playbook
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        ansible = risu.which("ansible-playbook")
        if not ansible:
            return risu.RC_SKIPPED, "", self._("ansible-playbook support not found")

        if risu.RISU_LIVE == 0 and risu.regexpfile(
            filename=plugin["plugin"], regexp="RISU_ROOT"
        ):
            # We're running in snapshot and playbook has RISU_ROOT
            skipped = 0
        elif risu.RISU_LIVE == 1:
            if risu.regexpfile(
                filename=plugin["plugin"], regexp="RISU_HYBRID"
            ) or not risu.regexpfile(filename=plugin["plugin"], regexp="RISU_ROOT"):
                # We're running in Live mode and either plugin supports HYBRID or has no RISU_ROOT
                skipped = 0
            else:
                # We do not satisfy conditions, exit early
                skipped = 1
        else:
            # We do not satisfy conditions, exit early
            skipped = 1

        if skipped == 1:
            return (
                risu.RC_SKIPPED,
                "",
                self._("Plugin does not satisfy conditions for running"),
            )

        command = "%s -i localhost, --connection=local %s" % (ansible, plugin["plugin"])

        # Disable Ansible retry files creation:
        os.environ["ANSIBLE_RETRY_FILES_ENABLED"] = "0"

        # Call exec to run playbook
        returncode, out, err = risu.execonshell(filename=command)

        # Do formatting of results and adjust return codes to risu standards
        if returncode == 2:
            returncode = risu.RC_FAILED
        elif returncode == 0:
            returncode = risu.RC_OKAY

        # Convert stdout to stderr for risu handling
        err = out
        out = ""

        # Rewrite error messages to not contain all playbook execution but just the actual error
        if "FAILED!" in err:
            start = err.find("FAILED!", 0) + 11
            end = err.find("PLAY RECAP", 0) - 10
            newtext = err[start:end]
            err = newtext

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._("This extension processes Ansible playbooks")


# Create module-level exports for backward compatibility
_instance = AnsibleExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
