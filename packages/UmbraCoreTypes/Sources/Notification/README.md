# Notification

## Overview
The Notification module provides core notification types and utilities used throughout the UmbraCore system. It offers a standardised interface for representing notifications in a Foundation-independent manner.

## Public API Summary

### Primary Types
- `NotificationDTO`: A structure representing a notification in the system, with support for various data types in the user info dictionary.

### Key Functionality
- Foundation-independent notification representation
- Type-safe accessors for user info values
- Immutable value types for thread-safety
- Support for creating modified notifications

## Usage Examples

### Creating and handling notifications
```swift
// Create a notification
let notification = NotificationDTO(
    name: "BackupComplete",
    sender: "BackupService",
    userInfo: [
        "repositoryId": "repo-123",
        "fileCount": "157",
        "totalSizeBytes": "1024576",
        "timestamp": "\(Date().timeIntervalSince1970)"
    ]
)

// Access user info with type conversion
if let repoId = notification.stringValue(for: "repositoryId"),
   let fileCount = notification.intValue(for: "fileCount"),
   let timestamp = notification.dateValue(for: "timestamp") {
    print("Backup of \(repoId) completed at \(timestamp) with \(fileCount) files")
}

// Create a modified notification
let enrichedNotification = notification.withAdditionalUserInfo([
    "compressionRatio": "0.87",
    "verificationComplete": "true"
])
```

## Notes for Developers
- This module is designed to be free of external dependencies beyond Foundation
- All types are immutable for thread-safety
- The types in this module conform to Sendable, Equatable, and Hashable for use in concurrent contexts
