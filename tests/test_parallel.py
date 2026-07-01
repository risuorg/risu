#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""Tests for parallel execution module"""

from __future__ import print_function

import os
import sys
import unittest

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

try:
    from maguiclient import parallel
except ImportError:
    parallel = None


@unittest.skipIf(parallel is None, "parallel module not available")
class TestParallelRisuExecutor(unittest.TestCase):
    """Tests for ParallelRisuExecutor class"""

    def setUp(self):
        """Set up test fixtures"""
        self.executor = parallel.ParallelRisuExecutor(num_processes=2)

    def test_initialization(self):
        """Test executor initialization"""
        self.assertIsNotNone(self.executor)
        self.assertEqual(self.executor.num_processes, 2)

    def test_initialization_default_cpus(self):
        """Test executor with default CPU count"""
        executor = parallel.ParallelRisuExecutor()
        self.assertIsNotNone(executor)
        self.assertGreater(executor.num_processes, 0)

    def test_sequential_fallback(self):
        """Test sequential execution fallback"""

        # Test with simple callable
        def simple_func(item):
            return item * 2

        items = [1, 2, 3]
        result = self.executor._execute_sequential(items, simple_func)

        self.assertEqual(len(result), 3)
        self.assertEqual(result[1], 2)
        self.assertEqual(result[2], 4)
        self.assertEqual(result[3], 6)

    def test_parallel_execution_with_simple_function(self):
        """Test parallel execution with simple function"""

        def simple_func(item):
            return item * 2

        items = [1, 2, 3, 4]

        # This may fall back to sequential if PluginExecutor not available
        result = self.executor.execute_parallel(items, simple_func)

        self.assertEqual(len(result), 4)
        self.assertEqual(result[1], 2)
        self.assertEqual(result[2], 4)
        self.assertEqual(result[3], 6)
        self.assertEqual(result[4], 8)


@unittest.skipIf(parallel is None, "parallel module not available")
class TestEnableParallelExecution(unittest.TestCase):
    """Tests for enable_parallel_execution function"""

    def test_enable_parallel_execution(self):
        """Test enabling parallel execution on a mock MaguiClient"""

        # Create a minimal mock MaguiClient
        class MockMaguiClient(object):
            def __init__(self):
                self.forcerun = False

            def call_risu(self, path, plugins=None):
                return {"test": "result"}

            def collect_risu_results(self, sosreports, risuplugins):
                result = {}
                for sosreport in sosreports:
                    result[sosreport] = self.call_risu(sosreport, risuplugins)
                return result

            def _sanity_check_results(self, sosreports, result, risuplugins):
                return result

        client = MockMaguiClient()

        # Enable parallel execution
        enhanced_client = parallel.enable_parallel_execution(client, num_processes=2)

        # Should be same instance
        self.assertEqual(id(enhanced_client), id(client))

        # collect_risu_results should be replaced
        self.assertNotEqual(
            enhanced_client.collect_risu_results.__name__, "collect_risu_results"
        )


if __name__ == "__main__":
    unittest.main()
