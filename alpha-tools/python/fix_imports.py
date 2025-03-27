#!/usr/bin/env python3
"""
Script to find and fix circular imports in the migrated UmbraCore modules.
"""
import os
import argparse
import re
import glob


def fix_imports(directory_path, module_name):
    """Find and fix circular imports in Swift files.
    
    Args:
        directory_path: Directory to search for Swift files
        module_name: Module name to look for in imports
    """
    print(f"Fixing imports in {directory_path} for module {module_name}")
    
    # Find all Swift files recursively
    swift_files = glob.glob(os.path.join(directory_path, "**/*.swift"), recursive=True)
    
    # Process each file
    for file_path in swift_files:
        with open(file_path, 'r') as file:
            content = file.read()
        
        # Check if the file imports the module
        if re.search(r'import\s+' + re.escape(module_name) + r'\b', content):
            print(f"  Found circular import in {os.path.relpath(file_path, directory_path)}")
            
            # Replace the import statement
            new_content = re.sub(r'import\s+' + re.escape(module_name) + r'\b\n+', '', content)
            
            # Write the modified content back
            with open(file_path, 'w') as file:
                file.write(new_content)
            
            print(f"  Fixed circular import in {os.path.relpath(file_path, directory_path)}")


def main():
    parser = argparse.ArgumentParser(description="Fix circular imports in Swift files")
    parser.add_argument("directory", help="Directory to process")
    parser.add_argument("module", help="Module name to look for in imports")
    
    args = parser.parse_args()
    
    fix_imports(args.directory, args.module)
    print(f"Import fixing completed for module {args.module}")


if __name__ == "__main__":
    main()
