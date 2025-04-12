import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Base protocol for all provider-based cryptographic operation commands.

 This protocol defines the contract that all provider command implementations
 must fulfil, following the command pattern to encapsulate cryptographic operations
 in discrete command objects with a consistent interface.
 */
public protocol ProviderCommand {
  /// The type of result returned by this command when executed
  associatedtype ResultType

  /**
   Executes the cryptographic operation.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  func execute(
    context: LogContextDTO,
    operationID: String
  ) async -> Result<ResultType, SecurityStorageError>
}

/**
 Base class for provider-based cryptographic commands providing common functionality.

 This abstract base class provides shared functionality for all provider-based commands,
 including access to the security provider, secure storage, standardised logging,
 and utility methods that are commonly needed across cryptographic operations.
 */
public class BaseProviderCommand {
  /// The security provider to use for operations
  internal let provider: SecurityProviderProtocol

  /// The secure storage to use for persisting cryptographic materials
  internal let secureStorage: SecureStorageProtocol

  /// Optional logger for operation tracking
  internal let logger: LoggingProtocol?

  /**
   Initialises a new base provider command.

   - Parameters:
      - provider: The security provider to use for operations
      - secureStorage: The secure storage to use for persisting materials
      - logger: Optional logger for tracking operations
   */
  public init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.provider=provider
    self.secureStorage=secureStorage
    self.logger=logger
  }

  /**
   Creates a logging context with standardised metadata.

   - Parameters:
      - operation: The name of the operation
      - algorithm: Optional algorithm being used
      - correlationID: Unique identifier for correlation
      - additionalMetadata: Additional metadata entries with privacy levels
   - Returns: A configured log context
   */
  internal func createLogContext(
    operation: String,
    algorithm: String?=nil,
    correlationID: String,
    additionalMetadata: [(key: String, value: (value: String, privacyLevel: PrivacyLevel))]=[]
  ) -> LogContextDTO {
    // Create a base context with operation metadata
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "correlationID", value: correlationID)
      .withPublic(key: "component", value: "SecurityProvider")

    // Add algorithm information if available
    if let algorithm {
      metadata=metadata.withPublic(key: "algorithm", value: algorithm)
    }

    // Add additional metadata with specified privacy levels
    for item in additionalMetadata {
      switch item.value.privacyLevel {
        case PrivacyLevel.public:
          metadata=metadata.withPublic(key: item.key, value: item.value.value)
        case .protected:
          metadata=metadata.withProtected(key: item.key, value: item.value.value)
        case PrivacyLevel.private:
          metadata=metadata.withPrivate(key: item.key, value: item.value.value)
      }
    }

    // Create and return a concrete implementation of LogContextDTO
    return ProviderLogContext(
      domainName: "SecurityProvider",
      operation: operation,
      category: "CryptoServices",
      source: algorithm != nil ? "\(operation).\(algorithm!)" : operation,
      correlationID: correlationID,
      metadata: metadata
    )
  }

  /**
   Creates security configuration for provider operations.

   - Parameters:
      - operation: The operation type
      - algorithm: Optional algorithm to use
      - additionalOptions: Additional options for the configuration
   - Returns: A configured SecurityConfigDTO
   */
  internal func createSecurityConfig(
    operation: SecurityOperationType,
    algorithm: String?=nil,
    additionalOptions: [String: Any]=[:]
  ) -> SecurityConfigDTO {
    // Create security config options
    var options = SecurityConfigOptions()
    
    // Set standard metadata
    var metadata: [String: String] = [
      "operation": operation.rawValue
    ]
    
    // Add the algorithm if specified
    if let algorithm {
      metadata["algorithm"] = algorithm
    }
    
    // Add additional options
    for (key, value) in additionalOptions {
      if let stringValue = value as? String {
        metadata[key] = stringValue
      } else {
        metadata[key] = String(describing: value)
      }
    }
    
    // Set the metadata
    options.metadata = metadata
    
    // Create and return the config with appropriate default algorithms
    return SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: .sha256,
      providerType: .system,
      options: options
    )
  }

  /**
   Logs a debug message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  internal func logDebug(_ message: String, context: LogContextDTO) async {
    await logger?.log(.debug, message, context: context)
  }

  /**
   Logs an info message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  internal func logInfo(_ message: String, context: LogContextDTO) async {
    await logger?.log(.info, message, context: context)
  }

  /**
   Logs a warning message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  internal func logWarning(_ message: String, context: LogContextDTO) async {
    await logger?.log(.warning, message, context: context)
  }

  /**
   Logs an error message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  internal func logError(_ message: String, context: LogContextDTO) async {
    await logger?.log(.error, message, context: context)
  }

  /**
   Creates an appropriate SecurityStorageError from a provider result.

   - Parameter result: The SecurityResultDTO from the provider
   - Returns: An appropriate SecurityStorageError
   */
  internal func createError(from result: SecurityResultDTO) -> SecurityStorageError {
    // Check if there's a specific error message
    if let errorMessage = result.message, !errorMessage.isEmpty {
      return SecurityStorageError.operationFailed(errorMessage)
    }
    
    // If no specific message, return a generic error based on the operation
    if let operation = result.operation {
      switch operation {
      case "encrypt":
        return SecurityStorageError.encryptionFailed
      case "decrypt":
        return SecurityStorageError.decryptionFailed
      case "hash":
        return SecurityStorageError.hashingFailed
      case "verify":
        return SecurityStorageError.hashVerificationFailed
      case "generateKey":
        return SecurityStorageError.keyGenerationFailed
      default:
        return SecurityStorageError.operationFailed("Security operation failed")
      }
    }
    
    // Default generic error
    return SecurityStorageError.operationFailed("Unknown security operation error")
  }
}

/**
 Concrete implementation of LogContextDTO for provider commands.
 */
private struct ProviderLogContext: LogContextDTO {
  /// The domain name for this context
  public let domainName: String
  
  /// The operation being performed
  public let operation: String
  
  /// The category for the log entry
  public let category: String
  
  /// Source of the log (typically class/component name)
  public let source: String?
  
  /// Correlation ID for tracking related logs
  public let correlationID: String?
  
  /// Metadata collection with privacy annotations
  public let metadata: LogMetadataDTOCollection
  
  /**
   Creates a new context with additional metadata merged with existing metadata.
   
   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    var newMetadata = self.metadata
    
    for entry in additionalMetadata.entries {
      newMetadata = newMetadata.with(
        key: entry.key,
        value: entry.value,
        privacyLevel: entry.privacyLevel
      )
    }
    
    return ProviderLogContext(
      domainName: self.domainName,
      operation: self.operation,
      category: self.category,
      source: self.source,
      correlationID: self.correlationID,
      metadata: newMetadata
    )
  }
}
