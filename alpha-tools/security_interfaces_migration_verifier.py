#!/usr/bin/env python3
"""
Security Interfaces Migration Verifier

This script verifies the successful migration of the SecurityInterfaces module
to the Alpha Dot Five architecture by checking for required files and validating 
build configurations.

Usage:
    python security_interfaces_migration_verifier.py
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
OLD_MODULE_PATH = PROJECT_ROOT / "Sources/SecurityInterfaces"
NEW_MODULE_PATH = PROJECT_ROOT / "packages/UmbraCoreTypes/Sources/SecurityInterfaces"

# Required components
REQUIRED_COMPONENTS = [
    "BUILD.bazel",
    "SecurityInterfaces.swift",
    "DTOs/BUILD.bazel",
    "DTOs/SecurityKeyDTO.swift",
    "DTOs/SecurityKeyInformationDTO.swift",
    "Protocols/BUILD.bazel",
    "Protocols/SecurityProviderProtocol.swift",
    "Protocols/SecurityProviderBase.swift",
    "Types/BUILD.bazel",
    "Types/Common/HashAlgorithm.swift",
    "Types/Common/SecurityOperation.swift",
    "Types/Errors/SecurityError.swift",
    "Models/BUILD.bazel",
    "Models/SecurityModels.swift",
]

def print_status(message: str, status: str, colour: str) -> None:
    """Print a formatted status message."""
    print(f"{message.ljust(60)} [{colour}{status}{Colours.END}]")

def check_file_exists(file_path: Path) -> bool:
    """Check if a file exists."""
    return file_path.exists()

def validate_build_file(file_path: Path) -> Tuple[bool, Optional[str]]:
    """Validate that a BUILD.bazel file contains expected dependencies."""
    if not file_path.exists():
        return False, "File not found"
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            
        # Check for key dependencies
        expected_deps = [
            "UmbraErrors",
            "SecurityTypes",
            "CoreDTOs",
        ]
        
        missing_deps = []
        for dep in expected_deps:
            if dep not in content:
                missing_deps.append(dep)
        
        if missing_deps:
            return False, f"Missing dependencies: {', '.join(missing_deps)}"
        
        return True, None
    except Exception as e:
        return False, str(e)

def main() -> None:
    """Main function to verify the migration."""
    print(f"\n{Colours.BOLD}Security Interfaces Migration Verifier{Colours.END}")
    print(f"Checking migration status for SecurityInterfaces module...\n")
    
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
    
    # Validate BUILD.bazel files
    print(f"\n{Colours.BOLD}Validating BUILD.bazel files:{Colours.END}")
    for component in REQUIRED_COMPONENTS:
        if "BUILD.bazel" in component:
            file_path = NEW_MODULE_PATH / component
            valid, error = validate_build_file(file_path)
            
            if valid:
                print_status(f"  {component}", "VALID", Colours.GREEN)
            else:
                print_status(f"  {component}", f"INVALID: {error}", Colours.RED)
                all_passed = False
    
    # Summary
    print(f"\n{Colours.BOLD}Migration Status:{Colours.END}")
    if all_passed:
        print(f"{Colours.GREEN}All required components have been successfully migrated.{Colours.END}")
        print("The SecurityInterfaces module has been successfully migrated to the Alpha Dot Five architecture.")
    else:
        print(f"{Colours.RED}Some components are missing or invalid.{Colours.END}")
        print("Please complete the migration of all required components.")
    
    # Next steps
    print(f"\n{Colours.BOLD}Next Steps:{Colours.END}")
    print("1. Run bazelisk build on the migrated module:")
    print("   bazelisk build //packages/UmbraCoreTypes/Sources/SecurityInterfaces:SecurityInterfaces --verbose_failures")
    print("2. Update the migration tracker to mark SecurityInterfaces as migrated")
    print("3. Commit and push the migrated module to the repository")

if __name__ == "__main__":
    main()
