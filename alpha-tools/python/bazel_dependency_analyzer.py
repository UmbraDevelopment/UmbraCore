#!/usr/bin/env python3
"""
Bazel Dependency Analyzer for Alpha Dot Five UmbraCore restructuring.
Uses bazelisk query to accurately analyze dependencies between packages.
"""
import json
import subprocess
import argparse
import sys
import os
from collections import defaultdict


class DependencyAnalyzer:
    def __init__(self, workspace_root, packages_dir):
        self.workspace_root = workspace_root
        self.packages_dir = packages_dir
        self.valid_dependencies = {
            "UmbraErrorKit": ["UmbraCoreTypes"],
            "UmbraInterfaces": ["UmbraCoreTypes", "UmbraErrorKit"],
            "UmbraUtils": ["UmbraCoreTypes"],
            "UmbraImplementations": ["UmbraInterfaces", "UmbraCoreTypes", "UmbraErrorKit", "UmbraUtils"],
            "UmbraFoundationBridge": ["UmbraCoreTypes"],
            "ResticKit": ["UmbraInterfaces", "UmbraCoreTypes", "UmbraUtils"],
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
            print(f"Output: {result.stdout}")
            return None

    def get_all_package_targets(self):
        """Get all targets in the packages directory."""
        query = f"//packages/..."
        return self.run_bazel_query(query)
    
    def get_target_deps(self, target):
        """Get all dependencies of a target."""
        query = f"deps({target})"
        return self.run_bazel_query(query)
    
    def get_target_rdeps(self, target):
        """Get all targets that depend on this target."""
        query = f"rdeps(//packages/..., {target})"
        return self.run_bazel_query(query)
    
    def parse_target_name(self, target):
        """Parse the package name from a target."""
        # Strip leading // and trailing :target if present
        if target.startswith("//"):
            target = target[2:]
        
        if ":" in target:
            target = target.split(":")[0]
            
        # Extract the top-level package name
        if target.startswith("packages/"):
            parts = target.split("/")
            if len(parts) > 1:
                return parts[1]  # Return the package name (UmbraCoreTypes, etc.)
        
        return None
    
    def is_dependency_valid(self, source_pkg, target_pkg):
        """Check if a dependency from source to target is valid."""
        if source_pkg == target_pkg:
            return True  # Self-dependencies are allowed
            
        if source_pkg not in self.valid_dependencies:
            return False  # Unknown source package
            
        return target_pkg in self.valid_dependencies[source_pkg]
    
    def analyze_dependencies(self):
        """Analyze dependencies between packages and validate against rules."""
        # Get all targets in packages directory
        all_targets = self.get_all_package_targets()
        if not all_targets:
            print("No targets found in packages directory")
            return
            
        # Store dependencies by package
        package_deps = defaultdict(set)
        
        # Process each target
        target_rules = all_targets.get("target", [])
        for target_rule in target_rules:
            target_name = target_rule.get("name")
            if not target_name:
                continue
                
            source_pkg = self.parse_target_name(target_name)
            if not source_pkg:
                continue
                
            # Get dependencies for this target
            deps_result = self.get_target_deps(target_name)
            if not deps_result:
                continue
                
            # Process each dependency
            for dep_rule in deps_result.get("target", []):
                dep_name = dep_rule.get("name")
                if not dep_name:
                    continue
                    
                target_pkg = self.parse_target_name(dep_name)
                if not target_pkg or target_pkg == source_pkg:
                    continue
                    
                # Only track dependencies between Alpha Dot Five packages
                if target_pkg in self.valid_dependencies or target_pkg == "UmbraCoreTypes":
                    package_deps[source_pkg].add(target_pkg)
        
        # Validate dependencies
        invalid_deps = []
        for source_pkg, deps in package_deps.items():
            for target_pkg in deps:
                if not self.is_dependency_valid(source_pkg, target_pkg):
                    invalid_deps.append((source_pkg, target_pkg))
        
        # Print results
        if invalid_deps:
            print("\n❌ Invalid dependencies found:")
            for source, target in invalid_deps:
                print(f"  • {source} depends on {target}")
                print(f"    This violates the Alpha Dot Five dependency rules.")
                print(f"    Valid dependencies for {source} are:")
                if source in self.valid_dependencies:
                    for valid_dep in self.valid_dependencies[source]:
                        print(f"      - {valid_dep}")
                print()
            print(f"Total invalid dependencies: {len(invalid_deps)}")
            return False
        else:
            print("\n✅ All dependencies conform to Alpha Dot Five structure.")
            return True
    
    def generate_dependency_graph(self, output_file=None):
        """Generate a visual dependency graph using Graphviz DOT format."""
        # Get all targets in packages directory
        all_targets = self.get_all_package_targets()
        if not all_targets:
            print("No targets found in packages directory")
            return
            
        # Store dependencies by package
        package_deps = defaultdict(set)
        
        # Process each target
        target_rules = all_targets.get("target", [])
        for target_rule in target_rules:
            target_name = target_rule.get("name")
            if not target_name:
                continue
                
            source_pkg = self.parse_target_name(target_name)
            if not source_pkg:
                continue
                
            # Get dependencies for this target
            deps_result = self.get_target_deps(target_name)
            if not deps_result:
                continue
                
            # Process each dependency
            for dep_rule in deps_result.get("target", []):
                dep_name = dep_rule.get("name")
                if not dep_name:
                    continue
                    
                target_pkg = self.parse_target_name(dep_name)
                if not target_pkg or target_pkg == source_pkg:
                    continue
                    
                # Only track dependencies between Alpha Dot Five packages
                if target_pkg in self.valid_dependencies or target_pkg == "UmbraCoreTypes":
                    package_deps[source_pkg].add(target_pkg)
        
        # Generate DOT file content
        dot_content = "digraph Dependencies {\n"
        dot_content += "  rankdir=LR;\n"
        dot_content += "  node [shape=box, style=filled, fillcolor=lightblue];\n"
        
        # Add nodes with different colors based on package type
        for pkg in set([pkg for pkg in package_deps.keys()] + [dep for deps in package_deps.values() for dep in deps]):
            color = "lightblue"
            if pkg == "UmbraCoreTypes":
                color = "lightgreen"
            elif pkg == "UmbraErrorKit":
                color = "lightyellow"
            elif pkg == "UmbraInterfaces":
                color = "lightcoral"
            
            dot_content += f'  "{pkg}" [fillcolor={color}];\n'
        
        # Add edges
        for source, targets in package_deps.items():
            for target in targets:
                # Color invalid dependencies red
                if self.is_dependency_valid(source, target):
                    dot_content += f'  "{source}" -> "{target}";\n'
                else:
                    dot_content += f'  "{source}" -> "{target}" [color=red, penwidth=2.0];\n'
        
        dot_content += "}\n"
        
        # Write to file or stdout
        if output_file:
            with open(output_file, 'w') as f:
                f.write(dot_content)
            print(f"Dependency graph written to {output_file}")
            print("To generate a PNG, run: dot -Tpng -o dependencies.png", output_file)
        else:
            print(dot_content)
        
        return dot_content


def main():
    parser = argparse.ArgumentParser(description="Analyze and validate Bazel dependencies for Alpha Dot Five")
    parser.add_argument("--workspace", default=os.getcwd(), help="Workspace root directory")
    parser.add_argument("--packages", default="packages", help="Packages directory relative to workspace")
    parser.add_argument("--graph", help="Generate dependency graph and save to specified file")
    
    args = parser.parse_args()
    
    analyzer = DependencyAnalyzer(args.workspace, args.packages)
    result = analyzer.analyze_dependencies()
    
    if args.graph:
        analyzer.generate_dependency_graph(args.graph)
    
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
