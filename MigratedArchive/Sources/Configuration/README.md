# Configuration

The Configuration module provides a structured approach to managing UmbraCore settings and preferences.

## Overview

Configuration enables UmbraCore applications to manage settings, preferences, and operational parameters in a consistent and type-safe manner. It supports both global defaults and repository-specific configurations.

## Features

- Type-safe configuration access
- Default value management
- Configuration persistence
- Schema validation
- Configuration migration
- Environment-specific overrides

## Architecture

Configuration uses a hierarchical approach to settings:

1. **Global Defaults**: Framework-wide settings
2. **Repository-Specific Settings**: Settings that apply to a specific repository
3. **Operation-Specific Overrides**: Settings that apply only to a specific operation

## Usage

```swift
import Configuration

// Access configuration
let config = UmbraConfiguration.shared

// Get a configuration value
let compressionLevel = config.get(\.backup.compressionLevel, 
                                  forRepository: "main-backup")

// Set a configuration value
try config.set(\.backup.compressionLevel, 
               value: 9, 
               forRepository: "main-backup")

// Define operation-specific settings
let backupSettings = BackupSettings(
    compressionLevel: 6,
    excludePatterns: ["*.tmp", "*.log"],
    tags: ["weekly"]
)

// Use settings in an operation
let operation = BackupOperation(
    paths: ["/Users/Documents"],
    settings: backupSettings
)
```

## Integration

Configuration is designed to integrate with the UmbraCore preferences system and provides a foundation for user-configurable settings in applications built with UmbraCore.
