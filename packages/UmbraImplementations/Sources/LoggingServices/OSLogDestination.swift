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
    switch privacy {
      case .public:
        .public
      case .private:
        .private
      case .sensitive:
        .sensitive
      case .auto:
        .auto
    }
  }

  /// Extract privacy settings from metadata if available
  /// - Parameter metadata: The log metadata to check
  /// - Returns: Tuple with message and metadata privacy levels
  private func extractPrivacySettings(from metadata: LogMetadata?)
  -> (messagePrivacy: LogPrivacy, metadataPrivacy: LogPrivacy) {
    guard let metadata else {
      return (.auto, .private)
    }

    // Extract message privacy from metadata
    let messagePrivacyStr=metadata["__privacy_message"]
    let messagePrivacy: LogPrivacy=if messagePrivacyStr == "public" {
      .public
    } else if messagePrivacyStr == "private" {
      .private
    } else if messagePrivacyStr == "sensitive" {
      .sensitive
    } else {
      .auto
    }

    // Extract metadata privacy from metadata
    let metadataPrivacyStr=metadata["__privacy_metadata"]
    let metadataPrivacy: LogPrivacy=if metadataPrivacyStr == "public" {
      .public
    } else if metadataPrivacyStr == "private" {
      .private
    } else if metadataPrivacyStr == "sensitive" {
      .sensitive
    } else {
      .private // Default is private for metadata
    }

    return (messagePrivacy, metadataPrivacy)
  }

  /// Filter out privacy control metadata
  /// - Parameter metadata: The original metadata
  /// - Returns: Filtered metadata without privacy control tags
  private func filterPrivacyMetadata(_ metadata: LogMetadata?) -> LogMetadata? {
    guard var filteredMetadata=metadata else {
      return nil
    }

    // Remove privacy control tags
    filteredMetadata["__privacy_message"]=nil
    filteredMetadata["__privacy_metadata"]=nil

    // If metadata is now empty, return nil
    if filteredMetadata.asDictionary.isEmpty {
      return nil
    }

    return filteredMetadata
  }

  /// Write a log entry to OSLog
  /// - Parameter entry: The log entry to write
  /// - Throws: LoggingError if writing fails
  public func write(_ entry: LoggingTypes.LogEntry) async throws {
    // Check minimum level
    guard entry.level.rawValue >= minimumLevel.rawValue else {
      return
    }

    // Extract privacy settings
    let privacySettings=extractPrivacySettings(from: entry.metadata)
    let messagePrivacy=privacySettings.messagePrivacy
    let metadataPrivacy=privacySettings.metadataPrivacy

    // Filter out privacy metadata
    let filteredMetadata=filterPrivacyMetadata(entry.metadata)

    // Get OSLog type based on log level
    let type=osLogType(for: entry.level)

    // Format metadata if present
    if let metadata=filteredMetadata, !metadata.asDictionary.isEmpty {
      // For interpolated strings with privacy controls, we need to use string interpolation
      let metadataStr=metadata.asDictionary
        .map { "\($0.key): \($0.value)" }
        .joined(separator: ", ")

      // Use appropriate privacy annotations based on the privacy levels
      switch messagePrivacy {
        case .public:
          switch metadataPrivacy {
            case .public:
              os_log(
                "%{public}@ [Metadata: %{public}@]",
                log: osLog,
                type: type,
                entry.message,
                metadataStr
              )
            default:
              os_log(
                "%{public}@ [Metadata: %{private}@]",
                log: osLog,
                type: type,
                entry.message,
                metadataStr
              )
          }
        default:
          switch metadataPrivacy {
            case .public:
              os_log(
                "%{private}@ [Metadata: %{public}@]",
                log: osLog,
                type: type,
                entry.message,
                metadataStr
              )
            default:
              os_log(
                "%{private}@ [Metadata: %{private}@]",
                log: osLog,
                type: type,
                entry.message,
                metadataStr
              )
          }
      }
    } else {
      // Just log the message with appropriate privacy
      switch messagePrivacy {
        case .public:
          os_log("%{public}@", log: osLog, type: type, entry.message)
        default:
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
