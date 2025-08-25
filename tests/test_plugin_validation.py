#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Plugin validation tests for metadata consistency
#
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

import os
import sys
import tempfile
import shutil
from unittest import TestCase
from collections import defaultdict

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))

try:
    import risuclient.shell as risu
except:
    import shell as risu


class PluginValidationTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-validation-test-")
        self.all_plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core")]
        )
        self.ansible_plugins = risu.findplugins(
            executables=False,
            fileextension=".yml",
            extension="ansible",
            folders=[os.path.join(risu.risudir, "plugins", "ansible")],
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_plugin_metadata_completeness(self):
        """Test that all plugins have complete metadata"""
        all_plugins = self.all_plugins + self.ansible_plugins
        incomplete_plugins = []

        for plugin in all_plugins:
            issues = []

            # Check required fields
            if not plugin.get("description"):
                issues.append("missing description")
            if not plugin.get("long_name"):
                issues.append("missing long_name")
            if not plugin.get("priority"):
                issues.append("missing priority")

            # Check field validity
            if plugin.get("description") and plugin.get("description").strip() == "":
                issues.append("empty description")
            if plugin.get("long_name") and plugin.get("long_name").strip() == "":
                issues.append("empty long_name")

            # Check priority validity
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    if prio_val < 1 or prio_val > 999:
                        issues.append(f"invalid priority range: {prio_val}")
                except ValueError:
                    issues.append(f"invalid priority format: {priority}")

            if issues:
                incomplete_plugins.append((plugin["plugin"], issues))

        if incomplete_plugins:
            print("\nPlugins with incomplete metadata:")
            for plugin_path, issues in incomplete_plugins:
                print(f"  {plugin_path}: {', '.join(issues)}")

        # Should have very few incomplete plugins
        completeness_rate = (
            (len(all_plugins) - len(incomplete_plugins)) / len(all_plugins)
        ) * 100
        self.assertGreaterEqual(
            completeness_rate,
            95,
            f"Plugin metadata completeness too low: {completeness_rate:.1f}%",
        )

    def test_plugin_naming_consistency(self):
        """Test consistency of plugin naming conventions"""
        all_plugins = self.all_plugins + self.ansible_plugins
        naming_issues = []

        for plugin in all_plugins:
            plugin_path = plugin["plugin"]
            plugin_name = os.path.basename(plugin_path)

            # Check file naming conventions
            if plugin_name.startswith("."):
                naming_issues.append(f"{plugin_path}: hidden file")

            # Check for spaces in filename
            if " " in plugin_name:
                naming_issues.append(f"{plugin_path}: spaces in filename")

            # Check for uppercase in filename (should be lowercase)
            if plugin_name != plugin_name.lower():
                naming_issues.append(f"{plugin_path}: uppercase characters in filename")

            # Check for invalid characters
            invalid_chars = ["(", ")", "[", "]", "{", "}", "&", "|", ";", "<", ">"]
            for char in invalid_chars:
                if char in plugin_name:
                    naming_issues.append(
                        f"{plugin_path}: invalid character '{char}' in filename"
                    )
                    break

        if naming_issues:
            print("\nPlugin naming issues:")
            for issue in naming_issues:
                print(f"  {issue}")

        # Should have minimal naming issues
        naming_error_rate = len(naming_issues) / len(all_plugins) * 100
        self.assertLessEqual(
            naming_error_rate, 5, f"Too many naming issues: {naming_error_rate:.1f}%"
        )

    def test_plugin_priority_consistency(self):
        """Test consistency of plugin priority assignments"""
        priority_analysis = defaultdict(list)

        for plugin in self.all_plugins:
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    # Categorize by plugin type
                    plugin_path = plugin["plugin"]

                    if "security" in plugin_path:
                        priority_analysis["security"].append(prio_val)
                    elif "network" in plugin_path:
                        priority_analysis["network"].append(prio_val)
                    elif "openstack" in plugin_path:
                        priority_analysis["openstack"].append(prio_val)
                    elif "openshift" in plugin_path:
                        priority_analysis["openshift"].append(prio_val)
                    elif "system" in plugin_path:
                        priority_analysis["system"].append(prio_val)
                    else:
                        priority_analysis["other"].append(prio_val)
                except ValueError:
                    pass

        print("\nPriority distribution by category:")
        for category, priorities in priority_analysis.items():
            if priorities:
                avg_priority = sum(priorities) / len(priorities)
                min_priority = min(priorities)
                max_priority = max(priorities)
                print(
                    f"  {category}: avg={avg_priority:.0f}, min={min_priority}, max={max_priority}, count={len(priorities)}"
                )

        # Validate priority ranges make sense
        if priority_analysis["security"]:
            avg_security = sum(priority_analysis["security"]) / len(
                priority_analysis["security"]
            )
            self.assertGreaterEqual(
                avg_security,
                700,
                f"Security plugins should have high average priority: {avg_security:.0f}",
            )

        if priority_analysis["network"]:
            avg_network = sum(priority_analysis["network"]) / len(
                priority_analysis["network"]
            )
            self.assertGreaterEqual(
                avg_network,
                600,
                f"Network plugins should have medium-high average priority: {avg_network:.0f}",
            )

    def test_plugin_description_quality(self):
        """Test quality of plugin descriptions"""
        all_plugins = self.all_plugins + self.ansible_plugins
        description_issues = []

        for plugin in all_plugins:
            description = plugin.get("description", "")
            long_name = plugin.get("long_name", "")

            if description:
                # Check description length
                if len(description) < 10:
                    description_issues.append(
                        f"{plugin['plugin']}: description too short"
                    )
                elif len(description) > 200:
                    description_issues.append(
                        f"{plugin['plugin']}: description too long"
                    )

                # Check for common issues
                if description.lower().startswith("checks"):
                    description_issues.append(
                        f"{plugin['plugin']}: description starts with 'checks'"
                    )

                # Check for placeholder text
                if "TODO" in description or "FIXME" in description:
                    description_issues.append(
                        f"{plugin['plugin']}: description contains placeholder text"
                    )

            if long_name:
                # Check long_name length
                if len(long_name) < 5:
                    description_issues.append(
                        f"{plugin['plugin']}: long_name too short"
                    )
                elif len(long_name) > 100:
                    description_issues.append(f"{plugin['plugin']}: long_name too long")

        if description_issues:
            print("\nDescription quality issues:")
            for issue in description_issues:
                print(f"  {issue}")

        # Should have minimal description issues
        description_error_rate = len(description_issues) / len(all_plugins) * 100
        self.assertLessEqual(
            description_error_rate,
            30,
            f"Too many description issues: {description_error_rate:.1f}%",
        )

    def test_plugin_file_structure_validation(self):
        """Test plugin file structure and permissions"""
        structure_issues = []

        for plugin in self.all_plugins:
            plugin_path = plugin["plugin"]

            # Check file exists
            if not os.path.exists(plugin_path):
                structure_issues.append(f"{plugin_path}: file does not exist")
                continue

            # Check file is readable
            if not os.access(plugin_path, os.R_OK):
                structure_issues.append(f"{plugin_path}: file not readable")

            # Check executable permissions for shell scripts
            if plugin_path.endswith(".sh"):
                if not os.access(plugin_path, os.X_OK):
                    structure_issues.append(
                        f"{plugin_path}: shell script not executable"
                    )

            # Check file size (should not be empty, but not too large)
            try:
                file_size = os.path.getsize(plugin_path)
                if file_size == 0:
                    structure_issues.append(f"{plugin_path}: empty file")
                elif file_size > 100000:  # 100KB
                    structure_issues.append(
                        f"{plugin_path}: file too large ({file_size} bytes)"
                    )
            except OSError:
                structure_issues.append(f"{plugin_path}: cannot read file size")

        if structure_issues:
            print("\nFile structure issues:")
            for issue in structure_issues:
                print(f"  {issue}")

        # Should have minimal structure issues
        structure_error_rate = len(structure_issues) / len(self.all_plugins) * 100
        self.assertLessEqual(
            structure_error_rate,
            5,
            f"Too many file structure issues: {structure_error_rate:.1f}%",
        )

    def test_plugin_header_format_validation(self):
        """Test plugin header format consistency"""
        header_issues = []

        for plugin in self.all_plugins:
            plugin_path = plugin["plugin"]

            try:
                with open(plugin_path, "r", encoding="utf-8") as f:
                    content = f.read()

                # Check for proper header format
                if plugin_path.endswith(".sh"):
                    # Shell scripts should have shebang
                    if not content.startswith("#!/"):
                        header_issues.append(f"{plugin_path}: missing shebang")

                    # Check for required header fields
                    if "# long_name:" not in content:
                        header_issues.append(f"{plugin_path}: missing long_name header")
                    if "# description:" not in content:
                        header_issues.append(
                            f"{plugin_path}: missing description header"
                        )
                    if "# priority:" not in content:
                        header_issues.append(f"{plugin_path}: missing priority header")

                elif plugin_path.endswith(".py"):
                    # Python scripts should have proper encoding
                    if "# -*- coding: utf-8 -*-" not in content:
                        header_issues.append(
                            f"{plugin_path}: missing encoding declaration"
                        )

                    # Check for required header fields
                    if "# long_name:" not in content:
                        header_issues.append(f"{plugin_path}: missing long_name header")
                    if "# description:" not in content:
                        header_issues.append(
                            f"{plugin_path}: missing description header"
                        )
                    if "# priority:" not in content:
                        header_issues.append(f"{plugin_path}: missing priority header")

            except Exception as e:
                header_issues.append(f"{plugin_path}: cannot read file - {e}")

        if header_issues:
            print("\nHeader format issues:")
            for issue in header_issues:
                print(f"  {issue}")

        # Should have minimal header issues
        header_error_rate = len(header_issues) / len(self.all_plugins) * 100
        self.assertLessEqual(
            header_error_rate,
            5,
            f"Too many header format issues: {header_error_rate:.1f}%",
        )

    def test_plugin_category_organization(self):
        """Test plugin category organization"""
        category_analysis = defaultdict(int)
        organization_issues = []

        for plugin in self.all_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")

            # Find category
            if "plugins" in parts:
                plugin_index = parts.index("plugins")
                if plugin_index + 2 < len(parts):
                    category = parts[plugin_index + 2]
                    category_analysis[category] += 1

                    # Check if plugin is in the right category
                    description = plugin.get("description", "").lower()
                    long_name = plugin.get("long_name", "").lower()

                    # Basic category validation
                    if category == "security":
                        if not any(
                            keyword in description or keyword in long_name
                            for keyword in [
                                "security",
                                "vulnerability",
                                "cve",
                                "meltdown",
                                "spectre",
                            ]
                        ):
                            organization_issues.append(
                                f"{plugin_path}: may not belong in security category"
                            )
                    elif category == "network":
                        if not any(
                            keyword in description or keyword in long_name
                            for keyword in [
                                "network",
                                "interface",
                                "connectivity",
                                "dns",
                                "ip",
                            ]
                        ):
                            organization_issues.append(
                                f"{plugin_path}: may not belong in network category"
                            )
                    elif category == "openstack":
                        if not any(
                            keyword in description or keyword in long_name
                            for keyword in [
                                "openstack",
                                "nova",
                                "neutron",
                                "keystone",
                                "glance",
                                "cinder",
                            ]
                        ):
                            organization_issues.append(
                                f"{plugin_path}: may not belong in openstack category"
                            )

        print("\nPlugin category distribution:")
        for category, count in sorted(category_analysis.items()):
            print(f"  {category}: {count} plugins")

        if organization_issues:
            print("\nCategory organization issues:")
            for issue in organization_issues:
                print(f"  {issue}")

        # Should have reasonable category distribution
        total_plugins = sum(category_analysis.values())
        largest_category = max(category_analysis.values())

        # No single category should dominate too much
        max_category_percentage = (largest_category / total_plugins) * 100
        self.assertLessEqual(
            max_category_percentage,
            60,
            f"Single category too dominant: {max_category_percentage:.1f}%",
        )

        # Should have minimal organization issues
        organization_error_rate = len(organization_issues) / len(self.all_plugins) * 100
        self.assertLessEqual(
            organization_error_rate,
            15,
            f"Too many category organization issues: {organization_error_rate:.1f}%",
        )

    def test_plugin_execution_validation(self):
        """Test basic plugin execution validation"""
        execution_issues = []

        # Test a representative sample
        test_plugins = self.all_plugins[:100]

        for plugin in test_plugins:
            try:
                result = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})

                # Validate result structure
                if not isinstance(result, dict):
                    execution_issues.append(
                        f"{plugin['plugin']}: result is not a dictionary"
                    )
                    continue

                if "result" not in result:
                    execution_issues.append(
                        f"{plugin['plugin']}: missing 'result' field"
                    )
                    continue

                plugin_result = result["result"]

                # Validate return code
                rc = plugin_result.get("rc")
                if rc not in [
                    risu.RC_OKAY,
                    risu.RC_FAILED,
                    risu.RC_SKIPPED,
                    risu.RC_INFO,
                ]:
                    execution_issues.append(
                        f"{plugin['plugin']}: invalid return code {rc}"
                    )

                # Validate output fields
                if "out" not in plugin_result:
                    execution_issues.append(f"{plugin['plugin']}: missing 'out' field")
                if "err" not in plugin_result:
                    execution_issues.append(f"{plugin['plugin']}: missing 'err' field")

            except Exception as e:
                execution_issues.append(f"{plugin['plugin']}: execution error - {e}")

        if execution_issues:
            print("\nExecution validation issues:")
            for issue in execution_issues:
                print(f"  {issue}")

        # Should have minimal execution issues
        execution_error_rate = len(execution_issues) / len(test_plugins) * 100
        self.assertLessEqual(
            execution_error_rate,
            30,
            f"Too many execution validation issues: {execution_error_rate:.1f}%",
        )

    def test_plugin_metadata_cross_validation(self):
        """Test cross-validation of plugin metadata"""
        cross_validation_issues = []

        for plugin in self.all_plugins:
            plugin_path = plugin["plugin"]
            description = plugin.get("description", "")
            long_name = plugin.get("long_name", "")
            priority = plugin.get("priority")

            # Check consistency between description and long_name
            if description and long_name:
                # They should have some common keywords
                desc_words = set(description.lower().split())
                name_words = set(long_name.lower().split())

                # Remove common words
                common_words = {
                    "the",
                    "and",
                    "or",
                    "for",
                    "in",
                    "on",
                    "at",
                    "to",
                    "of",
                    "a",
                    "an",
                    "is",
                    "are",
                    "was",
                    "were",
                    "be",
                    "been",
                    "being",
                    "have",
                    "has",
                    "had",
                    "do",
                    "does",
                    "did",
                    "will",
                    "would",
                    "could",
                    "should",
                    "may",
                    "might",
                    "must",
                    "can",
                    "cannot",
                    "check",
                    "checks",
                    "test",
                    "tests",
                }
                desc_words -= common_words
                name_words -= common_words

                # Should have at least one word in common
                if not desc_words.intersection(name_words):
                    cross_validation_issues.append(
                        f"{plugin_path}: description and long_name have no common keywords"
                    )

            # Check priority consistency with path
            if priority:
                try:
                    prio_val = int(priority)

                    # Security plugins should have high priority
                    if "security" in plugin_path and prio_val < 700:
                        cross_validation_issues.append(
                            f"{plugin_path}: security plugin with low priority {prio_val}"
                        )

                    # Info plugins should have low priority
                    if "sysinfo" in plugin_path and prio_val > 400:
                        cross_validation_issues.append(
                            f"{plugin_path}: info plugin with high priority {prio_val}"
                        )

                except ValueError:
                    pass

        if cross_validation_issues:
            print("\nCross-validation issues:")
            for issue in cross_validation_issues:
                print(f"  {issue}")

        # Should have minimal cross-validation issues
        cross_validation_error_rate = (
            len(cross_validation_issues) / len(self.all_plugins) * 100
        )
        self.assertLessEqual(
            cross_validation_error_rate,
            20,
            f"Too many cross-validation issues: {cross_validation_error_rate:.1f}%",
        )
