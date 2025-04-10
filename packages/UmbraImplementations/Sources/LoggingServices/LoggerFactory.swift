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
   Creates a domain logger for key management operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for key management
   */
  public static func createKeyManagementLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)
      .withPublic(key: "component", value: "KeyManagement")

    return createDomainLoggerInternal(
      domainName: "KeyManagement",
      metadata: metadata,
      source: source
    )
  }

  /**
   Creates a domain logger for network operations

   - Parameter source: The source component creating the logger
   - Returns: A privacy-aware domain logger for network operations
   */
  public static func createNetworkLogger(source: String) -> DomainLogger {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "source", value: source)
      .withPublic(key: "component", value: "Network")

    return createDomainLoggerInternal(
      domainName: "Network",
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
      defaultPrivacyLevel: privacyLevel
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
    subsystem: String="com.umbra.security",
    category: String,
    includeTimestamps: Bool=true
  ) async -> SecureLoggerActor {
    // Create a logging service actor
    let loggingServiceActor=await LoggingServiceFactory.shared.createDefault()

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
  /// The minimum log level to display
  private let minimumLogLevel: UmbraLogLevel = .info

  public init() {}

  // Implementing required protocol methods from LoggingServiceProtocol

  public func verbose(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    await logWithLevel(.verbose, message: message, metadata: metadata, source: source)
  }

  public func debug(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.debug, message: message, metadata: metadata, source: source)
  }

  public func info(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.info, message: message, metadata: metadata, source: source)
  }

  public func warning(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    await logWithLevel(.warning, message: message, metadata: metadata, source: source)
  }

  public func error(_ message: String, metadata: LogMetadataDTOCollection?, source: String?) async {
    await logWithLevel(.error, message: message, metadata: metadata, source: source)
  }

  public func critical(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
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
    let formattedMessage=formatMessage(message, metadata: metadata, source: source)

    // Print to console (in a real implementation, this would go to the configured destinations)
    print("[\(level)] \(formattedMessage)")
  }

  /// Format a log message with metadata
  private func formatMessage(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) -> String {
    var result=message

    // Add source if available
    if let source, !source.isEmpty {
      result="[\(source)] \(result)"
    }

    // Add metadata if available
    if let metadata, !metadata.entries.isEmpty {
      result="\(result) \(formatMetadata(metadata))"
    }

    return result
  }

  /// Format metadata as a string
  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    var parts: [String]=[]

    for entry in metadata.entries {
      // Format based on privacy level
      let value=switch entry.privacyLevel {
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
public actor BasicLoggingProtocol: LoggingProtocol, CoreLoggingProtocol {
  private let service: LoggingServiceProtocol
  private let domainName: String
  private let baseMetadata: LogMetadataDTOCollection
  public let loggingActor: LoggingActor

  public init(
    service: LoggingServiceProtocol,
    domainName: String,
    metadata: LogMetadataDTOCollection
  ) {
    self.service=service
    self.domainName=domainName
    baseMetadata=metadata
    loggingActor=LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  public func debug(_ message: String, context: LogContextDTO?=nil) async {
    let metadata=createMetadata(context)
    await service.debug(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func info(_ message: String, context: LogContextDTO?=nil) async {
    let metadata=createMetadata(context)
    await service.info(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func warning(_ message: String, context: LogContextDTO?=nil) async {
    let metadata=createMetadata(context)
    await service.warning(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func error(_ message: String, context: LogContextDTO?=nil) async {
    let metadata=createMetadata(context)
    await service.error(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func critical(_ message: String, context: LogContextDTO?=nil) async {
    let metadata=createMetadata(context)
    await service.critical(message, metadata: metadata, source: context?.source ?? domainName)
  }

  public func trace(_ message: String, context: LogContextDTO?=nil) async {
    // For trace, we use debug level but add additional context
    await log(
      .trace,
      message,
      context: context ?? BaseLogContextDTO(
        domainName: domainName,
        source: domainName,
        metadata: baseMetadata
      )
    )
  }

  /// Core logging method required by CoreLoggingProtocol
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log as DTO
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let metadata=createMetadata(context)

    switch level {
      case .trace:
        await service.verbose(message, metadata: metadata, source: context.source)
      case .debug:
        await service.debug(message, metadata: metadata, source: context.source)
      case .info:
        await service.info(message, metadata: metadata, source: context.source)
      case .warning:
        await service.warning(message, metadata: metadata, source: context.source)
      case .error:
        await service.error(message, metadata: metadata, source: context.source)
      case .critical:
        await service.critical(message, metadata: metadata, source: context.source)
    }
  }

  private func createMetadata(_ context: LogContextDTO?) -> LogMetadataDTOCollection {
    var metadata: LogMetadataDTOCollection=baseMetadata

    // Add context metadata if available
    if let context {
      metadata=metadata
        .withPublic(key: "domain", value: domainName)
      if let correlationID=context.correlationID {
        metadata=metadata.withPublic(key: "correlationID", value: correlationID)
      }
    }

    return metadata
  }
}

/**
 # OSLogger Adapter

 An actor that implements LoggingProtocol using OSLog.
 This provides compatibility with the APIServices logger style.
 */
public actor OSLoggerAdapter: LoggingProtocol, CoreLoggingProtocol {
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
     - defaultPrivacyLevel: The default privacy level for log entries
   */
  public init(
    subsystem: String,
    category: String,
    defaultPrivacyLevel: LogPrivacyLevel = .private
  ) {
    logger=OSLog(subsystem: subsystem, category: category)
    self.defaultPrivacyLevel=defaultPrivacyLevel
    loggingActor=LoggingActor(destinations: [], minimumLogLevel: .info)
  }

  /// Core logging method required by CoreLoggingProtocol
  /// - Parameters:
  ///   - level: The severity level of the log
  ///   - message: The message to log
  ///   - context: The context information for the log as DTO
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    let osLogType=convertToOSLogType(level)
    let source=context.source
    let metadata=context.metadata

    // Format the log message
    let formattedMessage=formatLogMessage(message, source: source, metadata: metadata)

    // Log to OS log
    os_log("%{public}@", log: logger, type: osLogType, formattedMessage)
  }

  /// Convert LogLevel to OSLogType
  private func convertToOSLogType(_ level: LogLevel) -> OSLogType {
    switch level {
      case .trace, .debug:
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

  /// Format a log message with source and metadata
  private func formatLogMessage(
    _ message: String,
    source: String?,
    metadata: LogMetadataDTOCollection?
  ) -> String {
    var components: [String]=[]

    // Add source if available
    if let source, !source.isEmpty {
      components.append("[\(source)]")
    }

    // Add message
    components.append(message)

    // Format metadata if available
    if let metadataCollection=metadata {
      let metadataString=formatMetadata(metadataCollection)
      if !metadataString.isEmpty {
        components.append(metadataString)
      }
    }

    return components.joined(separator: " ")
  }

  /// Format metadata to a string
  private func formatMetadata(_ metadata: LogMetadataDTOCollection) -> String {
    guard !metadata.isEmpty else {
      return ""
    }

    let parts: [String]=metadata.entries.map { entry in
      "\(entry.key)=\(entry.value)"
    }

    return "{ " + parts.joined(separator: ", ") + " }"
  }
}
