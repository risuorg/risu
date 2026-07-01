#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""Tests for streaming output module"""

from __future__ import print_function

import json
import os
import sys
import tempfile
import unittest

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

try:
    from maguiclient import streaming
except ImportError:
    streaming = None


@unittest.skipIf(streaming is None, "streaming module not available")
class TestStreamingJSONWriter(unittest.TestCase):
    """Tests for StreamingJSONWriter class"""

    def setUp(self):
        """Set up test fixtures"""
        self.temp_file = tempfile.NamedTemporaryFile(
            mode="w", delete=False, suffix=".json"
        )
        self.temp_file.close()
        self.output_file = self.temp_file.name

    def tearDown(self):
        """Clean up test files"""
        try:
            os.unlink(self.output_file)
        except (OSError, IOError):
            pass

    def test_write_single_result(self):
        """Test writing a single result"""
        with streaming.StreamingJSONWriter(self.output_file) as writer:
            writer.write_result({"test": "data"})

        # Read and verify
        with open(self.output_file, "r") as f:
            content = f.read()

        data = json.loads(content)
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["test"], "data")

    def test_write_multiple_results(self):
        """Test writing multiple results"""
        with streaming.StreamingJSONWriter(self.output_file) as writer:
            writer.write_result({"id": 1, "value": "first"})
            writer.write_result({"id": 2, "value": "second"})
            writer.write_result({"id": 3, "value": "third"})

        # Read and verify
        with open(self.output_file, "r") as f:
            content = f.read()

        data = json.loads(content)
        self.assertEqual(len(data), 3)
        self.assertEqual(data[0]["id"], 1)
        self.assertEqual(data[1]["id"], 2)
        self.assertEqual(data[2]["id"], 3)

    def test_write_results_from_generator(self):
        """Test writing from a generator"""

        def result_generator():
            for i in range(5):
                yield {"index": i, "squared": i * i}

        with streaming.StreamingJSONWriter(self.output_file) as writer:
            writer.write_results(result_generator())

        # Read and verify
        with open(self.output_file, "r") as f:
            content = f.read()

        data = json.loads(content)
        self.assertEqual(len(data), 5)
        self.assertEqual(data[0]["squared"], 0)
        self.assertEqual(data[4]["squared"], 16)

    def test_context_manager_creates_valid_json(self):
        """Test context manager creates valid JSON structure"""
        with streaming.StreamingJSONWriter(self.output_file) as writer:
            writer.write_result({"test": 1})

        # Should be valid JSON
        with open(self.output_file, "r") as f:
            data = json.load(f)

        self.assertIsInstance(data, list)

    def test_write_without_context_manager_fails(self):
        """Test writing without context manager raises error"""
        writer = streaming.StreamingJSONWriter(self.output_file)

        with self.assertRaises(IOError):
            writer.write_result({"test": "data"})


@unittest.skipIf(streaming is None, "streaming module not available")
class TestStreamingResultCollector(unittest.TestCase):
    """Tests for StreamingResultCollector class"""

    def setUp(self):
        """Set up test fixtures"""
        self.temp_file = tempfile.NamedTemporaryFile(
            mode="w", delete=False, suffix=".json"
        )
        self.temp_file.close()
        self.output_file = self.temp_file.name

    def tearDown(self):
        """Clean up test files"""
        try:
            os.unlink(self.output_file)
        except (OSError, IOError):
            pass

    def test_collector_without_streaming(self):
        """Test collector without file streaming"""
        collector = streaming.StreamingResultCollector()

        collector.add_result("host1", {"result": "data1"})
        collector.add_result("host2", {"result": "data2"})

        results = collector.get_results()
        self.assertEqual(len(results), 2)
        self.assertEqual(results["host1"]["result"], "data1")

    def test_collector_with_streaming(self):
        """Test collector with file streaming"""
        with streaming.StreamingResultCollector(self.output_file) as collector:
            collector.add_result("host1", {"result": "data1"})
            collector.add_result("host2", {"result": "data2"})

        # Verify file was created and contains data
        self.assertTrue(os.path.exists(self.output_file))

        with open(self.output_file, "r") as f:
            data = json.load(f)

        self.assertIsInstance(data, list)
        self.assertGreater(len(data), 0)


if __name__ == "__main__":
    unittest.main()
