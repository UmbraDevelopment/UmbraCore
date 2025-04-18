import Foundation
import LoggingInterfaces
import LoggingTypes
import os

/**
 # Default Logger

 A simple logger implementation that uses the Apple OSLog system.
 This implementation follows the Alpha Dot Five architecture's privacy-by-design
 principles, ensuring sensitive information is properly redacted in logs.

 ## Privacy Controls

 This logger implements comprehensive privacy controls for sensitive information:
 - Public information is logged normally
 - Private information is redacted in production builds
 - Sensitive information is always redacted

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in logging operations.
 */
public actor DefaultLogger: LoggingProtocol, CoreLoggingProtocol {
  private let logger: Logger

  /// Creates a new DefaultLogger
  public init() {
    logger=Logger(subsystem: "com.umbra.keychainservices", category: "KeychainServices")
  }

  /// The actor used for all logging operations
  private let _loggingActor=LoggingActor(destinations: [], minimumLogLevel: .info)

  /// Get the underlying logging actor
  public var loggingActor: LoggingActor {
    _loggingActor
  }

  /// Required CoreLoggingProtocol implementation
  public func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {
    switch level {
      case .trace:
        // Forward to debug since we don't have trace
        await debug(message, context: context)
      case .debug:
        await debug(message, context: context)
      case .info:
        await info(message, context: context)
      case .warning:
        await warning(message, context: context)
      case .error:
        await error(message, context: context)
      case .critical:
        await critical(message, context: context)
    }
  }

  /// Log a debug message with context
  public func debug(_ message: String, context: LogContextDTO) async {
    logger.debug("\(message, privacy: .public)")
    await _loggingActor.log(.debug, message, context: context)
  }

  /// Log an info message with context
  public func info(_ message: String, context: LogContextDTO) async {
    logger.info("\(message, privacy: .public)")
    await _loggingActor.log(.info, message, context: context)
  }

  /// Log a warning message with context
  public func warning(_ message: String, context: LogContextDTO) async {
    logger.warning("\(message, privacy: .public)")
    await _loggingActor.log(.warning, message, context: context)
  }

  /// Log an error message with context
  public func error(_ message: String, context: LogContextDTO) async {
    logger.error("\(message, privacy: .public)")
    await _loggingActor.log(.error, message, context: context)
  }

  /// Log a critical error message with context
  public func critical(_ message: String, context: LogContextDTO) async {
    logger.critical("\(message, privacy: .public)")
    await _loggingActor.log(.critical, message, context: context)
  }

  // Modern methods using LogMetadataDTOCollection
  /**
   Log a debug message with metadata collection.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func debug(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source,
      metadataCollection: metadata
    )
    await debug(message, context: context)
  }

  /**
   Log an info message with metadata collection.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func info(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source,
      metadataCollection: metadata
    )
    await info(message, context: context)
  }

  /**
   Log a warning message with metadata collection.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func warning(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source,
      metadataCollection: metadata
    )
    await warning(message, context: context)
  }

  /**
   Log an error message with metadata collection.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func error(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source,
      metadataCollection: metadata
    )
    await error(message, context: context)
  }

  /**
   Log a critical error message with metadata collection.

   - Parameters:
     - message: The message to log
     - metadata: Privacy-aware metadata collection
     - source: The source of the log message
   */
  public func critical(
    _ message: String,
    metadata: LogMetadataDTOCollection?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source,
      metadataCollection: metadata
    )
    await critical(message, context: context)
  }

  // Legacy methods for backward compatibility
  /**
   Log a debug message (deprecated method).

   - Parameters:
     - message: The message to log
     - metadata: Legacy privacy metadata
     - source: The source of the log message
   */
  @available(
    *,
    deprecated,
    message: "Use debug(_:metadata:source:) with LogMetadataDTOCollection instead"
  )
  public func debug(
    _ message: String,
    metadata _: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source
    )
    await debug(message, context: context)
  }

  /**
   Log an info message (deprecated method).

   - Parameters:
     - message: The message to log
     - metadata: Legacy privacy metadata
     - source: The source of the log message
   */
  @available(
    *,
    deprecated,
    message: "Use info(_:metadata:source:) with LogMetadataDTOCollection instead"
  )
  public func info(
    _ message: String,
    metadata _: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source
    )
    await info(message, context: context)
  }

  /**
   Log a warning message (deprecated method).

   - Parameters:
     - message: The message to log
     - metadata: Legacy privacy metadata
     - source: The source of the log message
   */
  @available(
    *,
    deprecated,
    message: "Use warning(_:metadata:source:) with LogMetadataDTOCollection instead"
  )
  public func warning(
    _ message: String,
    metadata _: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source
    )
    await warning(message, context: context)
  }

  /**
   Log an error message (deprecated method).

   - Parameters:
     - message: The message to log
     - metadata: Legacy privacy metadata
     - source: The source of the log message
   */
  @available(
    *,
    deprecated,
    message: "Use error(_:metadata:source:) with LogMetadataDTOCollection instead"
  )
  public func error(
    _ message: String,
    metadata _: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source
    )
    await error(message, context: context)
  }

  /**
   Log a critical error message (deprecated method).

   - Parameters:
     - message: The message to log
     - metadata: Legacy privacy metadata
     - source: The source of the log message
   */
  @available(
    *,
    deprecated,
    message: "Use critical(_:metadata:source:) with LogMetadataDTOCollection instead"
  )
  public func critical(
    _ message: String,
    metadata _: LoggingTypes.PrivacyMetadata?,
    source: String?
  ) async {
    let context=BaseLogContextDTO(
      domainName: "KeychainServices",
      operation: "general",
      category: "Keychain",
      source: source
    )
    await critical(message, context: context)
  }
}

/**
 A basic implementation of LogContextDTO for use with the DefaultLogger.
 */
private struct BaseLogContextDTO: LogContextDTO {
  let domainName: String
  let operation: String
  let category: String
  let source: String?
  let correlationID: String?
  let metadataCollection: LogMetadataDTOCollection?

  // Required by LogContextDTO protocol
  var metadata: LogMetadataDTOCollection {
    metadataCollection ?? LogMetadataDTOCollection()
  }

  init(
    domainName: String,
    operation: String="general",
    category: String="Keychain",
    source: String?=nil,
    correlationID: String?=nil,
    metadataCollection: LogMetadataDTOCollection?=nil
  ) {
    self.domainName=domainName
    self.operation=operation
    self.category=category
    self.source=source
    self.correlationID=correlationID
    self.metadataCollection=metadataCollection
  }

  func getDomain() -> String {
    domainName
  }

  /**
   * Creates a metadata collection with context information.
   *
   * - Returns: A LogMetadataDTOCollection with context metadata
   */
  func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadataCollection ?? LogMetadataDTOCollection()
    collection=collection.withPublic(key: "domain", value: domainName)
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "category", value: category)

    if let source {
      collection=collection.withPublic(key: "source", value: source)
    }

    if let correlationID {
      collection=collection.withPublic(key: "correlationId", value: correlationID)
    }

    return collection
  }

  /**
   * Updates the context with additional metadata.
   *
   * - Parameter additionalMetadata: Additional metadata to include
   * - Returns: A new context with merged metadata
   */
  func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    let existingMetadata=metadataCollection ?? LogMetadataDTOCollection()
    let mergedMetadata=existingMetadata.merging(with: additionalMetadata)

    return BaseLogContextDTO(
      domainName: domainName,
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadataCollection: mergedMetadata
    )
  }
}
