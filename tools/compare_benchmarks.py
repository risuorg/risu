#!/usr/bin/env python
"""
Compare benchmark results and detect performance regressions.

Compares current benchmark against baseline and reports
if performance has regressed beyond threshold.
"""

import argparse
import json
import sys
from pathlib import Path


def load_benchmark(filepath):
    """Load benchmark JSON file."""
    with open(filepath, "r") as f:
        return json.load(f)


def compare_benchmarks(baseline_path, current_path, threshold=20):
    """
    Compare benchmarks and detect regressions.

    Args:
        baseline_path: Path to baseline benchmark JSON
        current_path: Path to current benchmark JSON
        threshold: Regression threshold percentage (default: 20)

    Returns:
        tuple: (passed, message)
    """
    baseline = load_benchmark(baseline_path)
    current = load_benchmark(current_path)

    baseline_avg = baseline["statistics"]["avg_time"]
    current_avg = current["statistics"]["avg_time"]

    diff_seconds = current_avg - baseline_avg
    diff_percent = (diff_seconds / baseline_avg) * 100

    print("\n=== Benchmark Comparison ===")
    print(f"Baseline: {baseline_avg:.3f}s")
    print(f"Current:  {current_avg:.3f}s")
    print(f"Difference: {diff_seconds:+.3f}s ({diff_percent:+.1f}%)")
    print(f"Threshold: {threshold}%")

    if diff_percent > threshold:
        message = (
            f"❌ REGRESSION: Performance degraded by {diff_percent:.1f}% "
            f"(threshold: {threshold}%)"
        )
        print(f"\n{message}")
        return False, message
    elif diff_percent < -5:  # Improvement
        message = f"✅ IMPROVEMENT: Performance improved by {-diff_percent:.1f}%"
        print(f"\n{message}")
        return True, message
    else:
        message = "✅ PASS: Performance within acceptable range"
        print(f"\n{message}")
        return True, message


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Compare benchmark results and detect regressions"
    )
    parser.add_argument(
        "baseline",
        type=Path,
        help="Baseline benchmark JSON file",
    )
    parser.add_argument(
        "current",
        type=Path,
        help="Current benchmark JSON file",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=20.0,
        help="Regression threshold percentage (default: 20)",
    )

    args = parser.parse_args()

    if not args.baseline.exists():
        print(f"Error: Baseline file not found: {args.baseline}", file=sys.stderr)
        return 1

    if not args.current.exists():
        print(f"Error: Current file not found: {args.current}", file=sys.stderr)
        return 1

    try:
        passed, message = compare_benchmarks(
            args.baseline,
            args.current,
            args.threshold,
        )
        return 0 if passed else 1
    except Exception as e:
        print(f"Error comparing benchmarks: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
