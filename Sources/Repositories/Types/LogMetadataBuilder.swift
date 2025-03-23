// Standard modules
import Foundation

// Internal modules
import UmbraLogging

/// A builder for creating LogMetadata with consistent keys and values.
public enum LogMetadataBuilder {
  /// Creates LogMetadata for repository operations.
  ///
  /// - Parameters:
  ///   - identifier: Optional repository identifier
  ///   - path: Optional repository path
  ///   - count: Optional count value
  ///   - errorCount: Optional error count
  ///   - successCount: Optional success count
  /// - Returns: LogMetadata with the specified values
  public static func forRepository(
    identifier: String? = nil,
    path: String? = nil,
    count: Int? = nil,
    errorCount: Int? = nil,
    successCount: Int? = nil
  ) -> LogMetadata {
    var metadata: [String: String] = [:]

    if let identifier {
      metadata["repository_id"] = identifier
    }

    if let path {
      metadata["path"] = path
    }

    if let count {
      metadata["repository_count"] = String(count)
    }

    if let errorCount {
      metadata["error_count"] = String(errorCount)
    }

    if let successCount {
      metadata["success_count"] = String(successCount)
    }

    return LogMetadata(metadata)
  }
}
