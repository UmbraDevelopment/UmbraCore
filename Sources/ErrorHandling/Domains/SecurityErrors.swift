import Foundation
import UmbraErrorsCore
// Use the shared declarations instead of local ones
import Interfaces

extension UmbraErrors {
  /// General security-related error domains
  /// For specialised security error types, see:
  /// - SecurityCoreErrors.swift
  /// - SecurityProtocolErrors.swift
  /// - SecurityXPCErrors.swift
  public enum GeneralSecurity {
    /// Common security errors spanning all security domains
    public enum Core: Error, Sendable, Equatable {
      /// General encryption failure
      case encryptionFailed(reason: String)

      /// General decryption failure
      case decryptionFailed(reason: String)

      /// Key generation failed
      case keyGenerationFailed(reason: String)

      /// Provided key is invalid or in an incorrect format
      case invalidKey(reason: String)

      /// Hash verification failed
      case hashVerificationFailed(reason: String)

      /// Secure random number generation failed
      case randomGenerationFailed(reason: String)

      /// Input data is in an invalid format
      case invalidInput(reason: String)

      /// Secure storage operation failed
      case storageOperationFailed(reason: String)

      /// Security operation timed out
      case timeout(operation: String)

      /// General security service error
      case serviceError(code: Int, reason: String)

      /// Internal error within the security system
      case internalError(String)

      /// Operation not implemented
      case notImplemented(feature: String)
    }

    /// XPC-specific security errors
    public enum XPC: Error, Sendable, Equatable {
      /// Connection to XPC service failed
      case connectionFailed(reason: String)

      /// XPC service is not available
      case serviceUnavailable

      /// Received an invalid response from XPC service
      case invalidResponse(reason: String)

      /// Attempted to use an unexpected selector
      case unexpectedSelector(name: String)

      /// Service version does not match expected version
      case versionMismatch(expected: String, found: String)

      /// Service identifier is invalid
      case invalidServiceIdentifier

      /// Internal error within XPC handling
      case internalError(String)
    }

    /// Protocol-specific security errors
    public enum Protocols: Error, Sendable, Equatable {
      /// Data format does not conform to protocol expectations
      case invalidFormat(reason: String)

      /// Operation is not supported by the protocol
      case unsupportedOperation(name: String)

      /// Protocol version is incompatible
      case incompatibleVersion(version: String)

      /// Required protocol implementation is missing
      case missingProtocolImplementation(protocolName: String)

      /// Protocol in invalid state for operation
      case invalidState(state: String, expectedState: String)

      /// Internal error within protocol handling
      case internalError(String)

      /// Input data is in an invalid format
      case invalidInput(reason: String)

      /// General encryption failure
      case encryptionFailed(reason: String)

      /// General decryption failure
      case decryptionFailed(reason: String)

      /// Secure random number generation failed
      case randomGenerationFailed(reason: String)

      /// Secure storage operation failed
      case storageOperationFailed(reason: String)

      /// General security service error
      case serviceError(code: Int, reason: String)

      /// Operation not implemented
      case notImplemented
    }
  }
}
