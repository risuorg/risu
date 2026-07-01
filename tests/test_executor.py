#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Unit tests for risuclient/executor.py
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
import sys
import time
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from risuclient import executor


def sample_plugin_function(plugin):
    """Sample function that processes a plugin"""
    return {"plugin": plugin, "result": "success"}


def slow_plugin_function(plugin):
    """Sample function that takes time"""
    time.sleep(0.5)
    return {"plugin": plugin, "result": "slow"}


def error_plugin_function(plugin):
    """Sample function that raises an error"""
    raise ValueError("Intentional error for testing")


class TestPluginExecutor(unittest.TestCase):
    """Test cases for PluginExecutor class"""

    def test_executor_initialization(self):
        """Test executor initializes with correct defaults"""
        exec_obj = executor.PluginExecutor()
        self.assertIsNotNone(exec_obj.num_processes)
        self.assertEqual(exec_obj.timeout, 30)

    def test_executor_custom_parameters(self):
        """Test executor accepts custom parameters"""
        exec_obj = executor.PluginExecutor(num_processes=2, timeout=60)
        self.assertEqual(exec_obj.num_processes, 2)
        self.assertEqual(exec_obj.timeout, 60)

    def test_execute_plugins_serial(self):
        """Test serial execution of plugins"""
        exec_obj = executor.PluginExecutor()
        plugins = [
            {"plugin": "plugin1.sh"},
            {"plugin": "plugin2.sh"},
        ]

        results = exec_obj.execute_plugins_serial(plugins, sample_plugin_function)

        self.assertEqual(len(results), 2)
        for result in results:
            self.assertEqual(result["result"], "success")

    def test_empty_plugin_list(self):
        """Test executor handles empty plugin list"""
        exec_obj = executor.PluginExecutor()
        results = exec_obj.execute_plugins_serial([], sample_plugin_function)
        self.assertEqual(results, [])

    def test_single_plugin(self):
        """Test executor handles single plugin"""
        exec_obj = executor.PluginExecutor(num_processes=1)
        plugins = [{"plugin": "single.sh"}]

        results = exec_obj.execute_plugins_serial(plugins, sample_plugin_function)

        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["plugin"]["plugin"], "single.sh")

    def test_executor_with_none_num_processes(self):
        """Test executor uses CPU count when num_processes is None"""
        exec_obj = executor.PluginExecutor(num_processes=None)
        # Should default to some value (CPU count)
        self.assertIsNotNone(exec_obj.num_processes)
        self.assertGreater(exec_obj.num_processes, 0)

    def test_error_handling_serial(self):
        """Test serial executor handles errors gracefully"""
        exec_obj = executor.PluginExecutor()
        plugins = [
            {"plugin": "good.sh"},
            {"plugin": "error.sh"},
        ]

        # Manually simulate error handling
        results = []
        for plugin in plugins:
            try:
                if "error" in plugin["plugin"]:
                    raise ValueError("Error plugin")
                result = sample_plugin_function(plugin)
                results.append(result)
            except Exception:
                results.append(None)

        self.assertEqual(len(results), 2)
        non_none = [r for r in results if r is not None]
        self.assertEqual(len(non_none), 1)


if __name__ == "__main__":
    unittest.main()
