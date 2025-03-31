# CoreInterfaces

This module provides the core interfaces, protocols, and types that form the foundation of the UmbraCore framework. 

## Overview

CoreInterfaces defines the fundamental abstractions and contracts that all other modules in the UmbraCore framework use. By centralising these interfaces, we ensure consistent API design and implementation across the framework.

## Key Components

### Core Types
- Base protocols and interfaces for core functionality
- Essential types and type definitions
- Error types and handling protocols

### System Integration
- Platform and environment abstractions
- Version information interfaces
- System configuration protocols

### Utilities
- Common utility protocols
- Framework configuration interfaces

## Usage

Import CoreInterfaces wherever you need access to the core framework abstractions:

```swift
import CoreInterfaces

// Use core interfaces
let service = container.resolve(CoreServiceProtocol.self)
```

## Dependencies

CoreInterfaces depends only on UmbraErrors, maintaining a clean dependency graph.

## Alpha Dot Five Architecture

This module is part of the Alpha Dot Five architecture, which separates interfaces from implementations to improve testability, maintainability, and flexibility.
