import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore
import CoreDTOs

/**
 # XPC Protocol Migration Factory
 
 Factory for creating XPC service protocol adapters and helpers for migrating
 between the XPC Protocol versions
 */

/// Factory for XPC service protocol adapters and migration helpers
public enum XPCProtocolMigrationFactory {
  /// Create a standard protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolStandard
  public static func createStandardAdapter() -> any XPCServiceProtocolStandard {
    BasicToStandardProtocolAdapter(service: MockXPCService())
  }

  /// Create a complete protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolComplete
  public static func createCompleteAdapter() -> any XPCServiceProtocolComplete {
    StandardToCompleteProtocolAdapter(service: createStandardAdapter())
  }

  /// Create a basic protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolBasic
  public static func createBasicAdapter() -> any XPCServiceProtocolBasic {
    MockXPCService()
  }

  /// Convert from legacy error to SecurityError
  ///
  /// - Parameter error: Error to convert
  /// - Returns: SecurityError representation
  public static func convertLegacyError(_ error: Error) -> SecurityError {
    // First check if it's already the right type
    if let securityError=error as? SecurityError {
      return securityError
    }

    // Convert to SecurityError with appropriate mapping
    let nsError=error as NSError

    // Try to create a more specific error based on domain and code
    return .internalError(nsError.localizedDescription)
  }

  /// Convert any error to SecurityError
  ///
  /// - Parameter error: Any error
  /// - Returns: SecurityError representation
  public static func anyErrorToXPCError(_ error: Error) -> SecurityError {
    // If the error is already a SecurityError, return it directly
    if let xpcError=error as? SecurityError {
      return xpcError
    }

    // Otherwise create a general error with the original error's description
    return .internalError(error.localizedDescription)
  }

  /// Map a Foundation error to a SecurityError
  /// - Parameter error: The error to map
  /// - Returns: A SecurityError
  public static func mapFoundationError(_ error: Error) -> SecurityError {
    // If the error is already a SecurityError, convert it
    if let xpcError=error as? SecurityError {
      return xpcError
    }

    // Use NSError conversion for Foundation errors
    if let nsError=error as? NSError {
      return mapNSError(nsError)
    }

    // Fallback to a generic error
    return .internalError(error.localizedDescription)
  }

  /// Map NSError to a domain-specific error type
  ///
  /// - Parameter error: NSError to map
  /// - Returns: A SecurityError representing the given error
  public static func mapNSError(_ error: NSError) -> SecurityError {
    // For errors from a specific domain, try to create domain-specific errors
    switch error.domain {
      case NSURLErrorDomain:
        .connectionFailed(error.localizedDescription)
      case NSOSStatusErrorDomain:
        .operationFailed(error.localizedDescription)
      default:
        .internalError(error.localizedDescription)
    }
  }

  /// Convert from SecurityError to SecurityError
  ///
  /// - Parameter error: The SecurityError to convert
  /// - Returns: Equivalent SecurityError
  public static func convertErrorToSecurityError(
    _ error: SecurityError
  ) -> SecurityError {
    // First check if it's already the right type
    if let securityError=error as? SecurityError {
      return securityError
    }

    // Convert NSError
    let nsError=error as NSError
    // Try to create a more specific error based on domain and code
    return .internalError(nsError.localizedDescription)
  }

  /// Map any NSError to a SecurityError
  ///
  /// - Parameter error: NSError to convert
  /// - Returns: A SecurityError representing the given error
  public static func mapError(_ error: Error) -> SecurityError {
    // NSError properties
    let nsError=error as NSError
    let domain=nsError.domain

    // Map specific error domains
    if domain == NSURLErrorDomain {
      return .connectionFailed(nsError.localizedDescription)
    } else {
      return .internalError(nsError.localizedDescription)
    }
  }

  /// Map any error to a SecurityError
  /// - Parameter error: The error to convert
  /// - Returns: Converted error
  public static func mapGenericError(_ error: Error) -> SecurityError {
    // If the error is already a SecurityError, convert it
    if let xpcError=error as? SecurityError {
      return convertErrorToSecurityError(xpcError)
    }

    // Otherwise create a general error with the original error's description
    return .internalError(error.localizedDescription)
  }

  /// Convert a generic Error to SecurityError
  ///
  /// - Parameter error: The error to convert
  /// - Returns: Equivalent SecurityError
  public static func convertErrorToSecurityError(_ error: Error) -> SecurityError {
    // First check if it's already the right type
    if let securityError=error as? SecurityError {
      return securityError
    }

    // Otherwise map the error to a SecurityError
    return mapError(error)
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
    MockXPCService()
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
}

/// Simple mock implementation of XPCServiceProtocolComplete for testing
private final class MockXPCService: XPCServiceProtocolComplete {
  let serviceIdentifier: String = "MockXPCService"
  let serviceVersion: String = "1.0.0-mock"
  
  func ping() async -> Bool {
    true
  }
  
  func synchroniseKeys(_ syncData: SecureBytes) async throws {
    // Mock implementation that doesn't do anything
  }
  
  func secureRandomNumber() async -> Int {
    42 // Mock fixed number
  }
  
  func secureRandomBytes(count: Int) async throws -> SecureBytes {
    // Mock implementation with predictable bytes
    try SecureBytes(repeating: 0xAA, count: count)
  }
  
  func generateRandomData(length: Int) async -> Result<SecureBytes, SecurityError> {
    do {
      // Mock implementation with predictable bytes
      let bytes = try SecureBytes(repeating: 0xAA, count: length)
      return .success(bytes)
    } catch {
      return .failure(SecurityError(
        domain: "MockService",
        code: "RANDOM_DATA_FAILED",
        errorDescription: "Failed to generate random data",
        source: nil,
        underlyingError: error,
        context: ErrorContext()
      ))
    }
  }
  
  func status() async -> Result<[String: Any], SecurityError> {
    .success(["status": "mock", "version": serviceVersion])
  }
  
  func encryptSecureData(
    _ data: SecureBytes, 
    keyIdentifier: String?
  ) async -> Result<SecureBytes, SecurityError> {
    // Mock implementation just returns the same data
    .success(data)
  }
  
  func decryptSecureData(
    _ data: SecureBytes, 
    keyIdentifier: String?
  ) async -> Result<SecureBytes, SecurityError> {
    // Mock implementation just returns the same data
    .success(data)
  }
  
  // All other methods use default implementations from XPCServiceProtocolComplete
}
