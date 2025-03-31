# CoreServices

This module provides the implementation of core services that form the foundation of the UmbraCore framework.

## Overview

CoreServices implements the interfaces defined in CoreInterfaces, delivering concrete implementations of the fundamental services required by the UmbraCore framework. This module serves as the backbone for all higher-level services.

## Key Components

### Core Service Implementations
- Standard implementations of core service protocols
- Framework initialisation and configuration
- System integration services

### Environment Adaptors
- Operating system integration
- Environment-specific implementations
- Platform detection and adaptation

### Utility Services
- Common utility implementations
- Framework configuration services

## Usage

Import CoreServices when you need to initialise the core framework or access standard implementations:

```swift
import CoreServices

// Initialise the core framework
CoreServiceFactory.initialise()

// Get a core service implementation
let service = CoreServiceFactory.createCoreService()
```

## Dependencies

CoreServices depends on:
- CoreInterfaces - For the interfaces it implements
- UmbraErrors - For error handling

## Alpha Dot Five Architecture

This module is part of the Alpha Dot Five architecture, which separates interfaces from implementations to improve testability, maintainability, and flexibility.
