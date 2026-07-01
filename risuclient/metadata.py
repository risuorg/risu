#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Plugin metadata extraction and validation
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Plugin metadata extraction and validation.

This module provides functions to extract and validate metadata
from Risu plugins (bash, Python, Ansible, etc.).
"""

from __future__ import print_function

import os
import re

try:
    from risuclient import exceptions
except ImportError:
    import exceptions


# Priority ranges for validation
PRIORITY_MIN = 1
PRIORITY_MAX = 999

# Priority categories
PRIORITY_CATEGORIES = {
    "critical": (900, 999),
    "high": (800, 899),
    "medium": (600, 799),
    "medium_low": (400, 599),
    "low": (200, 399),
    "very_low": (100, 199),
    "metadata": (1, 99),
}


class PluginMetadata(object):
    """
    Container for plugin metadata.

    Attributes:
        long_name (str): Descriptive name for web UI
        description (str): What the plugin checks
        priority (int): Priority level (1-999)
        bugzilla (str, optional): Bugzilla URL
        kb (str, optional): Knowledge base URL
        tags (list): List of tags/categories
        plugin_path (str): Path to plugin file
    """

    def __init__(
        self,
        long_name,
        description,
        priority,
        bugzilla=None,
        kb=None,
        tags=None,
        plugin_path=None,
    ):
        """
        Initialize plugin metadata.

        Args:
            long_name (str): Descriptive name
            description (str): Plugin description
            priority (int): Priority level (1-999)
            bugzilla (str, optional): Bugzilla URL
            kb (str, optional): KB URL
            tags (list, optional): List of tags
            plugin_path (str, optional): Path to plugin
        """
        self.long_name = long_name
        self.description = description
        self.priority = int(priority)
        self.bugzilla = bugzilla
        self.kb = kb
        self.tags = tags if tags is not None else []
        self.plugin_path = plugin_path

    def validate(self):
        """
        Validate metadata.

        Returns:
            list: List of validation error messages (empty if valid)
        """
        errors = []

        if not self.long_name or not self.long_name.strip():
            errors.append("long_name is required and cannot be empty")

        if not self.description or not self.description.strip():
            errors.append("description is required and cannot be empty")

        if not (PRIORITY_MIN <= self.priority <= PRIORITY_MAX):
            errors.append(
                "priority must be %d-%d, got %d"
                % (PRIORITY_MIN, PRIORITY_MAX, self.priority)
            )

        return errors

    def get_category(self):
        """
        Get priority category name.

        Returns:
            str: Category name ('critical', 'high', etc.)
        """
        for category, (min_pri, max_pri) in PRIORITY_CATEGORIES.items():
            if min_pri <= self.priority <= max_pri:
                return category
        return "unknown"

    def to_dict(self):
        """
        Convert to dictionary.

        Returns:
            dict: Metadata as dictionary
        """
        return {
            "long_name": self.long_name,
            "description": self.description,
            "priority": self.priority,
            "bugzilla": self.bugzilla,
            "kb": self.kb,
            "tags": self.tags,
            "category": self.get_category(),
        }

    def __repr__(self):
        """String representation."""
        return "PluginMetadata(long_name=%r, priority=%d, category=%s)" % (
            self.long_name,
            self.priority,
            self.get_category(),
        )


def extract_metadata_from_file(plugin_path, comment_char="#"):
    """
    Extract metadata from plugin file.

    Reads the plugin file and extracts metadata from comment headers.

    Args:
        plugin_path (str): Path to plugin file
        comment_char (str): Comment character (default '#' for bash/python)

    Returns:
        PluginMetadata: Extracted metadata

    Raises:
        exceptions.PluginMetadataError: If required metadata is missing
        IOError: If file cannot be read
    """
    try:
        with open(plugin_path, "r") as f:
            content = f.read()
    except (IOError, OSError) as e:
        raise exceptions.PluginMetadataError(
            "Cannot read plugin %s: %s" % (plugin_path, str(e))
        )

    # Extract metadata fields
    metadata = {}
    pattern = r"^%s\s*(\w+):\s*(.+)$" % re.escape(comment_char)

    for line in content.split("\n"):
        match = re.match(pattern, line.strip())
        if match:
            key = match.group(1).lower()
            value = match.group(2).strip()
            metadata[key] = value

    # Check required fields
    required_fields = ["long_name", "description", "priority"]
    missing = [f for f in required_fields if f not in metadata]

    if missing:
        raise exceptions.PluginMetadataError(
            "Plugin %s missing required metadata: %s"
            % (plugin_path, ", ".join(missing))
        )

    # Convert priority to int
    try:
        priority = int(metadata["priority"])
    except ValueError:
        raise exceptions.PluginMetadataError(
            "Plugin %s has invalid priority: %s" % (plugin_path, metadata["priority"])
        )

    # Create PluginMetadata object
    plugin_metadata = PluginMetadata(
        long_name=metadata["long_name"],
        description=metadata["description"],
        priority=priority,
        bugzilla=metadata.get("bugzilla"),
        kb=metadata.get("kb"),
        plugin_path=plugin_path,
    )

    # Validate
    errors = plugin_metadata.validate()
    if errors:
        raise exceptions.PluginMetadataError(
            "Plugin %s metadata validation failed: %s"
            % (plugin_path, "; ".join(errors))
        )

    return plugin_metadata


def extract_metadata_generic(plugin, comment="#"):
    """
    Generic metadata extraction (for backward compatibility).

    This function maintains the same interface as the original
    generic_get_metadata in shell.py.

    Args:
        plugin (dict): Plugin dictionary with 'plugin' key containing path
        comment (str): Comment character

    Returns:
        dict: Metadata dictionary with keys: long_name, description,
              priority, bugzilla, kb
    """
    plugin_path = plugin.get("plugin", "")

    if not plugin_path or not os.path.isfile(plugin_path):
        return {
            "long_name": "",
            "description": "",
            "priority": 0,
            "bugzilla": "",
            "kb": "",
        }

    try:
        metadata = extract_metadata_from_file(plugin_path, comment)
        return {
            "long_name": metadata.long_name,
            "description": metadata.description,
            "priority": metadata.priority,
            "bugzilla": metadata.bugzilla or "",
            "kb": metadata.kb or "",
        }
    except exceptions.PluginMetadataError:
        # Return empty metadata on error (for backward compatibility)
        return {
            "long_name": "",
            "description": "",
            "priority": 0,
            "bugzilla": "",
            "kb": "",
        }


def get_metadata_for_plugin_dict(plugin):
    """
    Get metadata for plugin dictionary.

    Wrapper function that matches the original get_metadata interface.

    Args:
        plugin (dict): Plugin dictionary

    Returns:
        dict: Metadata dictionary
    """
    return extract_metadata_generic(plugin, comment="#")
