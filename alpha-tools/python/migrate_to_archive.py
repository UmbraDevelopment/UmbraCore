#!/usr/bin/env python3
"""
migrate_to_archive.py - Relocates migrated modules to the MigratedArchive directory.

This script:
1. Reads migration_status.json to identify migrated modules
2. Locates these modules in the original Sources directory
3. Properly archives them in MigratedArchive with appropriate structure
4. Creates a detailed log of all operations

Usage:
    python3 migrate_to_archive.py

Author: UmbraDevelopment Team
Date: 2025-03-27
"""

import json
import os
import shutil
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional


class MigrationArchiver:
    """Handles the process of archiving migrated modules from Sources to MigratedArchive."""

    def __init__(self, base_dir: str):
        """Initialise the archiver with the base project directory.
        
        Args:
            base_dir: The base directory of the UmbraCore project
        """
        self.base_dir = Path(base_dir)
        self.source_dir = self.base_dir / "Sources"
        self.archive_dir = self.base_dir / "MigratedArchive"
        self.packages_dir = self.base_dir / "packages" / "UmbraCoreTypes" / "Sources"
        self.migration_file = self.base_dir / "migration_status.json"
        self.log_file = self.base_dir / f"migration_archive_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        
        # Ensure required directories exist
        self.archive_dir.mkdir(exist_ok=True)
        
        # Log setup
        self.logs = []

    def log(self, message: str):
        """Log a message and print it to stdout.
        
        Args:
            message: The message to log
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {message}"
        print(log_entry)
        self.logs.append(log_entry)
    
    def write_logs(self):
        """Write all logs to the log file."""
        with open(self.log_file, "w") as f:
            f.write("\n".join(self.logs))
        self.log(f"Log written to {self.log_file}")

    def load_migration_status(self) -> Dict:
        """Load the migration status from the JSON file.
        
        Returns:
            Dict containing migration status information
        """
        try:
            with open(self.migration_file, "r") as f:
                return json.load(f)
        except Exception as e:
            self.log(f"ERROR: Could not load migration status: {e}")
            sys.exit(1)
    
    def get_migrated_modules(self) -> List[str]:
        """Extract modules marked as 'Completed' from the migration status.
        
        Returns:
            List of completed module names
        """
        status = self.load_migration_status()
        return [module for module, info in status.items() if info.get("status") == "Completed"]

    def find_module_in_sources(self, module_name: str) -> Set[Path]:
        """Find all instances of a module in the Sources directory.
        
        Args:
            module_name: Name of the module to find
            
        Returns:
            Set of paths where the module was found
        """
        found_paths = set()
        
        # Look for exact directory matches
        exact_match = self.source_dir / module_name
        if exact_match.exists():
            found_paths.add(exact_match)
        
        # Look for names containing the module name (for related modules)
        for item in self.source_dir.glob(f"*{module_name}*"):
            if item.is_dir():
                found_paths.add(item)
        
        return found_paths

    def archive_module(self, module_name: str, source_path: Path) -> bool:
        """Archive a single module by moving it to the MigratedArchive directory.
        
        Args:
            module_name: Name of the module
            source_path: Path to the module in Sources
            
        Returns:
            True if successful, False otherwise
        """
        try:
            target_path = self.archive_dir / source_path.name
            
            # Create necessary metadata
            metadata = {
                "original_path": str(source_path),
                "migrated_to": str(self.packages_dir / module_name),
                "archived_at": datetime.now().isoformat(),
                "moved_by": "migrate_to_archive.py"
            }
            
            # First, make sure target doesn't exist
            if target_path.exists():
                # If it does exist, append a timestamp to make it unique
                new_name = f"{source_path.name}_{int(time.time())}"
                target_path = self.archive_dir / new_name
                self.log(f"Target path already exists, using {new_name} instead")
            
            # Move the directory
            shutil.move(str(source_path), str(target_path))
            
            # Write metadata file
            with open(target_path / "MIGRATION_INFO.json", "w") as f:
                json.dump(metadata, f, indent=2)
            
            self.log(f"Archived {source_path} to {target_path}")
            return True
        except Exception as e:
            self.log(f"ERROR: Failed to archive {source_path}: {e}")
            return False

    def archive_all_migrated_modules(self):
        """Archive all modules marked as completed in the migration status."""
        migrated_modules = self.get_migrated_modules()
        self.log(f"Found {len(migrated_modules)} migrated modules: {', '.join(migrated_modules)}")
        
        archived_count = 0
        skipped_count = 0
        
        for module in migrated_modules:
            sources = self.find_module_in_sources(module)
            if not sources:
                self.log(f"No instances of {module} found in Sources directory, skipping")
                skipped_count += 1
                continue
            
            self.log(f"Found {len(sources)} instances of {module} in Sources")
            for source in sources:
                if self.archive_module(module, source):
                    archived_count += 1
        
        self.log(f"Archiving complete: {archived_count} modules archived, {skipped_count} modules skipped")

    def run(self):
        """Run the archiving process."""
        self.log(f"Starting migration archiving process")
        self.log(f"Base directory: {self.base_dir}")
        self.log(f"Sources directory: {self.source_dir}")
        self.log(f"Archive directory: {self.archive_dir}")
        self.log(f"Packages directory: {self.packages_dir}")
        
        self.archive_all_migrated_modules()
        self.write_logs()
        self.log("Archive process completed")


if __name__ == "__main__":
    # Use the current directory as the base
    current_dir = os.getcwd()
    
    # Find UmbraCore base directory (where .git exists)
    base_dir = current_dir
    while not (Path(base_dir) / ".git").exists():
        parent = os.path.dirname(base_dir)
        if parent == base_dir:  # Reached root
            print("ERROR: Could not find UmbraCore base directory (no .git found)")
            sys.exit(1)
        base_dir = parent
    
    archiver = MigrationArchiver(base_dir)
    archiver.run()
