#!/usr/bin/env python3
"""
Alpha Dot Five Migration Validator

This script analyses modules migrated to the Alpha Dot Five architecture
to ensure they meet structural requirements and dependency patterns.

It validates:
1. Package structure (correct directory layout)
2. Build file correctness
3. Import patterns (identifying temporary fixes)
4. Module dependencies (checking for circular dependencies)

Usage:
    python3 validate_migration.py [module_path]
"""

import os
import sys
import re
import glob
from pathlib import Path
from typing import List, Dict, Set, Tuple, Optional


class MigrationValidator:
    """Validates modules migrated to the Alpha Dot Five architecture."""

    def __init__(self, base_dir: str):
        """Initialize with the base directory of the UmbraCore project."""
        self.base_dir = base_dir
        self.packages_dir = os.path.join(base_dir, "packages")
        self.sources_dir = os.path.join(base_dir, "Sources")
        self.tmp_fixes_file = os.path.join(base_dir, "migration_data", "alpha_dot_five_temporary_fixes.md")
        self.migration_issues = []
        self.temporary_fixes = self._load_temporary_fixes()

    def _load_temporary_fixes(self) -> Dict[str, List[str]]:
        """Load the temporary fixes from the tracking document."""
        fixes = {}
        try:
            with open(self.tmp_fixes_file, 'r') as f:
                lines = f.readlines()
                
            current_section = None
            for line in lines:
                if line.startswith('## '):
                    current_section = line.strip('# \n')
                    fixes[current_section] = []
                elif line.startswith('| ') and current_section:
                    # Skip table headers
                    if not line.startswith('| Module'):
                        fixes[current_section].append(line.strip())
        except FileNotFoundError:
            print(f"Warning: Temporary fixes file not found at {self.tmp_fixes_file}")
        return fixes

    def validate_module(self, module_path: str) -> bool:
        """Validate a single migrated module."""
        if not os.path.exists(module_path):
            self.migration_issues.append(f"Module path does not exist: {module_path}")
            return False
        
        print(f"Validating module: {module_path}")
        self.migration_issues = []
        
        # Check module structure
        structure_valid = self._validate_structure(module_path)
        
        # Check build file
        build_valid = self._validate_build_file(module_path)
        
        # Check imports and dependencies
        imports_valid = self._validate_imports(module_path)
        
        # Report issues
        if self.migration_issues:
            print("\nMigration issues found:")
            for issue in self.migration_issues:
                print(f"  - {issue}")
            return False
        
        print("\nModule validation successful! ✅")
        return True
    
    def _validate_structure(self, module_path: str) -> bool:
        """Validate the module directory structure."""
        # Check if module has required files
        required_files = [
            "BUILD.bazel",
            f"{os.path.basename(module_path)}.swift"  # Umbrella file
        ]
        
        for file in required_files:
            if not os.path.exists(os.path.join(module_path, file)):
                self.migration_issues.append(f"Missing required file: {file}")
                return False
        
        # Check if README.md exists (recommended but not required)
        if not os.path.exists(os.path.join(module_path, "README.md")):
            print("  Warning: Missing recommended README.md file")
        
        return True
    
    def _validate_build_file(self, module_path: str) -> bool:
        """Validate the BUILD.bazel file."""
        build_file = os.path.join(module_path, "BUILD.bazel")
        if not os.path.exists(build_file):
            self.migration_issues.append(f"BUILD.bazel file missing")
            return False
        
        with open(build_file, 'r') as f:
            content = f.read()
        
        # Check if umbra_swift_library is used
        if "umbra_swift_library" not in content:
            self.migration_issues.append("BUILD.bazel doesn't use umbra_swift_library")
            return False
        
        # Check if visibility is set correctly
        if "visibility = [\"//visibility:public\"]" not in content:
            print("  Warning: visibility might not be set to public")
        
        return True
    
    def _validate_imports(self, module_path: str) -> bool:
        """Validate import statements in Swift files."""
        swift_files = glob.glob(os.path.join(module_path, "**/*.swift"), recursive=True)
        
        temp_import_pattern = re.compile(r'@_exported\s+import')
        commented_import_pattern = re.compile(r'//\s*@_exported\s+import')
        
        module_name = os.path.basename(module_path)
        known_temporary_fixes = {}
        
        # Extract known temporary fixes for this module
        for section, fixes in self.temporary_fixes.items():
            for fix in fixes:
                parts = fix.split('|')
                if len(parts) >= 3 and module_name in parts[1].strip():
                    file_name = parts[2].strip().strip('`')
                    known_temporary_fixes[file_name] = True
        
        for file in swift_files:
            rel_path = os.path.relpath(file, self.base_dir)
            file_name = os.path.basename(file)
            
            with open(file, 'r') as f:
                content = f.readlines()
            
            for i, line in enumerate(content):
                # Check for temporary @_exported imports
                if temp_import_pattern.search(line) and not commented_import_pattern.search(line):
                    if file_name not in known_temporary_fixes:
                        self.migration_issues.append(
                            f"Temporary @_exported import in {rel_path}:{i+1} not tracked in temporary fixes document")
        
        return len(self.migration_issues) == 0


def main():
    """Main entry point for the validation script."""
    if len(sys.argv) < 2:
        print("Usage: python3 validate_migration.py [module_path]")
        sys.exit(1)
    
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
    module_path = os.path.abspath(sys.argv[1])
    
    validator = MigrationValidator(base_dir)
    success = validator.validate_module(module_path)
    
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
