# CoreDTOs

## Purpose

This module provides data transfer objects (DTOs) used throughout the UmbraCore system. It defines structures for passing data between different components of the system, ensuring consistent data representation across module boundaries.

These types are foundation-independent where possible, following the UmbraCore Alpha Dot Five architecture principles to maximise reusability and minimise dependencies.

## Public API Summary

The CoreDTOs module contains several categories of data transfer objects:

- **Configuration**: Configuration-related data structures
- **Converters**: Type conversion utilities
- **DateTime**: Date and time handling structures
- **FileSystem**: File system operation data models
- **Network**: Network operation data structures
- **Notification**: Notification handling models
- **Operations**: Core operation models
- **Progress**: Progress tracking and reporting models
- **RepositoryManagement**: Repository management data structures
- **Scheduling**: Job scheduling and timing models
- **Security**: Security-related DTOs
- **UserDefaults**: User preferences models

## Dependencies

This package has minimal dependencies, primarily:
- Foundation (for Date and Data types)

## Example Usage

```swift
// Create and use a configuration DTO
let config = ConfigurationDTO(
    applicationID: "com.umbra.app",
    version: "1.0.0",
    parameters: [
        "backup_interval": "daily",
        "retention_period": "90"
    ]
)

// Access configuration parameters
if let backupInterval = config.parameters["backup_interval"] {
    // Use the backup interval
}
```

## Internal Structure

The module is organised into subdirectories based on functional areas:

- `Configuration/`: Configuration-related DTOs
- `Converters/`: Type conversion utilities
- `DateTime/`: Date and time structures
- `FileSystem/`: File system operation DTOs
- `Network/`: Network operation DTOs
- `Notification/`: Notification handling DTOs
- `Operations/`: Operation structures
- `Progress/`: Progress tracking DTOs
- `RepositoryManagement/`: Repository management DTOs
- `Scheduling/`: Scheduling and timing DTOs
- `Security/`: Security-related DTOs
- `UserDefaults/`: User preference DTOs
