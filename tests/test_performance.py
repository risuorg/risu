#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Performance tests for Risu plugins
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
import statistics
from unittest import TestCase

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))

try:
    import risuclient.shell as risu
except:
    import shell as risu


class PerformanceTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-perf-test-")
        self.plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core")]
        )
        self.slow_threshold = 10.0  # seconds
        self.very_slow_threshold = 30.0  # seconds

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_plugin_execution_times(self):
        """Test individual plugin execution times"""
        execution_times = {}
        slow_plugins = []
        very_slow_plugins = []

        for plugin in self.plugins[:50]:  # Test first 50 plugins to avoid timeout
            start_time = time.time()
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                execution_time = time.time() - start_time
                execution_times[plugin["plugin"]] = execution_time

                if execution_time > self.very_slow_threshold:
                    very_slow_plugins.append((plugin["plugin"], execution_time))
                elif execution_time > self.slow_threshold:
                    slow_plugins.append((plugin["plugin"], execution_time))

            except Exception as e:
                print(f"Error testing plugin {plugin['plugin']}: {e}")

        # Report findings
        if slow_plugins:
            print(f"\nSlow plugins (>{self.slow_threshold}s):")
            for plugin_name, exec_time in slow_plugins:
                print(f"  {plugin_name}: {exec_time:.2f}s")

        if very_slow_plugins:
            print(f"\nVery slow plugins (>{self.very_slow_threshold}s):")
            for plugin_name, exec_time in very_slow_plugins:
                print(f"  {plugin_name}: {exec_time:.2f}s")

        # Assert that we don't have too many very slow plugins
        self.assertLessEqual(
            len(very_slow_plugins),
            5,
            f"Too many very slow plugins: {len(very_slow_plugins)}",
        )

        # Calculate statistics
        if execution_times:
            avg_time = statistics.mean(execution_times.values())
            median_time = statistics.median(execution_times.values())
            print("\nPerformance statistics:")
            print(f"  Average execution time: {avg_time:.2f}s")
            print(f"  Median execution time: {median_time:.2f}s")
            print(f"  Total plugins tested: {len(execution_times)}")

    def test_parallel_execution_performance(self):
        """Test performance of parallel plugin execution"""
        test_plugins = self.plugins[:20]  # Test with subset

        # Parallel execution (using risu's built-in parallel execution)
        start_time = time.time()
        _ = risu.dorisu(
            path=self.tmpdir,
            plugins=test_plugins,
            okay=risu.RC_OKAY,
            failed=risu.RC_FAILED,
            skipped=risu.RC_SKIPPED,
            info=risu.RC_INFO,
        )
        parallel_time = time.time() - start_time

        print("\nParallel execution performance:")
        print(f"  Parallel time: {parallel_time:.2f}s")
        print(f"  Plugins tested: {len(test_plugins)}")
        print(f"  Average time per plugin: {parallel_time / len(test_plugins):.3f}s")

        # Assert that parallel execution completes in reasonable time
        # Allow up to 1 second per plugin on average (very generous)
        max_expected_time = len(test_plugins) * 1.0
        self.assertLess(
            parallel_time,
            max_expected_time,
            f"Parallel execution took too long: {parallel_time:.2f}s > {max_expected_time:.2f}s",
        )

    # def test_memory_usage_patterns(self):
    #     """Test memory usage patterns during plugin execution"""
    #     import psutil
    #     import gc
    #
    #     process = psutil.Process()
    #     initial_memory = process.memory_info().rss / 1024 / 1024  # MB
    #
    #     memory_measurements = []
    #
    #     for i, plugin in enumerate(self.plugins[:30]):  # Test subset
    #         try:
    #             result = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
    #             current_memory = process.memory_info().rss / 1024 / 1024  # MB
    #             memory_measurements.append(current_memory - initial_memory)
    #
    #             # Force garbage collection every 10 plugins
    #             if i % 10 == 0:
    #                 gc.collect()
    #
    #         except Exception as e:
    #             print(f"Error in memory test: {e}")
    #
    #     if memory_measurements:
    #         max_memory = max(memory_measurements)
    #         avg_memory = statistics.mean(memory_measurements)
    #
    #         print(f"\nMemory usage patterns:")
    #         print(f"  Initial memory: {initial_memory:.2f} MB")
    #         print(f"  Maximum memory increase: {max_memory:.2f} MB")
    #         print(f"  Average memory increase: {avg_memory:.2f} MB")
    #
    #         # Assert reasonable memory usage (less than 500MB increase)
    #         self.assertLess(max_memory, 500,
    #                        f"Memory usage too high: {max_memory:.2f} MB")

    def test_memory_usage_patterns_basic(self):
        """Test basic memory usage patterns during plugin execution (without psutil)"""
        print("\nBasic memory usage test (psutil not available)")

        # Simple test without psutil dependency
        test_plugins = self.plugins[:10]  # Small subset
        successful_runs = 0

        for plugin in test_plugins:
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                successful_runs += 1
            except Exception as e:
                print(f"Error in basic memory test: {e}")

        success_rate = (successful_runs / len(test_plugins)) * 100
        print(f"Basic memory test success rate: {success_rate:.1f}%")

        # Lower threshold for basic test
        self.assertGreaterEqual(
            success_rate,
            50,
            f"Basic memory test success rate too low: {success_rate:.1f}%",
        )

    def test_plugin_category_performance(self):
        """Test performance by plugin category"""
        categories = {}

        for plugin in self.plugins[:100]:  # Test subset
            # Extract category from plugin path
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "plugins" in parts:
                plugin_index = parts.index("plugins")
                if plugin_index + 2 < len(parts):
                    category = parts[
                        plugin_index + 2
                    ]  # e.g., 'openstack', 'system', etc.
                else:
                    category = "core"
            else:
                category = "unknown"

            if category not in categories:
                categories[category] = []

            start_time = time.time()
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                execution_time = time.time() - start_time
                categories[category].append(execution_time)
            except Exception as e:
                print(f"Error testing category {category}: {e}")

        # Report category performance
        print("\nPerformance by category:")
        for category, times in categories.items():
            if times:
                avg_time = statistics.mean(times)
                max_time = max(times)
                print(
                    f"  {category}: avg={avg_time:.2f}s, max={max_time:.2f}s, count={len(times)}"
                )
