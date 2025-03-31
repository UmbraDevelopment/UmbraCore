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
  func logOperationSuccess<T: LogContextDTO, R: Sendable>(
    context: T,
    result: R?,
    message: String?
  ) async

  /// Log an operation error
  /// - Parameters:
  ///   - context: The context for the log
  ///   - error: The error that occurred
  ///   - message: Optional custom message
  func logOperationError<T: LogContextDTO>(context: T, error: Error, message: String?) async
}

/// Base implementation of domain logger
public struct BaseDomainLogger: DomainLogger {
  /// The underlying logging protocol
  public let logger: LoggingProtocol

  /// Create a new domain logger
  /// - Parameter logger: The underlying logging protocol
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /// Log an operation start
  /// - Parameters:
  ///   - context: The context for the log
  ///   - message: Optional custom message
  public func logOperationStart(context: some LogContextDTO, message: String?=nil) async {
    let logMessage=message ?? "Starting operation"
    await logger.info(
      logMessage,
      metadata: context.toPrivacyMetadata(),
      source: context.getSource()
    )
  }

  /// Log an operation success
  /// - Parameters:
  ///   - context: The context for the log
  ///   - result: Optional result information
  ///   - message: Optional custom message
  public func logOperationSuccess(
    context: some LogContextDTO,
    result: (some Sendable)?=nil,
    message: String?=nil
  ) async {
    var metadata=context.toPrivacyMetadata()

    if let result {
      metadata["result"]=PrivacyMetadataValue(value: String(describing: result), privacy: .public)
    }

    let logMessage=message ?? "Operation completed successfully"
    await logger.info(logMessage, metadata: metadata, source: context.getSource())
  }

  /// Log an operation error
  /// - Parameters:
  ///   - context: The context for the log
  ///   - error: The error that occurred
  ///   - message: Optional custom message
  public func logOperationError(
    context: some LogContextDTO,
    error: Error,
    message: String?=nil
  ) async {
    var metadata=context.toPrivacyMetadata()

    if let loggableError=error as? LoggableError {
      // Merge the privacy-aware error metadata
      let errorMetadata=loggableError.toPrivacyMetadata()
      for key in errorMetadata.entries() {
        if let value=errorMetadata[key] {
          metadata[key]=value
        }
      }
    } else {
      // Add basic error information
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
      metadata["errorType"]=PrivacyMetadataValue(value: String(describing: type(of: error)),
                                                 privacy: .public)
    }

    let logMessage=message ?? "Operation failed"
    await logger.error(logMessage, metadata: metadata, source: context.getSource())
  }
}

/// A logger specialised for snapshot operations
public struct SnapshotLogger {
  /// The base domain logger
  private let domainLogger: DomainLogger

  /// Create a new snapshot logger
  /// - Parameter logger: The underlying logging protocol
  public init(logger: LoggingProtocol) {
    domainLogger=BaseDomainLogger(logger: logger)
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
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    message: String?=nil
  ) async {
    let context=SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage="Starting snapshot \(operation) operation"
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
    result: (some Sendable)?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    message: String?=nil
  ) async {
    let context=SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage="Snapshot \(operation) completed successfully"
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
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    message: String?=nil
  ) async {
    let context=SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage="Snapshot \(operation) operation failed"
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
    domainLogger=BaseDomainLogger(logger: logger)
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
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    message: String?=nil
  ) async {
    let context=KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage="Starting key \(operation) operation"
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
    result: (some Sendable)?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    message: String?=nil
  ) async {
    let context=KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage="Key \(operation) completed successfully"
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
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    message: String?=nil
  ) async {
    let context=KeyManagementLogContext(
      keyIdentifier: keyIdentifier,
      operation: operation,
      additionalContext: additionalContext
    )

    let defaultMessage="Key \(operation) operation failed"
    await domainLogger.logOperationError(
      context: context,
      error: error,
      message: message ?? defaultMessage
    )
  }
}

/**
 A domain-specific logger for keychain security operations.

 This logger is specialized for keychain operations, providing appropriate
 privacy controls for logging account information, keychain operations,
 and access policies.
 */
public struct KeychainLogger {
  private let domainLogger: DomainLogger

  /**
   Initializes a new instance of KeychainLogger.

   - Parameter logger: The underlying logger to use for logging operations.
   */
  public init(logger: LoggingProtocol) {
    domainLogger=BaseDomainLogger(logger: logger)
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
    keyIdentifier: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPrivate(key: "account", value: account)
    context.addPublic(key: "operation", value: operation)

    if let keyIdentifier {
      context.addPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let keychainContext=KeychainLogContext(
      account: account,
      operation: operation,
      additionalContext: context
    )

    await domainLogger.logOperationStart(
      context: keychainContext,
      message: message ?? "Starting keychain operation: \(operation)"
    )
  }

  /**
   Logs the successful completion of a keychain operation.

   - Parameters:
      - account: The account identifier associated with the operation.
      - operation: The type of operation that was performed.
      - keyIdentifier: Optional identifier for the encryption key.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationSuccess(
    account: String,
    operation: String,
    keyIdentifier: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPrivate(key: "account", value: account)
    context.addPublic(key: "operation", value: operation)
    context.addPublic(key: "status", value: "success")

    if let keyIdentifier {
      context.addPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let keychainContext=KeychainLogContext(
      account: account,
      operation: operation,
      additionalContext: context
    )

    await domainLogger.logOperationSuccess(
      context: keychainContext,
      result: nil as String?,
      message: message ?? "Completed keychain operation: \(operation)"
    )
  }

  /**
   Logs an error encountered during a keychain operation.

   - Parameters:
      - account: The account identifier associated with the operation.
      - operation: The type of operation that encountered an error.
      - error: The error that occurred.
      - keyIdentifier: Optional identifier for the encryption key.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationError(
    account: String,
    operation: String,
    error: Error,
    keyIdentifier: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPrivate(key: "account", value: account)
    context.addPublic(key: "operation", value: operation)
    context.addPrivate(key: "error", value: error.localizedDescription)
    context.addPrivate(key: "errorType", value: String(describing: type(of: error)))

    if let keyIdentifier {
      context.addPrivate(key: "keyIdentifier", value: keyIdentifier)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let keychainContext=KeychainLogContext(
      account: account,
      operation: operation,
      additionalContext: context
    )

    await domainLogger.logOperationError(
      context: keychainContext,
      error: error,
      message: message ?? "Error during keychain operation: \(operation)"
    )
  }
}

/**
 A domain-specific logger for cryptographic operations.

 This logger is specialised for cryptographic operations, providing appropriate
 privacy controls for logging cryptographic algorithms, key identifiers,
 and operation results.
 */
public struct CryptoLogger {
  private let domainLogger: DomainLogger

  /**
   Initialises a new instance of CryptoLogger.

   - Parameter logger: The underlying logger to use for logging operations.
   */
  public init(logger: LoggingProtocol) {
    domainLogger=BaseDomainLogger(logger: logger)
  }

  /**
   Logs the start of a cryptographic operation.

   - Parameters:
      - operation: The type of cryptographic operation being performed.
      - algorithm: The cryptographic algorithm being used, if applicable.
      - keyID: Optional identifier for any cryptographic key being used.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationStart(
    operation: String,
    algorithm: String?=nil,
    keyID: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)

    if let algorithm {
      context.addPublic(key: "algorithm", value: algorithm)
    }

    if let keyID {
      context.addPrivate(key: "keyID", value: keyID)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let cryptoContext=CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      additionalContext: context
    )

    await domainLogger.logOperationStart(
      context: cryptoContext,
      message: message ?? "Starting crypto operation: \(operation)"
    )
  }

  /**
   Logs the successful completion of a cryptographic operation.

   - Parameters:
      - operation: The type of cryptographic operation that was performed.
      - algorithm: The cryptographic algorithm that was used, if applicable.
      - keyID: Optional identifier for any cryptographic key that was used.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationSuccess(
    operation: String,
    algorithm: String?=nil,
    keyID: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)
    context.addPublic(key: "status", value: "success")

    if let algorithm {
      context.addPublic(key: "algorithm", value: algorithm)
    }

    if let keyID {
      context.addPrivate(key: "keyID", value: keyID)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let cryptoContext=CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      additionalContext: context
    )

    await domainLogger.logOperationSuccess(
      context: cryptoContext,
      result: nil as String?,
      message: message ?? "Completed crypto operation: \(operation)"
    )
  }

  /**
   Logs an error encountered during a cryptographic operation.

   - Parameters:
      - operation: The type of cryptographic operation that encountered an error.
      - error: The error that occurred.
      - algorithm: The cryptographic algorithm that was used, if applicable.
      - keyID: Optional identifier for any cryptographic key that was used.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationError(
    operation: String,
    error: Error,
    algorithm: String?=nil,
    keyID: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)
    context.addPrivate(key: "error", value: error.localizedDescription)
    context.addPrivate(key: "errorType", value: String(describing: type(of: error)))

    if let algorithm {
      context.addPublic(key: "algorithm", value: algorithm)
    }

    if let keyID {
      context.addPrivate(key: "keyID", value: keyID)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let cryptoContext=CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      additionalContext: context
    )

    await domainLogger.logOperationError(
      context: cryptoContext,
      error: error,
      message: message ?? "Error during crypto operation: \(operation)"
    )
  }
}

/**
 A domain-specific logger for error handling operations.

 This logger is specialised for error operations, providing appropriate
 privacy controls for logging errors, their sources, and contextual metadata.
 */
public struct ErrorLogger {
  private let domainLogger: DomainLogger

  /**
   Initialises a new instance of ErrorLogger.

   - Parameter logger: The underlying logger to use for logging operations.
   */
  public init(logger: LoggingProtocol) {
    domainLogger=BaseDomainLogger(logger: logger)
  }

  /**
   Logs an error with privacy-aware metadata.

   - Parameters:
      - error: The error that occurred.
      - source: Optional source of the error.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logError(
    _ error: Error,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()

    // Add user-provided additional context
    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let errorContext=ErrorLogContext(
      error: error,
      source: source,
      additionalContext: context
    )

    await domainLogger.logOperationError(
      context: errorContext,
      error: error,
      message: message ?? "Error encountered: \(error.localizedDescription)"
    )
  }

  /**
   Logs an error with domain-specific information.

   - Parameters:
      - error: The error that occurred.
      - source: Optional source of the error.
      - metadata: Additional string-based metadata.
      - message: Optional custom message override.
   */
  public func logError(
    _ error: Error,
    source: String?=nil,
    metadata: [String: String],
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()

    // Convert string metadata to DTOs with appropriate privacy level
    for (key, value) in metadata {
      context.addPrivate(key: key, value: value)
    }

    await logError(
      error,
      source: source,
      additionalContext: context,
      message: message
    )
  }

  /**
   Logs a warning with privacy-aware metadata.

   - Parameters:
      - message: The warning message.
      - source: Optional source of the warning.
      - additionalContext: Optional additional context information.
   */
  public func logWarning(
    _ message: String,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var context=LogMetadataDTOCollection()

    // Add user-provided additional context
    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let errorContext=ErrorLogContext(
      error: NSError(domain: "Warning", code: 0, userInfo: [NSLocalizedDescriptionKey: message]),
      source: source,
      additionalContext: context
    )

    await domainLogger.logger.warning(
      message,
      metadata: errorContext.toPrivacyMetadata(),
      source: errorContext.getSource()
    )
  }

  /**
   Creates a LogMetadataDTOCollection from an error.

   - Parameters:
      - error: The error to extract metadata from.
      - additionalContext: Optional additional context to merge.
   - Returns: A LogMetadataDTOCollection with error details.
   */
  public func createContextFromError(
    _ error: Error,
    additionalContext: LogMetadataDTOCollection?=nil
  ) -> LogMetadataDTOCollection {
    var context=LogMetadataDTOCollection()

    context.addPublic(key: "errorType", value: String(describing: type(of: error)))
    context.addPrivate(key: "errorMessage", value: error.localizedDescription)

    // Add domain information if available
    if let domainError=error as? CustomNSError {
      context.addPrivate(
        key: "errorDomain",
        value: String(describing: type(of: domainError).errorDomain)
      )
      context.addPrivate(key: "errorCode", value: "\(domainError.errorCode)")
    }

    // Add user-provided additional context
    if let additionalContext {
      context.merge(with: additionalContext)
    }

    return context
  }
}

/**
 A domain-specific logger for file system operations.

 This logger is specialised for file system operations, providing appropriate
 privacy controls for logging file paths, operations, and results while
 ensuring sensitive path information is properly handled.
 */
public struct FileSystemLogger {
  private let domainLogger: DomainLogger

  /**
   Initialises a new instance of FileSystemLogger.

   - Parameter logger: The underlying logger to use for logging operations.
   */
  public init(logger: LoggingProtocol) {
    domainLogger=BaseDomainLogger(logger: logger)
  }

  /**
   Logs the start of a file system operation.

   - Parameters:
      - operation: The type of file operation being performed.
      - path: Path to the file or directory involved.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationStart(
    operation: String,
    path: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)

    if let path {
      context.addPrivate(key: "path", value: path)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let fsContext=FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: context
    )

    await domainLogger.logOperationStart(
      context: fsContext,
      message: message ?? "Starting file system operation: \(operation)"
    )
  }

  /**
   Logs the successful completion of a file system operation.

   - Parameters:
      - operation: The type of file operation that was performed.
      - path: Path to the file or directory involved.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationSuccess(
    operation: String,
    path: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)
    context.addPublic(key: "status", value: "success")

    if let path {
      context.addPrivate(key: "path", value: path)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let fsContext=FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: context
    )

    await domainLogger.logOperationSuccess(
      context: fsContext,
      result: nil as String?,
      message: message ?? "Completed file system operation: \(operation)"
    )
  }

  /**
   Logs an error encountered during a file system operation.

   - Parameters:
      - operation: The type of file operation that encountered an error.
      - error: The error that occurred.
      - path: Path to the file or directory involved.
      - additionalContext: Optional additional context information.
      - message: Optional custom message override.
   */
  public func logOperationError(
    operation: String,
    error: Error,
    path: String?=nil,
    additionalContext: LogMetadataDTOCollection?=nil,
    message: String?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)
    context.addPrivate(key: "error", value: error.localizedDescription)
    context.addPrivate(key: "errorType", value: String(describing: type(of: error)))

    if let path {
      context.addPrivate(key: "path", value: path)
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let fsContext=FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: context
    )

    await domainLogger.logOperationError(
      context: fsContext,
      error: error,
      message: message ?? "Error during file system operation: \(operation)"
    )
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
    additionalContext: LogMetadataDTOCollection?=nil
  ) async {
    var context=LogMetadataDTOCollection()
    context.addPublic(key: "operation", value: operation)
    context.addPrivate(key: "path", value: path)

    // Extract safe portions of path if needed
    let components=path.split(separator: "/")
    if let fileName=components.last {
      // Just log the filename as public if it doesn't appear to contain sensitive info
      // This is a simplistic approach - in a real-world scenario, you'd want more
      // sophisticated logic to determine what parts of paths can be public
      if !fileName.contains(".") || fileName.hasSuffix(".txt") || fileName.hasSuffix(".log") {
        context.addPublic(key: "fileName", value: String(fileName))
      }
    }

    if let additionalContext {
      context.merge(with: additionalContext)
    }

    let message=switch level {
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

    let fsContext=FileSystemLogContext(
      operation: operation,
      path: path,
      additionalContext: context
    )

    switch level {
      case .trace:
        await domainLogger.logger.trace(
          message,
          metadata: fsContext.toPrivacyMetadata(),
          source: fsContext.getSource()
        )
      case .debug:
        await domainLogger.logger.debug(
          message,
          metadata: fsContext.toPrivacyMetadata(),
          source: fsContext.getSource()
        )
      case .info:
        await domainLogger.logger.info(
          message,
          metadata: fsContext.toPrivacyMetadata(),
          source: fsContext.getSource()
        )
      case .warning:
        await domainLogger.logger.warning(
          message,
          metadata: fsContext.toPrivacyMetadata(),
          source: fsContext.getSource()
        )
      case .error:
        await domainLogger.logger.error(
          message,
          metadata: fsContext.toPrivacyMetadata(),
          source: fsContext.getSource()
        )
      case .critical:
        await domainLogger.logger.critical(
          message,
          metadata: fsContext.toPrivacyMetadata(),
          source: fsContext.getSource()
        )
    }
  }
}
