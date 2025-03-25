import Foundation
import UmbraCoreTypes
import UmbraErrors

/**
 # XPC Protocol Migration Factory
 
 This factory provides tools to help migrate between different XPC protocol versions.
 It includes adapters and converters to maintain compatibility during the transition.
 */
public enum XPCProtocolMigrationFactory {
  /// Create a standard protocol adapter
  ///
  /// - Returns: An implementation that conforms to XPCServiceProtocolStandard
  public static func createStandardAdapter() -> any XPCServiceProtocolStandard {
    MockXPCService()
  }
  
  /// Convert a Result<T, Error> to Result<T, SecurityError>
  ///
  /// - Parameter result: The original result
  /// - Returns: A new result with any error converted to SecurityError
  public static func convertToSecurityResult<T>(_ result: Result<T, Error>) -> Result<T, UmbraErrors.SecurityError> {
    switch result {
    case .success(let value):
      return .success(value)
    case .failure(let error):
      return .failure(convertErrorToSecurityError(error))
    }
  }
  
  /// Convert any Error to SecurityError
  ///
  /// - Parameter error: The original error
  /// - Returns: A SecurityError representation of the error
  public static func convertErrorToSecurityError(_ error: Error) -> UmbraErrors.SecurityError {
    // First check if it's already the right type
    if let securityError = error as? UmbraErrors.SecurityError {
      return securityError
    }
    
    // Otherwise create a new SecurityError that wraps the original
    return UmbraErrors.SecurityError(
      code: .accessError,
      description: "Operation failed: \(error.localizedDescription)",
      underlyingError: error
    )
  }
  
  /// Convert Data to SecureBytes
  ///
  /// - Parameter data: The Data to convert
  /// - Returns: A SecureBytes instance containing the same bytes
  public static func convertDataToSecureBytes(_ data: Data) -> SecureBytes {
    let bytes = [UInt8](data)
    return SecureBytes(bytes: bytes)
  }
  
  /// Convert SecureBytes to Data
  ///
  /// - Parameter secureBytes: The SecureBytes to convert
  /// - Returns: A Data instance containing the same bytes
  public static func convertSecureBytesToData(_ secureBytes: SecureBytes) -> Data {
    Data([UInt8](secureBytes))
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
    let bytes = [UInt8](repeating: 0xAA, count: count)
    return SecureBytes(bytes: bytes)
  }
  
  func generateRandomData(length: Int) async -> Result<SecureBytes, UmbraErrors.SecurityError> {
    // Mock implementation with predictable bytes
    let bytes = [UInt8](repeating: 0xAA, count: length)
    let secureBytes = SecureBytes(bytes: bytes)
    return .success(secureBytes)
  }
  
  func status() async -> Result<[String: Any], UmbraErrors.SecurityError> {
    .success(["status": "mock", "version": serviceVersion])
  }
  
  func encryptSecureData(
    _ data: SecureBytes, 
    keyIdentifier: String?
  ) async -> Result<SecureBytes, UmbraErrors.SecurityError> {
    // Mock implementation just returns the same data
    .success(data)
  }
  
  func decryptSecureData(
    _ data: SecureBytes, 
    keyIdentifier: String?
  ) async -> Result<SecureBytes, UmbraErrors.SecurityError> {
    // Mock implementation just returns the same data
    .success(data)
  }
  
  func sign(_ data: SecureBytes, keyIdentifier: String) async -> Result<SecureBytes, UmbraErrors.SecurityError> {
    // Mock implementation just returns the same data as the signature
    .success(data)
  }
  
  func verify(
    signature: SecureBytes,
    for data: SecureBytes,
    keyIdentifier: String
  ) async -> Result<Bool, UmbraErrors.SecurityError> {
    // Mock implementation always returns true
    .success(true)
  }
  
  func resetSecurity() async -> Result<Void, UmbraErrors.SecurityError> {
    // Mock implementation just returns success
    .success(())
  }
  
  func getServiceVersion() async -> Result<String, UmbraErrors.SecurityError> {
    // Return the mock version
    .success(serviceVersion)
  }
  
  func getHardwareIdentifier() async -> Result<String, UmbraErrors.SecurityError> {
    // Return a mock hardware ID
    .success("MOCK-HARDWARE-ID-12345")
  }
  
  func pingStandard() async -> Result<Bool, UmbraErrors.SecurityError> {
    // Return success
    .success(true)
  }
  
  // All other methods use default implementations from XPCServiceProtocolComplete
}
