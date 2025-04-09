import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog

/// A log destination that writes to Apple's OSLog system
///
/// This implementation integrates with OSLog to provide efficient system logging
/// with proper privacy controls and integration with Console.app.
/// It follows the Alpha Dot Five architecture patterns with proper thread safety
/// and consistent British spelling in documentation.
public struct OSLogDestination: LoggingTypes.LogDestination {
  /// Unique identifier for this destination
  public let identifier: String

  /// Minimum log level this destination will accept
  public var minimumLevel: LoggingTypes.UmbraLogLevel

  /// The subsystem identifier (typically a reverse-DNS name)
  public let subsystem: String

  /// The logging category
  public let category: String

  /// OSLog instance used for logging
  private let osLog: OSLog

  /// Formatter for log entries
  private let formatter: LoggingInterfaces.LogFormatterProtocol?

  /// Initialise an OSLog destination with the given configuration
  /// - Parameters:
  ///   - identifier: Unique identifier for this destination
  ///   - subsystem: The subsystem identifier (typically a reverse-DNS name)
  ///   - category: The logging category
  ///   - minimumLevel: Minimum log level to display
  ///   - formatter: Optional formatter to use for non-structured logging
  public init(
    identifier: String="oslog",
    subsystem: String,
    category: String,
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) {
    self.identifier=identifier
    self.minimumLevel=minimumLevel
    self.subsystem=subsystem
    self.category=category
    osLog=OSLog(subsystem: subsystem, category: category)
    self.formatter=formatter
  }

  /// Convert UmbraLogLevel to OSLogType
  /// - Parameter level: UmbraLogLevel to convert
  /// - Returns: Corresponding OSLogType
  private func osLogType(for level: UmbraLogLevel) -> OSLogType {
    switch level {
      case .verbose:
        .debug
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .default
      case .error:
        .error
      case .critical:
        .fault
    }
  }

  /// Convert LogPrivacy to OSLogPrivacy
  /// - Parameter privacy: LogPrivacy to convert
  /// - Returns: Corresponding OSLogPrivacy
  private func osLogPrivacy(for privacy: LogPrivacy) -> OSLogPrivacy {
    if privacy == .public {
      .public
    } else if privacy == .private {
      .private
    } else if privacy == .sensitive {
      .sensitive
    } else {
      .auto
    }
  }

  /// Extract privacy settings from metadata if available
  /// - Parameter metadata: The log metadata to check
  /// - Returns: Tuple with message and metadata privacy levels
  private func extractPrivacySettings(from metadata: LogMetadataDTOCollection?)
  -> (messagePrivacy: OSLogPrivacy, metadataPrivacy: OSLogPrivacy) {
    guard metadata != nil else {
      return (.private, .private)
    }

    // In a real implementation, this would look for specific privacy annotations
    // For this example, we'll just default to private for everything
    return (.private, .private)
  }

  /// Filter out privacy metadata
  /// - Parameter metadata: The original metadata
  /// - Returns: Filtered metadata without privacy control tags
  private func filterPrivacyMetadata(_ metadata: LogMetadataDTOCollection?) -> [String: String] {
    guard let metadata else {
      return [:]
    }

    // Convert LogMetadataDTOCollection to dictionary of strings
    var result = [String: String]()
    for entry in metadata.entries {
      // Skip privacy control keys
      if !entry.key.starts(with: "__privacy_") {
        result[entry.key] = entry.value
      }
    }

    return result
  }

  /// Check if a privacy level is considered public
  /// - Parameter privacy: The OSLogPrivacy value to check
  /// - Returns: true if the privacy level is public
  private func isPublic(_ privacy: OSLogPrivacy) -> Bool {
    // Since OSLogPrivacy doesn't conform to Equatable,
    // we need to use a different approach
    #if DEBUG
      // In debug mode, we can use string comparison as a way to determine
      if String(describing: privacy) == String(describing: OSLogPrivacy.public) {
        return true
      }
      return false
    #else
      // In release mode, we use the tag defined in the original privacy level
      // This is implementation-specific but provides a way to check in release builds
      if case OSLogPrivacy.public=privacy {
        return true
      }
      return false
    #endif
  }

  /// Write a log entry to OSLog
  /// - Parameter entry: The log entry to write
  /// - Throws: LoggingError if writing fails
  public func write(_ entry: LoggingTypes.LogEntry) async throws {
    // Check minimum level using integer values for comparison
    let entryLevelValue=switch entry.level {
      case .trace: 0
      case .debug: 1
      case .info: 2
      case .warning: 3
      case .error: 4
      case .critical: 5
    }

    let minLevelValue=switch minimumLevel {
      case .verbose: 0 // UmbraLogLevel.verbose maps to LogLevel.trace
      case .debug: 1
      case .info: 2
      case .warning: 3
      case .error: 4
      case .critical: 5
    }

    guard entryLevelValue >= minLevelValue else {
      return
    }

    // Extract privacy settings
    let privacySettings=extractPrivacySettings(from: entry.metadata)
    let messagePrivacy=privacySettings.messagePrivacy
    let metadataPrivacy=privacySettings.metadataPrivacy

    // Filter out privacy metadata
    let filteredMetadata=filterPrivacyMetadata(entry.metadata)

    // Get OSLog type based on log level
    // Convert LogLevel to UmbraLogLevel
    let umbraLevel: UmbraLogLevel=switch entry.level {
      case .trace: .verbose // LogLevel.trace maps to UmbraLogLevel.verbose
      case .debug: .debug
      case .info: .info
      case .warning: .warning
      case .error: .error
      case .critical: .critical
    }
    let type=osLogType(for: umbraLevel)

    // Format metadata if present
    if !filteredMetadata.isEmpty {
      // Use helper function instead of direct equality comparison
      let isMessagePublic=isPublic(messagePrivacy)
      let isMetadataPublic=isPublic(metadataPrivacy)

      if isMessagePublic {
        if isMetadataPublic {
          os_log(
            "%{public}@ [Metadata: %{public}@]",
            log: osLog,
            type: type,
            entry.message,
            filteredMetadata.description
          )
        } else {
          os_log(
            "%{public}@ [Metadata: %{private}@]",
            log: osLog,
            type: type,
            entry.message,
            filteredMetadata.description
          )
        }
      } else {
        if isMetadataPublic {
          os_log(
            "%{private}@ [Metadata: %{public}@]",
            log: osLog,
            type: type,
            entry.message,
            filteredMetadata.description
          )
        } else {
          os_log(
            "%{private}@ [Metadata: %{private}@]",
            log: osLog,
            type: type,
            entry.message,
            filteredMetadata.description
          )
        }
      }
    } else {
      // Just log the message with appropriate privacy
      let isMessagePublic=isPublic(messagePrivacy)
      if isMessagePublic {
        os_log("%{public}@", log: osLog, type: type, entry.message)
      } else {
        os_log("%{private}@", log: osLog, type: type, entry.message)
      }
    }
  }

  /// Flush any pending entries (OSLog handles this automatically)
  /// - Throws: Never throws for OSLog
  public func flush() async throws {
    // OSLog doesn't require manual flushing
  }
}
