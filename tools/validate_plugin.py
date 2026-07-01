#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Validates Risu plugin structure and metadata
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Plugin validation tool for Risu framework.

Checks bash plugins for:
- Required metadata headers (long_name, description, priority)
- Proper exit code usage (RC_* constants instead of exit 0/1)
- Shellcheck compliance (if available)
- Common-functions loading
"""

from __future__ import print_function

import argparse
import os
import re
import subprocess
import sys


class PluginValidator:
    """Validates Risu plugin files"""

    REQUIRED_HEADERS = ["long_name", "description", "priority"]
    OPTIONAL_HEADERS = ["bugzilla", "kb"]
    RC_CONSTANTS = ["RC_OKAY", "RC_FAILED", "RC_SKIPPED", "RC_INFO"]

    def __init__(self, plugin_path):
        self.plugin_path = plugin_path
        self.errors = []
        self.warnings = []
        self.content = None

    def read_plugin(self):
        """Read plugin file content"""
        try:
            with open(self.plugin_path, "r") as f:
                self.content = f.read()
            return True
        except (IOError, OSError) as e:
            self.errors.append("Cannot read file: %s" % str(e))
            return False

    def check_shebang(self):
        """Verify plugin has proper shebang"""
        if not self.content:
            return

        lines = self.content.split("\n")
        if not lines:
            self.errors.append("Empty file")
            return

        if not lines[0].startswith("#!"):
            self.errors.append("Missing shebang line")
        elif "bash" not in lines[0] and "sh" not in lines[0]:
            self.warnings.append("Shebang does not reference bash/sh: %s" % lines[0])

    def check_metadata(self):
        """Check for required metadata headers"""
        if not self.content:
            return

        for header in self.REQUIRED_HEADERS:
            pattern = r"^#\s*%s:\s*.+" % header
            if not re.search(pattern, self.content, re.MULTILINE):
                self.errors.append("Missing required header: %s" % header)

        # Check priority value if present
        priority_match = re.search(
            r"^#\s*priority:\s*(\d+)", self.content, re.MULTILINE
        )
        if priority_match:
            priority = int(priority_match.group(1))
            if not (1 <= priority <= 999):
                self.errors.append("Priority must be between 1-999, got: %d" % priority)

    def check_exit_codes(self):
        """Check that plugin uses RC_ constants instead of exit 0/1"""
        if not self.content:
            return

        # Look for exit 0 or exit 1 (but not exit 10, exit 20, etc.)
        bad_exit_pattern = r"\bexit\s+[01](?![0-9])"
        matches = re.findall(bad_exit_pattern, self.content)

        if matches:
            self.errors.append(
                "Plugin uses 'exit 0' or 'exit 1' instead of RC_ constants (%d occurrences)"
                % len(matches)
            )

    def check_common_functions(self):
        """Check if plugin loads common-functions.sh"""
        if not self.content:
            return

        # Check if common-functions.sh is sourced
        if "common-functions.sh" not in self.content:
            self.warnings.append("Plugin does not appear to load common-functions.sh")
        else:
            # Check for proper loading pattern
            pattern = r'\[\[\s*-f\s+"\$\{RISU_BASE\}/common-functions\.sh"\s*\]\]\s*&&\s*\.\s+"\$\{RISU_BASE\}/common-functions\.sh"'
            if not re.search(pattern, self.content):
                self.warnings.append(
                    "common-functions.sh loading does not follow standard pattern"
                )

    def check_shellcheck(self):
        """Run shellcheck if available"""
        try:
            # Check if shellcheck is available
            result = subprocess.call(
                ["which", "shellcheck"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if result != 0:
                # shellcheck not available
                return

            # Run shellcheck
            result = subprocess.Popen(
                ["shellcheck", "-x", self.plugin_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            stdout, stderr = result.communicate()

            if result.returncode != 0:
                self.warnings.append(
                    "shellcheck found issues (run 'shellcheck -x %s' for details)"
                    % self.plugin_path
                )

        except (OSError, IOError):
            # shellcheck not available or error running it
            pass

    def validate(self):
        """Run all validation checks"""
        if not self.read_plugin():
            return False

        self.check_shebang()
        self.check_metadata()
        self.check_exit_codes()
        self.check_common_functions()
        self.check_shellcheck()

        return len(self.errors) == 0

    def print_results(self):
        """Print validation results"""
        if self.errors:
            print("ERRORS in %s:" % self.plugin_path)
            for error in self.errors:
                print("  - %s" % error)

        if self.warnings:
            print("WARNINGS in %s:" % self.plugin_path)
            for warning in self.warnings:
                print("  - %s" % warning)

        if not self.errors and not self.warnings:
            print("OK: %s" % self.plugin_path)

        return len(self.errors) == 0


def validate_plugin_file(plugin_path, verbose=False):
    """Validate a single plugin file"""
    validator = PluginValidator(plugin_path)
    is_valid = validator.validate()

    if verbose or not is_valid:
        validator.print_results()

    return is_valid


def find_bash_plugins(directory):
    """Find all bash plugin files in directory"""
    plugins = []
    for root, dirs, files in os.walk(directory):
        # Skip hidden directories
        dirs[:] = [d for d in dirs if not d.startswith(".")]

        for filename in files:
            if filename.endswith(".sh"):
                plugins.append(os.path.join(root, filename))

    return plugins


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Validate Risu plugin files for proper structure and metadata"
    )
    parser.add_argument(
        "plugins",
        nargs="+",
        help="Plugin file(s) or directory to validate",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Show results for all plugins, not just failures",
    )
    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Recursively find plugins in directory",
    )

    args = parser.parse_args()

    plugins_to_check = []

    for path in args.plugins:
        if os.path.isdir(path):
            if args.recursive:
                plugins_to_check.extend(find_bash_plugins(path))
            else:
                print("Error: %s is a directory. Use -r for recursive scan." % path)
                return 1
        elif os.path.isfile(path):
            plugins_to_check.append(path)
        else:
            print("Error: %s not found" % path)
            return 1

    if not plugins_to_check:
        print("No plugins found to validate")
        return 1

    print("Validating %d plugin(s)..." % len(plugins_to_check))
    print()

    failed = 0
    passed = 0

    for plugin in plugins_to_check:
        if validate_plugin_file(plugin, args.verbose):
            passed += 1
        else:
            failed += 1

    print()
    print("=" * 60)
    print("Results: %d passed, %d failed" % (passed, failed))

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
