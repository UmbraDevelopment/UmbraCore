import Foundation
import LoggingInterfaces
import LoggingTypes

// Simple struct for privacy-annotated strings
public struct PrivacyString {
  let value: String

  public init(value: String) {
    self.value=value
  }
}

/// Restic-specific logger implementation
public actor ResticLogger {
  // Underlying logger instance
  private let underlyingLogger: any LoggingProtocol

  /// Create a new Restic logger
  public init(logger: any LoggingProtocol) {
    underlyingLogger = logger
  }

  /// Log a message with debug level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  public func debug(
    _ message: String, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String
  ) async {
    await log(.debug, message, metadata: metadata, additionalContext: additionalContext, source: source)
  }

  /// Log a message with info level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  public func info(
    _ message: String, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String
  ) async {
    await log(.info, message, metadata: metadata, additionalContext: additionalContext, source: source)
  }

  /// Log a message with warning level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  public func warning(
    _ message: String, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String
  ) async {
    await log(.warning, message, metadata: metadata, additionalContext: additionalContext, source: source)
  }

  /// Log a message with error level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  public func error(
    _ message: String, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String
  ) async {
    await log(.error, message, metadata: metadata, additionalContext: additionalContext, source: source)
  }

  /// Log a message with critical level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  public func critical(
    _ message: String, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String
  ) async {
    await log(.critical, message, metadata: metadata, additionalContext: additionalContext, source: source)
  }

  /// Log a message with the specified level
  ///
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  public func log(
    _ level: LogLevel, 
    _ message: String, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String
  ) async {
    // Create the final metadata by merging the additional context if provided
    let finalMetadata: LogMetadataDTOCollection
    if let metadata {
      if let additionalContext {
        finalMetadata = metadata.merging(with: additionalContext)
      } else {
        finalMetadata = metadata
      }
    } else if let additionalContext {
      finalMetadata = additionalContext
    } else {
      finalMetadata = LogMetadataDTOCollection()
    }
    
    // Create a context with the metadata
    let context = ResticLogContext(
      metadata: finalMetadata,
      source: source
    )
    
    await underlyingLogger.log(level, message, context: context)
  }

  /// Log an error with context
  ///
  /// - Parameters:
  ///   - error: The error to log
  ///   - metadata: Additional metadata to include
  ///   - additionalContext: Optional additional context to merge with the primary metadata
  ///   - source: The source of the message
  ///   - message: Optional custom message
  public func logError(
    _ error: Error, 
    metadata: LogMetadataDTOCollection?, 
    additionalContext: LogMetadataDTOCollection? = nil,
    source: String, 
    message: String? = nil
  ) async {
    // Create the final metadata by merging the additional context if provided
    let finalMetadata: LogMetadataDTOCollection
    if let metadata {
      if let additionalContext {
        finalMetadata = metadata.merging(with: additionalContext)
      } else {
        finalMetadata = metadata
      }
    } else if let additionalContext {
      finalMetadata = additionalContext
    } else {
      finalMetadata = LogMetadataDTOCollection()
    }
    
    // Check if the error provides logging information
    if let loggableError = error as? LoggableErrorProtocol {
      // Create a context with combined metadata
      let metadataCollection = loggableError.createMetadataCollection()
      let combinedMetadata = finalMetadata.merging(with: metadataCollection)
      
      // Create a context with the metadata
      let context = ResticLogContext(
        metadata: combinedMetadata,
        source: source
      )
      
      // Use the error message or custom message
      let logMessage = message ?? loggableError.getLogMessage()
      await underlyingLogger.log(.error, logMessage, context: context)
    } else {
      // Create a context with the metadata
      let context = ResticLogContext(
        metadata: finalMetadata.withPrivate(key: "error", value: error.localizedDescription),
        source: source
      )
      
      // Use the error description or custom message
      let logMessage = message ?? error.localizedDescription
      await underlyingLogger.log(.error, logMessage, context: context)
    }
  }
}
