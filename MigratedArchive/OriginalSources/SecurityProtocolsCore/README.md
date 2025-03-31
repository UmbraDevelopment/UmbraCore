# SecurityProtocolsCore

This module provides the foundation-free security protocol definitions for UmbraCore, serving as a central location for security service interfaces.

## Overview

The SecurityProtocolsCore module defines the core interfaces for security services in UmbraCore without Foundation dependencies, allowing for better cross-platform compatibility and more efficient integration in sandboxed environments.

## Features

- Foundation-free security protocol definitions
- Standardised security operation types
- Cross-module security interface compatibility
- Support for both direct and XPC-based security operations

## Usage

```swift
import SecurityProtocolsCore

// Implement a security provider
class MySecurityProvider: SecurityProviderFactoryProtocol {
    // Implementation
}
```

## Integration

This module works closely with XPCProtocolsCore to enable secure cross-process security operations while maintaining a clean architecture.
