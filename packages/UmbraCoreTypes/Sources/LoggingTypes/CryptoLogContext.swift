/// A specialised log context for cryptographic operations
///
/// This structure provides contextual information specific to cryptographic
/// operations, with enhanced privacy controls for sensitive cryptographic data.
public struct CryptoLogContext: LogContextDTO, Sendable, Equatable {
  /// The name of the domain this context belongs to
  public let domainName: String="Crypto"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The cryptographic operation being performed
  public let operation: String

  /// The algorithm being used
  public let algorithm: String?

  /// Creates a new cryptographic log context
  ///
  /// - Parameters:
  ///   - operation: The cryptographic operation being performed
  ///   - algorithm: Optional algorithm being used
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    operation: String,
    algorithm: String?=nil,
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.algorithm=algorithm
    self.correlationID=correlationID
    self.source=source

    // Start with the additional context
    var contextMetadata=additionalContext

    // Add operation as public metadata
    contextMetadata=contextMetadata.withPublic(key: "operation", value: operation)

    // Add algorithm as public metadata if present
    if let algorithm {
      contextMetadata=contextMetadata.withPublic(key: "algorithm", value: algorithm)
    }

    metadata=contextMetadata
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> CryptoLogContext {
    CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance with data size information
  ///
  /// - Parameter dataSize: The size of the data being processed
  /// - Returns: A new log context with the data size information
  public func withDataSize(_ dataSize: Int) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "dataSize", value: String(dataSize))
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with key strength information
  ///
  /// - Parameter keyStrength: The strength of the key in bits
  /// - Returns: A new log context with the key strength information
  public func withKeyStrength(_ keyStrength: Int) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "keyStrength", value: String(keyStrength))
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with operation result information
  ///
  /// - Parameter success: Whether the operation was successful
  /// - Returns: A new log context with the result information
  public func withResult(success: Bool) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "success", value: String(success))
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with password length information
  ///
  /// - Parameter length: The length of the password
  /// - Returns: A new log context with the password length information
  public func withPasswordLength(_ length: Int) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "passwordLength", value: String(length))
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with salt size information
  ///
  /// - Parameter size: The size of the salt in bytes
  /// - Returns: A new log context with the salt size information
  public func withSaltSize(_ size: Int) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "saltSize", value: String(size))
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with iteration count information
  ///
  /// - Parameter iterations: The number of iterations used in key derivation
  /// - Returns: A new log context with the iteration count information
  public func withIterationCount(_ iterations: Int) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "iterations", value: String(iterations))
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with key ID information
  ///
  /// - Parameter keyId: The identifier of the key being used
  /// - Returns: A new log context with the key ID information
  public func withKeyID(_ keyID: String) -> CryptoLogContext {
    // Key IDs are private information
    let updatedMetadata=metadata.withPrivate(key: "keyId", value: keyID)
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with key type information
  ///
  /// - Parameter keyType: The type of key being used (e.g., symmetric, asymmetric)
  /// - Returns: A new log context with the key type information
  public func withKeyType(_ keyType: String) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "keyType", value: keyType)
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }

  /// Creates a new instance with security level information
  ///
  /// - Parameter level: The security level being applied (e.g., high, standard)
  /// - Returns: A new log context with the security level information
  public func withSecurityLevel(_ level: String) -> CryptoLogContext {
    let updatedMetadata=metadata.withPublic(key: "securityLevel", value: level)
    return CryptoLogContext(
      operation: operation,
      algorithm: algorithm,
      correlationID: correlationID,
      source: source,
      additionalContext: updatedMetadata
    )
  }
}
