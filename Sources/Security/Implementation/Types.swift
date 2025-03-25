import SecurityProtocolsCore
import UmbraCoreTypes

// This file contains local types to break dependency cycles
// Note: Most of these types are now defined in SecurityImplementation.swift

// MARK: - Additional Types

/// Foundation-free error type for security operations.
public enum ExtendedSecurityError: Error, Sendable, Equatable {
  case encryptionFailed(reason: String)
  case decryptionFailed(reason: String)
  case keyGenerationFailed(reason: String)
  case invalidKey
  case hashVerificationFailed
  case randomGenerationFailed
  case invalidInput(reason: String)
  case operationFailed(reason: String)
  case unsupportedOperation
  case keyManagementError(reason: String)

  public var description: String {
    switch self {
      case let .encryptionFailed(reason):
        "Encryption failed: \(reason)"
      case let .decryptionFailed(reason):
        "Decryption failed: \(reason)"
      case let .keyGenerationFailed(reason):
        "Key generation failed: \(reason)"
      case .invalidKey:
        "Invalid key"
      case .hashVerificationFailed:
        "Hash verification failed"
      case .randomGenerationFailed:
        "Random generation failed"
      case let .invalidInput(reason):
        "Invalid input: \(reason)"
      case let .operationFailed(reason):
        "Operation failed: \(reason)"
      case .unsupportedOperation:
        "Unsupported operation"
      case let .keyManagementError(reason):
        "Key management error: \(reason)"
    }
  }
}
