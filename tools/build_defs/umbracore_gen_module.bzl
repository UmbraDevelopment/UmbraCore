"""
UmbraCore module generator rule.

This rule provides a way to generate new Foundation-free modules with the standard directory structure
in accordance with the UmbraCore refactoring plan.
"""

def _umbracore_gen_module_impl(ctx):
    module_name = ctx.attr.module_name
    
    # Create a Python script that generates the module structure
    script_content = """
#!/usr/bin/env python3
import os
import sys

def create_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"Created {path}")

def main():
    module_name = "{module_name}"
    module_path = f"Sources/{{module_name}}"
    
    # Create directory structure
    os.makedirs(f"{{module_path}}/Sources", exist_ok=True)
    os.makedirs(f"{{module_path}}/Tests", exist_ok=True)
    
    # Create BUILD.bazel file
    build_content = '''load("//tools/build_defs:umbracore_module.bzl", "umbracore_foundation_free_module", "umbracore_test_module")

umbracore_foundation_free_module(
    name = "{module_name}",
    visibility = ["//visibility:public"],
    deps = [
        # Add foundation-free dependencies here
    ],
)

umbracore_test_module(
    name = "{module_name}Tests",
    deps = [
        ":{module_name}",
        # Add test dependencies here
    ],
)
'''
    
    # Create sample source file
    source_content = '''// {module_name}.swift
// {module_name}
//
// Created as part of the UmbraCore Foundation Decoupling project
//

/// Primary entry point for the {module_name} module.
/// This module is designed to be fully Foundation-free.
public enum {module_name} {{
    /// Module version
    public static let version = "1.0.0"
}}
'''
    
    # Create sample test file
    test_content = '''// {module_name}Tests.swift
// {module_name}
//
// Created as part of the UmbraCore Foundation Decoupling project
//

import XCTest
@testable import {module_name}

class {module_name}Tests: XCTestCase {{
    
    func testVersion() {{
        XCTAssertFalse({module_name}.version.isEmpty)
    }}
}}
'''

    # Write the files
    create_file(f"{{module_path}}/BUILD.bazel", build_content)
    create_file(f"{{module_path}}/Sources/{{module_name}}.swift", source_content)
    create_file(f"{{module_path}}/Tests/{{module_name}}Tests.swift", test_content)
    
    print(f"\\nCreated {{module_name}} module at {{module_path}}")
    print("• Module structure:")
    print(f"  - {{module_path}}/BUILD.bazel")
    print(f"  - {{module_path}}/Sources/{{module_name}}.swift")
    print(f"  - {{module_path}}/Tests/{{module_name}}Tests.swift")
    print("\\nNext steps:")
    print(f"1. Add your core types to {{module_path}}/Sources/")
    print(f"2. Add tests to {{module_path}}/Tests/")
    print(f"3. Update dependencies in {{module_path}}/BUILD.bazel if needed")

if __name__ == "__main__":
    main()
    """.format(
        module_name = module_name,
    )
    
    # Create the generator script
    script_file = ctx.actions.declare_file(ctx.label.name + ".py")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    # Create a wrapper script that executes the Python script
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(
        output = executable,
        content = "#!/bin/bash\npython3 $RUNFILES/{script_path}".format(
            script_path = script_file.short_path,
        ),
        is_executable = True,
    )
    
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles([script_file]),
    )]

umbracore_gen_module = rule(
    implementation = _umbracore_gen_module_impl,
    attrs = {
        "module_name": attr.string(
            mandatory = True,
            doc = "Name of the module to create",
        ),
    },
    executable = True,
)

def create_gen_module_target(name, **kwargs):
    """Creates a target to generate a new UmbraCore module.
    
    Args:
        name: Name of the target.
        **kwargs: Additional arguments to pass to the umbracore_gen_module rule.
    """
    umbracore_gen_module(
        name = name,
        **kwargs
    )
