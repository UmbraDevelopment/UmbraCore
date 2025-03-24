import CoreErrors
import Foundation
import UmbraCoreTypes
import UmbraErrors

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// Factory class that provides convenience methods for creating protocol adapters
/// during the migration from legacy protocols to the new XPCProtocolsCore protocols.
///
/// **Migration Notice:**
/// This factory now exclusively creates ModernXPCService instances which implement
/// all XPC service protocols. Legacy adapters have been removed as part of the
/// modernization effort.
///
/// The factory methods remain to ensure API compatibility, but all return
/// ModernXPCService implementations.
public enum XPCProtocolMigrationFactory {
  /// Create a standard protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolStandard
  public static func createStandardAdapter() -> any XPCServiceProtocolStandard {
    ModernXPCService()
  }

  /// Create a complete protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolComplete
  public static func createCompleteAdapter() -> any XPCServiceProtocolComplete {
    ModernXPCService()
  }

  /// Create a basic protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolBasic
  public static func createBasicAdapter() -> any XPCServiceProtocolBasic {
    ModernXPCService()
  }

  /// Convert from legacy error to UmbraErrors.Security.Core
  ///
  /// - Parameter error: Error to convert
  /// - Returns: UmbraErrors.Security.Protocols representation
  public static func convertLegacyError(_ error: Error) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // First check if it's already the right type
    if let securityError = error as? UmbraErrors.Security.Core {
      return convertErrorToSecurityProtocolError(securityError)
    }

    // Convert to UmbraErrors.Security.Core with appropriate mapping
    let nsError = error as NSError

    // Try to create a more specific error based on domain and code
    return .internalError(nsError.localizedDescription)
  }

  /// Convert any error to UmbraErrors.Security.Protocols
  ///
  /// - Parameter error: Any error
  /// - Returns: UmbraErrors.Security.Protocols representation
  public static func anyErrorToXPCError(_ error: Error) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // If the error is already a UmbraErrors.Security.Core, return it directly
    if let xpcError = error as? UmbraErrors.Security.Core {
      return convertErrorToSecurityProtocolError(xpcError)
    }

    // Otherwise create a general error with the original error's description
    return .internalError(error.localizedDescription)
  }

  /// Map a Foundation error to an XPC security error
  /// - Parameter error: The error to map
  /// - Returns: An XPC security error
  public static func mapFoundationError(_ error: Error) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // If the error is already an UmbraErrors.Security.Core, convert it
    if let xpcError = error as? UmbraErrors.Security.Core {
      return convertErrorToSecurityProtocolError(xpcError)
    }

    // Use NSError conversion for Foundation errors
    if let nsError = error as? NSError {
      return mapNSError(nsError)
    }

    // Fallback to a generic error
    return .internalError(error.localizedDescription)
  }

  /// Map NSError to a domain-specific error type
  ///
  /// - Parameter error: NSError to map
  /// - Returns: An UmbraErrors.Security.Protocols representing the given error
  public static func mapNSError(_ error: NSError) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // For errors from a specific domain, try to create domain-specific errors
    switch error.domain {
      case NSURLErrorDomain:
        return .connectionFailed(error.localizedDescription)
      case NSOSStatusErrorDomain:
        return .operationFailed(error.localizedDescription)
      default:
        return .internalError(error.localizedDescription)
    }
  }

  /// Convert from UmbraErrors.Security.Core to UmbraErrors.Security.Protocols
  ///
  /// - Parameter error: The UmbraErrors.Security.Core to convert
  /// - Returns: Equivalent UmbraErrors.Security.Protocols
  public static func convertErrorToSecurityProtocolError(_ error: UmbraErrors.Security.Core) -> ErrorHandlingDomains.UmbraErrors.Security.Protocols {
    // First check if it's already the right type
    if let securityError = error as? ErrorHandlingDomains.UmbraErrors.Security.Protocols {
      return securityError
    }

    // Convert NSError
    let nsError = error as NSError
    // Try to create a more specific error based on domain and code
    return .internalError(nsError.localizedDescription)
  }

  /// Map any NSError to an UmbraErrors.Security.Core
  ///
  /// - Parameter error: NSError to convert
  /// - Returns: An UmbraErrors.Security.Core representing the given error
  public static func mapError(_ error: Error) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // NSError properties
    let nsError = error as NSError
    let domain = nsError.domain

    // Map specific error domains
    if domain == NSURLErrorDomain {
      return .connectionFailed(nsError.localizedDescription)
    } else {
      return .internalError(nsError.localizedDescription)
    }
  }

  /// Map any error to a security protocol error
  /// - Parameter error: The error to convert
  /// - Returns: Converted error
  public static func mapGenericError(_ error: Error) -> ErrorHandlingDomains.UmbraErrors.Security
  .Protocols {
    // If the error is already an UmbraErrors.Security.Core, convert it
    if let xpcError = error as? UmbraErrors.Security.Core {
      return convertErrorToSecurityProtocolError(xpcError)
    }

    // Otherwise create a general error with the original error's description
    return .internalError(error.localizedDescription)
  }

  // MARK: - Migration Helper Methods

  /// Creates a wrapper for a legacy XPC service
  ///
  /// - Parameter legacyService: The legacy service to wrap
  /// - Returns: A modern XPCServiceProtocolComplete implementation
  public static func createWrapperForLegacyService(
    _: Any
  ) -> any XPCServiceProtocolComplete {
    createCompleteAdapter()
  }

  /// Creates a mock service implementation for testing purposes
  ///
  /// - Parameter mockResponses: Dictionary of method names to mock responses
  /// - Returns: A mock XPCServiceProtocolComplete implementation
  public static func createMockService(
    mockResponses _: [String: Any]=[:]
  ) -> any XPCServiceProtocolComplete {
    // This could be expanded in the future to provide a more sophisticated mock
    ModernXPCService()
  }

  /// Convert Data to SecureBytes
  ///
  /// Useful for migration from legacy code using Data to modern code using SecureBytes
  ///
  /// - Parameter data: The Data object to convert
  /// - Returns: A SecureBytes instance containing the same data
  public static func convertDataToSecureBytes(_ data: Data) -> SecureBytes {
    SecureBytes(bytes: [UInt8](data))
  }

  /// Convert SecureBytes to Data
  ///
  /// Useful for interoperability with APIs that require Data
  ///
  /// - Parameter secureBytes: The SecureBytes to convert
  /// - Returns: A Data instance containing the same bytes
  public static func convertSecureBytesToData(_ secureBytes: SecureBytes) -> Data {
    Data(secureBytes)
  }

  /// Convert a generic Error to UmbraErrors.Security.Core
  ///
  /// - Parameter error: The error to convert
  /// - Returns: Equivalent UmbraErrors.Security.Core
  public static func convertErrorToSecurityError(_ error: Error) -> UmbraErrors.Security.Core {
    // First check if it's already the right type
    if let securityError = error as? UmbraErrors.Security.Core {
      return securityError
    }

    // Convert NSError
    let nsError = error as NSError
    // Try to create a more specific error based on domain and code
    return UmbraErrors.Security.Core.internalError(nsError.localizedDescription)
  }
}
