#!/usr/bin/env python3
"""
Alpha Dot Five Migration Tracker

This script tracks the migration of modules to the new Alpha Dot Five architecture.
It provides utilities to update, visualise, and report on migration progress.
"""

import argparse
import csv
import datetime
import json
import os
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


class MigrationStatus(Enum):
    """Enum representing the migration status of a module."""
    NOT_STARTED = "Not Started"
    IN_PROGRESS = "In Progress"
    COMPLETED = "Completed"
    BLOCKED = "Blocked"
    SKIPPED = "Skipped"


@dataclass
class ModuleInfo:
    """Information about a module in the UmbraCore project."""
    name: str
    status: MigrationStatus
    dependencies: List[str]
    dependents: List[str]
    migration_date: Optional[datetime.date] = None
    blocking_issues: List[str] = None
    notes: str = ""

    def __post_init__(self):
        if self.blocking_issues is None:
            self.blocking_issues = []


class MigrationTracker:
    """Tracks the migration status of modules in the UmbraCore project."""

    def __init__(self, data_file: str = "migration_status.json"):
        """Initialize the migration tracker with a data file."""
        self.data_file = data_file
        self.modules: Dict[str, ModuleInfo] = {}
        self._load_data()

    def _load_data(self) -> None:
        """Load module data from the data file."""
        data_path = Path(self.data_file)
        if not data_path.exists():
            # Initialize with default modules if file doesn't exist
            self._initialize_default_modules()
        else:
            try:
                with open(data_path, "r") as f:
                    data = json.load(f)
                
                for module_name, module_data in data.items():
                    self.modules[module_name] = ModuleInfo(
                        name=module_name,
                        status=MigrationStatus(module_data["status"]),
                        dependencies=module_data["dependencies"],
                        dependents=module_data["dependents"],
                        migration_date=datetime.date.fromisoformat(module_data["migration_date"]) 
                            if module_data.get("migration_date") else None,
                        blocking_issues=module_data.get("blocking_issues", []),
                        notes=module_data.get("notes", "")
                    )
            except (json.JSONDecodeError, KeyError) as e:
                print(f"Error loading data file: {e}")
                self._initialize_default_modules()

    def _initialize_default_modules(self) -> None:
        """Initialize with default UmbraCore modules."""
        # Core modules
        self.add_module("UmbraErrors", MigrationStatus.COMPLETED, 
                      [], ["CoreDTOs", "UserDefaults", "SecurityInterfaces"],
                      migration_date=datetime.date.today(),
                      notes="Successfully migrated to Alpha Dot Five architecture.")
        
        self.add_module("CoreDTOs", MigrationStatus.IN_PROGRESS,
                      ["UmbraErrors"], ["UserDefaults", "SecurityInterfaces"],
                      notes="Dependencies updated to use migrated UmbraErrors module.")
        
        self.add_module("UserDefaults", MigrationStatus.NOT_STARTED,
                      ["UmbraErrors", "CoreDTOs"], ["SecurityInterfaces"],
                      notes="Planned for migration after CoreDTOs is complete.")
        
        self.add_module("SecurityInterfaces", MigrationStatus.NOT_STARTED,
                      ["UmbraErrors", "CoreDTOs", "UserDefaults"], [],
                      notes="Depends on UserDefaults migration.")
        
        # Additional modules
        self.add_module("Notification", MigrationStatus.NOT_STARTED,
                      ["UmbraErrors"], [])
        
        self.add_module("Scheduling", MigrationStatus.NOT_STARTED,
                      ["UmbraErrors"], [])
        
        self.add_module("FileSystemTypes", MigrationStatus.NOT_STARTED,
                      [], ["CoreDTOs"])
        
        self.add_module("SecurityTypes", MigrationStatus.NOT_STARTED,
                      [], ["CoreDTOs", "SecurityInterfaces"])

    def save_data(self) -> None:
        """Save module data to the data file."""
        data = {}
        for module_name, module_info in self.modules.items():
            data[module_name] = {
                "status": module_info.status.value,
                "dependencies": module_info.dependencies,
                "dependents": module_info.dependents,
                "migration_date": module_info.migration_date.isoformat() if module_info.migration_date else None,
                "blocking_issues": module_info.blocking_issues,
                "notes": module_info.notes
            }
        
        with open(self.data_file, "w") as f:
            json.dump(data, f, indent=2)
        
        print(f"Data saved to {self.data_file}")

    def add_module(self, name: str, status: MigrationStatus, 
                 dependencies: List[str], dependents: List[str],
                 migration_date: Optional[datetime.date] = None,
                 blocking_issues: List[str] = None,
                 notes: str = "") -> None:
        """Add a new module to the tracker."""
        if blocking_issues is None:
            blocking_issues = []
        
        self.modules[name] = ModuleInfo(
            name=name,
            status=status,
            dependencies=dependencies,
            dependents=dependents,
            migration_date=migration_date,
            blocking_issues=blocking_issues,
            notes=notes
        )

    def update_module_status(self, name: str, status: MigrationStatus, 
                           migration_date: Optional[datetime.date] = None,
                           notes: Optional[str] = None) -> bool:
        """Update the migration status of a module."""
        if name not in self.modules:
            print(f"Module {name} not found in tracker.")
            return False
        
        module = self.modules[name]
        module.status = status
        
        if status == MigrationStatus.COMPLETED and migration_date is None:
            module.migration_date = datetime.date.today()
        elif migration_date is not None:
            module.migration_date = migration_date
            
        if notes is not None:
            module.notes = notes
            
        return True

    def get_migration_order(self) -> List[str]:
        """Determine an optimal order for module migration based on dependencies."""
        visited: Set[str] = set()
        result: List[str] = []
        
        def dfs(module_name: str) -> None:
            if module_name in visited:
                return
            
            visited.add(module_name)
            for dep in self.modules[module_name].dependencies:
                if dep in self.modules:
                    dfs(dep)
            
            result.append(module_name)
        
        # Start DFS from modules with no dependents
        for name, module in self.modules.items():
            if not module.dependents:
                dfs(name)
        
        # Process any remaining modules
        for name in self.modules:
            dfs(name)
            
        return list(reversed(result))

    def export_csv(self, filename: str) -> None:
        """Export the migration status to a CSV file."""
        with open(filename, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["Module", "Status", "Dependencies", "Dependents", 
                           "Migration Date", "Blocking Issues", "Notes"])
            
            for name, module in sorted(self.modules.items()):
                writer.writerow([
                    name,
                    module.status.value,
                    ", ".join(module.dependencies),
                    ", ".join(module.dependents),
                    module.migration_date.isoformat() if module.migration_date else "",
                    ", ".join(module.blocking_issues),
                    module.notes
                ])
        
        print(f"CSV exported to {filename}")

    def print_status_report(self) -> None:
        """Print a status report of all modules."""
        print("=" * 80)
        print("UmbraCore Alpha Dot Five Migration Status Report")
        print(f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 80)
        
        completed = 0
        in_progress = 0
        not_started = 0
        blocked = 0
        
        for name, module in sorted(self.modules.items()):
            if module.status == MigrationStatus.COMPLETED:
                completed += 1
            elif module.status == MigrationStatus.IN_PROGRESS:
                in_progress += 1
            elif module.status == MigrationStatus.NOT_STARTED:
                not_started += 1
            elif module.status == MigrationStatus.BLOCKED:
                blocked += 1
        
        total = len(self.modules)
        print(f"Total Modules: {total}")
        print(f"Completed: {completed} ({completed/total*100:.1f}%)")
        print(f"In Progress: {in_progress} ({in_progress/total*100:.1f}%)")
        print(f"Not Started: {not_started} ({not_started/total*100:.1f}%)")
        print(f"Blocked: {blocked} ({blocked/total*100:.1f}%)")
        print("-" * 80)
        
        print("\nModules by status:")
        for status in MigrationStatus:
            modules = [name for name, module in self.modules.items() 
                     if module.status == status]
            if modules:
                print(f"\n{status.value}:")
                for name in sorted(modules):
                    module = self.modules[name]
                    date_str = f" (Completed: {module.migration_date})" if module.migration_date else ""
                    print(f"  - {name}{date_str}")
                    if module.notes:
                        print(f"    Notes: {module.notes}")
        
        print("\nSuggested migration order:")
        migration_order = self.get_migration_order()
        for i, name in enumerate(migration_order):
            status_marker = {
                MigrationStatus.COMPLETED: "✅",
                MigrationStatus.IN_PROGRESS: "⏳",
                MigrationStatus.NOT_STARTED: "⏱️",
                MigrationStatus.BLOCKED: "❌",
                MigrationStatus.SKIPPED: "⏭️"
            }[self.modules[name].status]
            
            print(f"{i+1}. {status_marker} {name}")


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description="Track Alpha Dot Five migration progress")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Status report command
    status_parser = subparsers.add_parser("status", help="Display migration status report")
    status_parser.add_argument("--csv", type=str, help="Export status to CSV file")
    
    # Update command
    update_parser = subparsers.add_parser("update", help="Update module status")
    update_parser.add_argument("module", help="Module name to update")
    update_parser.add_argument("status", choices=[s.value for s in MigrationStatus], 
                             help="New status for the module")
    update_parser.add_argument("--notes", type=str, help="Notes about the status update")
    
    args = parser.parse_args()
    
    tracker = MigrationTracker()
    
    if args.command == "status":
        tracker.print_status_report()
        if args.csv:
            tracker.export_csv(args.csv)
    elif args.command == "update":
        status = next(s for s in MigrationStatus if s.value == args.status)
        if tracker.update_module_status(args.module, status, notes=args.notes):
            tracker.save_data()
            print(f"Updated {args.module} status to {status.value}")
    else:
        tracker.print_status_report()


if __name__ == "__main__":
    main()
