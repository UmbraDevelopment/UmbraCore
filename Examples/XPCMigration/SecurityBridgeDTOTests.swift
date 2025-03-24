import UmbraErrors
import UmbraErrorsCore
import CoreDTOs

import SecurityBridge
import SecurityInterfaces
import UmbraCoreTypes
import XCTest
import XPCProtocolsCore

/// This file demonstrates how the Foundation-independent DTOs make testing easier
/// and more reliable compared to the old NSObject-based approach.
///
/// It shows how to create a mock implementation of the XPCServiceProtocolStandardDTO
/// interface for testing purposes.

// MARK: - Mock Implementation

/// A mock implementation of XPCServiceProtocolStandardDTO for testing
class MockXPCServiceDTOAdapter: XPCServiceProtocolStandardDTO {
  // Record of method calls for verification
  var methodCalls: [String: Int]=[:]

  // Configurable responses for testing
  var pingResponse: Result<Bool, UmbraErrors.Security.ProtocolsDTO> =
    .success(true)
  var randomDataResponse: Result<
    SecureBytes,
    UmbraErrors.Security.ProtocolsDTO
  > = .success(SecureBytes(bytes: [1, 2, 3, 4]))
  var encryptResponse: Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> =
    .success(SecureBytes(bytes: [
      5,
      6,
      7,
      8
    ]))
  var decryptResponse: Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> =
    .success(SecureBytes(bytes: [
      9,
      10,
      11,
      12
    ]))
  var signResponse: Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> =
    .success(SecureBytes(bytes: [
      13,
      14,
      15,
      16
    ]))
  var verifyResponse: Result<Bool, UmbraErrors.Security.ProtocolsDTO> =
    .success(true)
  var statusResponse: Result<
    XPCServiceDTO.ServiceStatusDTO,
    UmbraErrors.Security.ProtocolsDTO
  > = .success(
    XPCServiceDTO.ServiceStatusDTO(status: "healthy", version: "1.0.0")
  )
  var versionResponse: Result<String, UmbraErrors.Security.ProtocolsDTO> =
    .success("1.0.0")
  var hardwareIdentifierResponse: Result<
    String,
    UmbraErrors.Security.ProtocolsDTO
  > = .success("test-hardware")
  var resetSecurityResponse: Result<Void, UmbraErrors.Security.ProtocolsDTO> =
    .success(())

  // Implementation of XPCServiceProtocolDTO methods

  func ping() async -> Result<Bool, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("ping")
    return pingResponse
  }

  func getServiceStatus() async
    -> Result<
      XPCServiceDTO.ServiceStatusDTO,
      UmbraErrors.Security.ProtocolsDTO
    >
  {
    recordMethodCall("getServiceStatus")
    return statusResponse
  }

  func getServiceVersion() async
  -> Result<String, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("getServiceVersion")
    return versionResponse
  }

  func resetSecurity() async
  -> Result<Void, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("resetSecurity")
    return resetSecurityResponse
  }

  // Implementation of XPCServiceProtocolStandardDTO methods

  func generateRandomData(length _: Int) async
  -> Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("generateRandomData")
    return randomDataResponse
  }

  func encryptData(
    _: SecureBytes,
    keyIdentifier _: String?
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("encryptData")
    return encryptResponse
  }

  func decryptData(
    _: SecureBytes,
    keyIdentifier _: String?
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("decryptData")
    return decryptResponse
  }

  func sign(
    _: SecureBytes,
    keyIdentifier _: String
  ) async
  -> Result<SecureBytes, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("sign")
    return signResponse
  }

  func verify(
    signature _: SecureBytes,
    for _: SecureBytes,
    keyIdentifier _: String
  ) async
  -> Result<Bool, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("verify")
    return verifyResponse
  }

  func getHardwareIdentifier() async
  -> Result<String, UmbraErrors.Security.ProtocolsDTO> {
    recordMethodCall("getHardwareIdentifier")
    return hardwareIdentifierResponse
  }

  func synchronizeKeys(_: SecureBytes) async throws {
    recordMethodCall("synchronizeKeys")
    // This can be configured to throw an error if needed for testing
  }

  // Helper method to record method calls
  private func recordMethodCall(_ method: String) {
    methodCalls[method]=(methodCalls[method] ?? 0) + 1
  }

  // Helper method to verify method calls
  func verifyMethodCall(_ method: String, callCount: Int=1) -> Bool {
    methodCalls[method] == callCount
  }
}

// MARK: - Service Under Test

/// A service that uses the XPCServiceProtocolStandardDTO interface
class SecurityService {
  private let adapter: XPCServiceProtocolStandardDTO

  init(adapter: XPCServiceProtocolStandardDTO) {
    self.adapter=adapter
  }

  /// Encrypt sensitive data
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - keyId: Optional key identifier
  /// - Returns: Encrypted data or an error
  func encryptSensitiveData(_ data: [UInt8], keyID: String?=nil) async -> Result<[UInt8], Error> {
    // Check if the service is available
    let pingResult=await adapter.ping()
    guard case .success(true)=pingResult else {
      return .failure(UmbraErrors.Security.ProtocolsDTO.serviceUnavailable())
    }

    // Convert input data to SecureBytes
    let secureData=SecureBytes(bytes: data)

    // Encrypt the data
    let result=await adapter.encryptData(secureData, keyIdentifier: keyID)

    // Convert the result back to [UInt8]
    return result.flatMap { encryptedBytes in
      var bytesArray=[UInt8]()
      encryptedBytes.withUnsafeBytes { buffer in
        bytesArray=Array(buffer)
      }
      return .success(bytesArray)
    }.mapError { $0 as Error }
  }

  /// Check if the service is healthy
  /// - Returns: A boolean indicating if the service is healthy
  func isServiceHealthy() async -> Bool {
    let statusResult=await adapter.getServiceStatus()

    guard case let .success(status)=statusResult else {
      return false
    }

    return status.status == "healthy"
  }
}

// MARK: - Tests

/// Tests for the SecurityService using the mock adapter
class SecurityServiceTests: XCTestCase {
  var mockAdapter: MockXPCServiceDTOAdapter!
  var securityService: SecurityService!

  override func setUp() {
    super.setUp()
    mockAdapter=MockXPCServiceDTOAdapter()
    securityService=SecurityService(adapter: mockAdapter)
  }

  override func tearDown() {
    mockAdapter=nil
    securityService=nil
    super.tearDown()
  }

  func testEncryptSensitiveData_Success() async {
    // Configure the mock to return success responses
    mockAdapter.pingResponse = .success(true)
    mockAdapter.encryptResponse = .success(SecureBytes(bytes: [5, 6, 7, 8]))

    // Call the method under test
    let result=await securityService.encryptSensitiveData([1, 2, 3, 4])

    // Verify the result
    switch result {
      case let .success(data):
        XCTAssertEqual(data, [5, 6, 7, 8])
      case .failure:
        XCTFail("Expected success but got failure")
    }

    // Verify method calls
    XCTAssertTrue(mockAdapter.verifyMethodCall("ping"))
    XCTAssertTrue(mockAdapter.verifyMethodCall("encryptData"))
  }

  func testEncryptSensitiveData_ServiceUnavailable() async {
    // Configure the mock to return a failure response for ping
    mockAdapter.pingResponse = .failure(.serviceUnavailable())

    // Call the method under test
    let result=await securityService.encryptSensitiveData([1, 2, 3, 4])

    // Verify the result
    switch result {
      case .success:
        XCTFail("Expected failure but got success")
      case let .failure(error):
        XCTAssertTrue(error is UmbraErrors.Security.ProtocolsDTO)
        if let errorDTO=error as? UmbraErrors.Security.ProtocolsDTO {
          XCTAssertEqual(errorDTO.code, .serviceUnavailable)
        }
    }

    // Verify method calls
    XCTAssertTrue(mockAdapter.verifyMethodCall("ping"))
    XCTAssertFalse(mockAdapter.verifyMethodCall("encryptData"))
  }

  func testEncryptSensitiveData_EncryptionFails() async {
    // Configure the mock
    mockAdapter.pingResponse = .success(true)
    mockAdapter.encryptResponse = .failure(.cryptographicError(
      operation: "encryption",
      details: "Failed to encrypt data"
    ))

    // Call the method under test
    let result=await securityService.encryptSensitiveData([1, 2, 3, 4])

    // Verify the result
    switch result {
      case .success:
        XCTFail("Expected failure but got success")
      case let .failure(error):
        XCTAssertTrue(error is UmbraErrors.Security.ProtocolsDTO)
        if let errorDTO=error as? UmbraErrors.Security.ProtocolsDTO {
          XCTAssertEqual(errorDTO.code, .cryptographicError)
          XCTAssertEqual(errorDTO.details["operation"], "encryption")
        }
    }

    // Verify method calls
    XCTAssertTrue(mockAdapter.verifyMethodCall("ping"))
    XCTAssertTrue(mockAdapter.verifyMethodCall("encryptData"))
  }

  func testIsServiceHealthy_Success() async {
    // Configure the mock
    mockAdapter.statusResponse = .success(XPCServiceDTO.ServiceStatusDTO(
      status: "healthy",
      version: "1.0.0"
    ))

    // Call the method under test
    let isHealthy=await securityService.isServiceHealthy()

    // Verify the result
    XCTAssertTrue(isHealthy)

    // Verify method calls
    XCTAssertTrue(mockAdapter.verifyMethodCall("getServiceStatus"))
  }

  func testIsServiceHealthy_NotHealthy() async {
    // Configure the mock
    mockAdapter.statusResponse = .success(XPCServiceDTO.ServiceStatusDTO(
      status: "degraded",
      version: "1.0.0",
      stringInfo: ["reason": "High load"]
    ))

    // Call the method under test
    let isHealthy=await securityService.isServiceHealthy()

    // Verify the result
    XCTAssertFalse(isHealthy)

    // Verify method calls
    XCTAssertTrue(mockAdapter.verifyMethodCall("getServiceStatus"))
  }

  func testIsServiceHealthy_Error() async {
    // Configure the mock
    mockAdapter.statusResponse = .failure(.serviceUnavailable())

    // Call the method under test
    let isHealthy=await securityService.isServiceHealthy()

    // Verify the result
    XCTAssertFalse(isHealthy)

    // Verify method calls
    XCTAssertTrue(mockAdapter.verifyMethodCall("getServiceStatus"))
  }
}

/// Extension to support mapping errors in Result
extension Result {
  /// Map the error of a Result to a different error type
  /// - Parameter transform: A function that transforms the error to a new type
  /// - Returns: A Result with the same success type but a different error type
  func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> Result<Success, NewFailure> {
    switch self {
      case let .success(value):
        .success(value)
      case let .failure(error):
        .failure(transform(error))
    }
  }
}
