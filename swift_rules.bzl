"""
Swift rules for UmbraCore.
"""

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary", "swift_library", "swift_test")

def umbra_swift_library(name, srcs = [], deps = [], visibility = None, testonly = None, **kwargs):
    """
    A wrapper around swift_library that sets appropriate defaults for the UmbraCore project.
    
    Args:
        name: The name of the target.
        srcs: Source files to compile.
        deps: Dependencies.
        visibility: Visibility specification.
        testonly: Whether this target is for tests only.
        **kwargs: Additional arguments to pass to swift_library.
    """
    swift_library(
        name = name,
        srcs = srcs,
        deps = deps,
        visibility = visibility if visibility != None else ["//visibility:public"],
        testonly = testonly,
        module_name = name,
        copts = ["-strict-concurrency=complete"],
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
        copts = ["-strict-concurrency=complete"],
        **kwargs
    )
