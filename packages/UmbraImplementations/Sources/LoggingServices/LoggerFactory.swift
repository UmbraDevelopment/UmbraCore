import Foundation
import LoggingInterfaces
import LoggingTypes
import os.log

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
 
 // Create a logger with subsystem and category (OSLog style)
 let osLogger = LoggerFactory.createOSLogger(
     subsystem: "com.example.myapp",
     category: "networking"
 )
 ```
 */
public enum LoggerFactory {
  /// Shared logging service instance for all loggers
  private static let sharedLoggingService = DefaultLoggingService()

  /**
   Creates a domain logger for core framework operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for core operations
   */
  public static func createCoreLogger(source: String) -> DomainLogger {
    let metadata = LogMetadataDTOCollection()
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
    let metadata = LogMetadataDTOCollection()
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
    let metadata = LogMetadataDTOCollection()
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
    let metadata = LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)

    return createDomainLoggerInternal(domainName: "FileSystem", metadata: metadata, source: source)
  }

  /**
   Creates a domain logger for key management operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for key management operations
   */
  public static func createKeyManagementLogger(source: String) -> DomainLogger {
    let metadata = LogMetadataDTOCollection()
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
    let metadata = LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)

    return createDomainLoggerInternal(domainName: domainName, metadata: metadata, source: source)
  }
  
  /**
   Creates a logger with the specified subsystem and category using OSLog.
   
   This method provides compatibility with the APIServices logger style.

   - Parameters:
     - subsystem: The subsystem for the logger (typically reverse-DNS notation)
     - category: The category for the logger
     - privacyLevel: The default privacy level
   - Returns: A configured logger
   */
  public static func createOSLogger(
    subsystem: String,
    category: String,
    privacyLevel: LogPrivacyLevel = .private
  ) -> LoggingProtocol {
    OSLoggerAdapter(
      subsystem: subsystem,
      category: category,
      privacyLevel: privacyLevel
    )
  }
  
  /**
   Creates a logger with the specified configuration.
   
   This method provides compatibility with the APIServices logger style.

   - Parameters:
     - subsystem: The subsystem for the logger (typically reverse-DNS notation)
     - category: The category for the logger
     - privacyLevel: The default privacy level
   - Returns: A configured logger
   */
  public static func createLogger(
    subsystem: String,
    category: String,
    privacyLevel: LogPrivacyLevel = .private
  ) -> LoggingProtocol {
    createOSLogger(
      subsystem: subsystem,
      category: category,
      privacyLevel: privacyLevel
    )
  }

  /**
   Creates a secure logger actor with the specified configuration.

   - Parameters:
      - subsystem: The subsystem identifier (typically the application bundle identifier)
      - category: The category for this logger (typically the component name)
      - includeTimestamps: Whether to include timestamps in log messages
      - loggingServiceActor: Optional logging service actor for integration with the wider logging system

   - Returns: A new SecureLoggerActor instance
   */
  public static func createSecureLogger(
    subsystem: String = "com.umbra.security",
    category: String,
    includeTimestamps: Bool = true,
    loggingServiceActor: LoggingServiceActor? = nil
  ) -> SecureLoggerActor {
    SecureLoggerActor(
      subsystem: subsystem,
      category: category,
      includeTimestamps: includeTimestamps,
      loggingServiceActor: loggingServiceActor
    )
  }

  /**
   Creates a secure logger actor that integrates with the default logging system.

   This factory method automatically creates a logger that will send logs both
   to the system logging facility and to the default logging service.

   - Parameters:
      - subsystem: The subsystem identifier
      - category: The category for this logger
      - includeTimestamps: Whether to include timestamps in log messages

   - Returns: A new SecureLoggerActor instance integrated with the default logging service
   */
  public static func createIntegratedSecureLogger(
    subsystem: String = "com.umbra.security",
    category: String,
    includeTimestamps: Bool = true
  ) async -> SecureLoggerActor {
    // Create a logging service actor
    let loggingServiceActor = await LoggingServiceFactory.shared.createDefault()

    // Create a secure logger that integrates with the logging service
    return SecureLoggerActor(
      subsystem: subsystem,
      category: category,
      includeTimestamps: includeTimestamps,
      loggingServiceActor: loggingServiceActor
    )
  }

  static func createDomainLoggerInternal(
    domainName: String,
    metadata: LogMetadataDTOCollection,
    source: String
  ) -> DomainLogger {
    // Create a logging protocol to pass to the BaseDomainLogger
    let loggingProtocol = BasicLoggingProtocol(
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

  public func verbose(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.verbose, message: message, metadata: metadata, source: source)
  }

  public func debug(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.debug, message: message, metadata: metadata, source: source)
  }

  public func info(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.info, message: message, metadata: metadata, source: source)
  }

  public func warning(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.warning, message: message, metadata: metadata, source: source)
  }

  public func error(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.error, message: message, metadata: metadata, source: source)
  }

  public func critical(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
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

  // MARK: - Private Implementation

  private func logWithLevel(
    _ level: UmbraLogLevel,
    message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    // Only log if the level is at or above the minimum level
    guard level.rawValue >= minimumLogLevel.rawValue else {
      return
    }

    // Format the message with metadata
    let formattedMessage = formatMessage(message, metadata: metadata, source: source)
    
    // Print to console (in a real implementation, this would go to the configured destinations)
    print("[\(level)] \(formattedMessage)")
  }
  
  /// Format a log message with metadata
  private func formatMessage(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) -> String {
    var result = message
    
    // Add source if available
    if let source = source, !source.isEmpty {
      result = "[\(source)] \(result)"
    }
    
    // Add metadata if available
    if let metadata = metadata, !metadata.entries.isEmpty {
      result = "\(result) \(formatMetadata(metadata))"
    }
    
    return result
  }
  
  /// Format metadata as a string
  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String] = []
    
    for entry in metadata.entries {
      // Format based on privacy level
      let value = switch entry.privacyLevel {
        case .public:
          entry.value
        case .private:
          "<private>"
        case .sensitive:
          "<sensitive>"
        case .hash:
          "<hash>"
        case .auto:
          "<auto-redacted>"
      }
      
      parts.append("\(entry.key)=\(value)")
    }
    
    return "{\(parts.joined(separator: ", "))}"
  }
}

/**
 # Basic Logging Protocol

 A simple actor-based implementation of the LoggingProtocol that delegates
 to a LoggingServiceProtocol.
 */
public actor BasicLoggingProtocol: LoggingProtocol {
  private let service: LoggingServiceProtocol
  private let domainName: String
  private let baseMetadata: LogMetadataDTOCollection
  public let loggingActor: LoggingActor

  public init(
    service: LoggingServiceProtocol,
    domainName: String,
    metadata: LogMetadataDTOCollection
  ) {
    self.service = service
    self.domainName = domainName
    self.baseMetadata = metadata
    self.loggingActor = LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  public func debug(_ message: String, context: LogContextDTO? = nil) async {
    let metadata = createMetadata(context)
    await service.debug(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func info(_ message: String, context: LogContextDTO? = nil) async {
    let metadata = createMetadata(context)
    await service.info(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func warning(_ message: String, context: LogContextDTO? = nil) async {
    let metadata = createMetadata(context)
    await service.warning(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func error(_ message: String, context: LogContextDTO? = nil) async {
    let metadata = createMetadata(context)
    await service.error(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func critical(_ message: String, context: LogContextDTO? = nil) async {
    let metadata = createMetadata(context)
    await service.critical(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func trace(_ message: String, context: LogContextDTO? = nil) async {
    let metadata = createMetadata(context)
    await service.verbose(message, metadata: metadata, source: context?.source ?? domainName)
  }

  private func createMetadata(_ context: LogContextDTO?) -> LogMetadataDTOCollection {
    var metadata: LogMetadataDTOCollection = baseMetadata

    // Add context metadata if available
    if let context = context {
      metadata = metadata
        .withPublic(key: "domain", value: domainName)
      if let correlationID = context.correlationID {
        metadata = metadata.withPublic(key: "correlationID", value: correlationID)
      }
    }

    return metadata
  }
}

/**
 # OSLogger Adapter

 An adapter that implements LoggingProtocol using OSLog.
 This provides compatibility with the APIServices logger style.
 */
public class OSLoggerAdapter: LoggingProtocol {
  /// The underlying system logger
  private let logger: OSLog

  /// Default privacy level for this logger
  private let defaultPrivacyLevel: LogPrivacyLevel
  
  /// Actor for async operations
  public let loggingActor: LoggingActor

  /**
   Initialises a new OS logger adapter.

   - Parameters:
     - subsystem: The subsystem for the logger
     - category: The category for the logger
     - privacyLevel: The default privacy level
   */
  public init(
    subsystem: String,
    category: String,
    privacyLevel: LogPrivacyLevel
  ) {
    logger = OSLog(subsystem: subsystem, category: category)
    defaultPrivacyLevel = privacyLevel
    loggingActor = LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  // MARK: - LoggingProtocol Methods

  public func debug(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .debug, context: context)
  }

  public func info(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .info, context: context)
  }

  public func warning(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .default, context: context)
  }

  public func error(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .error, context: context)
  }

  public func critical(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .fault, context: context)
  }

  public func trace(_ message: String, context: LogContextDTO? = nil) async {
    // For trace, we use debug level but add additional context
    log("TRACE: \(message)", type: .debug, context: context)
  }

  // MARK: - Private Helper Methods

  private func log(_ message: String, type: OSLogType, context: LogContextDTO?) {
    let contextInfo = formatContext(context)
    os_log("%{public}s %{private}s", log: logger, type: type, message, contextInfo)
  }

  private func formatContext(_ context: LogContextDTO?) -> String {
    guard let context else {
      return ""
    }

    var parts: [String] = []

    if let source = context.source {
      parts.append("src=\(source)")
    }

    if let correlationID = context.correlationID {
      parts.append("corr=\(correlationID)")
    }

    // Format metadata as key-value pairs
    if let metadataCollection = context.metadata as? LogMetadataDTOCollection {
      let metadataString = formatMetadata(metadataCollection)
      if !metadataString.isEmpty {
        parts.append(metadataString)
      }
    }

    return parts.isEmpty ? "" : "[\(parts.joined(separator: ", "))]"
  }

  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String] = []

    // Add public keys
    for (key, value) in metadata.publicKeyValues {
      parts.append("\(key)=\(value)")
    }

    // Add private keys in a privacy-conscious way
    for key in metadata.privateKeys {
      parts.append("\(key)=<private>")
    }

    return parts.joined(separator: ", ")
  }
}

/**
 # SecureLoggerActor

 A secure logger actor that integrates with the system logging facility and
 an optional logging service actor.

 This actor provides a secure logging solution that meets the requirements of
 the Alpha Dot Five architecture principles.
 */
public actor SecureLoggerActor: LoggingProtocol {
  // MARK: - Properties

  /// The subsystem identifier for this logger
  public let subsystem: String

  /// The category for this logger
  public let category: String

  /// Whether to include timestamps in log messages
  public let includeTimestamps: Bool

  /// Optional logging service actor for integration with the wider logging system
  public let loggingServiceActor: LoggingServiceActor?

  /// Actor for async operations
  public let loggingActor: LoggingActor

  // MARK: - Initialisation

  /**
   Initialises a new SecureLoggerActor instance.

   - Parameters:
     - subsystem: The subsystem identifier (typically the application bundle identifier)
     - category: The category for this logger (typically the component name)
     - includeTimestamps: Whether to include timestamps in log messages
     - loggingServiceActor: Optional logging service actor for integration with the wider logging system
   */
  public init(
    subsystem: String,
    category: String,
    includeTimestamps: Bool,
    loggingServiceActor: LoggingServiceActor? = nil
  ) {
    self.subsystem = subsystem
    self.category = category
    self.includeTimestamps = includeTimestamps
    self.loggingServiceActor = loggingServiceActor
    self.loggingActor = LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  // MARK: - LoggingProtocol Methods

  public func debug(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .debug, context: context)
  }

  public func info(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .info, context: context)
  }

  public func warning(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .default, context: context)
  }

  public func error(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .error, context: context)
  }

  public func critical(_ message: String, context: LogContextDTO? = nil) async {
    log(message, type: .fault, context: context)
  }

  public func trace(_ message: String, context: LogContextDTO? = nil) async {
    // For trace, we use debug level but add additional context
    log("TRACE: \(message)", type: .debug, context: context)
  }

  // MARK: - Private Helper Methods

  private func log(_ message: String, type: OSLogType, context: LogContextDTO?) {
    let contextInfo = formatContext(context)
    os_log("%{public}s %{private}s", log: OSLog(subsystem: subsystem, category: category), type: type, message, contextInfo)
  }

  private func formatContext(_ context: LogContextDTO?) -> String {
    guard let context else {
      return ""
    }

    var parts: [String] = []

    if let source = context.source {
      parts.append("src=\(source)")
    }

    if let correlationID = context.correlationID {
      parts.append("corr=\(correlationID)")
    }

    // Format metadata as key-value pairs
    if let metadataCollection = context.metadata as? LogMetadataDTOCollection {
      let metadataString = formatMetadata(metadataCollection)
      if !metadataString.isEmpty {
        parts.append(metadataString)
      }
    }

    return parts.isEmpty ? "" : "[\(parts.joined(separator: ", "))]"
  }

  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String] = []

    // Add public keys
    for (key, value) in metadata.publicKeyValues {
      parts.append("\(key)=\(value)")
    }

    // Add private keys in a privacy-conscious way
    for key in metadata.privateKeys {
      parts.append("\(key)=<private>")
    }

    return parts.joined(separator: ", ")
  }
}
