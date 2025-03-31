#!/usr/bin/env python3
"""
Migration Helper for Alpha Dot Five UmbraCore restructuring.
Assists in migrating modules from the old structure to the new package structure.
"""
import os
import sys
import shutil
import argparse
import subprocess
import json
import re
from pathlib import Path


class ModuleMigrator:
    def __init__(self, source_dir, target_dir, workspace_root=None):
        """Initialize the module migrator.
        
        Args:
            source_dir: Source directory (e.g., /Users/mpy/CascadeProjects/UmbraCore/Sources)
            target_dir: Target directory for packages (e.g., /Users/mpy/CascadeProjects/UmbraCore/packages)
            workspace_root: Root of the workspace for running Bazel queries
        """
        self.source_dir = source_dir
        self.target_dir = target_dir
        self.workspace_root = workspace_root or os.path.dirname(source_dir)
        
        # Valid dependencies according to Alpha Dot Five structure
        self.valid_dependencies = {
            "UmbraErrorKit": ["UmbraCoreTypes"],
            "UmbraInterfaces": ["UmbraCoreTypes", "UmbraErrorKit"],
            "UmbraUtils": ["UmbraCoreTypes"],
            "UmbraImplementations": ["UmbraInterfaces", "UmbraCoreTypes", "UmbraErrorKit", "UmbraUtils"],
            "UmbraFoundationBridge": ["UmbraCoreTypes"],
            "ResticKit": ["UmbraInterfaces", "UmbraCoreTypes", "UmbraUtils"],
        }
        
        # Package mapping from old to new structure
        self.default_package_mapping = {
            # Core Types
            "CoreDTOs": "UmbraCoreTypes/CoreDTOs",
            "KeyManagementTypes": "UmbraCoreTypes/KeyManagementTypes",
            "ResticTypes": "UmbraCoreTypes/ResticTypes",
            "SecurityTypes": "UmbraCoreTypes/SecurityTypes",
            "ServiceTypes": "UmbraCoreTypes/ServiceTypes",
            "UmbraCoreTypes": "UmbraCoreTypes/Core",
            
            # Error Kit
            "ErrorHandling": "UmbraErrorKit/Implementation",
            "ErrorHandlingInterfaces": "UmbraErrorKit/Interfaces",
            "ErrorHandlingDomains": "UmbraErrorKit/Domains",
            "ErrorTypes": "UmbraErrorKit/Types",
            "UmbraErrors": "UmbraErrorKit/Core",
            
            # Interfaces
            "SecurityInterfaces": "UmbraInterfaces/SecurityInterfaces",
            "LoggingWrapperInterfaces": "UmbraInterfaces/LoggingInterfaces",
            "FileSystemTypes": "UmbraInterfaces/FileSystemInterfaces",
            "XPCProtocolsCore": "UmbraInterfaces/XPCProtocolsCore",
            "CryptoInterfaces": "UmbraInterfaces/CryptoInterfaces",
            
            # Implementations
            "UmbraSecurity": "UmbraImplementations/SecurityImpl",
            "LoggingWrapper": "UmbraImplementations/LoggingImpl",
            "FileSystemService": "UmbraImplementations/FileSystemImpl",
            "UmbraKeychainService": "UmbraImplementations/KeychainImpl",
            "UmbraCryptoService": "UmbraImplementations/CryptoImpl",
            
            # Foundation Bridge
            "ObjCBridgingTypes": "UmbraFoundationBridge/ObjCBridging",
            "FoundationBridgeTypes": "UmbraFoundationBridge/CoreTypeBridges",
            
            # Restic Kit
            "ResticCLIHelper": "ResticKit/CLIHelper",
            "ResticCLIHelperModels": "ResticKit/CommandBuilder",
            "RepositoryManager": "ResticKit/RepositoryManager",
            
            # Utils
            "DateTimeService": "UmbraUtils/DateUtils",
            "NetworkService": "UmbraUtils/Networking",
        }
    
    def run_bazel_query(self, query):
        """Run a bazelisk query and return the result as a Python object."""
        try:
            cmd = ["bazelisk", "query", "--output=json", query]
            print(f"Running: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                cwd=self.workspace_root,
                check=True,
                capture_output=True,
                text=True
            )
            return json.loads(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Error running bazelisk query: {e}")
            print(f"stderr: {e.stderr}")
            return None
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON from bazelisk query: {e}")
            return None

    def get_module_dependencies(self, module_name):
        """Get dependencies of a module using bazelisk query."""
        query = f"deps(//Sources/{module_name}:*)"
        result = self.run_bazel_query(query)
        if not result:
            return []
            
        deps = []
        for target in result.get("target", []):
            name = target.get("name", "")
            if name.startswith("//Sources/") and ":" in name:
                # Extract module name from target
                module = name.split("//Sources/")[1].split(":")[0]
                if module != module_name and module not in deps:
                    deps.append(module)
        
        return deps
    
    def check_migration_dependencies(self, module_name, target_package):
        """Check if all dependencies of a module have been migrated."""
        deps = self.get_module_dependencies(module_name)
        if not deps:
            print(f"No dependencies found for {module_name} or error in query")
            return True
            
        # Extract target top-level package
        top_level_package = target_package.split("/")[0]
        
        missing_deps = []
        for dep in deps:
            # Skip dependencies that aren't mapped
            if dep not in self.default_package_mapping:
                continue
                
            dep_target = self.default_package_mapping[dep]
            dep_package = dep_target.split("/")[0]
            
            # Check if this dependency is valid according to Alpha Dot Five rules
            if dep_package != top_level_package and dep_package not in self.valid_dependencies.get(top_level_package, []):
                print(f"⚠️ Warning: {module_name} depends on {dep} which maps to {dep_target}")
                print(f"   This would create an invalid dependency from {top_level_package} to {dep_package}")
                print(f"   Valid dependencies for {top_level_package} are: {', '.join(self.valid_dependencies.get(top_level_package, []))}")
            
            # Check if the dependency has been migrated
            dep_path = os.path.join(self.target_dir, dep_target, "Sources")
            if not os.path.exists(dep_path) or not any(f.endswith('.swift') for f in os.listdir(dep_path) if os.path.isfile(os.path.join(dep_path, f))):
                missing_deps.append((dep, dep_target))
        
        if missing_deps:
            print(f"❌ The following dependencies of {module_name} have not been migrated yet:")
            for dep, target in missing_deps:
                print(f"  • {dep} -> {target}")
            print("You should migrate these dependencies first to maintain proper dependency ordering.")
            return False
        
        return True
    
    def update_imports(self, file_path, module_mapping):
        """Update import statements in a Swift file."""
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Find all import statements
        import_pattern = r'import\s+(\w+)'
        imports = re.findall(import_pattern, content)
        
        # Replace imports according to mapping
        for old_import in imports:
            if old_import in module_mapping:
                new_import = module_mapping[old_import]
                content = re.sub(
                    f'import\\s+{old_import}\\b', 
                    f'import {new_import}', 
                    content
                )
                print(f"Updated import: {old_import} -> {new_import}")
        
        # Write updated content back to file
        with open(file_path, 'w') as f:
            f.write(content)
    
    def migrate_module(self, module_name, target_package, module_mapping=None, skip_dependency_check=False):
        """Migrate a module from the old structure to the new package structure.
        
        Args:
            module_name: Name of the module to migrate
            target_package: Target package and subpackage (e.g., UmbraCoreTypes/CoreDTOs)
            module_mapping: Mapping of old module names to new module names for import updates
            skip_dependency_check: Whether to skip dependency validation
        """
        source_module_path = os.path.join(self.source_dir, module_name)
        if not os.path.exists(source_module_path):
            print(f"❌ Error: Source module {module_name} not found at {source_module_path}")
            return False
        
        # Check dependencies unless skipped
        if not skip_dependency_check:
            if not self.check_migration_dependencies(module_name, target_package):
                print(f"⚠️ Dependency check failed for {module_name}")
                response = input("Do you want to continue anyway? (y/n): ")
                if response.lower() != 'y':
                    return False
        
        # Split target_package into package name and subpackage path
        parts = target_package.split("/", 1)
        package_name = parts[0]
        subpackage = parts[1] if len(parts) > 1 else ""
        
        target_module_path = os.path.join(self.target_dir, package_name, "Sources")
        if subpackage:
            target_module_path = os.path.join(target_module_path, subpackage)
        
        # Create target directory if it doesn't exist
        os.makedirs(target_module_path, exist_ok=True)
        
        # Prepare module mapping for import updates
        if module_mapping is None:
            # Create a default mapping based on our package mapping
            module_mapping = {}
            for old_name, new_path in self.default_package_mapping.items():
                # Extract the last component as the new module name
                new_name = new_path.split('/')[-1]
                module_mapping[old_name] = new_name
        
        # Copy Swift files, excluding tests
        files_copied = 0
        for root, _, files in os.walk(source_module_path):
            for file in files:
                if file.endswith(".swift") and "Tests" not in root and not file.endswith("Test.swift"):
                    source_file = os.path.join(root, file)
                    # Preserve subdirectory structure relative to the module
                    rel_path = os.path.relpath(root, source_module_path)
                    if rel_path != '.':
                        target_file_dir = os.path.join(target_module_path, rel_path)
                        os.makedirs(target_file_dir, exist_ok=True)
                        target_file = os.path.join(target_file_dir, file)
                    else:
                        target_file = os.path.join(target_module_path, file)
                    
                    # Copy the file
                    shutil.copy2(source_file, target_file)
                    files_copied += 1
                    print(f"Copied {file} to {os.path.relpath(target_file, self.target_dir)}")
                    
                    # Update imports
                    self.update_imports(target_file, module_mapping)
        
        print(f"Migration complete: {files_copied} files copied")
        
        # Create or update BUILD file for the subpackage
        self.create_or_update_build_file(package_name, subpackage)
        
        return files_copied > 0
    
    def create_or_update_build_file(self, package_name, subpackage=None):
        """Create or update a BUILD.bazel file for a package or subpackage."""
        if subpackage:
            # Subpackage BUILD file
            build_dir = os.path.join(self.target_dir, package_name, "Sources", subpackage)
            target_name = subpackage.split('/')[-1]
            visibility = [f"//packages/{package_name}:__subpackages__"]
            deps = []
            
            # Determine dependencies based on package rules
            if package_name == "UmbraErrorKit":
                if "Interfaces" not in subpackage:
                    deps.append("//packages/UmbraErrorKit/Sources/Interfaces")
                if "Implementation" in subpackage:
                    deps.append("//packages/UmbraCoreTypes")
            elif package_name == "UmbraInterfaces":
                if "SecurityInterfaces" in subpackage:
                    deps.append("//packages/UmbraCoreTypes")
                    deps.append("//packages/UmbraErrorKit/Sources/Interfaces")
            
            # Create subpackage BUILD file with appropriate deps and visibility
        else:
            # Main package BUILD file
            build_dir = os.path.join(self.target_dir, package_name)
            target_name = package_name
            visibility = ["//visibility:public"]
            deps = []
            
            # Add standard dependencies based on package type
            if package_name == "UmbraErrorKit":
                deps.append("//packages/UmbraCoreTypes")
            elif package_name == "UmbraInterfaces":
                deps.append("//packages/UmbraCoreTypes")
                deps.append("//packages/UmbraErrorKit")
            elif package_name == "UmbraImplementations":
                deps.append("//packages/UmbraInterfaces")
                deps.append("//packages/UmbraCoreTypes")
                deps.append("//packages/UmbraErrorKit")
            elif package_name == "UmbraFoundationBridge":
                deps.append("//packages/UmbraCoreTypes")
            elif package_name == "ResticKit":
                deps.append("//packages/UmbraInterfaces")
                deps.append("//packages/UmbraCoreTypes")
            elif package_name == "UmbraUtils":
                deps.append("//packages/UmbraCoreTypes")
        
        # Create BUILD file
        build_path = os.path.join(build_dir, "BUILD.bazel")
        
        # Only create the file if it doesn't exist or it's a subpackage (which gets recreated)
        if not os.path.exists(build_path) or subpackage:
            # Format dependencies for Starlark
            deps_str = ""
            if deps:
                deps_str = ",\n        ".join([f'"{d}"' for d in deps])
                deps_str = f"""
    deps = [
        {deps_str},
    ],"""
            
            # Format glob pattern based on whether this is a subpackage
            if subpackage:
                glob_pattern = '"*.swift"'
            else:
                glob_pattern = '"Sources/**/*.swift"'
            
            # Format visibility for Starlark
            visibility_str = ", ".join([f'"{v}"' for v in visibility])
            
            # Create BUILD file content
            build_content = f'''load("//bazel:swift_rules.bzl", "umbra_swift_library")

umbra_swift_library(
    name = "{target_name}",
    srcs = glob(
        [
            {glob_pattern},
        ],
        allow_empty = False,
        exclude = [
            "**/Tests/**",
            "**/*Test.swift",
            "**/*.generated.swift",
        ],
        exclude_directories = 1,
    ),{deps_str}
    visibility = [{visibility_str}],
)
'''
            
            # Write the BUILD file
            os.makedirs(os.path.dirname(build_path), exist_ok=True)
            with open(build_path, "w") as f:
                f.write(build_content)
            
            # Run buildifier to ensure proper formatting
            try:
                subprocess.run(["buildifier", build_path], check=True)
                print(f"Created and formatted BUILD file for {target_name}")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"Warning: Created BUILD file but buildifier formatting failed")
        
        return build_path


def main():
    parser = argparse.ArgumentParser(description="Migrate modules to Alpha Dot Five package structure")
    parser.add_argument("--source", default="Sources", help="Source directory containing old modules")
    parser.add_argument("--target", default="packages", help="Target directory for new packages")
    parser.add_argument("--workspace", default=None, help="Workspace root for running Bazel queries")
    parser.add_argument("--module", required=True, help="Name of the module to migrate")
    parser.add_argument("--destination", required=True, 
                       help="Destination path in new structure (e.g., UmbraCoreTypes/KeyManagementTypes)")
    parser.add_argument("--skip-deps", action="store_true", help="Skip dependency validation")
    
    args = parser.parse_args()
    
    # Create absolute paths
    source_dir = os.path.abspath(args.source)
    target_dir = os.path.abspath(args.target)
    workspace_root = args.workspace
    if workspace_root:
        workspace_root = os.path.abspath(workspace_root)
    
    migrator = ModuleMigrator(source_dir, target_dir, workspace_root)
    success = migrator.migrate_module(args.module, args.destination, skip_dependency_check=args.skip_deps)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
