# Scheduling

## Overview
The Scheduling module provides core scheduling types and utilities used throughout the UmbraCore system. It offers a standardised interface for representing schedule and task definitions in a Foundation-independent manner.

## Public API Summary

### Primary Types
- `ScheduleDTO`: A structure representing a schedule with various frequency options and configuration parameters.
- `ScheduledTaskDTO`: A structure representing a scheduled task with lifecycle stages and metadata.

### Key Functionality
- Foundation-independent schedule representation
- Type-safe schedule frequency configuration
- Immutable value types for thread-safety
- Task status lifecycle management
- Schedule and task factory methods

## Usage Examples

### Creating and managing schedules
```swift
// Create a daily backup schedule
let backupSchedule = ScheduleDTO.daily(
    name: "Daily System Backup", 
    interval: 1,
    startTimeOfDay: 1 * 3600, // 1:00 AM
    metadata: ["priority": "high", "category": "system"]
)

// Create a weekly maintenance schedule
let weeklyMaintenance = ScheduleDTO.weekly(
    name: "Weekly Repository Maintenance",
    daysOfWeek: [.sunday],
    startTimeOfDay: 2 * 3600, // 2:00 AM
    metadata: ["category": "maintenance"]
)

// Create a one-time task
let holidayBackup = ScheduleDTO.oneTime(
    name: "Pre-Holiday Full Backup",
    runTime: UInt64(Date().timeIntervalSince1970 + 86400), // Tomorrow
    metadata: ["priority": "critical"]
)
```

### Working with scheduled tasks
```swift
// Create a backup task
let backupTask = ScheduledTaskDTO.backupTask(
    id: UUID().uuidString,
    scheduleID: backupSchedule.id,
    name: "System Backup",
    configData: "{\"repositoryId\":\"repo-123\",\"fullBackup\":true}",
    createdAt: UInt64(Date().timeIntervalSince1970)
)

// Update task state through its lifecycle
let runningTask = backupTask.markAsRunning()
// ...after task completes...
let completedTask = runningTask.markAsCompleted(
    resultData: "{\"bytesProcessed\":1024576,\"filesProcessed\":1250}"
)

// Handle a task failure
let failedTask = backupTask.markAsFailed(
    errorMessage: "Network connection interrupted during backup"
)
```

## Notes for Developers
- This module is designed to be free of external dependencies beyond Foundation
- All types are immutable for thread-safety
- The types in this module conform to Sendable and Equatable protocols for use in concurrent contexts
- Time values are stored as Unix timestamps (seconds since 1970) for Foundation independence
- When creating schedules programmatically, use the provided factory methods rather than direct initialisation
