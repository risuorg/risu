#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extended test runner for Risu comprehensive testing
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
import unittest
import argparse
from io import StringIO

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import all test modules
test_modules = [
    "test_performance",
    "test_coverage",
    "test_openstack_plugins",
    "test_openshift_plugins",
    "test_security_plugins",
    "test_network_plugins",
    "test_integration",
    "test_plugin_validation",
]


def run_test_suite(test_module_name, verbose=False):
    """Run a specific test suite and return results"""
    try:
        # Import the module
        module = __import__(test_module_name)

        # Create test suite
        loader = unittest.TestLoader()
        suite = loader.loadTestsFromModule(module)

        # Run tests
        stream = StringIO()
        runner = unittest.TextTestRunner(stream=stream, verbosity=2 if verbose else 1)

        start_time = time.time()
        result = runner.run(suite)
        execution_time = time.time() - start_time

        return {
            "module": test_module_name,
            "tests_run": result.testsRun,
            "failures": len(result.failures),
            "errors": len(result.errors),
            "skipped": len(result.skipped) if hasattr(result, "skipped") else 0,
            "success": result.wasSuccessful(),
            "execution_time": execution_time,
            "output": stream.getvalue(),
        }

    except Exception as e:
        return {
            "module": test_module_name,
            "tests_run": 0,
            "failures": 0,
            "errors": 1,
            "skipped": 0,
            "success": False,
            "execution_time": 0,
            "output": f"Error importing or running {test_module_name}: {e}",
        }


def print_test_summary(results):
    """Print a summary of test results"""
    print("\n" + "=" * 70)
    print("EXTENDED TEST SUITE SUMMARY")
    print("=" * 70)

    total_tests = sum(r["tests_run"] for r in results)
    total_failures = sum(r["failures"] for r in results)
    total_errors = sum(r["errors"] for r in results)
    total_skipped = sum(r["skipped"] for r in results)
    total_time = sum(r["execution_time"] for r in results)

    print(f"Total test modules: {len(results)}")
    print(f"Total tests run: {total_tests}")
    print(f"Total failures: {total_failures}")
    print(f"Total errors: {total_errors}")
    print(f"Total skipped: {total_skipped}")
    print(f"Total execution time: {total_time:.2f} seconds")

    success_rate = (
        ((total_tests - total_failures - total_errors) / total_tests * 100)
        if total_tests > 0
        else 0
    )
    print(f"Overall success rate: {success_rate:.1f}%")

    print("\nPer-module results:")
    print("-" * 50)

    for result in results:
        status = "PASS" if result["success"] else "FAIL"
        print(
            f"{result['module']:<25} {status:>6} ({result['tests_run']} tests, {result['execution_time']:.2f}s)"
        )

        if result["failures"] > 0:
            print(f"  Failures: {result['failures']}")
        if result["errors"] > 0:
            print(f"  Errors: {result['errors']}")
        if result["skipped"] > 0:
            print(f"  Skipped: {result['skipped']}")

    print("\nTEST COVERAGE IMPROVEMENTS:")
    print("-" * 50)
    print("✓ Performance testing - Plugin execution times and memory usage")
    print("✓ Coverage analysis - Plugin categories and metadata coverage")
    print("✓ OpenStack plugins - Comprehensive testing of OpenStack-specific plugins")
    print("✓ OpenShift plugins - Comprehensive testing of OpenShift-specific plugins")
    print("✓ Security plugins - Testing of security vulnerability checks")
    print("✓ Network plugins - Testing of network-related functionality")
    print("✓ Integration testing - Multi-plugin execution and interaction testing")
    print("✓ Plugin validation - Metadata consistency and format validation")

    print("\nKEY FEATURES TESTED:")
    print("-" * 50)
    print("• Plugin execution performance and memory usage")
    print("• Plugin metadata completeness and consistency")
    print("• Priority system validation and distribution")
    print("• Category-specific plugin functionality")
    print("• Concurrent execution safety")
    print("• Error handling and recovery")
    print("• Output format consistency")
    print("• File structure and naming conventions")
    print("• Header format validation")
    print("• Cross-validation of plugin metadata")

    if total_failures > 0 or total_errors > 0:
        print(f"\n⚠️  {total_failures + total_errors} issues found that need attention")
    else:
        print("\n✅ All tests passed successfully!")


def main():
    parser = argparse.ArgumentParser(description="Run extended Risu test suite")
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Enable verbose output"
    )
    parser.add_argument(
        "--module", "-m", choices=test_modules, help="Run specific test module only"
    )
    parser.add_argument(
        "--list", "-l", action="store_true", help="List available test modules"
    )
    parser.add_argument(
        "--quick",
        "-q",
        action="store_true",
        help="Run quick tests only (skip performance and integration)",
    )

    args = parser.parse_args()

    if args.list:
        print("Available test modules:")
        for module in test_modules:
            print(f"  {module}")
        return

    # Determine which modules to run
    if args.module:
        modules_to_run = [args.module]
    elif args.quick:
        # Skip performance and integration tests for quick run
        modules_to_run = [
            m for m in test_modules if m not in ["test_performance", "test_integration"]
        ]
    else:
        modules_to_run = test_modules

    print("Starting extended Risu test suite...")
    print(f"Running {len(modules_to_run)} test modules")

    if args.verbose:
        print("Test modules to run:", modules_to_run)

    results = []

    for module_name in modules_to_run:
        print(f"\n{'=' * 50}")
        print(f"Running {module_name}")
        print("=" * 50)

        result = run_test_suite(module_name, args.verbose)
        results.append(result)

        if args.verbose:
            print(result["output"])
        else:
            status = "PASS" if result["success"] else "FAIL"
            print(
                f"{module_name}: {status} ({result['tests_run']} tests, {result['execution_time']:.2f}s)"
            )

    print_test_summary(results)

    # Return appropriate exit code
    if any(not r["success"] for r in results):
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
