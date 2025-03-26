# Swift compiler options for the project
# These are centralised here for consistency across all targets

# Library evolution options
LIBRARY_EVOLUTION_OPTIONS = [
    "-enable-library-evolution",
]

# Swift 6 preparation options
SWIFT_6_PREP_OPTIONS = [
    # Commenting out Swift 6 preparation flags that are causing issues
    # "-enable-upcoming-feature", "Isolated",
    # "-enable-upcoming-feature", "ExistentialAny",
    # "-enable-upcoming-feature", "StrictConcurrency",
    # "-enable-upcoming-feature", "InternalImportsByDefault",
    # "-warn-swift-5-to-swift-6-path",
]

# Concurrency safety options
CONCURRENCY_SAFETY_OPTIONS = [
    "-strict-concurrency=complete",
    "-enable-actor-data-race-checks",
    "-warn-concurrency",
]

# Target platform options
PLATFORM_OPTIONS = [
    "-target",
    "arm64-apple-macos14.7.4",
]

# Performance optimization options for release builds
OPTIMIZATION_OPTIONS = [
    "-O",
    "-whole-module-optimization",
]

# Debug options
DEBUG_OPTIONS = [
    "-g",
    "-Onone",
]

# Base swift compile options without library evolution
BASE_SWIFT_COPTS = PLATFORM_OPTIONS + CONCURRENCY_SAFETY_OPTIONS + SWIFT_6_PREP_OPTIONS

# All swift compile options for standard builds with library evolution
DEFAULT_SWIFT_COPTS = BASE_SWIFT_COPTS + LIBRARY_EVOLUTION_OPTIONS

# Release build options
RELEASE_SWIFT_COPTS = DEFAULT_SWIFT_COPTS + OPTIMIZATION_OPTIONS

# Debug build options
DEBUG_SWIFT_COPTS = DEFAULT_SWIFT_COPTS + DEBUG_OPTIONS

def get_swift_copts(mode = "default", enable_library_evolution = True):
    """Returns the appropriate Swift compiler options based on the build mode.

    Args:
        mode: Build mode ("default", "release", or "debug")
        enable_library_evolution: Whether to enable library evolution support

    Returns:
        List of Swift compiler options
    """
    if mode == "release":
        copts = BASE_SWIFT_COPTS + OPTIMIZATION_OPTIONS
    elif mode == "debug":
        copts = BASE_SWIFT_COPTS + DEBUG_OPTIONS
    else:
        copts = BASE_SWIFT_COPTS

    if enable_library_evolution:
        copts = copts + LIBRARY_EVOLUTION_OPTIONS

    return copts
