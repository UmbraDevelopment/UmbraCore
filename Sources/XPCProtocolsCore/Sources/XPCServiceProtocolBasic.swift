import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

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

/**
 # Basic XPC Service Protocol

 This file defines the most fundamental protocol for XPC services in UmbraCore.
 The basic protocol establishes minimal functionality that all XPC services must implement,
 providing a foundation for the more advanced protocol levels.

 ## Features

 * Protocol identification capability for service discovery
 * Basic connectivity testing (ping)
 * Simplified key synchronisation mechanism
 * Foundation-free interface design
 * Standardised error handling and data conversion

 This protocol serves as the base for all XPC service implementations in UmbraCore
 and ensures a consistent minimum API across all services.
 */

/// Protocol defining the base XPC service interface without Foundation dependencies.
/// This protocol serves as the foundation for all XPC services in UmbraCore and
/// provides the minimal functionality required for service discovery and basic operations.
public protocol XPCServiceProtocolBasic: Sendable {
  /// Protocol identifier - used for protocol negotiation and service discovery.
  /// Each XPC service implementation should provide a unique identifier.
  static var protocolIdentifier: String { get }

  /// Basic ping method to test if service is responsive.
  /// This method can be used for health checks and to verify connectivity.
  /// - Returns: `true` if the service is responsive, `false` otherwise
  func ping() async -> Bool

  /// Basic synchronisation of keys between XPC service and client.
  /// This method allows secure key material to be shared across process boundaries.
  /// - Parameter syncData: Secure bytes for key synchronisation
  /// - Throws: SecurityError if synchronisation fails
  func synchroniseKeys(_ syncData: SecureBytes) async throws

  /// Get the current status of the XPC service
  /// - Returns: Result containing status information or error
  func status() async -> Result<[String: Any], SecurityError>
}

/// Default protocol implementation with baseline functionality.
/// These implementations can be overridden by conforming types when needed,
/// but provide sensible defaults for minimal compliance.
extension XPCServiceProtocolBasic {
  /// Default protocol identifier that uniquely identifies this protocol version.
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.basic"
  }

  /// Default implementation of the basic ping method.
  /// - Returns: Always returns true for basic implementations
  public func pingBasic() async
  -> Result<Bool, SecurityError> {
    // Simple implementation that doesn't throw
    let pingResult=await ping()
    return .success(pingResult)
  }

  /// Extended synchronisation implementation with Result type return.
  /// - Parameter syncData: Secure bytes for key synchronisation
  /// - Returns: Result with success or failure with error information
  public func synchronizeKeys(_ syncData: SecureBytes) async
  -> Result<Void, SecurityError> {
    do {
      try await synchroniseKeys(syncData)
      return .success(())
    } catch let error as SecurityError {
      return .failure(error)
    } catch {
      return .failure(UmbraErrors.SecurityError.operationFailed(error.localizedDescription))
    }
  }
}
