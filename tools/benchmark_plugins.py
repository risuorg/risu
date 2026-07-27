#!/usr/bin/env python
"""
Benchmark plugin execution performance.

Runs Risu with a test sosreport or live mode multiple times
and records execution timings for analysis.
"""

import argparse
import json
import platform
import sys
import time
from datetime import datetime
from pathlib import Path


def run_benchmark(mode="live", iterations=3, output_file=None):
    """
    Run performance benchmark.

    Args:
        mode: "live" or path to sosreport
        iterations: Number of benchmark runs
        output_file: Output JSON file path

    Returns:
        dict: Benchmark results
    """
    print(f"Running {iterations} benchmark iterations...")

    results = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "python_version": platform.python_version(),
        "platform": platform.platform(),
        "mode": mode,
        "iterations": iterations,
        "runs": [],
    }

    for i in range(iterations):
        print(f"\nIteration {i + 1}/{iterations}")
        start_time = time.time()

        # TODO: Integrate with actual risu execution
        # For now, this is a placeholder
        # In real implementation, would run:
        # from risuclient import shell
        # shell.main(['--live']) or shell.main([sosreport_path])

        time.sleep(0.1)  # Placeholder

        end_time = time.time()
        elapsed = end_time - start_time

        results["runs"].append(
            {
                "iteration": i + 1,
                "elapsed_seconds": elapsed,
            }
        )

        print(f"Completed in {elapsed:.2f}s")

    # Calculate statistics
    times = [run["elapsed_seconds"] for run in results["runs"]]
    results["statistics"] = {
        "total_time": sum(times),
        "avg_time": sum(times) / len(times),
        "min_time": min(times),
        "max_time": max(times),
    }

    # Save results
    if output_file:
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w") as f:
            json.dump(results, f, indent=2)
        print(f"\nResults saved to {output_file}")

    return results


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Benchmark Risu plugin execution performance"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=3,
        help="Number of benchmark iterations (default: 3)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="benchmark.json",
        help="Output JSON file (default: benchmark.json)",
    )
    parser.add_argument(
        "--mode",
        default="live",
        help='Benchmark mode: "live" or path to sosreport (default: live)',
    )

    args = parser.parse_args()

    try:
        results = run_benchmark(
            mode=args.mode,
            iterations=args.iterations,
            output_file=args.output,
        )

        print("\n=== Benchmark Summary ===")
        print(f"Total time: {results['statistics']['total_time']:.2f}s")
        print(f"Average: {results['statistics']['avg_time']:.2f}s")
        print(f"Min: {results['statistics']['min_time']:.2f}s")
        print(f"Max: {results['statistics']['max_time']:.2f}s")

        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
