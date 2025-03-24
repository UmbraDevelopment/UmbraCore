# Gazelle Swift Extension

This extension adds Swift language support to [Gazelle](https://github.com/bazelbuild/bazel-gazelle), addressing common issues when working with Swift in Bazel:

- **Empty or missing srcs attributes** - Detects and fixes issues with empty glob patterns
- **Glob pattern handling** - Enforces consistent glob patterns for Swift files
- **Nested Swift files** - Properly handles Swift files in nested module directories
- **Visibility issues** - Configures appropriate visibility for Swift targets
- **External dependencies** - Handles common external dependencies like 'swiftpkg_xctest' and 'CryptoSwift'

## Setup

### 1. Add to your WORKSPACE

Add the following to your `WORKSPACE` file:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# Add Gazelle dependencies if not already present
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "80a98277ad1311dacd837f9b16db62887702e9f1d1c4c9f796d0121a46c8e184",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.46.0/rules_go-v0.46.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.46.0/rules_go-v0.46.0.zip",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "32938bda16e6700063035479063d9d24c60eda8d79fd4739563f50d331cb3209",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.34.0/bazel-gazelle-v0.34.0.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.34.0/bazel-gazelle-v0.34.0.tar.gz",
    ],
)

# Add the Swift Gazelle extension
local_repository(
    name = "gazelle_swift",
    path = "gazelle-swift",  # Update this path if placed elsewhere
)

# Load Go rules
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.21.3")

# Load Gazelle
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()
```

### 2. Update your root BUILD.bazel file

Replace your existing Gazelle rule with the following:

```starlark
load("@bazel_gazelle//:def.bzl", "gazelle")
load("@gazelle_swift//:def.bzl", "GAZELLE_SWIFT_BINARY")

# gazelle:prefix github.com/umbracore/project
gazelle(
    name = "gazelle",
    gazelle = GAZELLE_SWIFT_BINARY,
)
```

## Configuration Options

Use the following directives in your BUILD.bazel files to customize Swift Gazelle behavior:

### Basic Swift Configuration

```starlark
# gazelle:swift_srcs_glob_pattern **/*.swift    # Default glob pattern for Swift source files
# gazelle:swift_visibility //visibility:public  # Default visibility for Swift targets
# gazelle:swift_empty_srcs_allow true           # Whether to allow empty srcs (default false)
```

### External Dependencies

```starlark
# gazelle:swift_external_dep CryptoSwift=@CryptoSwift//:CryptoSwift  # Map dependency name to label
# gazelle:swift_external_dep swiftpkg_xctest=@swiftpkg_xctest//:SwiftPkg  # For XCTest
```

### Module Configuration

```starlark
# gazelle:swift_module_map ModuleName=//path/to:target  # Map Swift module to Bazel target
```

### Fix empty glob patterns

This extension includes a fix for the issue with empty glob patterns in swift_library targets. 
It will automatically add proper glob patterns with `allow_empty` set appropriately.

```starlark
# gazelle:swift_fix_srcs all       # Fix all srcs attributes in Swift rules
# gazelle:swift_fix_srcs none      # Don't fix any srcs attributes
# gazelle:swift_fix_srcs Target1,Target2  # Only fix specified targets
```

## Usage

### Generate BUILD files

```bash
bazel run //:gazelle
```

### Fix Missing or Empty Glob Patterns

```bash
bazel run //:gazelle -- fix
```

### Update External Dependencies

```bash
bazel run //:gazelle -- update-repos -from_file=go.mod
```

## Examples

### Fixing empty srcs

If you have a BUILD.bazel file with:

```starlark
swift_library(
    name = "MyLibrary",
    visibility = ["//visibility:public"],
    deps = [
        "//Sources/OtherModule",
    ],
)
```

Running Gazelle will fix it to:

```starlark
swift_library(
    name = "MyLibrary",
    srcs = glob(
        ["**/*.swift"],
        allow_empty = True,  # Use False to catch missing files
    ),
    visibility = ["//visibility:public"],
    deps = [
        "//Sources/OtherModule",
    ],
)
```

### Adding XCTest dependencies

For test targets, the extension will automatically add XCTest dependencies:

```starlark
swift_test(
    name = "MyTests",
    srcs = glob(["**/*Tests.swift"]),
    deps = [
        "//Sources/MyModule",
        "@swiftpkg_xctest//:SwiftPkg",
    ],
)
```

## Common Issues

### Missing External Dependencies

If you're missing external dependencies like CryptoSwift, add them to your WORKSPACE file and use the `swift_external_dep` directive to map them.

### Empty or Missing srcs

This extension automatically fixes missing or empty srcs attributes. Run `bazel run //:gazelle -- fix` to update all BUILD files.

### Nested Swift Files Not Found

The extension configures glob patterns to recursively search for Swift files with `**/*.swift`. This handles nested directory structures properly.

## Troubleshooting

- **Gazelle doesn't find Swift files**: Ensure that your Swift files have the `.swift` extension and check the glob patterns.
- **Dependencies not resolved**: Make sure you've added all external repositories to your WORKSPACE file and defined swift_external_dep directives.
- **Visibility issues**: Set the default visibility using the swift_visibility directive in your root BUILD.bazel file.
