import Foundation
import UmbraErrors
import UmbraErrorsCore

/// Mapper for security-related errors to the UmbraErrors.Security namespace
public struct SecurityErrorMapper: ErrorMapper {
  public typealias TargetError=Error

  public init() {}

  /// Maps standard security errors to the UmbraErrors.Security namespace
  /// - Parameter error: The error to map
  /// - Returns: A properly namespaced security error
  public func map(_ error: Error) -> Error {
    // Handle different types of security errors
    let nsError = error as NSError
    
    // Map NSError based on domain and code
    switch nsError.domain {
      case "NSOSStatusErrorDomain":
        return mapOSStatusError(nsError)
      case "kCFErrorDomainCFNetwork":
        return mapNetworkSecurityError(nsError)
      case _ where nsError.domain.contains("apple.security"):
        // Handle platform-specific security errors
        #if os(macOS)
          if let secError = error as? SecurityKeyChainError {
            return mapKeyChainError(secError)
          }
        #endif
        return mapGenericSecurityError(nsError)
      default:
        return mapGenericSecurityError(nsError)
    }
  }

  /// Check if this mapper can handle the given error
  /// - Parameter error: The error to check
  /// - Returns: True if this mapper can handle the error
  public func canMap(_ error: Error) -> Bool {
    // Can map NSErrors from security-related domains
    let nsError = error as NSError
    let securityDomains=[
      "NSOSStatusErrorDomain",
      "kCFErrorDomainCFNetwork",
      "com.apple.security"
    ]
    
    if securityDomains.contains(nsError.domain) {
      return true
    }

    // Can map platform-specific security errors
    #if os(macOS)
      return error is SecurityKeyChainError
    #else
      return false
    #endif
  }

  // MARK: - Private mapping methods

  private func mapOSStatusError(_ error: NSError) -> Error {
    // Map common OS status codes to security errors
    switch error.code {
      case -25293: // errSecItemNotFound
        UmbraErrors.Security.Core.accessDenied(reason: "Item not found in keychain")
      case -25299: // errSecUnimplemented
        UmbraErrors.Security.Core.operationFailed(reason: "Security operation not implemented")
      case -25300: // errSecParam
        UmbraErrors.Security.Core.invalidParameter(name: "unknown", reason: "Invalid parameter")
      default:
        UmbraErrors.Security.Core
          .internalError(description: "OS Security error: \(error.localizedDescription)")
    }
  }

  private func mapNetworkSecurityError(_ error: NSError) -> Error {
    // Map common network security errors
    switch error.code {
      case -1202: // Certificate validation failure
        UmbraErrors.Security.Core.invalidCertificate(reason: error.localizedDescription)
      case -1200: // SSL protocol error
        UmbraErrors.Security.Core
          .operationFailed(reason: "SSL protocol error: \(error.localizedDescription)")
      default:
        UmbraErrors.Security.Core
          .operationFailed(reason: "Network security error: \(error.localizedDescription)")
    }
  }

  private func mapGenericSecurityError(_ error: NSError) -> Error {
    UmbraErrors.Security.Core.internalError(description: error.localizedDescription)
  }

  #if os(macOS)
    private func mapKeyChainError(_ error: SecurityKeyChainError) -> Error {
      switch error {
        case .itemNotFound:
          UmbraErrors.Security.Core.accessDenied(reason: "Item not found in keychain")
        case .accessDenied:
          UmbraErrors.Security.Core.accessDenied(reason: "Access to keychain denied")
        case .invalidData:
          UmbraErrors.Security.Core.invalidParameter(name: "data", reason: "Invalid keychain data")
        case .duplicateItem:
          UmbraErrors.Security.Core.operationFailed(reason: "Duplicate keychain item")
        case .unknown:
          UmbraErrors.Security.Core.internalError(description: "Unknown keychain error")
      }
    }
  #endif
}

// Platform-specific security error types
#if os(macOS)
  /// Keychain-specific error type for macOS
  public enum SecurityKeyChainError: Error {
    case itemNotFound
    case accessDenied
    case invalidData
    case duplicateItem
    case unknown
  }
#endif
