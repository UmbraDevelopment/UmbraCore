# ResticCLIHelper

The ResticCLIHelper module provides a Swift interface for interacting with the Restic command-line tool.

## Overview

ResticCLIHelper enables UmbraCore applications to execute Restic commands, parse output, and handle errors in a type-safe manner. It serves as the bridge between Swift code and the powerful Restic backup system.

## Features

- Type-safe command generation
- Structured output parsing
- Error handling and recovery
- Progress tracking for long-running operations
- Environment variable management
- Secure credential handling

## Architecture

ResticCLIHelper is designed to work in different execution contexts:

1. **Direct Execution**: For non-sandboxed applications
2. **XPC Service Execution**: For sandboxed applications requiring privileged operations

## Usage

```swift
import ResticCLIHelper

// Create a Restic CLI helper
let resticHelper = ResticCLIHelper(
    repositoryPath: "~/backups/my-repo",
    environmentProvider: MyCredentialProvider()
)

// Execute a backup command
let result = try await resticHelper.backup(
    paths: ["/Users/Documents", "/Users/Pictures"],
    tags: ["daily"],
    excludePatterns: ["*.tmp", "node_modules"]
)

// Handle the result
switch result {
case .success(let backupInfo):
    print("Backup successful: \(backupInfo.snapshotId)")
case .failure(let error):
    print("Backup failed: \(error.localizedDescription)")
}
```

## Integration

ResticCLIHelper is designed to be used alongside UmbraXPC for sandboxed applications, ensuring that all Restic operations comply with macOS security requirements.
