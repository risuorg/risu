#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Unit tests for risuclient/cache.py
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from risuclient import cache


class TestMetadataCache(unittest.TestCase):
    """Test cases for MetadataCache class"""

    def setUp(self):
        """Set up test cache with temporary file"""
        self.temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".pkl")
        # Write empty cache to avoid EOF error
        try:
            import cPickle as pickle
        except ImportError:
            import pickle
        pickle.dump({}, self.temp_file)
        self.temp_file.close()
        self.cache = cache.MetadataCache(cache_file=self.temp_file.name)

    def tearDown(self):
        """Clean up temporary file"""
        try:
            os.unlink(self.temp_file.name)
        except OSError:
            pass

    def test_cache_initialization(self):
        """Test cache initializes with empty dict"""
        self.assertIsInstance(self.cache._cache, dict)
        self.assertEqual(len(self.cache._cache), 0)

    def test_cache_set_and_get(self):
        """Test setting and getting cached metadata"""
        plugin_path = "/fake/plugin.sh"
        metadata = {"priority": 800, "long_name": "Test Plugin"}

        # Create a real temp file for mtime
        with tempfile.NamedTemporaryFile(delete=False) as f:
            plugin_path = f.name

        try:
            self.cache.set(plugin_path, metadata)
            retrieved = self.cache.get(plugin_path)
            self.assertEqual(retrieved, metadata)
        finally:
            os.unlink(plugin_path)

    def test_cache_get_nonexistent(self):
        """Test getting non-existent entry returns None"""
        result = self.cache.get("/nonexistent/plugin.sh")
        self.assertIsNone(result)

    def test_cache_invalidation_on_mtime_change(self):
        """Test cache invalidates when file mtime changes"""
        # Create temp file
        with tempfile.NamedTemporaryFile(delete=False) as f:
            plugin_path = f.name
            f.write(b"original content")

        try:
            metadata1 = {"priority": 800}
            self.cache.set(plugin_path, metadata1)

            # Verify it's cached
            self.assertEqual(self.cache.get(plugin_path), metadata1)

            # Modify file (changes mtime)
            import time

            time.sleep(0.01)  # Ensure mtime changes
            with open(plugin_path, "w") as f:
                f.write("modified content")

            # Should return None because mtime changed
            self.assertIsNone(self.cache.get(plugin_path))
        finally:
            os.unlink(plugin_path)

    def test_cache_persistence(self):
        """Test cache saves and loads from disk"""
        plugin_path = "/fake/plugin.sh"
        metadata = {"priority": 900, "long_name": "Persistent Test"}

        # Create temp file for plugin
        with tempfile.NamedTemporaryFile(delete=False) as f:
            plugin_path = f.name

        try:
            # Set and save
            self.cache.set(plugin_path, metadata)
            self.cache.save()

            # Create new cache instance with same file
            new_cache = cache.MetadataCache(cache_file=self.temp_file.name)

            # Should have loaded the data
            self.assertIn(plugin_path, new_cache._cache)
            self.assertEqual(new_cache.get(plugin_path), metadata)
        finally:
            os.unlink(plugin_path)

    def test_cache_cleanup(self):
        """Test cleanup removes stale entries"""
        # Create multiple temp files
        files = []
        for i in range(3):
            f = tempfile.NamedTemporaryFile(delete=False)
            files.append(f.name)
            f.close()
            self.cache.set(f.name, {"priority": i * 100})

        try:
            # Delete one file
            os.unlink(files[1])

            # Cleanup should remove entry for deleted file
            self.cache.cleanup()

            # Only existing files should remain
            self.assertIsNotNone(self.cache.get(files[0]))
            self.assertIsNone(self.cache.get(files[1]))  # Deleted file
            self.assertIsNotNone(self.cache.get(files[2]))
        finally:
            for f in files:
                try:
                    os.unlink(f)
                except OSError:
                    pass

    def test_cache_stats(self):
        """Test cache statistics reporting"""
        # Add some entries
        for i in range(5):
            with tempfile.NamedTemporaryFile(delete=False) as f:
                self.cache.set(f.name, {"priority": i * 100})
                os.unlink(f.name)  # Delete immediately

        stats = self.cache.stats()
        self.assertIn("total_entries", stats)
        self.assertIn("cache_file", stats)
        self.assertEqual(stats["total_entries"], 5)

    def test_cache_default_location(self):
        """Test default cache file location"""
        default_cache = cache.MetadataCache()
        expected_path = os.path.expanduser("~/.risu/metadata_cache.pkl")
        self.assertEqual(default_cache.cache_file, expected_path)

    def test_cache_handles_corrupted_file(self):
        """Test cache handles corrupted cache file gracefully"""
        # Write garbage to cache file
        with open(self.temp_file.name, "wb") as f:
            f.write(b"corrupted data not pickle")

        # Should not crash, should start fresh
        new_cache = cache.MetadataCache(cache_file=self.temp_file.name)
        self.assertEqual(len(new_cache._cache), 0)

    def test_cache_handles_permission_error(self):
        """Test cache handles permission errors gracefully"""
        # This test may not work on all platforms
        if os.name == "posix":
            # Make cache file read-only
            os.chmod(self.temp_file.name, 0o444)

            try:
                with tempfile.NamedTemporaryFile(delete=False) as f:
                    plugin_path = f.name

                self.cache.set(plugin_path, {"priority": 800})
                # Save should not crash even if file is read-only
                try:
                    self.cache.save()
                except (IOError, OSError):
                    pass  # Expected

                os.unlink(plugin_path)
            finally:
                # Restore permissions for cleanup
                os.chmod(self.temp_file.name, 0o644)


if __name__ == "__main__":
    unittest.main()
