#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Generate plugin documentation from metadata
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Plugin documentation generator.

Scans all plugins and generates markdown documentation organized by
category and priority.
"""

from __future__ import print_function

import argparse
import os
import sys
from collections import defaultdict

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from risuclient import exceptions
    from risuclient import metadata as meta
except ImportError as e:
    print("Error importing risuclient modules: %s" % str(e), file=sys.stderr)
    print("Make sure you're running from the Risu root directory", file=sys.stderr)
    sys.exit(1)


def find_all_plugins(base_dir):
    """
    Recursively find all plugin files.

    Args:
        base_dir (str): Base directory to search

    Returns:
        list: List of plugin file paths
    """
    plugins = []

    for root, dirs, files in os.walk(base_dir):
        # Skip hidden directories and common excludes
        dirs[:] = [
            d
            for d in dirs
            if not d.startswith(".") and d not in ["__pycache__", "node_modules"]
        ]

        for filename in files:
            # Include bash, python, and ansible plugins
            if filename.endswith((".sh", ".py", ".yml", ".yaml")):
                # Skip test files
                if "test" in filename.lower():
                    continue
                plugins.append(os.path.join(root, filename))

    return plugins


def extract_plugin_info(plugin_path):
    """
    Extract metadata from plugin file.

    Args:
        plugin_path (str): Path to plugin file

    Returns:
        tuple: (PluginMetadata, error_message) - error_message is None if OK
    """
    try:
        plugin_metadata = meta.extract_metadata_from_file(plugin_path)
        return plugin_metadata, None
    except exceptions.PluginMetadataError as e:
        return None, str(e)
    except (IOError, OSError) as e:
        return None, "Cannot read file: %s" % str(e)


def group_plugins_by_category(plugins_metadata):
    """
    Group plugins by priority category.

    Args:
        plugins_metadata (list): List of PluginMetadata objects

    Returns:
        dict: Dict mapping category name to list of plugins
    """
    grouped = defaultdict(list)

    for plugin_meta in plugins_metadata:
        category = plugin_meta.get_category()
        grouped[category].append(plugin_meta)

    # Sort plugins within each category by priority (highest first)
    for category in grouped:
        grouped[category].sort(key=lambda p: p.priority, reverse=True)

    return grouped


def generate_markdown(grouped_plugins, output_file):
    """
    Generate markdown documentation.

    Args:
        grouped_plugins (dict): Plugins grouped by category
        output_file (str): Output file path

    Returns:
        bool: True if successful
    """
    # Category order (most critical first)
    category_order = [
        "critical",
        "high",
        "medium",
        "medium_low",
        "low",
        "very_low",
        "metadata",
        "unknown",
    ]

    # Category descriptions
    category_desc = {
        "critical": "Critical - System can break at any moment (900-999)",
        "high": "High - Core system services at risk (800-899)",
        "medium": "Medium - Applications & services (600-799)",
        "medium_low": "Medium-Low - Middleware & support (400-599)",
        "low": "Low - Monitoring & logging (200-399)",
        "very_low": "Very Low - Informational (100-199)",
        "metadata": "Metadata & Development (1-99)",
        "unknown": "Unknown Priority",
    }

    try:
        with open(output_file, "w") as f:
            # Header
            f.write("# Risu Plugins Catalog\n\n")
            f.write("Auto-generated documentation of all Risu plugins.\n\n")

            # Calculate statistics
            total_plugins = sum(len(plugins) for plugins in grouped_plugins.values())
            f.write("**Total Plugins**: %d\n\n" % total_plugins)

            # Summary table
            f.write("## Summary by Category\n\n")
            f.write("| Category | Count | Priority Range |\n")
            f.write("|----------|-------|----------------|\n")

            for category in category_order:
                if category not in grouped_plugins:
                    continue

                plugins = grouped_plugins[category]
                pri_range = meta.PRIORITY_CATEGORIES.get(category, (0, 0))
                f.write(
                    "| %s | %d | %d-%d |\n"
                    % (
                        category.replace("_", " ").title(),
                        len(plugins),
                        pri_range[0],
                        pri_range[1],
                    )
                )

            f.write("\n")

            # Table of contents
            f.write("## Table of Contents\n\n")
            for category in category_order:
                if category not in grouped_plugins:
                    continue
                anchor = category.replace("_", "-")
                title = category.replace("_", " ").title()
                f.write("- [%s](#%s)\n" % (title, anchor))
            f.write("\n")

            # Detailed listings
            for category in category_order:
                if category not in grouped_plugins:
                    continue

                plugins = grouped_plugins[category]
                title = category.replace("_", " ").title()
                desc = category_desc.get(category, "")

                f.write("## %s\n\n" % title)
                f.write("%s\n\n" % desc)
                f.write("**Plugins in this category**: %d\n\n" % len(plugins))

                for plugin_meta in plugins:
                    # Plugin heading
                    f.write("### %s\n\n" % plugin_meta.long_name)

                    # Description
                    f.write("**Description**: %s\n\n" % plugin_meta.description)

                    # Priority
                    f.write("**Priority**: %d\n\n" % plugin_meta.priority)

                    # Optional fields
                    if plugin_meta.bugzilla:
                        f.write("**Bugzilla**: %s\n\n" % plugin_meta.bugzilla)

                    if plugin_meta.kb:
                        f.write("**Knowledge Base**: %s\n\n" % plugin_meta.kb)

                    # Plugin file path (relative)
                    if plugin_meta.plugin_path:
                        rel_path = os.path.relpath(plugin_meta.plugin_path)
                        f.write("**File**: `%s`\n\n" % rel_path)

                    f.write("---\n\n")

        return True

    except (IOError, OSError) as e:
        print("Error writing to %s: %s" % (output_file, str(e)), file=sys.stderr)
        return False


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate markdown documentation from Risu plugin metadata"
    )
    parser.add_argument(
        "--plugins-dir",
        default="risuclient/plugins",
        help="Directory containing plugins (default: risuclient/plugins)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="PLUGINS.md",
        help="Output markdown file (default: PLUGINS.md)",
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument(
        "--show-errors", action="store_true", help="Show plugins with metadata errors"
    )

    args = parser.parse_args()

    # Validate plugins directory
    if not os.path.isdir(args.plugins_dir):
        print(
            "Error: Plugins directory not found: %s" % args.plugins_dir, file=sys.stderr
        )
        return 1

    print("Scanning plugins in %s..." % args.plugins_dir)

    # Find all plugins
    plugin_files = find_all_plugins(args.plugins_dir)
    print("Found %d plugin files" % len(plugin_files))

    # Extract metadata
    plugins_metadata = []
    errors = []

    for plugin_file in plugin_files:
        if args.verbose:
            print("Processing: %s" % plugin_file)

        plugin_meta, error = extract_plugin_info(plugin_file)

        if plugin_meta:
            plugins_metadata.append(plugin_meta)
        elif error:
            errors.append((plugin_file, error))

    print("Successfully parsed %d plugins" % len(plugins_metadata))

    if errors:
        print("Failed to parse %d plugins" % len(errors))
        if args.show_errors:
            print("\nErrors:")
            for plugin_file, error in errors:
                print("  %s: %s" % (plugin_file, error))

    # Group by category
    grouped = group_plugins_by_category(plugins_metadata)

    # Generate markdown
    print("Generating documentation: %s" % args.output)
    if generate_markdown(grouped, args.output):
        print("Documentation generated successfully!")
        return 0
    else:
        print("Failed to generate documentation", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
