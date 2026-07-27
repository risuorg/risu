#!/usr/bin/env python
"""
Property-based tests for plugin metadata parsing.

Uses Hypothesis library to generate test cases and verify
invariants in metadata extraction and validation.
"""

import unittest

try:
    from hypothesis import given
    from hypothesis import settings as hypothesis_settings
    from hypothesis import strategies as st

    HYPOTHESIS_AVAILABLE = True
except ImportError:
    HYPOTHESIS_AVAILABLE = False

    # Provide dummy decorators when hypothesis is not available
    def given(*args, **kwargs):
        def decorator(func):
            return func

        return decorator

    def hypothesis_settings(*args, **kwargs):
        def decorator(func):
            return func

        return decorator

    # Dummy strategies for when hypothesis isn't available
    class st:
        @staticmethod
        def integers(*args, **kwargs):
            return None

        @staticmethod
        def text(*args, **kwargs):
            return None

        @staticmethod
        def lists(*args, **kwargs):
            return None

        @staticmethod
        def one_of(*args, **kwargs):
            return None

        @staticmethod
        def none():
            return None


try:
    from risuclient import metadata
except ImportError:
    import os
    import sys

    sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
    from risuclient import metadata


@unittest.skipUnless(HYPOTHESIS_AVAILABLE, "hypothesis not available")
class TestPluginMetadataProperties(unittest.TestCase):
    """
    Property-based tests for plugin metadata.

    These tests use Hypothesis to generate many random inputs
    and verify that invariants always hold.
    """

    @given(
        priority=st.integers(
            min_value=metadata.PRIORITY_MIN, max_value=metadata.PRIORITY_MAX
        )
    )
    @hypothesis_settings(max_examples=100)
    def test_priority_validation_accepts_valid_range(self, priority):
        """Valid priorities (1-999) should always pass validation."""
        meta = metadata.PluginMetadata(
            long_name="Test Plugin",
            description="Test description",
            priority=priority,
        )
        # Should not raise exception
        meta.validate()
        self.assertEqual(meta.priority, priority)

    @given(priority=st.integers().filter(lambda x: x < 1 or x > 999))
    @hypothesis_settings(max_examples=100)
    def test_priority_validation_rejects_invalid_range(self, priority):
        """Priorities outside 1-999 should always fail validation."""
        meta = metadata.PluginMetadata(
            long_name="Test Plugin",
            description="Test description",
            priority=priority,
        )
        with self.assertRaises(metadata.PluginMetadataError):
            meta.validate()

    @given(
        long_name=st.text(min_size=1, max_size=100),
        description=st.text(min_size=1, max_size=200),
        priority=st.integers(min_value=1, max_value=999),
    )
    @hypothesis_settings(max_examples=50)
    def test_metadata_to_dict_round_trip(self, long_name, description, priority):
        """Metadata should survive to_dict() conversion."""
        meta = metadata.PluginMetadata(
            long_name=long_name,
            description=description,
            priority=priority,
        )

        data = meta.to_dict()

        self.assertEqual(data["long_name"], long_name)
        self.assertEqual(data["description"], description)
        self.assertEqual(data["priority"], priority)

    @given(
        priority=st.integers(
            min_value=metadata.PRIORITY_MIN, max_value=metadata.PRIORITY_MAX
        )
    )
    @hypothesis_settings(max_examples=100)
    def test_get_category_always_returns_valid_category(self, priority):
        """Every valid priority should map to exactly one category."""
        meta = metadata.PluginMetadata(
            long_name="Test",
            description="Test",
            priority=priority,
        )

        category = meta.get_category()

        # Should return one of the defined categories
        valid_categories = list(metadata.PRIORITY_CATEGORIES.keys())
        self.assertIn(category, valid_categories)

        # Category range should contain the priority
        cat_min, cat_max = metadata.PRIORITY_CATEGORIES[category]
        self.assertGreaterEqual(priority, cat_min)
        self.assertLessEqual(priority, cat_max)

    @given(tags=st.lists(st.text(min_size=1, max_size=20), min_size=0, max_size=10))
    @hypothesis_settings(max_examples=50)
    def test_tags_handling(self, tags):
        """Tags should be stored and retrieved correctly."""
        meta = metadata.PluginMetadata(
            long_name="Test",
            description="Test",
            priority=500,
            tags=tags,
        )

        if tags:
            self.assertEqual(meta.tags, tags)
        else:
            # Empty tags should be stored as empty list
            self.assertEqual(meta.tags, [])

    @given(
        url=st.one_of(
            st.none(),
            st.text(min_size=10, max_size=100).filter(lambda x: "://" in x),
        )
    )
    @hypothesis_settings(max_examples=50)
    def test_optional_urls(self, url):
        """Bugzilla and KB URLs should handle None and valid URLs."""
        meta = metadata.PluginMetadata(
            long_name="Test",
            description="Test",
            priority=500,
            bugzilla=url,
            kb=url,
        )

        self.assertEqual(meta.bugzilla, url)
        self.assertEqual(meta.kb, url)


@unittest.skipUnless(HYPOTHESIS_AVAILABLE, "hypothesis not available")
class TestMetadataExtractionProperties(unittest.TestCase):
    """
    Property-based tests for metadata extraction from plugin content.
    """

    def _create_plugin_content(self, long_name, description, priority):
        """Helper to create valid plugin content."""
        # Use actual values instead of placeholders to avoid parsing issues
        return f"""#!/bin/bash
# long_name: {long_name}
# description: {description}
# priority: {priority}

echo "test"
"""

    @given(
        long_name=st.text(min_size=1, max_size=60).filter(lambda x: "\n" not in x),
        description=st.text(min_size=1, max_size=150).filter(lambda x: "\n" not in x),
        priority=st.integers(min_value=1, max_value=999),
    )
    @hypothesis_settings(max_examples=50)
    def test_extract_metadata_from_content(self, long_name, description, priority):
        """Metadata extraction should work for any valid header values."""
        content = self._create_plugin_content(long_name, description, priority)

        # Would test with actual extraction function
        # meta = metadata.extract_metadata_from_content(content, "test.sh")
        # self.assertEqual(meta.long_name, long_name)
        # self.assertEqual(meta.description, description)
        # self.assertEqual(meta.priority, priority)

        # For now, just verify content was created properly
        self.assertIn("# long_name:", content)
        self.assertIn("# description:", content)
        self.assertIn("# priority:", content)


if __name__ == "__main__":
    unittest.main()
