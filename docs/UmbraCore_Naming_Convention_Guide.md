# UmbraCore Naming Convention Style Guide

## Overview

This document provides comprehensive guidelines for naming conventions within the UmbraCore project. Following these conventions ensures consistency, clarity, and reduces the risk of naming conflicts across the codebase. The guidelines align with the project's architectural principles and enhance code maintainability.

## General Principles

1. **Clarity over Brevity**: Names should be self-explanatory, even if longer.
2. **Domain-Specific Prefixes**: Use domain-specific prefixes to avoid name collisions.
3. **Consistency**: Similar concepts should follow similar naming patterns.
4. **British English**: Use British English spelling in documentation and comments.

## File Naming

| Type | Convention | Example |
|------|------------|---------|
| Swift source files | PascalCase matching type name | `BackupCancellationToken.swift` |
| Protocol files | PascalCase with "Protocol" suffix | `BackupServiceProtocol.swift` |
| Test files | PascalCase with "Tests" suffix | `BackupServiceTests.swift` |
| Documentation files | All caps with underscores | `ERROR_HANDLING_STANDARDS.md` |
| Resources | lowercase with hyphens | `backup-icon.png` |

## Type Naming

### Protocol Naming

Protocols should be named using PascalCase with the "Protocol" suffix when they define a service or component boundary. For protocols that define capabilities or traits, use nouns or adjectives without the "Protocol" suffix.

```swift
// Service protocol
public protocol BackupServiceProtocol { ... }

// Capability protocol
public protocol Cancellable { ... }
```

### Domain-Specific Type Naming

Types that might have generic or common names should be prefixed with their domain:

```swift
// Good: Clear domain prefix
public struct BackupCancellationToken: Sendable { ... }

// Avoid: Generic name with potential collisions
public struct CancellationToken: Sendable { ... }
```

### Enum Naming

Enums should be named using PascalCase for the type and camelCase for cases:

```swift
public enum BackupOperationError: Error, Sendable {
    case invalidInput(String)
    case repositoryNotFound(String)
    case accessDenied
}
```

### Actor Naming

Actors should be named with the "Actor" suffix:

```swift
public actor BackupServiceActor: BackupServiceProtocol { ... }
```

## Property and Method Naming

### Properties

Properties should be named using camelCase:

```swift
public var repositoryPath: URL
private let configurationManager: ConfigurationManager
```

Use Boolean properties with positive phrasing:

```swift
// Good: Positive phrasing
var isEncrypted: Bool

// Avoid: Negative phrasing
var isNotEncrypted: Bool
```

### Methods

Methods should be named using camelCase with verb-first naming:

```swift
func createSnapshot() async throws -> BackupSnapshot
func deleteBackup(snapshotID: String) async -> Result<BackupDeleteResult, BackupOperationError>
```

For methods with similar functionality across types, maintain consistent naming:

```swift
// Consistency across related types
protocol FileHandlerProtocol {
    func readFile(at path: URL) async throws -> Data
}

protocol NetworkHandlerProtocol {
    func readData(from url: URL) async throws -> Data
}
```

## Parameter Naming

Parameters should be named using camelCase and be descriptive:

```swift
func exportSnapshot(
    snapshotID: String,
    destinationPath: URL,
    format: BackupExportFormat
) async throws -> BackupExportResult
```

Use underscore for unused parameters or when an external name is unnecessary:

```swift
func handleEvent(_ event: BackupEvent) 
```

## Constant Naming

### Global Constants

Global constants should be named with camelCase and grouped in enums when related:

```swift
enum BackupConstants {
    static let maximumFileSize: UInt64 = 1_073_741_824
    static let defaultPruneSchedule: TimeInterval = 86400 * 7
}
```

### Enum-Based Constants

Use enums with static properties for grouping constants by domain:

```swift
enum BackupLimits {
    static let maxConcurrentOperations = 5
    static let maxRetryAttempts = 3
}
```

## Abbreviations and Acronyms

### Common Abbreviations

Follow these guidelines for common abbreviations:

1. Well-known acronyms (URL, JSON, XML) are uppercase when they stand alone
2. When part of a longer name, follow the capitalization rules:
   - camelCase: first letter lowercase if not at the beginning
   - PascalCase: first letter uppercase

```swift
// Examples
let jsonData: Data
let parseUrl: URL
let BackupUrlValidator
```

## Type Suffixes

Use consistent suffixes for common patterns:

| Suffix | Use Case | Example |
|--------|----------|---------|
| Protocol | Interfaces | `BackupServiceProtocol` |
| Provider | Dependency providers | `SecurityProvider` |
| Factory | Factory methods/classes | `BackupServiceFactory` |
| Manager | Orchestrators | `SnapshotManager` |
| Service | Service implementations | `SnapshotService` |
| Error | Error types | `BackupOperationError` |
| Result | Operation results | `BackupCopyResult` |
| DTO | Data transfer objects | `SnapshotMetadataDTO` |

## Domain-Specific Naming

### Backup Domain

Backup-related types should be prefixed with "Backup" to clearly identify their domain:

```swift
struct BackupSnapshot { ... }
struct BackupDeleteResult { ... }
enum BackupExportFormat { ... }
```

### Progress Reporting Domain

Progress reporting types should be prefixed with "Progress" to avoid conflicts:

```swift
protocol ProgressCancellationToken { ... }
class ProgressOperationCancellationToken { ... }
```

### Snapshot Operations Domain

Snapshot operation types can use the "SOp" prefix to distinguish them from similar types:

```swift
enum SOpVerificationLevel { ... }
struct SOpExportResult { ... }
```

## Spelling Conventions

1. **Documentation, Comments, and UI Text**: Use British English spelling
   - Examples: "centralised" (not "centralized"), "colour" (not "color")

2. **Code Identifiers**: American English spelling is acceptable
   - Example: `initialize()` rather than `initialise()`

## Documentation

Document public APIs using standard Swift markup:

```swift
/// Exports a snapshot to the specified location.
///
/// This operation creates an exportable copy of the snapshot that can be
/// moved to another system or stored as a backup.
///
/// - Parameters:
///   - snapshotID: Unique identifier of the snapshot to export
///   - destinationPath: Path where the export should be stored
///   - format: Format to use for the export
/// - Returns: Result containing export details or an error
public func exportSnapshot(
    snapshotID: String,
    destinationPath: URL,
    format: BackupExportFormat
) async -> Result<BackupExportResult, BackupOperationError>
```

## Examples from Codebase

### Good Examples

```swift
// Clear domain-specific naming
public protocol BackupCancellationToken: Sendable {
    func isCancelled() async -> Bool
    func cancel() async
}

// Clear operation result types
public struct BackupCopyResult: Sendable, Equatable {
    public let targetSnapshotID: String
    public let completionTime: Date
    public let transferredBytes: UInt64
}

// Consistent error naming
public enum BackupOperationError: Error, Sendable, Equatable {
    case invalidInput(String)
    case repositoryNotFound(String)
    case accessDenied(reason: String)
}
```

### Names to Avoid

```swift
// Avoid generic names (use BackupCancellationToken instead)
public protocol CancellationToken: Sendable { ... }

// Avoid ambiguous names (use BackupDeleteResult instead)
public struct DeleteResult: Sendable, Equatable { ... }

// Avoid inconsistent spelling mixtures in documentation
/// This centralizes the configuration while changing the color settings
```

## Architecture-Specific Considerations

When working within the project architecture, consider:

1. **Actor Isolation**: Ensure types crossing actor boundaries conform to `Sendable`
2. **Type-Safe Interfaces**: Prefer strongly-typed interfaces over generic ones
3. **Privacy Awareness**: Use appropriate privacy annotations in logs and errors

## Version Control Commit Messages

When renaming types or updating conventions, use clear commit messages:

```
refactor(backup): rename generic CancellationToken to BackupCancellationToken

- Updates all references to use the new domain-specific name
- Maintains backward compatibility through typealias
- Fixes potential name collision with system types
```

## Conclusion

Following these naming conventions ensures consistency, clarity, and maintainability across the UmbraCore project. When in doubt, prioritize clarity and domain specificity over brevity or generic naming.
