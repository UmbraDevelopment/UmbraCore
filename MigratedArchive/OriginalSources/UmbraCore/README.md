# UmbraCore

This is the main module of the UmbraCore framework, providing the core functionality for integrating with Restic backup on macOS systems.

## Overview

The UmbraCore module brings together all the components of the framework to provide a cohesive and unified API for macOS applications to interact with Restic backup functionality. It serves as the main entry point for applications using the framework.

## Features

- Unified API for Restic operations
- Integration with macOS security features
- Complete backup and restore functionality
- Cross-process security operations

## Usage

```swift
import UmbraCore

// Initialize the core framework
let core = UmbraCore()

// Access various subsystems
let repositories = core.repositories
let snapshots = core.snapshots
let securityService = core.securityService
```

## Integration

This module integrates with all other UmbraCore modules to provide a seamless experience for developers building backup solutions on macOS.
