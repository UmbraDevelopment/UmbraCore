# UmbraCore Naming Convention Refactoring

## Overview

This document summarises the changes made during the refactoring of the UmbraCore codebase to improve naming conventions, particularly focusing on removing generic names and replacing them with more domain-specific ones to avoid potential naming collisions.

## Key Changes

### Core Type Renaming

| Original Name | New Name | Reason for Change |
|---------------|----------|------------------|
| `AlphaDotFiveCancellationToken` | `BackupCancellationToken` | More descriptive and domain-specific |
| `StandardAlphaDotFiveCancellationToken` | `StandardBackupCancellationToken` | Aligns with BackupCancellationToken naming |
| `CancellationToken` (in ProgressReporting) | `ProgressCancellationToken` | Avoids name collision |
| `BackupCancellationToken` (in ProgressReporting) | `ProgressOperationCancellationToken` | Avoids name collision |
| `CancellationToken` (Implementation) | `BackupOperationCancellationToken` | Descriptive implementation name |

### Result Types

| Original Name | New Name | Reason for Change |
|---------------|----------|------------------|
| `AlphaDotFiveCopyResult` | `BackupCopyResult` | More descriptive and domain-specific |
| `AlphaDotFiveDeleteResult` | `BackupDeleteResult` | More descriptive and domain-specific |
| `AlphaDotFiveExportFormat` | `BackupExportFormat` | More descriptive and domain-specific |
| `AlphaDotFiveExportResult` | `BackupExportResult` | More descriptive and domain-specific |
| `AlphaDotFiveImportFormat` | `BackupImportFormat` | More descriptive and domain-specific |
| `AlphaDotFiveImportResult` | `BackupImportResult` | More descriptive and domain-specific |
| `AlphaDotFiveSnapshotComparisonResult` | `BackupSnapshotComparisonResult` | More descriptive and domain-specific |
| `DeleteResult` (in BackupResults) | `BRDeleteResult` | Avoids name collision |
| `SnapshotComparisonResult` | `BackupSnapshotComparisonResult` | Consistent with domain naming |
| `SnapshotDifference` | `BackupSnapshotDifference` | Consistent with domain naming |
| `VerificationResult` | `BackupVerificationResult` | Consistent with domain naming |
| `VerificationIssue` | `BackupVerificationIssue` | Consistent with domain naming |

### Snapshot Operations Types

| Original Name | New Name | Reason for Change |
|---------------|----------|------------------|
| `ExportFormat` | `SOpExportFormat` | Avoids name collision |
| `ExportResult` | `SOpExportResult` | Avoids name collision |
| `ImportFormat` | `SOpImportFormat` | Avoids name collision |
| `ImportResult` | `SOpImportResult` | Avoids name collision |
| `VerificationLevel` | `SOpVerificationLevel` | Consistent with domain naming |
| `CopyResult` | `SOpCopyResult` | Avoids name collision |

## Refactoring Approach

The refactoring was carried out with these principles in mind:

1. **Domain Specificity**: Names should reflect their domain and purpose clearly
2. **Consistency**: Similar types should follow similar naming patterns
3. **Collision Avoidance**: Names should be unique enough to avoid ambiguity
4. **Clarity**: Names should be descriptive and self-explanatory

## Files Modified

The following files were modified during this refactoring effort:

### Interface Files
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/CancellationToken.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/OperationResults.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/ProgressReporting.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/BackupResults.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/SnapshotOperations.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/SnapshotComparisonResult.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/SnapshotDifference.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Types/VerificationResult.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Protocols/SnapshotServiceProtocol.swift`
- `/packages/UmbraInterfaces/Sources/BackupInterfaces/Protocols/BackupServiceProtocol.swift`

### Implementation Files
- `/packages/UmbraImplementations/Sources/BackupServices/Types/CancellationHandlerProtocol.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/Shared/CancellationHandler.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/Shared/SnapshotOperationExecutor.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/SnapshotService/SnapshotResultParser.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/Services/SnapshotManagementService.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/Services/SnapshotOperationsService.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/Services/SnapshotRestoreService.swift`
- `/packages/UmbraImplementations/Sources/BackupServices/Implementation/BackupServicesActor.swift`

## Next Steps

For future development, consider:

1. Creating a naming convention style guide to ensure consistency
2. Adding comprehensive unit tests to verify that the renamed types function correctly
3. Conducting a code review to ensure all references have been properly updated
4. Updating documentation to reflect the new naming conventions
