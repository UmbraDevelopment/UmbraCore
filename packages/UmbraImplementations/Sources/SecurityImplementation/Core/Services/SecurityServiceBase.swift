import CoreSecurityTypes
import Foundation
import LoggingTypes

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # Security Service Base Protocol

 Defines the common interface for all security service components.
 Each specialised service implements this protocol to ensure consistent
 behaviour across the security implementation.

 ## Design Notes

 This protocol follows the component pattern, allowing the SecurityProviderImpl
 to delegate specific operations to specialised services while maintaining
 a consistent interface for interaction.
 */
protocol SecurityServiceBase {
  /**
   The logger instance for recording operation details
   */
  var logger: LoggingInterfaces.LoggingProtocol { get }

  /**
   Initialises the service with required dependencies

   - Parameters:
       - logger: The logging service to use for operation logging
   */
  init(logger: LoggingInterfaces.LoggingProtocol)

  /**
   Creates standard logging metadata for security operations

   - Parameters:
       - operationID: Unique identifier for the operation
       - operation: The type of operation being performed
       - config: Configuration for the operation
   - Returns: A metadata collection for logging
   */
  func createOperationMetadata(
    operationID: String,
    operation: CoreSecurityTypes.SecurityOperation,
    config: SecurityConfigDTO
  ) -> LoggingTypes.LogMetadataDTOCollection

}

/**
 Default implementation of common security service functionality
 */
extension SecurityServiceBase {
  /**
   Creates standard logging metadata for security operations

   - Parameters:
       - operationID: Unique identifier for the operation
       - operation: The type of operation being performed
       - config: Configuration for the operation
   - Returns: A metadata collection for logging
   */
  func createOperationMetadata(
    operationID: String,
    operation: CoreSecurityTypes.SecurityOperation,
    config: SecurityConfigDTO
  ) -> LoggingTypes.LogMetadataDTOCollection {
    LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: operation.rawValue)
      .withPublic(key: "algorithm", value: config.encryptionAlgorithm.rawValue)
      .withPublic(key: "timestamp", value: "\(Date())")
  }
}

// CoreSecurityError extension has been moved to CoreSecurityError+Extensions.swift
