"""
Swift rules for UmbraCore.
"""

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary", "swift_library", "swift_test")

def umbra_swift_library(name, srcs = [], deps = [], visibility = None, testonly = None, swiftc_opts = None, **kwargs):
    """
    A wrapper around swift_library that sets appropriate defaults for the UmbraCore project.

    Args:
        name: The name of the target.
        srcs: Source files to compile.
        deps: Dependencies.
        visibility: Visibility specification.
        testonly: Whether this target is for tests only.
        swiftc_opts: Additional Swift compiler options.
        **kwargs: Additional arguments to pass to swift_library.
    """

    # Handle empty source files gracefully by creating a placeholder filegroup
    if not srcs:
        # Create an empty filegroup as a placeholder when no sources exist
        native.filegroup(
            name = name,
            srcs = [],
            testonly = testonly,
            visibility = visibility if visibility != None else ["//visibility:public"],
        )
    else:
        # Define default compiler options
        default_copts = ["-strict-concurrency=complete"]

        # Add user-provided compiler options if any
        if swiftc_opts:
            default_copts.extend(swiftc_opts)

        swift_library(
            name = name,
            srcs = srcs,
            deps = deps,
            visibility = visibility if visibility != None else ["//visibility:public"],
            testonly = testonly,
            module_name = name,
            copts = default_copts,
            **kwargs
        )

def umbra_swift_test(name, srcs = [], deps = [], visibility = None, **kwargs):
    """
    A wrapper around swift_test that sets appropriate defaults for the UmbraCore project.

    Args:
        name: The name of the target.
        srcs: Source files to compile.
        deps: Dependencies.
        visibility: Visibility specification.
        **kwargs: Additional arguments to pass to swift_test.
    """
    swift_test(
        name = name,
        srcs = srcs,
        deps = deps,
        visibility = visibility if visibility != None else ["//visibility:public"],
        **kwargs
    )
