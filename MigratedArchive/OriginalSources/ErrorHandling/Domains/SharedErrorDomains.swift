import Foundation
import Interfaces
import UmbraErrorsCore

// This file provides shared declarations for error domains and compatibility
// between ErrorHandling and UmbraErrors modules

// MARK: - Error Domains

/// Error domain namespace for security-related errors
public enum ErrorDomain {
  /// Domain for network-related errors
  public static let network="Network.Core"
  /// Domain for security-related errors
  public static let security="Security.Core"
  /// Domain for resource-related errors
  public static let resource="Resource.Core"
  /// Domain for repository-related errors
  public static let repository="Repository.Core"
  /// Crypto domain for cryptographic operations
  public static let crypto="Crypto"
  /// Application domain for application-specific errors
  public static let application="Application"
  /// Service domain for service-related operations
  public static let service="Service"
  /// Logging domain for logging-related operations
  public static let logging="Logging"
  /// Key management domain for key-related operations
  public static let keyManagement="KeyManagement"
  /// Storage domain for secure storage operations
  public static let storage="Storage"
  /// XPC domain for XPC-related operations
  public static let xpc="XPC"
}

// MARK: - Error Type Compatibility

/// Type compatibility for UmbraError protocol
/// Use this typedef to avoid ambiguity between different modules
public typealias ErrorProtocol=UmbraErrorsCore.UmbraError

/// Type compatibility for error source
/// Use this typedef to avoid ambiguity between different modules
public typealias ErrorSource=UmbraErrorsCore.ErrorSource

/// Standard error capabilities interface
/// This provides a standard interface for error handling capabilities
public protocol StandardErrorCapabilitiesProtocol {
  /// Domain identifier
  var domain: String { get }

  /// Code identifier
  var code: String { get }

  /// Human-readable error description
  var errorDescription: String { get }

  /// Source information
  var source: ErrorSource? { get }

  /// Create a new error with source information
  func with(source: ErrorSource) -> Self
}

/// Unified error context implementation
/// Use this to avoid ambiguous declarations across modules
public struct UmbraSharedErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code, and description
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: Human-readable description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

// MARK: - ErrorSource Type Compatibility

/// Extension to add conversion initializers between ErrorSource types
extension Interfaces.ErrorSource {
  /// Convert from UmbraErrorsCore.ErrorSource to Interfaces.ErrorSource
  public init(from source: UmbraErrorsCore.ErrorSource) {
    self.init(file: source.file, line: source.line, function: source.function)
  }

  /// Convert to UmbraErrorsCore.ErrorSource
  public func toUmbraErrorsCoreType() -> UmbraErrorsCore.ErrorSource {
    UmbraErrorsCore.ErrorSource(file: file, line: line, function: function)
  }
}

/// Extension to add conversion initializers between ErrorSource types
extension UmbraErrorsCore.ErrorSource {
  /// Convert from Interfaces.ErrorSource to UmbraErrorsCore.ErrorSource
  public init(from source: Interfaces.ErrorSource) {
    self.init(file: source.file, line: source.line, function: source.function)
  }

  /// Convert to Interfaces.ErrorSource
  public func toInterfacesType() -> Interfaces.ErrorSource {
    Interfaces.ErrorSource(file: file, line: line, function: function)
  }
}

// MARK: - ErrorContext Type Compatibility

// Commenting out these methods as they reference types that don't exist in the Interfaces module

/*
 /// Extension to add conversion initializers between ErrorContext types
 extension Interfaces.ErrorContext {
   /// Convert from UmbraErrorsCore.ErrorContext to Interfaces.ErrorContext
   public init(from context: UmbraErrorsCore.ErrorContext) {
     self.init(
       source: context.source,
       operation: context.operation,
       details: context.details,
       file: context.file,
       line: context.line,
       function: context.function
     )
   }
 }
 */

// MARK: - Type-safe wrapper functions to help with protocol conformance

/// Convert UmbraErrorsCore.ErrorSource to Interfaces.ErrorSource safely
public func convertToInterfacesSource(_ source: UmbraErrorsCore.ErrorSource?) -> Interfaces
.ErrorSource? {
  guard let source else { return nil }
  return Interfaces.ErrorSource(from: source)
}

/// Convert Interfaces.ErrorSource to UmbraErrorsCore.ErrorSource safely
public func convertToUmbraErrorsCoreSource(_ source: Interfaces.ErrorSource?) -> UmbraErrorsCore
.ErrorSource? {
  guard let source else { return nil }
  return UmbraErrorsCore.ErrorSource(from: source)
}

/*
 /// Convert UmbraErrorsCore.ErrorContext to Interfaces.ErrorContext safely
 public func convertToInterfacesContext(_ context: UmbraErrorsCore.ErrorContext) -> Interfaces.ErrorContext {
   return Interfaces.ErrorContext(from: context)
 }
 */
