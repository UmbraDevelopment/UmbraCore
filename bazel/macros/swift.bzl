"""
Swift macros for UmbraCore build system.
"""

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")
load("//tools/swift:compiler_options.bzl", "get_swift_copts")

def umbra_swift_library(
        name,
        srcs,
        deps = [],
        testonly = False,
        additional_copts = [],
        swift_mode = "default",
        enable_library_evolution = True,
        **kwargs):
    """Standard Swift library configuration for UmbraCore.

    Args:
        name: Target name
        srcs: Source files
        deps: Dependencies
        testonly: Whether this is a test-only library
        additional_copts: Additional compiler options
        swift_mode: Swift compilation mode ("default", "release", or "debug")
        enable_library_evolution: Whether to enable library evolution for this module
        **kwargs: Additional arguments to pass to swift_library
    """
    copts = get_swift_copts(swift_mode, enable_library_evolution) + additional_copts

    # Handle empty source files gracefully by creating a placeholder filegroup
    # when no source files are found
    if not srcs:
        # Create an empty filegroup as a placeholder when no sources exist
        native.filegroup(
            name = name,
            srcs = [],
            testonly = testonly,
            visibility = ["//visibility:public"],
        )
    else:
        swift_library(
            name = name,
            srcs = srcs,
            copts = copts,
            module_name = name,
            testonly = testonly,
            visibility = ["//visibility:public"],
            deps = deps,
            **kwargs
        )

def umbra_test_library(
        name,
        srcs,
        deps = [],
        additional_copts = [],
        **kwargs):
    """Standard Swift test library configuration for UmbraCore.

    Args:
        name: Target name
        srcs: Source files
        deps: Dependencies
        additional_copts: Additional compiler options
        **kwargs: Additional arguments to pass to swift_library
    """
    umbra_swift_library(
        name = name,
        srcs = srcs,
        deps = deps,
        testonly = True,
        additional_copts = additional_copts + ["-enable-testing"],
        swift_mode = "debug",
        **kwargs
    )

def umbra_swift_test(
        name,
        srcs,
        deps = [],
        data = [],
        copts = [],
        swiftc_inputs = [],
        env = {},
        tags = [],
        **kwargs):
    """A macro that creates a Swift test target with UmbraCore-specific configuration.

    Args:
        name: Name of the test target.
        srcs: Source files to compile.
        deps: Dependencies of the test target.
        data: Data files required by the test.
        copts: Additional compiler options.
        swiftc_inputs: Additional inputs to swiftc.
        env: Environment variables for the test.
        tags: Tags for the test target.
        **kwargs: Additional arguments to pass to swift_test.
    """

    # Get compiler options for tests
    test_copts = get_swift_copts("debug") + ["-enable-testing"] + copts

    # Base environment variables for Swift tests
    base_env = {
        "MACOS_DEPLOYMENT_TARGET": "14.7.4",  # Updated from 15.4 to match project minimum
        "SWIFT_DETERMINISTIC_HASHING": "1",
        "DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer",
    }

    # Merge the base environment with any provided environment variables
    test_env = dict(base_env)
    test_env.update(env)

    # Create the Swift test target
    swift_test(
        name = name,
        srcs = srcs,
        deps = deps,
        data = data,
        copts = test_copts,
        swiftc_inputs = swiftc_inputs,
        env = test_env,
        target_compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:arm64",
        ],
        tags = tags,
        **kwargs
    )
