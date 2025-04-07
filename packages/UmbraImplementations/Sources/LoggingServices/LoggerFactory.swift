import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Logger Factory

 Factory for creating domain-specific loggers with privacy-enhanced capabilities
 following the Alpha Dot Five architecture principles.

 This static factory provides centralised creation of properly configured
 domain loggers with appropriate privacy controls and context handling.

 ## Usage Example

 ```swift
 // Create a logger for the Core domain
 let coreLogger = LoggerFactory.createCoreLogger(source: "CoreServiceImpl")

 // Log with privacy-enhanced context
 await coreLogger.info("Service initialised", context: coreLogContext)
 ```
 */
public enum LoggerFactory {
  /// Shared logging service instance for all loggers
  private static let sharedLoggingService=DefaultLoggingService()

  /**
   Creates a domain logger for core framework operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for core operations
   */
  public static func createCoreLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)
      .withPublic(key: "moduleVersion", value: "1.0.0")

    return createDomainLoggerInternal(
      domainName: "CoreFramework",
      metadata: metadata,
      source: source
    )
  }

  /**
   Creates a domain logger for cryptographic operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for crypto operations
   */
  public static func createCryptoLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)
      .withPublic(key: "securityLevel", value: "HIGH")

    return createDomainLoggerInternal(
      domainName: "CryptoOperations",
      metadata: metadata,
      source: source
    )
  }

  /**
   Creates a domain logger for security operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for security operations
   */
  public static func createSecurityLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)
      .withPublic(key: "securityDomain", value: "CORE_SECURITY")

    return createDomainLoggerInternal(
      domainName: "SecurityOperations",
      metadata: metadata,
      source: source
    )
  }

  /**
   Creates a domain logger for file system operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for file system operations
   */
  public static func createFileSystemLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)

    return createDomainLoggerInternal(domainName: "FileSystem", metadata: metadata, source: source)
  }

  /**
   Creates a domain logger for key management operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for key management operations
   */
  public static func createKeyManagementLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)
      .withPublic(key: "securityLevel", value: "CRITICAL")

    return createDomainLoggerInternal(
      domainName: "KeyManagement",
      metadata: metadata,
      source: source
    )
  }

  /**
   Creates a generic domain logger for the specified domain

   - Parameters:
     - domainName: The name of the domain
     - source: The source component creating the logger
   - Returns: A privacy-aware domain logger for the specified domain
   */
  public static func createDomainLogger(domainName: String, source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)

    return createDomainLoggerInternal(domainName: domainName, metadata: metadata, source: source)
  }

  static func createDomainLoggerInternal(
    domainName: String,
    metadata: LogMetadataDTOCollection,
    source _: String
  ) -> DomainLogger {
    // Create a logging protocol to pass to the BaseDomainLogger
    let loggingProtocol=BasicLoggingProtocol(
      service: sharedLoggingService,
      domainName: domainName,
      metadata: metadata
    )

    return BaseDomainLogger(logger: loggingProtocol)
  }
}

/**
 # Default Logging Service

 A simple implementation of the LoggingServiceProtocol that handles
 log entries according to their privacy classifications.
 */
public final class DefaultLoggingService: LoggingServiceProtocol {
  public init() {}

  // Implementing required protocol methods from LoggingServiceProtocol

  public func verbose(_ message: String, metadata: LogMetadata?, source: String?) async {
    await logWithLevel(.verbose, message: message, metadata: metadata, source: source)
  }

  public func debug(_ message: String, metadata: LogMetadata?, source: String?) async {
    await logWithLevel(.debug, message: message, metadata: metadata, source: source)
  }

  public func info(_ message: String, metadata: LogMetadata?, source: String?) async {
    await logWithLevel(.info, message: message, metadata: metadata, source: source)
  }

  public func warning(_ message: String, metadata: LogMetadata?, source: String?) async {
    await logWithLevel(.warning, message: message, metadata: metadata, source: source)
  }

  public func error(_ message: String, metadata: LogMetadata?, source: String?) async {
    await logWithLevel(.error, message: message, metadata: metadata, source: source)
  }

  public func critical(_ message: String, metadata: LogMetadata?, source: String?) async {
    await logWithLevel(.critical, message: message, metadata: metadata, source: source)
  }

  public func addDestination(_ destination: LogDestination) async throws {
    // Implementation would add destination to a collection
    print("Added log destination: \(destination.identifier)")
  }

  public func removeDestination(withIdentifier identifier: String) async -> Bool {
    // Implementation would remove destination from a collection
    print("Removed log destination: \(identifier)")
    return true
  }

  public func setMinimumLogLevel(_ level: UmbraLogLevel) async {
    // Implementation would set minimum log level
    print("Set minimum log level to: \(level)")
  }

  public func getMinimumLogLevel() async -> UmbraLogLevel {
    // Implementation would return current minimum log level
    .info
  }

  public func flushAllDestinations() async throws {
    // Implementation would flush all destinations
    print("Flushed all log destinations")
  }

  // Private helper method
  private func logWithLevel(
    _ level: UmbraLogLevel,
    message: String,
    metadata: LogMetadata?,
    source: String?
  ) async {
    // Format and print the log message
    let timestamp=formatTimestamp(Date())
    let levelString=formatLevel(level)
    let sourceInfo=source != nil ? "[\(source!)]" : ""

    var metadataString=""
    if let metadata {
      var metadataItems=[String]()
      // Access the asDictionary property to get a standard dictionary to iterate over
      for (key, value) in metadata.asDictionary {
        metadataItems.append("\(key): \(value)")
      }
      if !metadataItems.isEmpty {
        metadataString=" {" + metadataItems.joined(separator: ", ") + "}"
      }
    }

    print("\(timestamp) \(levelString) \(sourceInfo) \(message)\(metadataString)")
  }

  private func formatTimestamp(_ date: Date) -> String {
    let formatter=DateFormatter()
    formatter.dateFormat="yyyy-MM-dd HH:mm:ss.SSS"
    return formatter.string(from: date)
  }

  private func formatLevel(_ level: UmbraLogLevel) -> String {
    switch level {
      case .verbose: "[VERBOSE]"
      case .debug: "[DEBUG]"
      case .info: "[INFO] "
      case .warning: "[WARN] "
      case .error: "[ERROR]"
      case .critical: "[CRITICAL]"
    }
  }
}

// Helper actor to adapt LoggingServiceProtocol to LoggingProtocol
public actor BasicLoggingProtocol: LoggingProtocol {
  private let service: LoggingServiceProtocol
  private let domainName: String
  private let baseMetadata: LogMetadataDTOCollection
  public let loggingActor: LoggingActor

  init(service: LoggingServiceProtocol, domainName: String, metadata: LogMetadataDTOCollection) {
    self.service=service
    self.domainName=domainName
    baseMetadata=metadata
    // Create a simple logging actor with no destinations since we'll delegate
    // all logging to the service
    loggingActor=LoggingActor(destinations: [])
  }

  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    // Convert metadata to LogMetadata format
    var metadataDict=LogMetadata()
    var combinedMetadata=baseMetadata

    // Add context metadata to base metadata
    for entry in context.metadata.entries {
      combinedMetadata=combinedMetadata.with(
        key: entry.key,
        value: entry.value,
        privacyLevel: entry.privacyLevel
      )
    }

    // Convert to LogMetadata for the service
    for entry in combinedMetadata.entries {
      metadataDict[entry.key]=entry.value
    }

    // Map LogLevel to UmbraLogLevel
    let umbraLevel: UmbraLogLevel=switch level {
      case .trace:
        .debug // Map trace to debug as we don't have a direct mapping
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }

    // Log through the service with the appropriate method
    switch umbraLevel {
      case .verbose:
        await service.verbose(message, metadata: metadataDict, source: context.source)
      case .debug:
        await service.debug(message, metadata: metadataDict, source: context.source)
      case .info:
        await service.info(message, metadata: metadataDict, source: context.source)
      case .warning:
        await service.warning(message, metadata: metadataDict, source: context.source)
      case .error:
        await service.error(message, metadata: metadataDict, source: context.source)
      case .critical:
        await service.critical(message, metadata: metadataDict, source: context.source)
    }
  }
}
