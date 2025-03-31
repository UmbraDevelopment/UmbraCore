# ErrorTypes

The ErrorTypes module provides the foundation for error handling across the UmbraCore framework.

## Overview

ErrorTypes defines a consistent error handling architecture that is used throughout UmbraCore. It standardises error types, domains, and propagation mechanisms, enabling consistent error handling across module boundaries.

## Features

- Foundation-free error type definitions
- Hierarchical error domains
- Error code standardisation
- Localisation support
- Cross-module error propagation

## Architecture

ErrorTypes follows a domain-based architecture:

1. **Error Domains**: Logical groupings of related error types
2. **Error Codes**: Numeric identifiers for specific error conditions
3. **Error Contexts**: Additional information about error circumstances
4. **Recovery Options**: Suggested approaches to recover from errors

## Usage

```swift
import ErrorTypes

// Define an error type
enum BackupError: ErrorDomain {
    static let domain = "UmbraCore.Backup"
    
    case repositoryNotFound
    case insufficientPermissions
    case networkUnavailable
    
    var code: Int {
        switch self {
        case .repositoryNotFound: return 1001
        case .insufficientPermissions: return 1002
        case .networkUnavailable: return 1003
        }
    }
    
    var description: String {
        switch self {
        case .repositoryNotFound: return "Repository not found at specified location"
        case .insufficientPermissions: return "Insufficient permissions to access repository"
        case .networkUnavailable: return "Network is unavailable"
        }
    }
}

// Use the error in your code
throw CoreError(domain: BackupError.domain, 
                code: BackupError.repositoryNotFound.code,
                description: BackupError.repositoryNotFound.description)
```

## Integration

ErrorTypes is designed to be used by all UmbraCore modules to provide a consistent error handling experience across the framework.
