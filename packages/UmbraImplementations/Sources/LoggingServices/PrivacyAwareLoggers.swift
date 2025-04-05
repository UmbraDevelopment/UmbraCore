import Foundation
import LoggingInterfaces
import LoggingTypes

/// A protocol for domain-specific privacy-aware loggers
public protocol DomainLogger: Sendable {
  /// The underlying logging protocol
  var logger: LoggingProtocol { get }

  /// Log an operation start
  /// - Parameters:
  ///   - context: The context for the log
  ///   - message: Optional custom message
  func logOperationStart<T: LogContextDTO>(context: T, message: String?) async

  /// Log an operation success
  /// - Parameters:
  ///   - context: The context for the log
  ///   - result: Optional result information
  ///   - message: Optional custom message
  func logOperationSuccess<T: LogContextDTO, R>(context: T, result: R?, message: String?) async

  /// Log an operation error
  /// - Parameters:
  ///   - context: The context for the log
  ///   - error: The error that occurred
  ///   - message: Optional custom message
  func logOperationError<T: LogContextDTO>(context: T, error: Error, message: String?) async

  /**
   Logs a loggable error with enhanced privacy controls.

   - Parameters:
     - error: The error to log.
     - severity: The severity to use.
     - message: Optional custom message override.
   */
  func logLoggableError(
    _ error: LoggableErrorDTO,
    severity: LogLevel,
    message: String?
  ) async
}

/// Base implementation of domain logger
public struct BaseDomainLogger: DomainLogger {
  /// The underlying logging protocol
  public let logger: LoggingProtocol

  /// Create a new domain logger
  /// - Parameter logger: The underlying logging protocol
  public init(logger: LoggingProtocol) {
    self.logger = logger
  }

  /**
   Logs an operation start with contextual information.

   - Parameters:
      - context: The domain-specific log context
      - message: Optional custom message
   */
  public func logOperationStart(
    context: some LogContextDTO,
    message: String? = nil
  ) async {
    let logMessage = message ?? "Starting operation"
    await logger.info(logMessage, context: context)
  }

  /**
   Logs an operation success with contextual information.

   - Parameters:
      - context: The domain-specific log context
      - result: Optional operation result
      - message: Optional custom message
   */
  public func logOperationSuccess(
    context: some LogContextDTO,
    result: (some Any)?,
    message: String? = nil
  ) async {
    var updatedMetadata = context.metadata

    if let result {
      // Add result information if available and convertible to string
      if let stringValue = result as? CustomStringConvertible {
        updatedMetadata = updatedMetadata.withPrivate(
          key: "result",
          value: stringValue.description
        )
      }
    }

    let logMessage = message ?? "Operation completed successfully"
    let updatedContext = BaseLogContextDTO(
      domainName: context.domainName,
      source: context.source,
      metadata: updatedMetadata,
      correlationID: context.correlationID
    )
    await logger.info(logMessage, context: updatedContext)
  }

  /**
   Logs an operation error with contextual information.

   - Parameters:
      - context: The domain-specific log context
      - error: The error that occurred
      - message: Optional custom message
   */
  public func logOperationError(
    context: some LogContextDTO,
    error: Error,
    message: String? = nil
  ) async {
    var updatedMetadata = context.metadata

    if let loggableError = error as? LoggableErrorProtocol {
      // For structured logging errors, get their privacy metadata
      let errorMetadata = loggableError.getPrivacyMetadata()
      for entry in errorMetadata.entriesArray {
        // Add each entry with its privacy level
        switch entry.privacy {
        case .public:
          updatedMetadata = updatedMetadata.withPublic(key: entry.key, value: entry.value)
        case .private:
          updatedMetadata = updatedMetadata.withPrivate(key: entry.key, value: entry.value)
        case .sensitive:
          updatedMetadata = updatedMetadata.withSensitive(key: entry.key, value: entry.value)
        case .hash:
          updatedMetadata = updatedMetadata.withHashed(key: entry.key, value: entry.value)
        case .auto:
          updatedMetadata = updatedMetadata.withPrivate(key: entry.key, value: entry.value)
        }
        
        // Add error type with public visibility
        updatedMetadata = updatedMetadata.withPublic(
          key: "errorType",
          value: String(describing: type(of: error))
        )
      }
    }

    let logMessage = message ?? "Operation failed"
    let updatedContext = BaseLogContextDTO(
      domainName: context.domainName,
      source: context.source,
      metadata: updatedMetadata,
      correlationID: context.correlationID
    )
    await logger.error(logMessage, context: updatedContext)
  }

  /**
   Logs a loggable error with enhanced privacy controls.

   - Parameters:
     - error: The error to log.
     - severity: The severity to use.
     - message: Optional custom message override.
   */
  public func logLoggableError(
    _ error: LoggableErrorDTO,
    severity: LogLevel,
    message: String?
  ) async {
    // Use the error's built-in privacy metadata
    let metadata = error.getPrivacyMetadata()
    
    // Get source information if available
    let source = error.getSource()
    
    // Create a context from the error information with proper metadata conversion
    let metadataDTO = createMetadataCollection(from: metadata)
    let context = BaseLogContextDTO(
      domainName: "Error",
      source: source,
      metadata: metadataDTO,
      correlationID: nil
    )

    // Get the message or use the error's log message
    let logMessage = message ?? error.getLogMessage()

    // Log the error
    await logger.log(severity, logMessage, context: context)
  }
  
  // MARK: - Helper Functions

  /// Helper method to convert PrivacyMetadata to LogMetadataDTOCollection
  /// - Parameter metadata: The privacy metadata to convert
  /// - Returns: A LogMetadataDTOCollection with the same entries
  private func createMetadataCollection(from metadata: PrivacyMetadata?) -> LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    
    // If no metadata, return empty collection
    guard let metadata = metadata else {
      return collection
    }
    
    // Convert each entry based on its privacy level
    for entry in metadata.entriesArray {
      switch entry.privacy {
      case .public:
        collection = collection.withPublic(key: entry.key, value: entry.value)
      case .private:
        collection = collection.withPrivate(key: entry.key, value: entry.value)
      case .sensitive:
        collection = collection.withSensitive(key: entry.key, value: entry.value)
      case .hash:
        collection = collection.withHashed(key: entry.key, value: entry.value)
      case .auto:
        // Default to private for auto
        collection = collection.withPrivate(key: entry.key, value: entry.value)
      }
    }
    
    return collection
  }
}

/// A logger specialised for snapshot operations
public struct SnapshotLogger {
  /// The base domain logger
  private let domainLogger: DomainLogger

  /// Create a new snapshot logger
  /// - Parameter logger: The underlying logging protocol
  public init(logger: LoggingProtocol) {
    domainLogger = BaseDomainLogger(logger: logger)
  }

  /// Log a snapshot operation start
  /// - Parameters:
  ///   - snapshotID: The snapshot ID
  ///   - operation: The operation being performed
  ///   - additionalContext: Additional context information
  ///   - message: Optional custom message
  public func logOperationStart(
    snapshotID: String,
    operation: String,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    message: String? = nil
  ) async {
    let context = SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage = "Starting snapshot \(operation) operation"
    await domainLogger.logOperationStart(context: context, message: message ?? defaultMessage)
  }

  /// Log a snapshot operation success
  /// - Parameters:
  ///   - snapshotID: The snapshot ID
  ///   - operation: The operation being performed
  ///   - result: Optional result information
  ///   - additionalContext: Additional context information
  ///   - message: Optional custom message
  public func logOperationSuccess(
    snapshotID: String,
    operation: String,
    result: (some Sendable)? = nil,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    message: String? = nil
  ) async {
    let context = SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage = "Snapshot \(operation) completed successfully"
    await domainLogger.logOperationSuccess(
      context: context,
      result: result,
      message: message ?? defaultMessage
    )
  }

  /// Log a snapshot operation error
  /// - Parameters:
  ///   - snapshotID: The snapshot ID
  ///   - operation: The operation being performed
  ///   - error: The error that occurred
  ///   - additionalContext: Additional context information
  ///   - message: Optional custom message
  public func logOperationError(
    snapshotID: String,
    operation: String,
    error: Error,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    message: String? = nil
  ) async {
    let context = SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage = "Snapshot \(operation) operation failed"
    await domainLogger.logOperationError(
      context: context,
      error: error,
      message: message ?? defaultMessage
    )
  }
}

/// A logger specialised for key management operations
public struct KeyManagementLogger {
  /// The base domain logger
  private let domainLogger: DomainLogger

  /// Create a new key management logger
  /// - Parameter logger: The underlying logging protocol
  public init(logger: LoggingProtocol) {
    domainLogger = BaseDomainLogger(logger: logger)
  }

  /// Log a key management operation start
  /// - Parameters:
  ///   - keyIdentifier: The key identifier
  ///   - operation: The operation being performed
  ///   - additionalContext: Additional context information
  ///   - message: Optional custom message
  public func logOperationStart(
    keyIdentifier: String,
    operation: String,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    message: String? = nil
  ) async {
    let context = KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage = "Starting key \(operation) operation"
    await domainLogger.logOperationStart(context: context, message: message ?? defaultMessage)
  }

  /// Log a key management operation success
  /// - Parameters:
  ///   - keyIdentifier: The key identifier
  ///   - operation: The operation being performed
  ///   - result: Optional result information
  ///   - additionalContext: Additional context information
  ///   - message: Optional custom message
  public func logOperationSuccess(
    keyIdentifier: String,
    operation: String,
    result: (some Sendable)? = nil,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    message: String? = nil
  ) async {
    let context = KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage = "Key \(operation) completed successfully"
    await domainLogger.logOperationSuccess(
      context: context,
      result: result,
      message: message ?? defaultMessage
    )
  }

  /// Log a key management operation error
  /// - Parameters:
  ///   - keyIdentifier: The key identifier
  ///   - operation: The operation being performed
  ///   - error: The error that occurred
  ///   - additionalContext: Additional context information
  ///   - message: Optional custom message
  public func logOperationError(
    keyIdentifier: String,
    operation: String,
    error: Error,
    additionalContext: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    message: String? = nil
  ) async {
    let context = KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage = "Key \(operation) operation failed"
    await domainLogger.logOperationError(
      context: context,
      error: error,
      message: message ?? defaultMessage
    )
  }
}

/// A domain-specific logger for keychain security operations.

/// This logger is specialized for keychain operations, providing appropriate
/// privacy controls for logging account information, keychain operations,
/// and access policies.
public struct KeychainLogger {
  private let logger: LoggingProtocol
  private let domain: String

  /**
   Initializes a new instance of KeychainLogger.

   - Parameter logger: The underlying logger to use for logging operations.
   - Parameter domain: The domain for this logger.
   */
  public init(logger: LoggingProtocol, domain: String = "Keychain") {
    self.logger = logger
    self.domain = domain
  }

  /**
   Logs the start of a keychain operation.

   - Parameters:
      - account: The account identifier associated with the operation.
      - operation: The type of operation being performed.
      - keyIdentifier: Optional identifier for the encryption key.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationStart(
    account: String,
    operation: String,
    keyIdentifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    // Create base metadata with operation information
    var context = LogMetadataDTOCollection()
      .withPrivate(key: "account", value: account)
      .withPublic(key: "operation", value: operation)

    // Add key identifier if available
    if let keyIdentifier {
      context = context.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    // Merge with additional context if provided
    if let additionalContext {
      context = context.merging(with: additionalContext)
    }

    // Create the keychain context
    let keychainContext = KeychainLogContext(
      account: account,
      operation: operation,
      additionalContext: context
    )

    // Create the log message
    let defaultMessage = "Starting keychain operation: \(operation)"
    let logMessage = message ?? defaultMessage
    
    // Log the operation start with a proper context
    await logger.info(logMessage, context: keychainContext)
  }

  /**
   Logs an error that occurred during a keychain operation.

   - Parameters:
      - account: The account identifier associated with the operation.
      - operation: The operation during which the error occurred.
      - error: The error that occurred.
      - keyIdentifier: Optional identifier for the encryption key.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logError(
    account: String,
    operation: String,
    error: Error,
    keyIdentifier: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    // Create base metadata with operation and error information
    var context = LogMetadataDTOCollection()
      .withPrivate(key: "account", value: account)
      .withPublic(key: "operation", value: operation)
      .withPrivate(key: "error", value: error.localizedDescription)
      .withPrivate(key: "errorType", value: String(describing: type(of: error)))

    // Add key identifier if available
    if let keyIdentifier {
      context = context.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    // Merge with additional context if provided
    if let additionalContext {
      context = context.merging(with: additionalContext)
    }

    // Create the keychain context
    let keychainContext = KeychainLogContext(
      account: account,
      operation: operation,
      additionalContext: context
    )

    // Create the log message
    let defaultMessage = "Error during keychain operation: \(operation)"
    let logMessage = message ?? defaultMessage
    
    // Log the error with proper context
    await logger.error(logMessage, context: keychainContext)
  }
}

/// A logger specialised for cryptographic operations.

/// This logger is specialised for cryptographic operations, providing appropriate
/// privacy controls for logging cryptographic algorithms, key identifiers,
/// and operation results.
public struct CryptoLogger {
  private let logger: LoggingProtocol
  private let domain: String

  /**
   Initialises a new instance of CryptoLogger.

   - Parameters:
      - logger: The underlying logger to use.
      - domain: The domain for this logger.
   */
  public init(logger: LoggingProtocol, domain: String = "Crypto") {
    self.logger = logger
    self.domain = domain
  }

  /**
   Logs a cryptographic operation start with enhanced privacy controls.

   - Parameters:
      - operation: The operation being performed.
      - algorithm: Optional cryptographic algorithm used.
      - keyID: Optional key identifier used.
      - additionalContext: Optional additional context.
      - message: Optional custom message.
   */
  public func logOperationStart(
    operation: String,
    algorithm: String? = nil,
    keyID: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    // Create base metadata with operation information
    var context = LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)

    // Add algorithm information if available
    if let algorithm {
      context = context.withPublic(key: "algorithm", value: algorithm)
    }

    // Add key ID if available (as private data)
    if let keyID {
      context = context.withPrivate(key: "keyID", value: keyID)
    }

    // Merge with additional context if provided
    if let additionalContext {
      context = context.merging(with: additionalContext)
    }

    // Create the crypto context
    let cryptoContext = CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      additionalContext: context
    )

    // Create the log message
    let defaultMessage = "Starting cryptographic operation: \(operation)"
    let logMessage = message ?? defaultMessage

    // Log the operation start with proper context
    await logger.info(logMessage, context: cryptoContext)
  }

  /**
   Logs an error that occurred during a cryptographic operation.

   - Parameters:
      - operation: The operation during which the error occurred.
      - error: The error that occurred.
      - algorithm: Optional cryptographic algorithm used.
      - keyID: Optional key identifier used.
      - additionalContext: Optional additional context.
      - message: Optional custom message.
   */
  public func logError(
    operation: String,
    error: Error,
    algorithm: String? = nil,
    keyID: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    // Create base metadata with operation and error information
    var context = LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPrivate(key: "error", value: error.localizedDescription)
      .withPrivate(key: "errorType", value: String(describing: type(of: error)))

    // Add algorithm information if available
    if let algorithm {
      context = context.withPublic(key: "algorithm", value: algorithm)
    }

    // Add key ID if available (as private data)
    if let keyID {
      context = context.withPrivate(key: "keyID", value: keyID)
    }

    // Merge with additional context if provided
    if let additionalContext {
      context = context.merging(with: additionalContext)
    }

    // Create the crypto context
    let cryptoContext = CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      additionalContext: context
    )

    // Create the log message
    let defaultMessage = "Error during cryptographic operation: \(operation)"
    let logMessage = message ?? defaultMessage
    
    // Log the error with proper context
    await logger.error(logMessage, context: cryptoContext)
  }
}

/**
 A domain-specific logger for error handling operations.

 This logger is specialised for error operations, providing appropriate
 privacy controls for logging errors, their sources, and contextual metadata.
 */
public class EnhancedErrorLogger: LegacyErrorLoggingProtocol {
  private let logger: LoggingProtocol

  /**
   Initialises a new instance of EnhancedErrorLogger.

   - Parameter logger: The underlying logger to use.
   */
  public init(logger: LoggingProtocol) {
    self.logger = logger
  }

  /**
   Logs a loggable error with enhanced privacy controls.

   - Parameters:
     - error: The loggable error to log.
     - level: The log level to use.
     - message: Optional custom message override.
   */
  public func logLoggableError(
    _ error: LoggableErrorDTO,
    level: LogLevel,
    message: String?
  ) async {
    let metadata = error.getPrivacyMetadata()
    let source = error.getSource()
    let logMessage = message ?? error.getLogMessage()
    
    // Create a context from the error information
    let metadataDTO = createMetadataCollection(from: metadata)
    let context = BaseLogContextDTO(
      domainName: "Error",
      source: source,
      metadata: metadataDTO,
      correlationID: nil
    )

    await logger.log(level, logMessage, context: context)
  }

  /**
   Logs an error with privacy controls.

   - Parameters:
     - error: The error to log.
     - level: The log level to use.
     - metadata: Metadata for the error.
     - source: The source of the error.
     - message: Optional custom message.
   */
  public func logError(
    _ error: Error,
    level: LogLevel,
    metadata: PrivacyMetadata?,
    source: String,
    message: String?
  ) async {
    let logMessage = message ?? "Error: \(error.localizedDescription)"
    
    // Create a context from the error information
    let context = BaseLogContextDTO(
      domainName: "Error",
      source: source,
      metadata: createMetadataCollection(from: metadata),
      correlationID: nil
    )
    
    await logger.log(level, logMessage, context: context)
  }

  /**
   Logs an error with contextual information.

   - Parameters:
     - error: The error to log.
     - context: The error context containing privacy metadata.
     - message: Optional custom message.
   */
  public func logContextualError(
    _ error: Error,
    context: ErrorLogContext,
    message: String? = nil
  ) async {
    // Create updated metadata collection
    var updatedMetadata = LogMetadataDTOCollection()
    
    // Add error metadata
    updatedMetadata = updatedMetadata.withPrivate(
      key: "errorDescription",
      value: error.localizedDescription
    )
    
    updatedMetadata = updatedMetadata.withPublic(
      key: "errorType",
      value: String(describing: type(of: error))
    )
    
    // If this is a loggable error, add structured details
    if let loggableError = error as? LoggableErrorDTO {
      // Get structured error information
      _ = loggableError.getLogMessage()
      
      // Add error metadata
      updatedMetadata = updatedMetadata.merging(with: createMetadataCollection(
        from: loggableError.getPrivacyMetadata())
      )
    }
    
    // Create a context with updated metadata
    let logContext = BaseLogContextDTO(
      domainName: "Error",
      source: context.source,
      metadata: updatedMetadata.merging(with: context.metadata),
      correlationID: nil
    )
    
    // Get the message or use a default
    let logMessage = message ?? "An error occurred: \(error.localizedDescription)"
    
    // Default to error level
    let level: LogLevel = .error
    
    await logger.log(level, logMessage, context: logContext)
  }

  /**
   Logs a structured error with appropriate privacy controls.

   - Parameters:
     - error: The error to log.
     - source: Optional source identifier.
     - message: Optional custom message.
   */
  public func logStructuredError(
    _ error: Error,
    level: LogLevel = .error,
    message: String? = nil,
    source: String? = nil
  ) async {
    if let loggableError = error as? LoggableErrorDTO {
      // Use the error's built-in privacy metadata
      let metadata = loggableError.getPrivacyMetadata()
      
      // Get source information if available
      let errorSource = source ?? loggableError.getSource()
      
      // Create a context from the error information
      let metadataDTO = createMetadataCollection(from: metadata)
      let context = BaseLogContextDTO(
        domainName: "Error",
        source: errorSource,
        metadata: metadataDTO,
        correlationID: nil
      )

      // Get the log message or use the error's message
      let logMessage = message ?? loggableError.getLogMessage()
      
      // Log with error severity or specified level
      await logger.log(level, logMessage, context: context)
    } else {
      // For standard errors, create basic metadata
      var metadata = LogMetadataDTOCollection()
      
      metadata = metadata.withPrivate(
        key: "errorDescription",
        value: error.localizedDescription
      )
      
      metadata = metadata.withPublic(
        key: "errorType",
        value: String(describing: type(of: error))
      )
      
      // Create basic context
      let context = BaseLogContextDTO(
        domainName: "Error",
        source: source ?? "UnknownSource",
        metadata: metadata,
        correlationID: nil
      )
      
      // Use default message or a generic one
      let logMessage = message ?? "Error: \(error.localizedDescription)"
      
      // Log with the specified level
      await logger.log(level, logMessage, context: context)
    }
  }
  
  // MARK: - Helper Functions

  /// Helper method to convert PrivacyMetadata to LogMetadataDTOCollection
  /// - Parameter metadata: The privacy metadata to convert
  /// - Returns: A LogMetadataDTOCollection with the same entries
  private func createMetadataCollection(from metadata: PrivacyMetadata?) -> LogMetadataDTOCollection {
    var collection = LogMetadataDTOCollection()
    
    // If no metadata, return empty collection
    guard let metadata = metadata else {
      return collection
    }
    
    // Convert each entry based on its privacy level
    for entry in metadata.entriesArray {
      switch entry.privacy {
      case .public:
        collection = collection.withPublic(key: entry.key, value: entry.value)
      case .private:
        collection = collection.withPrivate(key: entry.key, value: entry.value)
      case .sensitive:
        collection = collection.withSensitive(key: entry.key, value: entry.value)
      case .hash:
        collection = collection.withHashed(key: entry.key, value: entry.value)
      case .auto:
        // Default to private for auto
        collection = collection.withPrivate(key: entry.key, value: entry.value)
      }
    }
    
    return collection
  }
}

/**
 A protocol for structured error logging.

 This protocol defines methods for logging structured errors with privacy controls.
 */
public protocol LegacyErrorLoggingProtocol {
  /**
    Logs a loggable error with enhanced privacy controls.

    - Parameters:
      - error: The loggable error to log.
      - level: The log level to use.
      - message: Optional custom message override.
   */
  func logLoggableError(
    _ error: LoggableErrorDTO,
    level: LogLevel,
    message: String?
  ) async

  /**
    Logs an error with enhanced privacy controls.

    - Parameters:
      - error: The error to log.
      - level: The log level to use.
      - metadata: Metadata for the error.
      - source: The source of the error.
      - message: Optional custom message override.
   */
  func logError(
    _ error: Error,
    level: LogLevel,
    metadata: PrivacyMetadata?,
    source: String,
    message: String?
  ) async
}

/**
 A domain-specific logger for file system operations.

 This logger is specialised for file system operations, providing appropriate
 privacy controls for logging file paths, operations, and results while
 ensuring sensitive path information is properly handled.
 */
public struct FileSystemLogger {
  private let logger: LoggingProtocol
  private let domain: String

  /**
   Initialises a new instance of FileSystemLogger.

   - Parameters:
      - logger: The underlying logger to use.
      - domain: The domain for this logger.
   */
  public init(logger: LoggingProtocol, domain: String = "FileSystem") {
    self.logger = logger
    self.domain = domain
  }

  /**
   Logs a file system operation with enhanced privacy controls.

   - Parameters:
      - operation: The operation being performed.
      - path: Optional path associated with the operation.
      - level: The log level to use.
      - message: The message to log.
      - additionalContext: Optional additional context.
   */
  public func logOperation(
    _ operation: String,
    path: String? = nil,
    level: LogLevel = .info,
    message: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    // Create a file system context with the operation and path
    let fsContext = FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: additionalContext ?? LogMetadataDTOCollection()
    )

    let defaultMessage = path != nil ?
      "File system operation \(operation) on path" :
      "File system operation: \(operation)"

    let logMessage = message ?? defaultMessage
    
    // Log with the appropriate level using context
    await logger.log(level, logMessage, context: fsContext)
  }

  /**
   Logs an error that occurred during a file system operation.

   - Parameters:
      - operation: The operation during which the error occurred.
      - error: The error that occurred.
      - path: Optional path associated with the operation.
      - additionalContext: Optional additional context.
      - message: Optional custom message.
   */
  public func logError(
    operation: String,
    error: Error,
    path: String? = nil,
    additionalContext: LogMetadataDTOCollection? = nil,
    message: String? = nil
  ) async {
    // Create a file system context with the operation and path
    let fsContext = FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: additionalContext ?? LogMetadataDTOCollection()
    )

    let defaultMessage = "Error during file system operation \(operation): \(error.localizedDescription)"
    let logMessage = message ?? defaultMessage
    
    // Log the error with context
    await logger.error(logMessage, context: fsContext)
  }

  /**
   Safely logs a file path with appropriate privacy controls.
   Provides special handling to ensure path components are properly protected.

   - Parameters:
      - path: The file path to log.
      - operation: The operation being performed on the path.
      - level: The log level to use.
      - additionalContext: Optional additional context.
   */
  public func logPath(
    _ path: String,
    operation: String,
    level: LogLevel = .info,
    additionalContext: LogMetadataDTOCollection? = nil
  ) async {
    // Create a file system context directly - it already handles path privacy
    let fsContext = FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: additionalContext ?? LogMetadataDTOCollection()
    )

    let message = switch level {
      case .trace:
        "Trace file operation: \(operation)"
      case .debug:
        "Debug file operation: \(operation)"
      case .info:
        "File operation: \(operation)"
      case .warning:
        "Warning during file operation: \(operation)"
      case .error:
        "Error during file operation: \(operation)"
      case .critical:
        "Critical error during file operation: \(operation)"
    }

    // Log with the appropriate level using context
    await logger.log(level, message, context: fsContext)
  }
}
