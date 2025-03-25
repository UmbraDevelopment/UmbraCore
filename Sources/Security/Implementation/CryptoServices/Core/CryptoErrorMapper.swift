import Foundation
import UmbraCoreTypes
import UmbraErrors
import Errors

/// Provides mapping functions between internal CryptoError and the Core SecurityProtocolError
///
/// This mapper facilitates the transition from the implementation-specific CryptoError type to the
/// SecurityProtocolError type from Security Core Errors. It ensures consistent error handling
/// across the codebase.
public enum CryptoErrorMapper {
  /// Maps from implementation-specific CryptoError to SecurityProtocolError
  ///
  /// - Parameter error: Implementation-specific CryptoError to map
  /// - Returns: Equivalent SecurityProtocolError instance
  public static func mapToSecurityProtocolError(_ error: CryptoError) -> SecurityProtocolError {
    switch error {
      case let .encryptionError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .decryptionError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .hashingError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .keyGenerationError(reason):
        return SecurityProtocolError.keyManagementError(reason)

      case let .keyDerivationFailed(reason):
        return SecurityProtocolError.keyManagementError(reason)

      case let .invalidKeySize(size):
        return SecurityProtocolError.invalidInput("Invalid key size: \(size) bytes")

      case let .invalidKeyFormat(reason):
        return SecurityProtocolError.invalidInput("Invalid key format: \(reason)")

      case let .invalidParameters(reason):
        return SecurityProtocolError.invalidInput(reason)

      case let .algorithmNotSupported(algorithm):
        return SecurityProtocolError.unsupportedOperation(name: algorithm)

      case let .asymmetricEncryptionError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .asymmetricDecryptionError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .symmetricEncryptionError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .symmetricDecryptionError(reason):
        return SecurityProtocolError.cryptographicError(reason)

      case let .invalidKeyIdentifier(identifier):
        return SecurityProtocolError.keyManagementError("Key not found: \(identifier)")
        
      case let .invalidNonce(reason):
        return SecurityProtocolError.invalidInput("Invalid nonce: \(reason)")
        
      case let .authenticationFailed(reason):
        return SecurityProtocolError.authenticationFailed(reason)
        
      case let .internalError(reason):
        return SecurityProtocolError.internalError(reason)
    }
  }

  /// Maps from SecurityProtocolError to implementation-specific CryptoError
  ///
  /// - Parameter error: SecurityProtocolError to map
  /// - Returns: Equivalent CryptoError instance
  public static func mapToImplementationError(_ error: SecurityProtocolError) -> CryptoError {
    switch error {
      case let .cryptographicError(reason):
        if reason.contains("encryption") {
          return .encryptionError(reason: reason)
        } else if reason.contains("decryption") {
          return .decryptionError(reason: reason)
        } else if reason.contains("hash") {
          return .hashingError(reason: reason)
        } else {
          return .internalError(reason)
        }

      case let .keyManagementError(reason):
        if reason.contains("generation") {
          return .keyGenerationError(reason: reason)
        } else if reason.contains("derivation") {
          return .keyDerivationFailed(reason: reason)
        } else if reason.contains("not found") {
          let identifier = reason.components(separatedBy: ":").last?.trimmingCharacters(in: CharacterSet.whitespaces) ?? "unknown"
          return .invalidKeyIdentifier(identifier)
        } else {
          return .keyGenerationError(reason: reason)
        }

      case let .invalidInput(reason):
        if reason.contains("key size") {
          // Try to extract the key size
          let sizeString = reason.components(separatedBy: ":").last?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
          if let size = Int(sizeString.components(separatedBy: " ").first ?? "") {
            return .invalidKeySize(size: size)
          }
          return .invalidParameters(reason: reason)
        } else if reason.contains("key format") {
          return .invalidKeyFormat(reason: reason.components(separatedBy: ":").last?.trimmingCharacters(in: CharacterSet.whitespaces) ?? reason)
        } else if reason.contains("nonce") {
          return .invalidNonce(reason.components(separatedBy: ":").last?.trimmingCharacters(in: CharacterSet.whitespaces) ?? reason)
        } else {
          return .invalidParameters(reason: reason)
        }

      case let .unsupportedOperation(name):
        return .algorithmNotSupported(algorithm: name)
        
      case let .authenticationFailed(reason):
        return .authenticationFailed(reason)
        
      case let .internalError(reason):
        return .internalError(reason)
        
      // Handle other cases
      case let .configurationError(reason):
        return .invalidParameters(reason: reason)
        
      case let .securityError(reason):
        return .internalError(reason)
        
      case let .storageError(reason):
        return .internalError(reason)
        
      case let .serviceError(_, message):
        return .internalError(message)
    }
  }
}

/// Convenience extensions for CryptoError for easy conversion to SecurityProtocolError
extension CryptoError {
  /// Converts this implementation-specific CryptoError to SecurityProtocolError
  ///
  /// - Returns: Equivalent SecurityProtocolError instance
  public func toSecurityProtocolError() -> SecurityProtocolError {
    CryptoErrorMapper.mapToSecurityProtocolError(self)
  }
}

/// Convenience extensions for SecurityProtocolError for easy conversion to CryptoError
extension SecurityProtocolError {
  /// Converts this SecurityProtocolError to implementation-specific CryptoError
  ///
  /// - Returns: Equivalent CryptoError instance
  public func toImplementationError() -> CryptoError {
    CryptoErrorMapper.mapToImplementationError(self)
  }
}
