# RepositoryManager

The RepositoryManager module provides comprehensive repository management for UmbraCore applications.

## Overview

RepositoryManager enables applications to create, configure, monitor, and maintain Restic repositories across different storage backends, including local disks, cloud storage, and network shares.

## Features

- Repository initialisation and verification
- Multi-backend support (local, S3, SFTP, etc.)
- Repository health checking
- Repository statistics and analytics
- Auto-detection of existing repositories
- Repository migration and conversion

## Architecture

RepositoryManager uses a provider-based architecture:

1. **Repository**: The core data structure representing a backup repository
2. **StorageProvider**: Backend-specific implementation for different storage systems
3. **RepositoryMonitor**: Service that tracks repository health and status
4. **RepositoryAnalytics**: Tools for analysing repository content and structure

## Usage

```swift
import RepositoryManager

// Create a repository manager
let repoManager = RepositoryManager()

// Initialize a new repository
let newRepo = try await repoManager.initialiseRepository(
    path: "/Volumes/Backup/main-backup",
    password: "secure-password",
    options: [.enableCompression, .setChunkingParameters]
)

// Open an existing repository
let existingRepo = try await repoManager.openRepository(
    path: "/Volumes/Backup/main-backup",
    password: "secure-password"
)

// Check repository health
let healthStatus = try await existingRepo.checkHealth()
if healthStatus.needsRepair {
    try await existingRepo.repair()
}

// Get repository statistics
let stats = try await existingRepo.getStatistics()
print("Total size: \(stats.totalSize)")
print("Deduplication ratio: \(stats.deduplicationRatio)")
```

## Integration

RepositoryManager integrates with the UmbraCore security and keychain services to ensure secure handling of repository passwords and encryption keys.
