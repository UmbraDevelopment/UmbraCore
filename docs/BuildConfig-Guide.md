# UmbraCore BuildConfig System

## Overview

The BuildConfig system provides centralised configuration for UmbraCore, enabling consistent behaviour across different environments and backend integration scenarios. This guide explains how to use the BuildConfig system to control build settings and runtime behaviour.

## Key Components

### 1. Bazel Integration

The BuildConfig system integrates with Bazel to provide compiler-level configuration:

- **build_settings.bzl**: Defines environment types and backend strategies
- **compiler_options.bzl**: Sets Swift compiler flags based on environment
- **build_with_config.sh**: Helper script for building with specific configurations

### 2. Environment Types

UmbraCore supports five environment types:

| Environment | Description | Use Case |
|-------------|-------------|----------|
| Debug | Full logging, assertions enabled | Local development |
| Development | Enhanced logging | Internal testing |
| Alpha | Selected debug features | Early external testing |
| Beta | Minimal debug features | Pre-release testing |
| Production | Optimised performance | Release environment |

### 3. Backend Strategies

Three primary backend strategies are supported:

| Strategy | Description | Best For |
|----------|-------------|----------|
| Restic | Default integration with Restic | Standard environments |
| RingFFI | Ring cryptography with Argon2id | Cross-platform needs |
| AppleCK | Apple CryptoKit integration | Sandboxed environments |

## Usage Examples

### Building with Environment Settings

To build UmbraCore with specific environment and backend settings:

```bash
# Format: ./tools/build_scripts/build_with_config.sh [environment] [backend] [mode]
# Example: Build for alpha environment with RingFFI backend
./tools/build_scripts/build_with_config.sh alpha ringFFI default
```

### Using BuildConfig in Code

The BuildConfig system provides several ways to access configuration settings:

```swift
// 1. Global constants
let env = BuildConfig.activeEnvironment
let backend = BuildConfig.activeBackendStrategy

// 2. Factory methods for creating configurations
let config = BuildConfigFactory.createConfig(
    environment: .alpha, 
    backendStrategy: .ringFFI
)

// 3. Environment-specific configurations
let debugConfig = BuildConfigFactory.createDebugConfig()
let productionConfig = BuildConfigFactory.createProductionConfig()

// 4. Special-purpose configurations
let sandboxedConfig = BuildConfigFactory.createSandboxedConfig()
let crossPlatformConfig = BuildConfigFactory.createCrossPlatformConfig()
```

### Conditional Compilation

Use compiler directives to conditionally include code:

```swift
// Environment-specific code
#if DEBUG
    // Debug-only code
#elseif PRODUCTION
    // Production-only code
#endif

// Backend-specific code
#if BACKEND_RING_FFI
    // Ring FFI specific implementation
#elseif BACKEND_APPLE_CRYPTOKIT
    // Apple CryptoKit specific implementation
#else
    // Default Restic implementation
#endif
```

### Utility Methods

Utility methods provide runtime checks for environment and backend:

```swift
// Environment checks
if CompilerDirectives.isDebugBuild {
    // Debug-specific code
}

// Conditional execution
CompilerDirectives.onlyInDevelopment {
    // Development environment code
}

CompilerDirectives.withBackendStrategy(.appleCK) {
    // AppleCK-specific code
}
```

## Privacy-Aware Logging Configuration

BuildConfig includes built-in support for privacy-aware logging:

```swift
// Get default logging configuration
let defaultConfig = PrivacyAwareLoggingConfig.createDefault()

// Environment-specific configurations
let devConfig = PrivacyAwareLoggingConfig.createForDevelopment()
let prodConfig = PrivacyAwareLoggingConfig.createForProduction()

// Custom configuration
let customConfig = PrivacyAwareLoggingConfig.create(
    isEnabled: true,
    defaultPrivacyLevel: .private,
    redactionBehavior: .alwaysRedact,
    includeSourceLocation: false
)
```

## Service Factory Integration

UmbraCore service factories integrate with BuildConfig to provide environment-aware service creation:

```swift
// Create crypto service for specific environment
let cryptoService = await CryptoServiceFactory.shared.createDefault(
    environment: .beta,
    backendStrategy: .ringFFI
)

// File system service with environment awareness
let fileSystemService = await FileSystemServiceFactory.shared.createFileSystemService(
    environment: .production,
    backendStrategy: .appleCK
)
```

## Best Practices

1. **Default to Configuration Properties**: Use BuildConfig properties rather than hardcoded values
2. **Factory Methods**: Use factory methods to create consistent configurations
3. **Conditional Compilation**: Use compiler directives for platform-specific code
4. **Privacy Controls**: Always provide appropriate privacy levels for logging sensitive data
5. **Environment Awareness**: Design services to adapt behaviour based on environment

## Extending the System

When adding new services to UmbraCore, integrate with BuildConfig by:

1. Adding environment-aware factory methods
2. Using conditional compilation for platform-specific code
3. Implementing privacy-aware logging appropriate to each environment
4. Supporting all backend strategies where appropriate

---

For further information, see the API documentation for `UmbraBuildConfig`, `BuildConfigFactory`, and `CompilerDirectives` classes.
