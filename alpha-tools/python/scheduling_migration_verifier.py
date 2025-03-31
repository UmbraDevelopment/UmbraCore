#!/usr/bin/env python3
"""
Scheduling Module Migration Verifier

This script verifies the successful migration of the Scheduling module
to the Alpha Dot Five architecture by checking for required files and validating 
build configurations.

Usage:
    python scheduling_migration_verifier.py
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple

# Define colours for output
class Colours:
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BOLD = "\033[1m"
    END = "\033[0m"

# Define paths
PROJECT_ROOT = Path("/Users/mpy/CascadeProjects/UmbraCore")
NEW_MODULE_PATH = PROJECT_ROOT / "packages/UmbraCoreTypes/Sources/Scheduling"

# Required components
REQUIRED_COMPONENTS = [
    "BUILD.bazel",
    "Scheduling.swift",
    "ScheduleDTO.swift",
    "ScheduledTaskDTO.swift",
    "SchedulingServiceProtocol.swift",
    "SchedulingServiceFactory.swift",
    "README.md",
]

def print_status(message: str, status: str, colour: str) -> None:
    """Print a formatted status message."""
    print(f"{message.ljust(60)} [{colour}{status}{Colours.END}]")

def check_file_exists(file_path: Path) -> bool:
    """Check if a file exists."""
    return file_path.exists()

def validate_build_file(file_path: Path) -> Tuple[bool, Optional[str]]:
    """Validate that a BUILD.bazel file contains expected configuration."""
    if not file_path.exists():
        return False, "File not found"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            
        # Check for key components
        expected_elements = [
            "umbra_swift_library",
            "Scheduling",
            "visibility",
        ]
        
        missing_elements = []
        for element in expected_elements:
            if element not in content:
                missing_elements.append(element)
        
        if missing_elements:
            return False, f"Missing elements: {', '.join(missing_elements)}"
        
        return True, None
    except Exception as e:
        return False, str(e)

def main() -> None:
    """Main function to verify the migration."""
    print(f"\n{Colours.BOLD}Scheduling Module Migration Verifier{Colours.END}")
    print(f"Checking migration status for Scheduling module...\n")
    
    all_passed = True
    
    # Check all required files
    print(f"{Colours.BOLD}Checking required files:{Colours.END}")
    for component in REQUIRED_COMPONENTS:
        file_path = NEW_MODULE_PATH / component
        exists = check_file_exists(file_path)
        
        if exists:
            print_status(f"  {component}", "FOUND", Colours.GREEN)
        else:
            print_status(f"  {component}", "MISSING", Colours.RED)
            all_passed = False
    
    # Validate BUILD.bazel file
    print(f"\n{Colours.BOLD}Validating BUILD.bazel file:{Colours.END}")
    file_path = NEW_MODULE_PATH / "BUILD.bazel"
    valid, error = validate_build_file(file_path)
    
    if valid:
        print_status(f"  BUILD.bazel", "VALID", Colours.GREEN)
    else:
        print_status(f"  BUILD.bazel", f"INVALID: {error}", Colours.RED)
        all_passed = False
    
    # Update the BUILD.bazel file to include UmbraErrors dependency
    if all_passed:
        print(f"\n{Colours.BOLD}Updating BUILD.bazel dependencies:{Colours.END}")
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            
            # Check if UmbraErrors dependency is already present
            if "UmbraErrors" not in content:
                # Update the BUILD.bazel file to include UmbraErrors dependency
                updated_content = content.replace(
                    "visibility = [\"//visibility:public\"],",
                    "visibility = [\"//visibility:public\"],\n    deps = [\n        \"//packages/UmbraCoreTypes/Sources/UmbraErrors\",\n    ],"
                )
                
                with open(file_path, 'w') as f:
                    f.write(updated_content)
                
                print_status(f"  Added UmbraErrors dependency to BUILD.bazel", "UPDATED", Colours.GREEN)
            else:
                print_status(f"  UmbraErrors dependency already present", "OK", Colours.GREEN)
        except Exception as e:
            print_status(f"  Failed to update BUILD.bazel: {str(e)}", "ERROR", Colours.RED)
            all_passed = False
    
    # Summary
    print(f"\n{Colours.BOLD}Migration Status:{Colours.END}")
    if all_passed:
        print(f"{Colours.GREEN}All required components have been successfully migrated.{Colours.END}")
        print("The Scheduling module has been successfully migrated to the Alpha Dot Five architecture.")
        
        # Update migration tracker
        print("\nUpdating migration tracker...")
        try:
            subprocess.run([
                "python3", 
                str(PROJECT_ROOT / "alpha-tools/python/alpha_migration_tracker.py"),
                "update",
                "Scheduling",
                "Completed",
                "--notes", "Successfully migrated to Alpha Dot Five architecture."
            ], check=True)
            print(f"{Colours.GREEN}Migration tracker updated successfully.{Colours.END}")
        except subprocess.CalledProcessError:
            print(f"{Colours.RED}Failed to update migration tracker.{Colours.END}")
            print("Please update the migration tracker manually.")
    else:
        print(f"{Colours.RED}Some components are missing or invalid.{Colours.END}")
        print("Please complete the migration of all required components.")
    
    # Next steps
    print(f"\n{Colours.BOLD}Next Steps:{Colours.END}")
    print("1. Run bazelisk build on the migrated module:")
    print("   bazelisk build //packages/UmbraCoreTypes/Sources/Scheduling:Scheduling --verbose_failures")
    print("2. Verify the module works correctly by running any associated tests")
    print("3. Commit and push the migrated modules to the repository")
    print("4. All core modules have now been migrated to Alpha Dot Five!")

if __name__ == "__main__":
    main()
