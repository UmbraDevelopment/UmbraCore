import Foundation

/// Protocol for errors that provide enhanced logging information
///
/// This protocol allows errors to provide privacy-classified metadata
/// and other information needed for structured logging.
public protocol LoggableErrorProtocol: Error {
  /// Get the metadata collection for this error
  /// - Returns: Metadata collection for logging this error
  func createMetadataCollection() -> LogMetadataDTOCollection

  /// Get the source information for this error
  /// - Returns: Source information (e.g., file, function, line)
  func getSource() -> String

  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  func getLogMessage() -> String
}

/// Data Transfer Object for privacy-enhanced error logging
///
/// This DTO encapsulates error information with privacy classifications,
/// following the Alpha Dot Five architecture for immutable data transfer objects.
public struct LoggableErrorDTO: Error, Sendable, Equatable, LoggableErrorProtocol {
  /// The underlying error
  public let error: Error

  /// Error domain (e.g., "CoreFramework", "Security", etc.)
  public let domain: String
  
  /// Error code
  public let code: Int
  
  /// Error message suitable for logging
  public let message: String
  
  /// Error details (may contain sensitive information)
  public let details: String
  
  /// Source information (e.g., file, function, line)
  public let source: String
  
  /// Correlation ID for tracing related logs
  public let correlationID: String?
  
  /**
   Creates a new loggable error DTO.
   
   - Parameters:
     - error: The original error
     - domain: Error domain (defaults to "Application")
     - code: Error code (defaults to 0)
     - message: Error message suitable for logging
     - details: Error details (may contain sensitive information)
     - source: Source information
     - correlationID: Optional correlation ID for tracing
   */
  public init(
    error: Error,
    domain: String = "Application",
    code: Int = 0,
    message: String,
    details: String = "",
    source: String,
    correlationID: String? = nil
  ) {
    self.error = error
    self.domain = domain
    self.code = code
    self.message = message
    self.details = details
    self.source = source
    self.correlationID = correlationID
  }
  
  /**
   Creates a new loggable error DTO from an existing error.
   
   - Parameters:
     - error: The original error
     - message: Optional error message (defaults to error's localizedDescription)
     - details: Optional error details
     - source: Source information
     - correlationID: Optional correlation ID for tracing
   */
  public init(
    error: Error,
    message: String? = nil,
    details: String = "",
    source: String,
    correlationID: String? = nil
  ) {
    self.error = error
    
    // Extract domain and code from NSError
    // Note: All Swift errors bridge to NSError
    let nsError = error as NSError
    self.domain = nsError.domain
    self.code = nsError.code
    
    self.message = message ?? error.localizedDescription
    self.details = details
    self.source = source
    self.correlationID = correlationID
  }
  
  /**
   Determines if two LoggableErrorDTOs are equal.
   
   Comparison is based on domain, code, message, details, source,
   and correlationID. The underlying error is not compared.
   
   - Parameters:
     - lhs: First error to compare
     - rhs: Second error to compare
   - Returns: True if the errors are considered equal
   */
  public static func ==(lhs: LoggableErrorDTO, rhs: LoggableErrorDTO) -> Bool {
    return lhs.domain == rhs.domain &&
    lhs.code == rhs.code &&
    lhs.message == rhs.message &&
    lhs.details == rhs.details &&
    lhs.source == rhs.source &&
    lhs.correlationID == rhs.correlationID
  }
  
  /// Creates metadata collection for this error with appropriate privacy levels
  ///
  /// - Returns: A metadata collection with privacy classifications
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()
    
    // Public information
    metadata = metadata.withPublic(key: "domain", value: domain)
    metadata = metadata.withPublic(key: "code", value: String(code))
    
    // Private information
    metadata = metadata.withPrivate(key: "message", value: message)
    metadata = metadata.withPrivate(key: "source", value: source)
    
    // Sensitive information
    metadata = metadata.withSensitive(key: "details", value: details)
    
    // Correlation ID (if available)
    if let correlationID = correlationID {
      metadata = metadata.withPrivate(key: "correlationID", value: correlationID)
    }
    
    return metadata
  }
  
  /**
   Creates a new LoggableErrorDTO with an updated correlation ID.
   
   - Parameter correlationID: The correlation ID to set
   - Returns: A new LoggableErrorDTO with the updated correlation ID
   */
  public func withCorrelationID(_ correlationID: String) -> LoggableErrorDTO {
    LoggableErrorDTO(
      error: self.error,
      domain: self.domain,
      code: self.code,
      message: self.message,
      details: self.details,
      source: self.source,
      correlationID: correlationID
    )
  }
  
  /// Get the source information for this error
  /// - Returns: Source information
  public func getSource() -> String {
    return source
  }
  
  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  public func getLogMessage() -> String {
    return message
  }
  
  /**
   Creates a LoggableErrorDTO for a validation error.
   
   - Parameters:
     - message: Error message
     - field: Field that failed validation
     - expectedValue: Expected value (optional)
     - receivedValue: Received value (optional)
     - correlationID: Optional correlation ID
     - source: Source of the error
   - Returns: A LoggableErrorDTO configured for validation errors
   */
  public static func validationError(
    message: String,
    field: String,
    expectedValue: String? = nil,
    receivedValue: String? = nil,
    correlationID: String? = nil,
    source: String
  ) -> LoggableErrorDTO {
    let details = "Validation failed for field: \(field)"
    
    return LoggableErrorDTO(
      error: NSError(domain: "Validation", code: 400, userInfo: [
        "field": field,
        "expectedValue": expectedValue ?? "N/A",
        "receivedValue": receivedValue ?? "N/A"
      ]),
      domain: "Validation",
      code: 400,
      message: message,
      details: details,
      source: source,
      correlationID: correlationID
    )
  }
  
  /**
   Creates a LoggableErrorDTO for a security error.
   
   - Parameters:
     - message: Error message
     - operation: Security operation that failed
     - correlationID: Optional correlation ID
     - source: Source of the error
   - Returns: A LoggableErrorDTO configured for security errors
   */
  public static func securityError(
    message: String,
    operation: String,
    correlationID: String? = nil,
    source: String
  ) -> LoggableErrorDTO {
    let details = "Security operation failed: \(operation)"
    
    return LoggableErrorDTO(
      error: NSError(domain: "Security", code: 403, userInfo: [
        "operation": operation
      ]),
      domain: "Security",
      code: 403,
      message: message,
      details: details,
      source: source,
      correlationID: correlationID
    )
  }
  
  /**
   Creates a LoggableErrorDTO for a network error.
   
   - Parameters:
     - message: Error message
     - statusCode: HTTP status code
     - endpoint: API endpoint
     - correlationID: Optional correlation ID
     - source: Source of the error
   - Returns: A LoggableErrorDTO configured for network errors
   */
  public static func networkError(
    message: String,
    statusCode: Int,
    endpoint: String,
    correlationID: String? = nil,
    source: String
  ) -> LoggableErrorDTO {
    let details = "Network request failed with status code: \(statusCode)\nEndpoint: \(endpoint)"
    
    return LoggableErrorDTO(
      error: NSError(domain: "Network", code: statusCode, userInfo: [
        "endpoint": endpoint
      ]),
      domain: "Network",
      code: statusCode,
      message: message,
      details: details,
      source: source,
      correlationID: correlationID
    )
  }
}
