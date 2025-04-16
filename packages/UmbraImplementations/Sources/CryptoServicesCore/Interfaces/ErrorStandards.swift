import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # Error Standards

 This file defines standardised error types and error handling patterns for the UmbraCore
 cryptographic services. All implementations should follow these standards to ensure
 consistent error reporting and handling across modules.

 ## Error Categories

 Errors in the cryptographic services are categorised into:

 1. Input validation errors
 2. Operational errors
 3. Storage errors
 4. Configuration errors
 5. Security boundary errors

 ## Error Handling Principles

 1. All errors should be properly typed and follow the categories defined here
 2. Error messages should be informative without leaking sensitive information
 3. Errors should include appropriate metadata for diagnostics
 4. Error codes should be consistent across implementations
 */

// MARK: - Error Types

/**
 Standardised error codes for cryptographic operation errors.

 These codes provide a consistent way to identify specific error conditions
 across different implementations and environments.
 */
public enum CryptoErrorCode: Int, Codable, Sendable {
  // Input validation errors (1-99)
  case invalidInput=1
  case invalidKey=2
  case invalidIV=3
  case invalidAlgorithm=4
  case invalidMode=5
  case invalidPadding=6
  case invalidSignature=7
  case invalidHash=8
  case invalidData=9
  case invalidParameter=10
  case duplicateEntry=11

  // Operational errors (100-199)
  case encryptionFailed=100
  case decryptionFailed=101
  case hashingFailed=102
  case signatureFailed=103
  case keyGenerationFailed=104
  case randomGenerationFailed=105
  case verificationFailed=106
  case operationTimedOut=107
  case operationCancelled=108
  case unsupportedOperation=109

  // Storage errors (200-299)
  case storageError=200
  case itemNotFound=201
  case itemAlreadyExists=202
  case storageCorrupted=203
  case storageFull=204
  case storageUnavailable=205
  case storagePermissionDenied=206

  // Configuration errors (300-399)
  case invalidConfiguration=300
  case missingConfiguration=301
  case incompatibleConfiguration=302

  // Security boundary errors (400-499)
  case securityBoundaryViolation=400
  case unauthorizedAccess=401
  case insufficientPermissions=402

  // Platform-specific errors (500-599)
  case platformNotSupported=500
  case hardwareFeatureUnavailable=501
  case libraryNotAvailable=502

  // Implementation-specific errors (1000+)
  case internalError=1000
  case notImplemented=1001
  case unspecifiedError=9999
  case encryptionError=1002
  case decryptionError=1003
  case hashingError=1004
  case verificationError=1005
  case keyGenerationError=1006
  case invalidIdentifier=1007
  case rateLimited=1008
}

/**
 Standardised error for cryptographic operations.

 This provides a consistent error type across all cryptographic implementations,
 with appropriate error codes, messages, and metadata.
 */
public struct CryptoOperationError: Error, Equatable, Codable, Sendable {
  /// The error code that identifies the specific error
  public let code: CryptoErrorCode

  /// A human-readable description of the error
  public let message: String

  /// Additional metadata about the error (should not contain sensitive data)
  public let metadata: [String: String]?

  /// The underlying error, if applicable
  public let underlyingError: Error?

  /**
   Initialises a new CryptoOperationError.

   - Parameters:
      - code: The error code
      - message: A human-readable description
      - metadata: Additional diagnostic information
      - underlyingError: The original error that caused this error
   */
  public init(
    code: CryptoErrorCode,
    message: String,
    metadata: [String: String]?=nil,
    underlyingError: Error?=nil
  ) {
    self.code=code
    self.message=message
    self.metadata=metadata
    self.underlyingError=underlyingError
  }

  // Implement Equatable manually since Error doesn't conform to Equatable
  public static func == (lhs: CryptoOperationError, rhs: CryptoOperationError) -> Bool {
    lhs.code == rhs.code && lhs.message == rhs.message
  }

  // Implement Codable manually to handle the underlying error
  private enum CodingKeys: String, CodingKey {
    case code
    case message
    case metadata
    case underlyingErrorDescription
  }

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    code=try container.decode(CryptoErrorCode.self, forKey: .code)
    message=try container.decode(String.self, forKey: .message)
    metadata=try container.decodeIfPresent([String: String].self, forKey: .metadata)

    // We can't decode the actual Error, but we can decode its description
    let errorDescription=try container.decodeIfPresent(
      String.self,
      forKey: .underlyingErrorDescription
    )
    if let description=errorDescription {
      underlyingError=NSError(
        domain: "CryptoErrorDomain",
        code: code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: description]
      )
    } else {
      underlyingError=nil
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)
    try container.encode(code, forKey: .code)
    try container.encode(message, forKey: .message)
    try container.encodeIfPresent(metadata, forKey: .metadata)

    // Store the underlying error as a description
    if let error=underlyingError {
      try container.encode(error.localizedDescription, forKey: .underlyingErrorDescription)
    }
  }
}

// MARK: - Error Mapping

/**
 Standardised error mapper from platform-specific errors to CryptoOperationError.

 This provides consistent error mapping logic for different cryptographic implementations.
 */
public enum CryptoErrorMapper {
  /**
   Maps a SecurityStorageError to a CryptoOperationError.

   - Parameter error: The storage error to map
   - Returns: A standardised CryptoOperationError
   */
  public static func map(storageError: SecurityStorageError) -> CryptoOperationError {
    switch storageError {
      case .dataNotFound:
        CryptoOperationError(
          code: .itemNotFound,
          message: "Data not found in secure storage",
          underlyingError: storageError
        )
      case let .invalidInput(message):
        CryptoOperationError(
          code: .invalidInput,
          message: "Invalid input: \(message)",
          underlyingError: storageError
        )
      case .keyNotFound:
        CryptoOperationError(
          code: .itemNotFound,
          message: "Key not found in secure storage",
          underlyingError: storageError
        )
      case .hashNotFound:
        CryptoOperationError(
          code: .itemNotFound,
          message: "Hash not found in secure storage",
          underlyingError: storageError
        )
      case .storageUnavailable:
        CryptoOperationError(
          code: .storageError,
          message: "Secure storage is not available",
          underlyingError: storageError
        )
      case .encryptionFailed:
        CryptoOperationError(
          code: .encryptionError,
          message: "Encryption operation failed",
          underlyingError: storageError
        )
      case .decryptionFailed:
        CryptoOperationError(
          code: .decryptionError,
          message: "Decryption operation failed",
          underlyingError: storageError
        )
      case .hashingFailed:
        CryptoOperationError(
          code: .hashingError,
          message: "Hashing operation failed",
          underlyingError: storageError
        )
      case .hashVerificationFailed:
        CryptoOperationError(
          code: .verificationError,
          message: "Hash verification failed",
          underlyingError: storageError
        )
      case .keyGenerationFailed:
        CryptoOperationError(
          code: .keyGenerationError,
          message: "Key generation failed",
          underlyingError: storageError
        )
      case .unsupportedOperation:
        CryptoOperationError(
          code: .unsupportedOperation,
          message: "The operation is not supported",
          underlyingError: storageError
        )
      case .implementationUnavailable:
        CryptoOperationError(
          code: .internalError,
          message: "The protocol implementation is not available",
          underlyingError: storageError
        )
      case let .invalidIdentifier(reason):
        CryptoOperationError(
          code: .invalidIdentifier,
          message: "Invalid identifier: \(reason)",
          underlyingError: storageError
        )
      case let .identifierNotFound(identifier):
        CryptoOperationError(
          code: .itemNotFound,
          message: "Identifier not found: \(identifier)",
          underlyingError: storageError
        )
      case let .storageFailure(reason):
        CryptoOperationError(
          code: .storageError,
          message: "Storage failure: \(reason)",
          underlyingError: storageError
        )
      case let .generalError(reason):
        CryptoOperationError(
          code: .internalError,
          message: "General error: \(reason)",
          underlyingError: storageError
        )
      case let .operationFailed(message):
        CryptoOperationError(
          code: .internalError,
          message: "Operation failed: \(message)",
          underlyingError: storageError
        )
      case .operationRateLimited:
        CryptoOperationError(
          code: .rateLimited,
          message: "Operation was rate limited for security purposes",
          underlyingError: storageError
        )
      case .storageError:
        CryptoOperationError(
          code: .storageError,
          message: "Generic storage error",
          underlyingError: storageError
        )
    }
  }

  /**
   Maps a SecurityProviderError to a CryptoOperationError.

   - Parameter error: The provider error to map
   - Returns: A standardised CryptoOperationError
   */
  public static func map(providerError: SecurityProviderError) -> CryptoOperationError {
    switch providerError {
      case let .invalidKeySize(expected, actual):
        CryptoOperationError(
          code: .invalidKey,
          message: "Invalid key size: expected \(expected), got \(actual)",
          underlyingError: providerError
        )
      case let .invalidIVSize(expected, actual):
        CryptoOperationError(
          code: .invalidIV,
          message: "Invalid IV size: expected \(expected), got \(actual)",
          underlyingError: providerError
        )
      case let .encryptionFailed(reason):
        CryptoOperationError(
          code: .encryptionFailed,
          message: "Encryption failed: \(reason)",
          underlyingError: providerError
        )
      case let .decryptionFailed(reason):
        CryptoOperationError(
          code: .decryptionFailed,
          message: "Decryption failed: \(reason)",
          underlyingError: providerError
        )
      case let .hashingFailed(reason):
        CryptoOperationError(
          code: .hashingFailed,
          message: "Hashing failed: \(reason)",
          underlyingError: providerError
        )
      case let .signingFailed(reason):
        CryptoOperationError(
          code: .signatureFailed,
          message: "Signing failed: \(reason)",
          underlyingError: providerError
        )
      case let .verificationFailed(reason):
        CryptoOperationError(
          code: .verificationFailed,
          message: "Verification failed: \(reason)",
          underlyingError: providerError
        )
      case let .randomGenerationFailed(reason):
        CryptoOperationError(
          code: .randomGenerationFailed,
          message: "Random number generation failed: \(reason)",
          underlyingError: providerError
        )
      case let .keyGenerationFailed(reason):
        CryptoOperationError(
          code: .keyGenerationFailed,
          message: "Key generation failed: \(reason)",
          underlyingError: providerError
        )
      case let .unsupportedAlgorithm(algorithm):
        CryptoOperationError(
          code: .invalidAlgorithm,
          message: "Unsupported algorithm: \(algorithm)",
          underlyingError: providerError
        )
      case let .configurationError(reason):
        CryptoOperationError(
          code: .invalidConfiguration,
          message: "Configuration error: \(reason)",
          underlyingError: providerError
        )
      case let .internalError(reason):
        CryptoOperationError(
          code: .internalError,
          message: "Internal error: \(reason)",
          underlyingError: providerError
        )
      case let .cryptorCreationFailed(reason):
        CryptoOperationError(
          code: .encryptionFailed,
          message: "Cryptor creation failed: \(reason)",
          underlyingError: providerError
        )
      case let .aadProcessingFailed(reason):
        CryptoOperationError(
          code: .encryptionFailed,
          message: "AAD processing failed: \(reason)",
          underlyingError: providerError
        )
      case let .encryptionFinalisationFailed(reason):
        CryptoOperationError(
          code: .encryptionFailed,
          message: "Encryption finalisation failed: \(reason)",
          underlyingError: providerError
        )
      case let .authenticationTagGenerationFailed(reason):
        CryptoOperationError(
          code: .encryptionFailed,
          message: "Authentication tag generation failed: \(reason)",
          underlyingError: providerError
        )
      case .invalidDataFormat:
        CryptoOperationError(
          code: .invalidData,
          message: "Invalid data format",
          underlyingError: providerError
        )
      case let .decryptionFinalisationFailed(reason):
        CryptoOperationError(
          code: .decryptionFailed,
          message: "Decryption finalisation failed: \(reason)",
          underlyingError: providerError
        )
      case let .authenticationTagVerificationFailed(reason):
        CryptoOperationError(
          code: .decryptionFailed,
          message: "Authentication tag verification failed: \(reason)",
          underlyingError: providerError
        )
      case .authenticationTagMismatch:
        CryptoOperationError(
          code: .decryptionFailed,
          message: "Authentication tag mismatch",
          underlyingError: providerError
        )
      case let .keyDerivationFailed(reason):
        CryptoOperationError(
          code: .keyGenerationFailed,
          message: "Key derivation failed: \(reason)",
          underlyingError: providerError
        )
      case let .conversionError(reason):
        CryptoOperationError(
          code: .invalidData,
          message: "Conversion error: \(reason)",
          underlyingError: providerError
        )
    }
  }

  /**
   Creates a standardised validation error.

   - Parameters:
      - code: The specific validation error code
      - message: A human-readable error message
      - metadata: Additional diagnostic information
   - Returns: A standardised CryptoOperationError
   */
  public static func validationError(
    code: CryptoErrorCode,
    message: String,
    metadata: [String: String]?=nil
  ) -> CryptoOperationError {
    precondition(
      code.rawValue < 100,
      "Validation error codes must be between 1-99, got \(code.rawValue)"
    )

    return CryptoOperationError(
      code: code,
      message: message,
      metadata: metadata
    )
  }

  /**
   Creates a standardised operational error.

   - Parameters:
      - code: The specific operational error code
      - message: A human-readable error message
      - metadata: Additional diagnostic information
      - underlyingError: The original error that caused this error
   - Returns: A standardised CryptoOperationError
   */
  public static func operationalError(
    code: CryptoErrorCode,
    message: String,
    metadata: [String: String]?=nil,
    underlyingError: Error?=nil
  ) -> CryptoOperationError {
    precondition(
      code.rawValue >= 100 && code.rawValue < 200,
      "Operational error codes must be between 100-199, got \(code.rawValue)"
    )

    return CryptoOperationError(
      code: code,
      message: message,
      metadata: metadata,
      underlyingError: underlyingError
    )
  }

  /**
   Maps a generic Error to a CryptoOperationError.

   - Parameters:
      - error: The error to map
      - context: Additional context for the error mapping
   - Returns: A standardised CryptoOperationError
   */
  public static func mapGenericError(
    _ error: Error,
    context: String?=nil
  ) -> CryptoOperationError {
    // If it's already a CryptoOperationError, return it
    if let cryptoError=error as? CryptoOperationError {
      return cryptoError
    }

    // If it's a SecurityStorageError, map it
    if let storageError=error as? SecurityStorageError {
      return map(storageError: storageError)
    }

    // If it's a SecurityProviderError, map it
    if let providerError=error as? SecurityProviderError {
      return map(providerError: providerError)
    }

    // Otherwise, create a generic error
    let contextPrefix=context.map { "\($0): " } ?? ""
    return CryptoOperationError(
      code: .unspecifiedError,
      message: "\(contextPrefix)\(error.localizedDescription)",
      underlyingError: error
    )
  }
}

/**
 Utility for handling cryptographic operation errors in a standardised way.

 This provides validation helpers and error transformation methods to ensure
 consistent error handling logic across implementations.
 */
public enum CryptoErrorHandling {
  /**
   Validates that a condition is true or returns a validation error.

   - Parameters:
      - condition: The condition to validate
      - errorCode: The error code to use if validation fails
      - message: The error message to use if validation fails
   - Throws: A CryptoOperationError if the validation fails
   */
  public static func validateOrThrow(
    _ condition: Bool,
    errorCode: CryptoErrorCode,
    message: String
  ) throws {
    if !condition {
      throw CryptoErrorMapper.validationError(
        code: errorCode,
        message: message
      )
    }
  }

  /**
   Transforms a Result type to handle CryptoOperationError consistently.

   - Parameters:
      - result: The result to transform
      - context: Additional context for error handling
   - Returns: A new Result with any errors mapped to CryptoOperationError
   */
  public static func transformResult<T>(
    _ result: Result<T, Error>,
    context: String?=nil
  ) -> Result<T, CryptoOperationError> {
    result.mapError { error in
      CryptoErrorMapper.mapGenericError(error, context: context)
    }
  }

  /**
   Transforms a Result type specifically for SecurityStorageError.

   - Parameters:
      - result: The result to transform
      - context: Additional context for error handling
   - Returns: A new Result with SecurityStorageError mapped to CryptoOperationError
   */
  public static func transformStorageResult<T>(
    _ result: Result<T, SecurityStorageError>,
    context _: String?=nil
  ) -> Result<T, CryptoOperationError> {
    result.mapError { error in
      CryptoErrorMapper.map(storageError: error)
    }
  }

  /**
   Execute a function and map any thrown errors to CryptoOperationError.

   - Parameters:
      - context: Context description for error reporting
      - operation: The function to execute
   - Returns: The result of the operation
   - Throws: A CryptoOperationError if the operation fails
   */
  public static func execute<T>(
    context: String?=nil,
    operation: () throws -> T
  ) throws -> T {
    do {
      return try operation()
    } catch {
      throw CryptoErrorMapper.mapGenericError(error, context: context)
    }
  }

  /**
   Execute an async function and map any thrown errors to CryptoOperationError.

   - Parameters:
      - context: Context description for error reporting
      - operation: The async function to execute
   - Returns: The result of the operation
   - Throws: A CryptoOperationError if the operation fails
   */
  public static func execute<T>(
    context: String?=nil,
    operation: () async throws -> T
  ) async throws -> T {
    do {
      return try await operation()
    } catch {
      throw CryptoErrorMapper.mapGenericError(error, context: context)
    }
  }
}
