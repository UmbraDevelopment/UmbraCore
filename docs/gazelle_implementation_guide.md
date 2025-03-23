# Implementing Gazelle for UmbraCore Project

## Overview

This document outlines the implementation plan for incorporating Gazelle into the UmbraCore project to manage BUILD files more effectively. Gazelle offers a superior alternative to shell scripts for BUILD file generation and management, providing automatic, consistent, and scalable build configuration.

## What is Gazelle?

Gazelle is a Bazel build file generator that:

- Creates and updates BUILD.bazel files automatically based on source code
- Natively supports multiple languages through extensions
- Manages dependencies intelligently
- Provides consistent, error-free BUILD files
- Integrates well with the Bazel ecosystem

## Swift Support with Rules Swift Package Manager

For Swift projects like UmbraCore, the [rules_swift_package_manager](https://github.com/cgrindel/rules_swift_package_manager) extension provides:

- Swift-specific support for generating `swift_library`, `swift_binary`, and `swift_test` rules
- Integration with Swift Package Manager for dependency management
- Automatic BUILD file generation based on Swift code structure
- Facilities for resolving, downloading, and building external Swift packages

## Implementation Plan

### 1. Initial Setup

Add the necessary dependencies to your WORKSPACE file:

```python
# In your WORKSPACE file
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Add rules_swift dependency
http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "...", # Use appropriate sha
    url = "https://github.com/bazelbuild/rules_swift/releases/download/[VERSION]/rules_swift.[VERSION].tar.gz",
)

# Add Gazelle dependency
http_archive(
    name = "bazel_gazelle",
    sha256 = "...", # Use appropriate sha
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/v[VERSION]/bazel-gazelle-v[VERSION].tar.gz",
)

# Add rules_swift_package_manager
http_archive(
    name = "cgrindel_rules_swift_package_manager",
    sha256 = "...", # Use appropriate sha
    url = "https://github.com/cgrindel/rules_swift_package_manager/releases/download/v[VERSION]/rules_swift_package_manager.[VERSION].tar.gz",
)

# Load dependencies
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@cgrindel_rules_swift_package_manager//:deps.bzl", "swift_gazelle_dependencies")

# Initialize dependencies
gazelle_dependencies()
swift_gazelle_dependencies()
```

### 2. Create Root Gazelle Configuration

Add this to your root BUILD.bazel file:

```python
load("@bazel_gazelle//:def.bzl", "gazelle")

# gazelle:prefix dev.mpy.UmbraCore
gazelle(name = "gazelle")

# Create verification test
load("@bazel_gazelle//:def.bzl", "gazelle_test")
gazelle_test(
    name = "gazelle_test",
    workspace = "//:BUILD.bazel",
)
```

### 3. Integration with SwiftLint and SwiftFormat

Create a unified workflow that combines all three tools:

```python
# In your root BUILD.bazel file
sh_binary(
    name = "lint_and_format",
    srcs = ["tools/lint_and_format.sh"],
    data = [
        "@com_github_realm_swiftlint//:swiftlint",
        "@com_github_nicklockwood_swiftformat//:swiftformat",
    ],
)
```

With a small shell script (under 30 lines as per project guidelines) to orchestrate the process:

```bash
#!/bin/bash
# tools/lint_and_format.sh

# Run swiftformat
swiftformat .

# Run swiftlint
swiftlint autocorrect
swiftlint

# Run gazelle to update BUILD files
bazel run //:gazelle
```

### 4. CI Integration

Add a CI verification step to ensure BUILD files are up-to-date:

```yaml
# In your CI config
- name: Verify BUILD files
  run: bazel test //:gazelle_test
```

## Fixing Current BUILD Files

To fix the immediate issues with the BUILD files:

```bash
# Run gazelle to fix existing BUILD files
bazel run //:gazelle -- fix
```

This will address the syntax errors in your test BUILD.bazel files and provide a clean baseline for future development.

## Gazelle Directives for Swift Projects

Gazelle can be controlled through directives in your BUILD files. Here are some useful directives for Swift projects:

```
# Set the import path prefix for your repository
# gazelle:prefix dev.mpy.UmbraCore

# Exclude files or directories from Gazelle processing
# gazelle:exclude path/to/exclude

# Define custom resolve rules for imports
# gazelle:resolve swift swift UIKit @rules_apple//apple:foo
```

## Benefits Over Shell Scripts

1. **Automatic Dependency Management**
   - Gazelle automatically detects imports and adds appropriate dependencies
   - Eliminates manual tracking of dependencies between targets

2. **Consistency**
   - Generated BUILD files follow a consistent pattern
   - Eliminates syntax errors like those currently seen in test BUILD files
   - Maintains standard formatting across the project

3. **Scalability**
   - As your codebase grows, Gazelle scales much better than shell scripts
   - Handles complex dependency graphs without additional complexity

4. **Language-Aware**
   - The Swift extension understands Swift-specific constructs
   - Makes intelligent decisions about target types (library vs. binary vs. test)
   - Handles Swift-specific considerations like access modifiers

5. **Integration**
   - Works well with other tools in the Bazel ecosystem
   - Provides a solid foundation for CI/CD pipelines

## Best Practices

1. **Start Small**
   - Begin by implementing Gazelle for a single module to understand its behaviour
   - Gradually expand to cover the entire codebase

2. **Document Conventions**
   - Create documentation explaining your Gazelle directives and BUILD file patterns
   - Standardise on naming conventions for targets

3. **Team Training**
   - Ensure everyone understands the workflow with Gazelle
   - Provide examples of common operations (adding new files, resolving dependencies)

4. **Code Organisation**
   - Use Python for complex tasks beyond Gazelle's capabilities
   - Keep automation scripts focused and small (under 30 lines for shell scripts)

5. **Verification**
   - Use `gazelle_test` to ensure generated files are correct before committing
   - Include BUILD file verification in code reviews

## Conclusion

Implementing Gazelle for the UmbraCore project will significantly improve the BUILD file management process, leading to fewer errors, more consistent build definitions, and better scalability. By replacing complex shell scripts with a purpose-built tool, the team can focus more on feature development and less on build system maintenance.

For ongoing updates and more Gazelle extensions, see the [official Gazelle repository](https://github.com/bazel-contrib/bazel-gazelle).
