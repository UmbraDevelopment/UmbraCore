import Foundation
import ResticTypes

/// Example progress handler that prints progress to the console
final class ConsoleProgressHandler: ResticProgressReporting {
  private var lastUpdateTime: Date = .now
  private let updateInterval: TimeInterval=1.0 // Update console every second

  func progressUpdated(_ progress: Any) {
    // Only update console at specified interval to avoid flooding
    guard Date.now.timeIntervalSince(lastUpdateTime) >= updateInterval else {
      return
    }
    lastUpdateTime = .now

    if let backupProgress=progress as? BackupProgress {
      printBackupProgress(backupProgress)
    } else if let restoreProgress=progress as? RestoreProgress {
      printRestoreProgress(restoreProgress)
    }
  }

  private func printBackupProgress(_ progress: BackupProgress) {
    // Clear previous lines
    print("\u{1B}[2K\r", terminator: "") // Clear current line
    print("\u{1B}[1A\u{1B}[2K\r", terminator: "") // Move up and clear line
    print("\u{1B}[1A\u{1B}[2K\r", terminator: "") // Move up and clear line

    // Format sizes
    let speed=ByteCountFormatter.string(
      fromByteCount: Int64(progress.bytesPerSecond),
      countStyle: .binary
    ) + "/s"
    let processed=ByteCountFormatter.string(
      fromByteCount: Int64(progress.processedBytes),
      countStyle: .binary
    )
    let total=ByteCountFormatter.string(
      fromByteCount: Int64(progress.totalBytes),
      countStyle: .binary
    )

    // Print status
    print("Status: \(progress.status.rawValue)")
    print("Progress: \(Int(progress.percentComplete))% (\(processed) of \(total)) at \(speed)")
    if let file=progress.currentFile {
      print("Processing: \(file)")
    }
  }

  private func printRestoreProgress(_ progress: RestoreProgress) {
    // Clear previous lines
    print("\u{1B}[2K\r", terminator: "") // Clear current line
    print("\u{1B}[1A\u{1B}[2K\r", terminator: "") // Move up and clear line
    print("\u{1B}[1A\u{1B}[2K\r", terminator: "") // Move up and clear line

    // Format sizes
    let speed=ByteCountFormatter.string(
      fromByteCount: progress.bytesPerSecond,
      countStyle: .binary
    ) + "/s"
    let restored=ByteCountFormatter.string(
      fromByteCount: progress.restoredBytes,
      countStyle: .binary
    )
    let total=ByteCountFormatter.string(
      fromByteCount: progress.totalBytes,
      countStyle: .binary
    )

    // Print status
    print("Status: \(progress.status.rawValue)")
    print("Progress: \(Int(progress.percentComplete))% (\(restored) of \(total)) at \(speed)")
    if let file=progress.currentFile {
      print("Restoring: \(file)")
    }
  }
}

/// Example of using progress reporting with BackupCommand
///
/// This example demonstrates how to enable and handle progress reporting
/// when running a backup command.
public final class ProgressReportingExample {
  private let command: BackupCommand
  private let parser: ProgressParser

  public init(repository: String, password: String) {
    // Create command with progress reporting enabled
    let options=CommonOptions(repository: repository, password: password)
    command=BackupCommand(paths: ["/path/to/backup"], options: options)
      .tag("example")
      .withProgress()

    // Create parser with progress handler
    parser=ProgressParser(delegate: ConsoleProgressHandler())
  }

  /// Example progress handler that prints to console
  private class ConsoleProgressHandler: ResticProgressReporting {
    func progressUpdated(_ progress: Any) {
      if let backupProgress=progress as? BackupProgress {
        handleBackupProgress(backupProgress)
      } else if let restoreProgress=progress as? RestoreProgress {
        handleRestoreProgress(restoreProgress)
      }
    }

    private func handleBackupProgress(_ progress: BackupProgress) {
      // Format sizes
      let speed=ByteCountFormatter.string(
        fromByteCount: Int64(progress.bytesPerSecond),
        countStyle: .binary
      ) + "/s"

      let processed=ByteCountFormatter.string(
        fromByteCount: Int64(progress.processedBytes),
        countStyle: .binary
      )

      let total=ByteCountFormatter.string(
        fromByteCount: Int64(progress.totalBytes),
        countStyle: .binary
      )

      // Print status
      print("Status: \(progress.status.rawValue)")
      print("Progress: \(Int(progress.percentComplete))% (\(processed) of \(total)) at \(speed)")
      if let file=progress.currentFile {
        print("Processing: \(file)")
      }
    }

    private func handleRestoreProgress(_ progress: RestoreProgress) {
      // Format sizes
      let speed=ByteCountFormatter.string(
        fromByteCount: progress.bytesPerSecond,
        countStyle: .binary
      ) + "/s"

      let restored=ByteCountFormatter.string(
        fromByteCount: progress.restoredBytes,
        countStyle: .binary
      )

      let total=ByteCountFormatter.string(
        fromByteCount: progress.totalBytes,
        countStyle: .binary
      )

      // Print status
      print("Status: \(progress.status.rawValue)")
      print("Progress: \(Int(progress.percentComplete))% (\(restored) of \(total)) at \(speed)")
      if let file=progress.currentFile {
        print("Restoring: \(file)")
      }
    }
  }

  /// Run the backup with progress reporting
  public func run() throws {
    try command.run()
  }
}

// Example usage:
/*
 let progressHandler = ConsoleProgressHandler()
 let helper = try ResticCLIHelper(
     executablePath: "/usr/local/bin/restic",
     progressDelegate: progressHandler
 )

 // Create a backup command with progress reporting
 let backupCommand = BackupCommand(options: commonOptions)
     .addPath("/path/to/backup")
     .tag("daily")
     .withProgress()  // Enable progress reporting

 // Execute the command
 try await helper.execute(backupCommand)

 // Sample output:
 // Status: scanning
 // Progress: 25% (2.5 GB of 10 GB) at 100 MB/s
 // Processing: /path/to/backup/large_file.dat
 */
