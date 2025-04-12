"""
Build settings for UmbraCore.
"""

BuildEnvironmentInfo = provider(
    doc = "Information about the current build environment",
    fields = {
        "is_local": "Boolean indicating whether this is a local build",
        "env_type": "Environment type (debug, development, alpha, beta, production)",
        "backend_strategy": "Backend strategy (restic, ringFFI, appleCK)",
    },
)

def _build_environment_impl(ctx):
    return [BuildEnvironmentInfo(
        is_local = ctx.attr.is_local,
        env_type = ctx.attr.env_type,
        backend_strategy = ctx.attr.backend_strategy,
    )]

build_environment = rule(
    implementation = _build_environment_impl,
    attrs = {
        "is_local": attr.bool(default = False),
        "env_type": attr.string(default = "development"),
        "backend_strategy": attr.string(default = "restic"),
    },
)

# Environment types supported by UmbraCore
UMBRA_ENV_DEBUG = "debug"
UMBRA_ENV_DEVELOPMENT = "development"
UMBRA_ENV_ALPHA = "alpha"
UMBRA_ENV_BETA = "beta"
UMBRA_ENV_PRODUCTION = "production"

# Backend strategies supported by UmbraCore
UMBRA_BACKEND_RESTIC = "restic"
UMBRA_BACKEND_RING_FFI = "ringFFI"
UMBRA_BACKEND_APPLE_CK = "appleCK"

def get_swift_defines_for_environment(env_type, backend_strategy):
    """
    Returns Swift define flags for the specified environment type and backend strategy.
    
    Args:
        env_type: The environment type (debug, development, alpha, beta, production)
        backend_strategy: The backend strategy (restic, ringFFI, appleCK)
    
    Returns:
        A list of Swift define flags.
    """
    defines = []
    
    # Add environment-specific defines
    if env_type == UMBRA_ENV_DEBUG:
        defines.append("DEBUG=1")
    elif env_type == UMBRA_ENV_DEVELOPMENT:
        defines.append("DEVELOPMENT=1")
    elif env_type == UMBRA_ENV_ALPHA:
        defines.append("ALPHA=1")
    elif env_type == UMBRA_ENV_BETA:
        defines.append("BETA=1")
    else:
        # Default to production
        defines.append("PRODUCTION=1")
    
    # Add backend strategy defines
    if backend_strategy == UMBRA_BACKEND_RING_FFI:
        defines.append("BACKEND_RING_FFI=1")
    elif backend_strategy == UMBRA_BACKEND_APPLE_CK:
        defines.append("BACKEND_APPLE_CRYPTOKIT=1")
    else:
        # Default to restic
        defines.append("BACKEND_RESTIC=1")
    
    return defines

def get_default_swift_defines():
    """
    Returns the default Swift define flags for development builds.
    """
    return get_swift_defines_for_environment(
        env_type = UMBRA_ENV_DEVELOPMENT,
        backend_strategy = UMBRA_BACKEND_RESTIC,
    )

def get_swift_defines(env_type = None, backend_strategy = None):
    """
    Returns Swift define flags for the specified or default environment.
    
    Args:
        env_type: Optional environment type
        backend_strategy: Optional backend strategy
        
    Returns:
        A list of Swift define flags.
    """
    effective_env = env_type or UMBRA_ENV_DEVELOPMENT
    effective_backend = backend_strategy or UMBRA_BACKEND_RESTIC
    
    return get_swift_defines_for_environment(
        env_type = effective_env,
        backend_strategy = effective_backend,
    )
