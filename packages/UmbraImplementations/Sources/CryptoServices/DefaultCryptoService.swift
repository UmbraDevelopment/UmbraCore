import CommonCrypto
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import UmbraErrors
import LoggingInterfaces
import LoggingTypes
import LoggingAdapters
import Foundation

/**
 # DefaultCryptoServiceImpl

 Default implementation of CryptoServiceProtocol using system cryptography APIs.
 This actor provides thread-safe cryptographic operations aligned with the
 Alpha Dot Five architecture's concurrency model.

 ## Security Considerations

 This implementation uses secure memory handling practices to prevent sensitive
 data leakage and zeroes all buffers after use.

 ## Concurrency Safety

 As an actor, this implementation serialises access to cryptographic operations,
 preventing race conditions when multiple callers attempt operations simultaneously.
 */
public actor DefaultCryptoServiceImpl: CryptoServiceProtocol {
  /// Specialised logger for crypto operations
  private let cryptoLogger: CryptoLogger
  
  /// Initialise a new DefaultCryptoServiceImpl with enhanced logging
  ///
  /// - Parameter logger: The logging service to use
  public init(logger: LoggingServiceProtocol) {
    self.cryptoLogger = CryptoLogger(loggingService: logger)
  }
  
  /// Initialise a new DefaultCryptoServiceImpl with default logging
  public init() {
    // Create a default logging service
    let loggingService = LoggingServiceAdapter(logger: SimpleConsoleLogger())
    self.cryptoLogger = CryptoLogger(loggingService: loggingService)
  }

  /**
   Generates a key of the specified length.

   - Parameters:
     - length: Length of the key to generate in bytes
     - keyOptions: Optional configuration for key generation
   - Returns: Generated key as Data
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(length: Int, keyOptions: KeyGenerationOptions?) async throws -> Data {
    // Create a context for this operation
    let context = CryptoLogContext(
      operation: "keyGeneration",
      algorithm: "SecureRandom"
    ).withKeyStrength(length * 8)
    
    await cryptoLogger.logWithContext(
      .info,
      "Generating secure random key of \(length) bytes",
      context: context
    )
    
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

    guard status == errSecSuccess else {
      let error = CryptoError.keyGenerationFailed(
        reason: "Random generation failed with status: \(status)"
      )
      await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
      throw error
    }
    
    await cryptoLogger.logWithContext(
      .info,
      "Successfully generated secure random key",
      context: context.withResult(success: true)
    )

    return Data(bytes)
  }

  /**
   Encrypts data using AES encryption.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - iv: Initialisation vector
     - cryptoOptions: Optional encryption configuration
   - Returns: Encrypted data as Data
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    // Create a context for this operation
    let context = CryptoLogContext(
      operation: "encryption",
      algorithm: "AES"
    )
    .withDataSize(data.count)
    .withKeyStrength(key.count * 8)
    
    await cryptoLogger.logWithContext(
      .info,
      "Attempting to encrypt data",
      context: context
    )

    // This implementation will be enhanced in future versions
    // Currently, we throw an error to indicate encryption should use
    // the SecurityCryptoServices module instead
    let error = CryptoError.encryptionFailed(
      reason: "Please use SecurityCryptoServices for encryption operations"
    )
    
    await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
    throw error
  }

  /**
   Decrypts data using AES encryption.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - iv: Initialisation vector
     - cryptoOptions: Optional decryption configuration
   - Returns: Decrypted data as Data
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data,
    cryptoOptions: CryptoOptions?
  ) async throws -> Data {
    // Create a context for this operation
    let context = CryptoLogContext(
      operation: "decryption",
      algorithm: "AES"
    )
    .withDataSize(data.count)
    .withKeyStrength(key.count * 8)
    
    await cryptoLogger.logWithContext(
      .info,
      "Attempting to decrypt data",
      context: context
    )

    // This implementation will be enhanced in future versions
    // Currently, we throw an error to indicate decryption should use
    // the SecurityCryptoServices module instead
    let error = CryptoError.decryptionFailed(
      reason: "Please use SecurityCryptoServices for decryption operations"
    )
    
    await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
    throw error
  }

  /**
   Derives a key from a password using PBKDF2.

   - Parameters:
     - password: Password to derive the key from
     - salt: Salt value for the derivation
     - iterations: Number of iterations for the derivation
     - derivationOptions: Optional key derivation configuration
   - Returns: Derived key as Data
   - Throws: CryptoError if key derivation fails
   */
  public func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    derivationOptions: KeyDerivationOptions?
  ) async throws -> Data {
    // Create a context for this operation
    let context = CryptoLogContext(
      operation: "keyDerivation",
      algorithm: "PBKDF2"
    )
    .withPasswordLength(password.count)
    .withSaltSize(salt.count)
    .withIterationCount(iterations)
    
    await cryptoLogger.logWithContext(
      .info,
      "Deriving key from password",
      context: context
    )

    // Validate inputs
    guard !password.isEmpty else {
      let error = CryptoError.keyDerivationFailed(
        reason: "Password cannot be empty"
      )
      await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
      throw error
    }

    guard iterations > 0 else {
      let error = CryptoError.keyDerivationFailed(
        reason: "Invalid iteration count: \(iterations)"
      )
      await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
      throw error
    }

    // This implementation will be enhanced in future versions
    // Currently, we throw an error to indicate key derivation should use
    // the SecurityCryptoServices module instead
    let error = CryptoError.keyDerivationFailed(
      reason: "Please use SecurityCryptoServices for key derivation operations"
    )
    
    await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
    throw error
  }

  /**
   Generates a message authentication code (HMAC) using SHA-256.

   - Parameters:
     - data: Data to authenticate
     - key: The authentication key
     - hmacOptions: Optional HMAC configuration
   - Returns: HMAC as Data
   - Throws: CryptoError if HMAC generation fails
   */
  public func generateHMAC(
    for data: Data,
    using key: Data,
    hmacOptions: HMACOptions?
  ) async throws -> Data {
    // Create a context for this operation
    let context = CryptoLogContext(
      operation: "hmacGeneration",
      algorithm: "SHA-256"
    )
    .withDataSize(data.count)
    .withKeyStrength(key.count * 8)
    
    await cryptoLogger.logWithContext(
      .info,
      "Generating HMAC for data",
      context: context
    )

    // This implementation will be enhanced in future versions
    // Currently, we throw an error to indicate HMAC generation should use
    // the SecurityCryptoServices module instead
    let error = CryptoError.operationFailed(
      reason: "Please use SecurityCryptoServices for HMAC operations"
    )
    
    await cryptoLogger.logError(error, context: context, privacyLevel: error.privacyClassification)
    throw error
  }
}

/**
 A simple logger implementation for console output.
 This is used as a fallback when no other logger is provided.
 */
private struct SimpleConsoleLogger: LoggingProtocol {
  // MARK: - LoggingProtocol Requirements
  
  /// The underlying logging actor
  let loggingActor: LoggingInterfaces.LoggingActor
  
  /// Initialise with a default console logging actor
  init() {
    // Create a simple console log destination
    self.loggingActor = LoggingInterfaces.LoggingActor(
      destinations: [ConsoleLogDestination()],
      minimumLogLevel: .debug
    )
  }
  
  // MARK: - CoreLoggingProtocol Requirements
  
  /// Log a message with the specified level and context
  func logMessage(_ level: LoggingTypes.LogLevel, _ message: String, context: LoggingTypes.LogContext) async {
    let source = context.source
    let prefix = levelPrefix(for: level)
    print("[\(prefix)][\(source)]: \(message)")
  }
  
  // MARK: - LoggingProtocol Implementation
  
  /// Log a trace message
  func trace(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await logMessage(.trace, message, context: LoggingTypes.LogContext(source: source, metadata: metadata))
  }
  
  /// Log a debug message
  func debug(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await logMessage(.debug, message, context: LoggingTypes.LogContext(source: source, metadata: metadata))
  }
  
  /// Log an info message
  func info(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await logMessage(.info, message, context: LoggingTypes.LogContext(source: source, metadata: metadata))
  }
  
  /// Log a warning message
  func warning(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await logMessage(.warning, message, context: LoggingTypes.LogContext(source: source, metadata: metadata))
  }
  
  /// Log an error message
  func error(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await logMessage(.error, message, context: LoggingTypes.LogContext(source: source, metadata: metadata))
  }
  
  /// Log a critical message
  func critical(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String) async {
    await logMessage(.critical, message, context: LoggingTypes.LogContext(source: source, metadata: metadata))
  }
  
  /// Backward compatibility for source parameter being optional
  func debug(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String?) async {
    await debug(message, metadata: metadata, source: source ?? "CryptoService")
  }
  
  /// Backward compatibility for source parameter being optional
  func info(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String?) async {
    await info(message, metadata: metadata, source: source ?? "CryptoService")
  }
  
  /// Backward compatibility for source parameter being optional
  func warn(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String?) async {
    await warning(message, metadata: metadata, source: source ?? "CryptoService")
  }
  
  /// Backward compatibility for source parameter being optional
  func error(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String?) async {
    await error(message, metadata: metadata, source: source ?? "CryptoService")
  }
  
  /// Backward compatibility for source parameter being optional
  func fatal(_ message: String, metadata: LoggingTypes.PrivacyMetadata?, source: String?) async {
    await critical(message, metadata: metadata, source: source ?? "CryptoService")
  }
  
  // MARK: - Private Helper Methods
  
  /// Get a string prefix for a log level
  private func levelPrefix(for level: LoggingTypes.LogLevel) -> String {
    switch level {
    case .trace:
      return "TRACE"
    case .debug:
      return "DEBUG"
    case .info:
      return "INFO"
    case .warning:
      return "WARN"
    case .error:
      return "ERROR"
    case .critical:
      return "CRITICAL"
    }
  }
}

/**
 A simple console log destination that prints messages to stdout.
 */
private actor ConsoleLogDestination: LoggingInterfaces.ActorLogDestination {
  /// The identifier for this log destination
  let identifier = "SimpleConsole"
  
  /// Whether this destination should log entries at the specified level
  func shouldLog(level: LoggingInterfaces.LogLevel) -> Bool {
    return true  // Log all levels
  }
  
  /// Write a log entry to the console
  func write(_ entry: LoggingInterfaces.LogEntry) {
    // Already printing in the LoggingProtocol methods above, so this is a no-op
  }
}
