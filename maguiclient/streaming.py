#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Streaming JSON output for Magui
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import json
import logging

LOG = logging.getLogger("magui")


class StreamingJSONWriter(object):
    """
    Stream JSON results to file as they complete.

    Reduces memory usage for large analysis runs by writing
    results incrementally instead of building entire result
    dict in memory.
    """

    def __init__(self, output_file):
        """
        Initialize streaming writer.

        :param output_file: Path to output JSON file
        """
        self.output_file = output_file
        self.file_handle = None
        self.first_item = True

    def __enter__(self):
        """Context manager entry - open file and write JSON array start"""
        self.file_handle = open(self.output_file, "w")
        self.file_handle.write("[\n")
        self.first_item = True
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - write JSON array end and close file"""
        if self.file_handle:
            self.file_handle.write("\n]\n")
            self.file_handle.close()
            self.file_handle = None
        return False

    def write_result(self, result):
        """
        Write a single result to the JSON stream.

        :param result: Result dictionary to write
        """
        if not self.file_handle:
            raise IOError("StreamingJSONWriter not opened (use context manager)")

        # Add comma separator for all but first item
        if not self.first_item:
            self.file_handle.write(",\n")
        else:
            self.first_item = False

        # Write the result with indentation
        json.dump(result, self.file_handle, indent=2)

        # Flush to ensure data is written
        self.file_handle.flush()

    def write_results(self, results_generator):
        """
        Write multiple results from a generator.

        :param results_generator: Generator or iterable of results
        """
        for result in results_generator:
            self.write_result(result)


def stream_magui_results(sosreports, magui_client, output_file, risuplugins=None):
    """
    Execute magui and stream results to JSON file.

    :param sosreports: List of sosreport paths
    :param magui_client: MaguiClient instance
    :param output_file: Path to output JSON file
    :param risuplugins: List of risu plugins to run (optional)
    :return: Number of results written
    """
    count = 0

    with StreamingJSONWriter(output_file) as writer:
        # Process each sosreport and stream results
        for sosreport in sosreports:
            LOG.debug("Processing sosreport: %s", sosreport)

            # Call risu for this sosreport
            try:
                result = magui_client.call_risu(
                    path=sosreport, plugins=risuplugins or []
                )

                # Add sosreport identifier to result
                result_with_host = {"sosreport": sosreport, "results": result}

                # Stream to file
                writer.write_result(result_with_host)
                count += 1

            except (IOError, OSError, KeyError, TypeError) as e:
                LOG.error("Failed to process %s: %s", sosreport, str(e))
                continue

    LOG.info("Streamed %d sosreport results to %s", count, output_file)
    return count


class StreamingResultCollector(object):
    """
    Collect results with streaming to reduce memory usage.

    Can be used as a drop-in replacement for dict-based result
    collection when dealing with 50+ sosreports.
    """

    def __init__(self, output_file=None):
        """
        Initialize collector.

        :param output_file: Optional file to stream results to
        """
        self.output_file = output_file
        self.results = {}
        self.writer = None

    def add_result(self, key, value):
        """
        Add a result.

        :param key: Result key (e.g., sosreport path)
        :param value: Result value
        """
        self.results[key] = value

        # Stream to file if configured
        if self.output_file and self.writer:
            self.writer.write_result({key: value})

    def get_results(self):
        """Get all collected results"""
        return self.results

    def __enter__(self):
        """Context manager entry"""
        if self.output_file:
            self.writer = StreamingJSONWriter(self.output_file)
            self.writer.__enter__()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        if self.writer:
            self.writer.__exit__(exc_type, exc_val, exc_tb)
            self.writer = None
        return False
