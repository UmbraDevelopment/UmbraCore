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
  protected let provider: SecurityProviderProtocol

  /// The secure storage to use for persisting cryptographic materials
  protected let secureStorage: SecureStorageProtocol

  /// Optional logger for operation tracking
  protected let logger: LoggingProtocol?

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
  protected func createLogContext(
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
        case .public:
          metadata=metadata.withPublic(key: item.key, value: item.value.value)
        case .protected:
          metadata=metadata.withProtected(key: item.key, value: item.value.value)
        case .private:
          metadata=metadata.withPrivate(key: item.key, value: item.value.value)
      }
    }

    return LogContextDTO(metadata: metadata)
  }

  /**
   Creates security configuration for provider operations.

   - Parameters:
      - operation: The operation type
      - algorithm: Optional algorithm to use
      - additionalOptions: Additional options for the configuration
   - Returns: A configured SecurityConfigDTO
   */
  protected func createSecurityConfig(
    operation: SecurityOperationType,
    algorithm: String?=nil,
    additionalOptions: [String: Any]=[:]
  ) -> SecurityConfigDTO {
    // Create base options
    var options=SecurityConfigOptions()

    // Set the operation type
    options.operation=operation

    // Add the algorithm if specified
    if let algorithm {
      options.algorithm=algorithm
    }

    // Add additional options to the metadata dictionary
    var metadata: [String: Any]=[:]
    for (key, value) in additionalOptions {
      metadata[key]=value
    }

    // Set the metadata
    options.metadata=metadata

    // Create and return the config
    return SecurityConfigDTO(options: options)
  }

  /**
   Logs a debug message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logDebug(_ message: String, context: LogContextDTO) async {
    await logger?.log(.debug, message, context: context)
  }

  /**
   Logs an info message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logInfo(_ message: String, context: LogContextDTO) async {
    await logger?.log(.info, message, context: context)
  }

  /**
   Logs a warning message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logWarning(_ message: String, context: LogContextDTO) async {
    await logger?.log(.warning, message, context: context)
  }

  /**
   Logs an error message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logError(_ message: String, context: LogContextDTO) async {
    await logger?.log(.error, message, context: context)
  }

  /**
   Creates a SecurityStorageError from a provider operation result.

   - Parameter result: The SecurityResultDTO from the provider
   - Returns: An appropriate SecurityStorageError
   */
  protected func createError(from result: SecurityResultDTO) -> SecurityStorageError {
    if let errorCode=result.errorCode {
      .providerError(code: errorCode, message: result.errorMessage ?? "Provider error")
    } else if let errorMessage=result.errorMessage {
      .operationFailed(errorMessage)
    } else {
      .operationFailed("Provider operation failed with unknown error")
    }
  }
}
