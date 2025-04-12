# Swift compiler options for the project
# These are centralised here for consistency across all targets

load("//tools/swift:build_settings.bzl", 
     "get_swift_defines", 
     "UMBRA_ENV_DEBUG", 
     "UMBRA_ENV_DEVELOPMENT", 
     "UMBRA_ENV_ALPHA", 
     "UMBRA_ENV_BETA", 
     "UMBRA_ENV_PRODUCTION",
     "UMBRA_BACKEND_RESTIC",
     "UMBRA_BACKEND_RING_FFI",
     "UMBRA_BACKEND_APPLE_CK")

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

# Swift 6 mode options (enabled for all builds)
SWIFT_6_MODE_OPTIONS = [
    "-swift-version", "6",
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
BASE_SWIFT_COPTS = PLATFORM_OPTIONS + CONCURRENCY_SAFETY_OPTIONS + SWIFT_6_PREP_OPTIONS + SWIFT_6_MODE_OPTIONS

# All swift compile options for standard builds with library evolution
DEFAULT_SWIFT_COPTS = BASE_SWIFT_COPTS + LIBRARY_EVOLUTION_OPTIONS

# Release build options
RELEASE_SWIFT_COPTS = DEFAULT_SWIFT_COPTS + OPTIMIZATION_OPTIONS

# Debug build options
DEBUG_SWIFT_COPTS = DEFAULT_SWIFT_COPTS + DEBUG_OPTIONS

def get_environment_defines(env_type, backend_strategy = None):
    """Returns the Swift compiler define flags for the specified environment and backend strategy.
    
    Args:
        env_type: The environment type (debug, development, alpha, beta, production)
        backend_strategy: Optional backend strategy override
        
    Returns:
        List of Swift compiler define flags
    """
    defines = get_swift_defines(env_type = env_type, backend_strategy = backend_strategy)
    return ["-D" + define for define in defines]

def get_swift_copts(mode = "default", enable_library_evolution = True, env_type = None, backend_strategy = None):
    """Returns the appropriate Swift compiler options based on the build mode and environment settings.

    Args:
        mode: Build mode ("default", "release", or "debug")
        enable_library_evolution: Whether to enable library evolution support
        env_type: Optional environment type (debug, development, alpha, beta, production)
        backend_strategy: Optional backend strategy (restic, ringFFI, appleCK)

    Returns:
        List of Swift compiler options
    """
    # Determine the base compiler options based on mode
    if mode == "release":
        copts = BASE_SWIFT_COPTS + OPTIMIZATION_OPTIONS
        # Default to production environment for release builds if not specified
        effective_env = env_type or UMBRA_ENV_PRODUCTION
    elif mode == "debug":
        copts = BASE_SWIFT_COPTS + DEBUG_OPTIONS
        # Default to debug environment for debug builds if not specified
        effective_env = env_type or UMBRA_ENV_DEBUG
    else:
        copts = BASE_SWIFT_COPTS
        # Default to development environment for other builds if not specified
        effective_env = env_type or UMBRA_ENV_DEVELOPMENT

    # Add library evolution options if enabled
    if enable_library_evolution:
        copts = copts + LIBRARY_EVOLUTION_OPTIONS
    
    # Add environment and backend strategy define flags
    copts = copts + get_environment_defines(effective_env, backend_strategy)
    
    return copts

def get_debug_swift_copts(enable_library_evolution = True):
    """Returns Swift compiler options for debug builds.
    
    Args:
        enable_library_evolution: Whether to enable library evolution support
        
    Returns:
        List of Swift compiler options for debug builds
    """
    return get_swift_copts(
        mode = "debug", 
        enable_library_evolution = enable_library_evolution,
        env_type = UMBRA_ENV_DEBUG
    )

def get_development_swift_copts(enable_library_evolution = True):
    """Returns Swift compiler options for development builds.
    
    Args:
        enable_library_evolution: Whether to enable library evolution support
        
    Returns:
        List of Swift compiler options for development builds
    """
    return get_swift_copts(
        mode = "default", 
        enable_library_evolution = enable_library_evolution,
        env_type = UMBRA_ENV_DEVELOPMENT
    )

def get_alpha_swift_copts(enable_library_evolution = True):
    """Returns Swift compiler options for alpha testing builds.
    
    Args:
        enable_library_evolution: Whether to enable library evolution support
        
    Returns:
        List of Swift compiler options for alpha testing builds
    """
    return get_swift_copts(
        mode = "default", 
        enable_library_evolution = enable_library_evolution,
        env_type = UMBRA_ENV_ALPHA
    )

def get_beta_swift_copts(enable_library_evolution = True):
    """Returns Swift compiler options for beta testing builds.
    
    Args:
        enable_library_evolution: Whether to enable library evolution support
        
    Returns:
        List of Swift compiler options for beta testing builds
    """
    return get_swift_copts(
        mode = "release", 
        enable_library_evolution = enable_library_evolution,
        env_type = UMBRA_ENV_BETA
    )

def get_production_swift_copts(enable_library_evolution = True):
    """Returns Swift compiler options for production builds.
    
    Args:
        enable_library_evolution: Whether to enable library evolution support
        
    Returns:
        List of Swift compiler options for production builds
    """
    return get_swift_copts(
        mode = "release", 
        enable_library_evolution = enable_library_evolution,
        env_type = UMBRA_ENV_PRODUCTION
    )
