#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Plugin metadata caching for Risu
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Plugin metadata caching.

This module provides caching for plugin metadata to avoid repeated
file I/O and parsing. The cache uses file modification time to
detect when plugins have changed.

Cache is stored using pickle for Python 2.7 compatibility.
"""

from __future__ import print_function

import logging
import os

# Use pickle (works in Python 2.7 and 3.x)
try:
    import cPickle as pickle
except ImportError:
    import pickle

try:
    from risuclient import exceptions
except ImportError:
    import exceptions


LOG = logging.getLogger("risu.cache")


class MetadataCache(object):
    """
    Cache for plugin metadata.

    Stores plugin metadata with file modification time to detect changes.
    Uses pickle for serialization (Python 2.7 compatible).

    The cache is stored as a dictionary:
        {
            plugin_path: (mtime, metadata_dict),
            ...
        }

    Attributes:
        cache_file (str): Path to cache file
        _cache (dict): In-memory cache dictionary
        _dirty (bool): True if cache has unsaved changes
    """

    def __init__(self, cache_file=None):
        """
        Initialize metadata cache.

        Args:
            cache_file (str, optional): Path to cache file. If None,
                                       uses ~/.risu/metadata_cache.pkl
        """
        if cache_file is None:
            home = os.path.expanduser("~")
            cache_dir = os.path.join(home, ".risu")
            if not os.path.exists(cache_dir):
                try:
                    os.makedirs(cache_dir)
                except (IOError, OSError) as e:
                    LOG.warning(
                        "Cannot create cache directory %s: %s", cache_dir, str(e)
                    )
            cache_file = os.path.join(cache_dir, "metadata_cache.pkl")

        self.cache_file = cache_file
        self._cache = {}
        self._dirty = False

        # Try to load existing cache
        self._load()

    def _load(self):
        """
        Load cache from disk.

        Silently fails if cache file doesn't exist or is corrupted.
        """
        if not os.path.exists(self.cache_file):
            LOG.debug("Cache file does not exist: %s", self.cache_file)
            return

        try:
            with open(self.cache_file, "rb") as f:
                self._cache = pickle.load(f)
            LOG.debug("Loaded cache with %d entries", len(self._cache))
        except (IOError, OSError, pickle.PickleError) as e:
            LOG.warning("Cannot load cache from %s: %s", self.cache_file, str(e))
            self._cache = {}

    def save(self):
        """
        Save cache to disk.

        Only saves if cache has been modified (_dirty flag).

        Returns:
            bool: True if saved successfully, False otherwise
        """
        if not self._dirty:
            LOG.debug("Cache not dirty, skipping save")
            return True

        try:
            # Ensure directory exists
            cache_dir = os.path.dirname(self.cache_file)
            if cache_dir and not os.path.exists(cache_dir):
                os.makedirs(cache_dir)

            # Write cache atomically (write to temp file, then rename)
            temp_file = self.cache_file + ".tmp"
            with open(temp_file, "wb") as f:
                pickle.dump(self._cache, f, protocol=2)  # Protocol 2 for Python 2.7

            # Atomic rename
            os.rename(temp_file, self.cache_file)

            self._dirty = False
            LOG.debug("Saved cache with %d entries", len(self._cache))
            return True

        except (IOError, OSError, pickle.PickleError) as e:
            LOG.warning("Cannot save cache to %s: %s", self.cache_file, str(e))
            return False

    def get(self, plugin_path):
        """
        Get cached metadata for plugin.

        Checks if the cached entry is still valid (file hasn't changed).

        Args:
            plugin_path (str): Path to plugin file

        Returns:
            dict or None: Cached metadata dict, or None if not cached or stale
        """
        if plugin_path not in self._cache:
            return None

        # Check if file still exists
        if not os.path.isfile(plugin_path):
            # File deleted, remove from cache
            del self._cache[plugin_path]
            self._dirty = True
            return None

        # Get cached entry
        cached_mtime, metadata = self._cache[plugin_path]

        # Check if file has been modified
        try:
            current_mtime = os.path.getmtime(plugin_path)
        except (IOError, OSError):
            return None

        if current_mtime != cached_mtime:
            # File modified, cache is stale
            del self._cache[plugin_path]
            self._dirty = True
            return None

        LOG.debug("Cache hit for %s", plugin_path)
        return metadata

    def set(self, plugin_path, metadata):
        """
        Cache metadata for plugin.

        Args:
            plugin_path (str): Path to plugin file
            metadata (dict): Metadata dictionary to cache

        Returns:
            bool: True if cached successfully
        """
        try:
            mtime = os.path.getmtime(plugin_path)
        except (IOError, OSError) as e:
            LOG.warning("Cannot get mtime for %s: %s", plugin_path, str(e))
            return False

        self._cache[plugin_path] = (mtime, metadata)
        self._dirty = True
        LOG.debug("Cached metadata for %s", plugin_path)
        return True

    def clear(self):
        """
        Clear all cached entries.
        """
        self._cache = {}
        self._dirty = True
        LOG.debug("Cleared cache")

    def remove(self, plugin_path):
        """
        Remove plugin from cache.

        Args:
            plugin_path (str): Path to plugin file

        Returns:
            bool: True if removed, False if not in cache
        """
        if plugin_path in self._cache:
            del self._cache[plugin_path]
            self._dirty = True
            LOG.debug("Removed %s from cache", plugin_path)
            return True
        return False

    def cleanup(self):
        """
        Remove stale entries (files that no longer exist).

        Returns:
            int: Number of entries removed
        """
        removed = 0
        stale_paths = []

        for plugin_path in list(self._cache.keys()):
            if not os.path.isfile(plugin_path):
                stale_paths.append(plugin_path)

        for path in stale_paths:
            del self._cache[path]
            removed += 1

        if removed > 0:
            self._dirty = True
            LOG.debug("Cleaned up %d stale cache entries", removed)

        return removed

    def stats(self):
        """
        Get cache statistics.

        Returns:
            dict: Cache statistics
        """
        return {
            "total_entries": len(self._cache),
            "cache_file": self.cache_file,
            "dirty": self._dirty,
        }

    def __len__(self):
        """Return number of cached entries."""
        return len(self._cache)

    def __contains__(self, plugin_path):
        """Check if plugin is in cache (doesn't validate freshness)."""
        return plugin_path in self._cache

    def __del__(self):
        """Save cache on object destruction."""
        if self._dirty:
            self.save()
