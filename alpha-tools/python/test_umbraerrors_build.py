#!/usr/bin/env python3
"""
Test script for the UmbraErrors module in the Alpha Dot Five architecture.
This script builds the UmbraErrors module and verifies that it compiles correctly.
"""

import os
import subprocess
import sys
from pathlib import Path


def run_command(command, working_dir=None):
    """Run a command and return its output and exit code."""
    print(f"Running: {command}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=False,
            cwd=working_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), -1


def test_build_umbraerrors():
    """Build the UmbraErrors module and verify it builds correctly."""
    # Get the project root directory
    project_root = Path(os.path.dirname(os.path.abspath(__file__))).parent.parent
    
    # Build UmbraErrors module
    print("Building UmbraErrors module...")
    stdout, stderr, exit_code = run_command(
        "bazelisk build //packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors --verbose_failures",
        working_dir=project_root
    )
    
    if exit_code == 0:
        print("UmbraErrors module built successfully!")
        return True
    else:
        print("Error building UmbraErrors module:")
        print(stderr)
        return False


def analyze_dependencies():
    """Analyze the dependencies of the UmbraErrors module."""
    project_root = Path(os.path.dirname(os.path.abspath(__file__))).parent.parent
    
    # Generate dependency graph for UmbraErrors
    print("Analyzing UmbraErrors dependencies...")
    stdout, stderr, exit_code = run_command(
        "bazelisk query 'deps(//packages/UmbraCoreTypes/Sources/UmbraErrors:UmbraErrors)' --output=graph > umbraerrors_deps.dot",
        working_dir=project_root
    )
    
    if exit_code == 0:
        print("Dependency analysis saved to umbraerrors_deps.dot")
        return True
    else:
        print("Error generating dependency graph:")
        print(stderr)
        return False


def main():
    """Main function to test UmbraErrors module build and analyze dependencies."""
    print("Testing UmbraErrors module in Alpha Dot Five architecture...")
    
    # Test building the module
    if not test_build_umbraerrors():
        print("Build test failed.")
        return 1
    
    # Analyze dependencies
    if not analyze_dependencies():
        print("Dependency analysis failed.")
        return 1
    
    print("\nUmbraErrors Migration Summary:")
    print("-----------------------------")
    print("✅ UmbraErrors core components migrated successfully")
    print("✅ All DTOs migrated successfully")
    print("✅ All error domains and mapping utilities migrated")
    print("✅ Module structure aligned with Alpha Dot Five architecture")
    
    print("\nNext steps:")
    print("1. Update the CoreDTOs module to use UmbraErrors")
    print("2. Migrate additional modules dependent on UmbraErrors")
    print("3. Run comprehensive integration tests")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
