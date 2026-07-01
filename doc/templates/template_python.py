#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2026 Your Name <your.email@example.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
Python Plugin Template for Risu

REQUIRED METADATA:
    long_name: Brief descriptive name shown in web UI
    description: Detailed description of what this plugin checks
    priority: 1-999 (see template_modern.sh for priority ranges)

OPTIONAL METADATA:
    bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=XXXXX
    kb: https://access.redhat.com/solutions/XXXXX
"""

from __future__ import print_function

import os
import sys

# Return codes
RC_OKAY = 10
RC_FAILED = 20
RC_SKIPPED = 30
RC_INFO = 40


def is_required_file(filepath):
    """
    Check if a required file exists.

    Args:
        filepath: Path to file

    Returns:
        True if file exists, exits with RC_SKIPPED otherwise
    """
    if not os.path.isfile(filepath):
        # Remove RISU_ROOT prefix from error message for cleaner output
        risu_root = os.environ.get("RISU_ROOT", "/")
        display_path = filepath.replace(risu_root, "")
        print("required file %s not found." % display_path, file=sys.stderr)
        sys.exit(RC_SKIPPED)
    return True


def check_file_content(filepath, search_string):
    """
    Check if file contains a specific string.

    Args:
        filepath: Path to file
        search_string: String to search for

    Returns:
        True if string found, False otherwise
    """
    try:
        with open(filepath, "r") as f:
            content = f.read()
            return search_string in content
    except (IOError, OSError) as e:
        print("Error reading %s: %s" % (filepath, str(e)), file=sys.stderr)
        return False


def main():
    """Main plugin logic"""
    # Get environment variables
    risu_root = os.environ.get("RISU_ROOT", "/")
    risu_live = os.environ.get("RISU_LIVE", "0")

    # Define files to check
    config_file = os.path.join(risu_root, "etc", "example", "config.conf")

    # Check prerequisites
    is_required_file(config_file)

    # Initialize return code
    rc = RC_OKAY

    # Perform checks
    if check_file_content(config_file, "problematic_setting"):
        print("Problematic setting detected in %s" % config_file, file=sys.stderr)
        rc = RC_FAILED

    # Example: different behavior for live vs snapshot
    if risu_live == "1":
        # Live mode - can check running processes, etc.
        # Example: check if service is running
        pass
    else:
        # Snapshot mode - work with static files
        pass

    # Example: Check numeric values
    # try:
    #     value = get_config_value(config_file, "section", "key")
    #     if int(value) > 100:
    #         print("Value too high: %s" % value, file=sys.stderr)
    #         rc = RC_FAILED
    # except (ValueError, KeyError) as e:
    #     print("Configuration error: %s" % str(e), file=sys.stderr)
    #     rc = RC_FAILED

    return rc


if __name__ == "__main__":
    sys.exit(main())
