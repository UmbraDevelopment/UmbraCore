import Foundation
import ErrorHandlingInterfaces
import ErrorHandlingDomains

/// Mapper for security-related errors to the UmbraErrors.Security namespace
public struct SecurityErrorMapper: ErrorMapper {
  public typealias TargetError = Error
  
  public init() {}
  
  /// Maps standard security errors to the UmbraErrors.Security namespace
  /// - Parameter error: The error to map
  /// - Returns: A properly namespaced security error
  public func map(_ error: Error) -> Error {
    // Handle different types of security errors
    if let nsError = error as? NSError {
      // Map NSError based on domain and code
      switch nsError.domain {
        case "NSOSStatusErrorDomain":
          return mapOSStatusError(nsError)
        case "kCFErrorDomainCFNetwork":
          return mapNetworkSecurityError(nsError)
        default:
          return mapGenericSecurityError(nsError)
      }
    }
    
    // Handle platform-specific security errors
    #if os(macOS)
    if let secError = error as? SecurityKeyChainError {
      return mapKeyChainError(secError)
    }
    #endif
    
    // Default case - wrap in a generic security error
    return UmbraErrors.Security.Core.internalError(description: "Unmapped security error: \(error.localizedDescription)")
  }
  
  /// Check if this mapper can handle the given error
  /// - Parameter error: The error to check
  /// - Returns: True if this mapper can handle the error
  public func canMap(_ error: Error) -> Bool {
    // Can map NSErrors from security-related domains
    if let nsError = error as? NSError {
      let securityDomains = [
        "NSOSStatusErrorDomain",
        "kCFErrorDomainCFNetwork",
        "com.apple.security",
      ]
      return securityDomains.contains(nsError.domain)
    }
    
    // Can map platform-specific security errors
    #if os(macOS)
    if error is SecurityKeyChainError {
      return true
    }
    #endif
    
    return false
  }
  
  // MARK: - Private mapping methods
  
  private func mapOSStatusError(_ error: NSError) -> Error {
    // Map common OS status codes to security errors
    switch error.code {
      case -25293: // errSecItemNotFound
        return UmbraErrors.Security.Core.accessDenied(reason: "Item not found in keychain")
      case -25299: // errSecUnimplemented
        return UmbraErrors.Security.Core.operationFailed(reason: "Security operation not implemented")
      case -25300: // errSecParam
        return UmbraErrors.Security.Core.invalidParameter(name: "unknown", reason: "Invalid parameter")
      default:
        return UmbraErrors.Security.Core.internalError(description: "OS Security error: \(error.localizedDescription)")
    }
  }
  
  private func mapNetworkSecurityError(_ error: NSError) -> Error {
    // Map common network security errors
    switch error.code {
      case -1202: // Certificate validation failure
        return UmbraErrors.Security.Core.invalidCertificate(reason: error.localizedDescription)
      case -1200: // SSL protocol error
        return UmbraErrors.Security.Core.operationFailed(reason: "SSL protocol error: \(error.localizedDescription)")
      default:
        return UmbraErrors.Security.Core.operationFailed(reason: "Network security error: \(error.localizedDescription)")
    }
  }
  
  private func mapGenericSecurityError(_ error: NSError) -> Error {
    return UmbraErrors.Security.Core.internalError(description: error.localizedDescription)
  }
  
  #if os(macOS)
  private func mapKeyChainError(_ error: SecurityKeyChainError) -> Error {
    switch error {
      case .itemNotFound:
        return UmbraErrors.Security.Core.accessDenied(reason: "Item not found in keychain")
      case .accessDenied:
        return UmbraErrors.Security.Core.accessDenied(reason: "Access to keychain denied")
      case .invalidData:
        return UmbraErrors.Security.Core.invalidParameter(name: "data", reason: "Invalid keychain data")
      case .duplicateItem:
        return UmbraErrors.Security.Core.operationFailed(reason: "Duplicate keychain item")
      case .unknown:
        return UmbraErrors.Security.Core.internalError(description: "Unknown keychain error")
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
