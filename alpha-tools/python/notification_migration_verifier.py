#!/usr/bin/env python3
"""
Notification Module Migration Verifier

This script verifies the successful migration of the Notification module
to the Alpha Dot Five architecture by checking for required files and validating 
build configurations.

Usage:
    python notification_migration_verifier.py
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
OLD_MODULE_PATH = PROJECT_ROOT / "Sources/NotificationService"
NEW_MODULE_PATH = PROJECT_ROOT / "packages/UmbraCoreTypes/Sources/Notification"

# Required components
REQUIRED_COMPONENTS = [
    "BUILD.bazel",
    "Notification.swift",
    "NotificationDTO.swift",
    "NotificationServiceProtocol.swift",
    "NotificationServiceFactory.swift",
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
            "Notification",
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
    print(f"\n{Colours.BOLD}Notification Module Migration Verifier{Colours.END}")
    print(f"Checking migration status for Notification module...\n")
    
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
    
    # Summary
    print(f"\n{Colours.BOLD}Migration Status:{Colours.END}")
    if all_passed:
        print(f"{Colours.GREEN}All required components have been successfully migrated.{Colours.END}")
        print("The Notification module has been successfully migrated to the Alpha Dot Five architecture.")
        
        # Update migration tracker
        print("\nUpdating migration tracker...")
        try:
            subprocess.run([
                "python3", 
                str(PROJECT_ROOT / "alpha-tools/python/alpha_migration_tracker.py"),
                "update",
                "Notification",
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
    print("   bazelisk build //packages/UmbraCoreTypes/Sources/Notification:Notification --verbose_failures")
    print("2. Migrate the Scheduling module next")
    print("3. Commit and push the migrated modules to the repository")

if __name__ == "__main__":
    main()
