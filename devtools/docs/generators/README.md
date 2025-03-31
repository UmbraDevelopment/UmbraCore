# DocC Documentation in UmbraCore

This directory contains the tools and rules for generating and serving DocC documentation for Swift modules in UmbraCore.

## Overview

DocC (Documentation Compiler) is Apple's tool for creating rich, interactive documentation for Swift code. This integration enables UmbraCore to generate and serve DocC documentation as part of the Bazel build system.

## Directory Structure

For a module to support DocC documentation, it should have the following structure:

```
Sources/YourModule/
  ├── Documentation.docc/
  │   ├── YourModule.md       # Main documentation page
  │   ├── Info.plist          # Optional configuration
  │   ├── Resources/          # Optional resources
  │   └── Tutorials/          # Optional tutorials
  ├── Sources/
  │   └── ...                 # Swift source files with DocC comments
  └── BUILD.bazel             # Build configuration
```

## Usage

### Generating Documentation

To generate documentation for a module:

```bash
bazel build //Sources/YourModule:YourModuleDocC
```

This will create a `.doccarchive` file in the Bazel output directory.

### Serving Documentation

To serve the documentation over HTTP:

```bash
bazel run //Sources/YourModule:serve_docs
```

This will start a local web server on port 8080. You can then access the documentation by opening http://localhost:8080 in your web browser.

### Previewing Documentation

To preview the documentation with DocC's native preview tool (if available):

```bash
bazel run //Sources/YourModule:preview_docs
```

This will attempt to open the documentation in Xcode's DocC preview interface or, if not available, serve it via a local web server.

## Customisation

### Adding DocC Support to a Module

To add DocC support to a Swift module, add the following to your `BUILD.bazel` file:

```python
load("//tools/swift:docc_rules.bzl", "docc_documentation")

docc_documentation(
    name = "YourModuleDocC",
    module_name = "YourModule",
    srcs = glob([
        "Documentation.docc/**/*.md",
        "Documentation.docc/**/*.docc",
        "Documentation.docc/**/*.plist",
        "Sources/**/*.swift",
    ]),
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "serve_docs",
    srcs = ["//tools/swift:serve_docc.sh"],
    args = ["$(location :YourModuleDocC)"],
    data = [":YourModuleDocC"],
)

sh_binary(
    name = "preview_docs",
    srcs = ["//tools/swift:preview_docc.sh"],
    args = ["$(location :YourModuleDocC)"],
    data = [":YourModuleDocC"],
)
```

## Troubleshooting

If you encounter issues with DocC documentation generation or serving:

1. Ensure all necessary source files are included in the `srcs` attribute of the `docc_documentation` rule.
2. Check that the DocC archive was built successfully by examining the Bazel build output.
3. If the documentation server fails to start, check that the port (8080) is not already in use.
4. For preview issues, ensure Xcode and its command-line tools are installed correctly.

## References

- [Apple's DocC Documentation](https://developer.apple.com/documentation/docc)
- [Swift-DocC GitHub Repository](https://github.com/apple/swift-docc)
