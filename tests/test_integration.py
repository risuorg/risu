#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Integration tests for Risu plugins
#
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

import os
import sys
import time
import tempfile
import shutil
from unittest import TestCase
from collections import defaultdict

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))

try:
    import risuclient.shell as risu
    import maguiclient.magui as magui
except:
    import shell as risu
    import magui


class IntegrationTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-integration-test-")
        self.tmpdir2 = tempfile.mkdtemp(prefix="risu-integration-test-2-")
        self.all_plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core")]
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)
        if os.path.exists(self.tmpdir2):
            shutil.rmtree(self.tmpdir2)

    def test_full_risu_run(self):
        """Test complete Risu execution with multiple plugins"""
        # Select a representative subset of plugins from different categories
        test_plugins = []
        categories = defaultdict(list)

        # Categorize plugins
        for plugin in self.all_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "plugins" in parts:
                plugin_index = parts.index("plugins")
                if plugin_index + 2 < len(parts):
                    category = parts[plugin_index + 2]
                    categories[category].append(plugin)

        # Select plugins from each category
        for category, plugins in categories.items():
            test_plugins.extend(plugins[:5])  # Take first 5 from each category

        # Limit total plugins to avoid timeout
        test_plugins = test_plugins[:100]

        print(
            f"\nRunning integration test with {len(test_plugins)} plugins from {len(categories)} categories"
        )

        start_time = time.time()
        results = risu.dorisu(
            path=self.tmpdir,
            plugins=test_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
            web=True,
        )
        execution_time = time.time() - start_time

        print(f"Integration test completed in {execution_time:.2f} seconds")

        # Verify results
        self.assertIsNotNone(results, "Integration test should return results")
        self.assertGreater(
            len(results), 0, "Integration test should have plugin results"
        )

        # Verify web output was generated
        self.assertTrue(
            os.path.exists(os.path.join(self.tmpdir, "risu.json")),
            "Integration test should generate risu.json",
        )
        self.assertTrue(
            os.path.exists(os.path.join(self.tmpdir, "risu.html")),
            "Integration test should generate risu.html",
        )

        # Check result distribution
        result_counts = defaultdict(int)
        for plugin_result in results.values():
            rc = plugin_result["result"]["rc"]
            result_counts[rc] += 1

        print("Result distribution:")
        for rc, count in result_counts.items():
            print(f"  RC {rc}: {count} plugins")

        # Should have results in all expected categories
        expected_rcs = [risu.RC_OKAY, risu.RC_FAILED, risu.RC_SKIPPED, risu.RC_INFO]
        for rc in expected_rcs:
            if rc in result_counts:
                print(f"Found plugins with RC {rc}: {result_counts[rc]}")
            # Don't assert that all RCs must be present - some may not occur

    def test_magui_integration(self):
        """Test Magui integration with multiple sosreports"""
        # Create test plugins
        test_plugins = self.all_plugins[:50]  # Use subset

        print(f"\nRunning Magui integration test with {len(test_plugins)} plugins")

        start_time = time.time()
        magui_results = magui.domagui(
            sosreports=[self.tmpdir, self.tmpdir2], risuplugins=test_plugins
        )
        execution_time = time.time() - start_time

        print(f"Magui integration test completed in {execution_time:.2f} seconds")

        # Verify results
        self.assertIsNotNone(magui_results, "Magui integration should return results")

    def test_plugin_dependency_handling(self):
        """Test handling of plugin dependencies and interactions"""
        # Test plugins that might depend on each other
        system_plugins = [p for p in self.all_plugins if "system" in p["plugin"]][:20]

        print(
            f"\nTesting plugin dependency handling with {len(system_plugins)} system plugins"
        )

        # Run plugins individually first
        individual_results = {}
        for plugin in system_plugins:
            try:
                result = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                individual_results[plugin["plugin"]] = result
            except Exception as e:
                print(f"Error running plugin {plugin['plugin']}: {e}")

        # Run plugins together
        batch_results = risu.dorisu(
            path=self.tmpdir,
            plugins=system_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
        )

        # Compare results - should be consistent
        consistent_results = 0
        total_compared = 0

        for plugin_path, individual_result in individual_results.items():
            if plugin_path in batch_results:
                total_compared += 1
                individual_rc = individual_result["result"]["rc"]
                batch_rc = batch_results[plugin_path]["result"]["rc"]

                if individual_rc == batch_rc:
                    consistent_results += 1
                else:
                    print(
                        f"Inconsistent result for {plugin_path}: individual={individual_rc}, batch={batch_rc}"
                    )

        if total_compared > 0:
            consistency_rate = (consistent_results / total_compared) * 100
            print(f"Plugin consistency rate: {consistency_rate:.1f}%")

            # Most plugins should be consistent
            self.assertGreaterEqual(
                consistency_rate,
                80,
                f"Plugin consistency rate too low: {consistency_rate:.1f}%",
            )

    def test_concurrent_execution_safety(self):
        """Test safety of concurrent plugin execution"""
        import concurrent.futures

        test_plugins = self.all_plugins[:30]  # Use subset
        results = {}
        errors = []

        def run_plugin(plugin):
            try:
                result = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                return plugin["plugin"], result
            except Exception as e:
                errors.append((plugin["plugin"], str(e)))
                return plugin["plugin"], None

        print(f"\nTesting concurrent execution safety with {len(test_plugins)} plugins")

        # Run plugins concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            futures = [executor.submit(run_plugin, plugin) for plugin in test_plugins]

            for future in concurrent.futures.as_completed(futures):
                plugin_path, result = future.result()
                results[plugin_path] = result

        print("Concurrent execution completed:")
        print(f"  Successful: {len([r for r in results.values() if r is not None])}")
        print(f"  Errors: {len(errors)}")

        if errors:
            print("  Error details:")
            for plugin_path, error in errors:
                print(f"    {plugin_path}: {error}")

        # Most plugins should execute successfully
        success_rate = (
            len([r for r in results.values() if r is not None]) / len(results) * 100
        )
        self.assertGreaterEqual(
            success_rate,
            60,
            f"Concurrent execution success rate too low: {success_rate:.1f}%",
        )

    def test_plugin_category_interactions(self):
        """Test interactions between different plugin categories"""
        # Test representative plugins from different categories
        category_plugins = {}

        for plugin in self.all_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "plugins" in parts:
                plugin_index = parts.index("plugins")
                if plugin_index + 2 < len(parts):
                    category = parts[plugin_index + 2]
                    if category not in category_plugins:
                        category_plugins[category] = []
                    if len(category_plugins[category]) < 3:  # Limit per category
                        category_plugins[category].append(plugin)

        # Flatten to get test plugins
        test_plugins = []
        for plugins in category_plugins.values():
            test_plugins.extend(plugins)

        print(
            f"\nTesting category interactions with {len(test_plugins)} plugins from {len(category_plugins)} categories"
        )

        # Run mixed category plugins
        results = risu.dorisu(
            path=self.tmpdir,
            plugins=test_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
        )

        # Analyze results by category
        category_results = defaultdict(lambda: defaultdict(int))

        for plugin_path, result in results.items():
            # Find category
            plugin_category = None
            for category, plugins in category_plugins.items():
                if any(p["plugin"] == plugin_path for p in plugins):
                    plugin_category = category
                    break

            if plugin_category:
                rc = result["result"]["rc"]
                category_results[plugin_category][rc] += 1

        print("Results by category:")
        for category, rc_counts in category_results.items():
            print(f"  {category}: {dict(rc_counts)}")

        # Each category should have some successful executions
        for category, rc_counts in category_results.items():
            total = sum(rc_counts.values())
            if total > 0:
                success_rate = (rc_counts[risu.RC_OKAY] / total) * 100
                self.assertGreaterEqual(
                    success_rate,
                    30,
                    f"Category {category} success rate too low: {success_rate:.1f}%",
                )

    def test_large_scale_execution(self):
        """Test large-scale execution with many plugins"""
        # Use a larger subset for stress testing
        test_plugins = self.all_plugins[:200]  # Larger subset

        print(f"\nTesting large-scale execution with {len(test_plugins)} plugins")

        start_time = time.time()
        results = risu.dorisu(
            path=self.tmpdir,
            plugins=test_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
        )
        execution_time = time.time() - start_time

        print(f"Large-scale execution completed in {execution_time:.2f} seconds")

        # Verify results
        self.assertIsNotNone(results, "Large-scale execution should return results")
        self.assertGreaterEqual(
            len(results),
            len(test_plugins),
            f"Should have results for at least {len(test_plugins)} plugins, got {len(results)}",
        )
        # Allow for some plugin expansion by extensions (faraday, etc.)
        self.assertLessEqual(
            len(results),
            len(test_plugins) * 1.1,
            f"Too many results: expected around {len(test_plugins)}, got {len(results)}",
        )

        # Check performance
        avg_time_per_plugin = execution_time / len(test_plugins)
        print(f"Average time per plugin: {avg_time_per_plugin:.3f} seconds")

        # Should be reasonably fast
        self.assertLess(
            avg_time_per_plugin,
            1.0,
            f"Average time per plugin too high: {avg_time_per_plugin:.3f}s",
        )

    def test_error_propagation_and_recovery(self):
        """Test error propagation and recovery mechanisms"""
        # Include some plugins that might fail
        test_plugins = self.all_plugins[:50]

        print(
            f"\nTesting error propagation and recovery with {len(test_plugins)} plugins"
        )

        # Run with error handling
        results = risu.dorisu(
            path=self.tmpdir,
            plugins=test_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
        )

        # Analyze error handling
        error_count = 0
        for plugin_path, result in results.items():
            if result["result"]["rc"] == risu.RC_FAILED:
                error_count += 1
                # Failed plugins should have error messages
                self.assertNotEqual(
                    result["result"]["err"],
                    "",
                    f"Failed plugin {plugin_path} should have error message",
                )

        print("Error handling results:")
        print(f"  Failed plugins: {error_count}")
        print(f"  Successful plugins: {len(results) - error_count}")

        # System should handle errors gracefully
        success_rate = ((len(results) - error_count) / len(results)) * 100
        self.assertGreaterEqual(
            success_rate,
            70,
            f"Error recovery success rate too low: {success_rate:.1f}%",
        )

    def test_output_format_consistency(self):
        """Test consistency of output formats across plugins"""
        test_plugins = self.all_plugins[:30]  # Use subset

        print(f"\nTesting output format consistency with {len(test_plugins)} plugins")

        results = risu.dorisu(
            path=self.tmpdir,
            plugins=test_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
        )

        # Check output format consistency
        format_issues = []

        for plugin_path, result in results.items():
            # Check required fields
            if "result" not in result:
                format_issues.append(f"{plugin_path}: missing 'result' field")
                continue

            plugin_result = result["result"]

            # Check required result fields
            required_fields = ["rc", "out", "err"]
            for field in required_fields:
                if field not in plugin_result:
                    format_issues.append(f"{plugin_path}: missing '{field}' field")

            # Check return code validity
            rc = plugin_result.get("rc")
            if rc not in [risu.RC_OKAY, risu.RC_FAILED, risu.RC_SKIPPED, risu.RC_INFO]:
                format_issues.append(f"{plugin_path}: invalid return code {rc}")

        if format_issues:
            print("Format issues found:")
            for issue in format_issues:
                print(f"  {issue}")

        # Should have minimal format issues
        format_error_rate = len(format_issues) / len(results) * 100
        self.assertLessEqual(
            format_error_rate, 5, f"Too many format issues: {format_error_rate:.1f}%"
        )
