"""
UmbraCore module build rules to ensure consistent module structure.

These rules automate the creation of UmbraCore modules with the proper 
structure and dependencies according to our refactoring plan.
"""

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

def umbracore_foundation_free_module(
        name,
        srcs = None,
        deps = None,
        copts = None,
        visibility = None,
        testonly = None,
        additional_inputs = None):
    """Creates a Foundation-free UmbraCore module with standard structure.

    This macro generates a Swift library target that explicitly has no
    Foundation dependencies and follows the architecture defined in our
    refactoring plan.

    Args:
        name: Name of the module to create.
        srcs: Source files for the module. Defaults to all Swift files in Sources/.
        deps: Additional dependencies. Must be Foundation-free.
        copts: Compiler options.
        testonly: Whether this module is only used for testing.
        visibility: Visibility of the module. Defaults to public.
        additional_inputs: Additional input files to include in the module.
    """
    if srcs == None:
        srcs = native.glob(["Sources/**/*.swift"])

    if deps == None:
        deps = []

    if visibility == None:
        visibility = ["//visibility:public"]

    if copts == None:
        copts = [
            "-target",
            "arm64-apple-macos15.4",
            "-g",
            "-swift-version",
            "5",
        ]

    if additional_inputs == None:
        additional_inputs = []

    swift_library(
        name = name,
        srcs = srcs,
        module_name = name,
        deps = deps,
        copts = copts,
        visibility = visibility,
        testonly = testonly,
    )

def umbracore_foundation_independent_module(
        name,
        srcs = None,
        deps = None,
        copts = None,
        visibility = None,
        testonly = None):
    """
    Creates a Swift module that may use other modules but avoids Foundation dependencies.

    Args:
        name: Name of the module
        srcs: Source files
        deps: Dependencies (should be Foundation-independent)
        copts: Compiler options
        visibility: Visibility
        testonly: Whether this is a test-only target
    """
    if srcs == None:
        srcs = native.glob(["Sources/**/*.swift"])

    if deps == None:
        deps = []

    if copts == None:
        copts = [
            "-target",
            "arm64-apple-macos15.4",
            "-g",
            "-swift-version",
            "5",
        ]

    if visibility == None:
        visibility = ["//visibility:public"]

    swift_library(
        name = name,
        srcs = srcs,
        module_name = name,
        deps = deps,
        copts = copts,
        visibility = visibility,
        testonly = testonly,
    )

def umbracore_module_test(
        name,
        srcs = None,
        deps = None,
        copts = None,
        visibility = None):
    """
    Creates a test target for an UmbraCore module.

    Args:
        name: Name of the test module
        srcs: Test source files
        deps: Test dependencies
        copts: Compiler options
        visibility: Visibility
    """
    module_name = name.replace("Tests", "")

    # Create a testable version of the module
    swift_library(
        name = name,
        srcs = srcs if srcs != None else native.glob(["Tests/**/*.swift"]),
        module_name = name,
        testonly = True,
        deps = deps if deps != None else ["@{}_test//dependency:{}".format(module_name, module_name)],
        copts = copts if copts != None else ["-target", "arm64-apple-macos15.4", "-g", "-swift-version", "5"],
        visibility = visibility if visibility != None else ["//visibility:public"],
    )
