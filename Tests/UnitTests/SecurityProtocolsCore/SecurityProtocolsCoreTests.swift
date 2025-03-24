import ErrorHandling
import ErrorHandlingDomains
@testable import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

class SecurityProtocolsCoreTests: XCTestCase {
  func testVersion() {
    XCTAssertFalse(ModuleInfo.version.isEmpty)
  }

  // MARK: - Security Protocol Error Tests

  func testSecurityProtocolErrorEquatable() {
    // Test that the errors are equatable
    let error1=UmbraErrors.Security.Protocols.internalError("Encryption failed: " + "test")
    let error2=UmbraErrors.Security.Protocols.internalError("Encryption failed: " + "test")
    let error3=UmbraErrors.Security.Protocols.internalError("Decryption failed: " + "test")

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
  }

  func testSecurityProtocolErrorDescription() {
    // Test that the errors have descriptions
    let error1=UmbraErrors.Security.Protocols.internalError("Encryption failed: " + "test")
    let error2=UmbraErrors.Security.Protocols.invalidFormat(reason: "Invalid key")

    XCTAssertEqual(
      String(describing: error1),
      "[Security.Protocols.internal_error] Internal protocol error: Encryption failed: test"
    )
    XCTAssertEqual(
      String(describing: error2),
      "[Security.Protocols.invalid_format] Invalid data format for protocol: Invalid key"
    )
  }

  // MARK: - SecurityOperation Tests

  func testSecurityOperationDescription() {
    // Test operation descriptions
    XCTAssertEqual(SecurityOperation.asymmetricEncryption.rawValue, "asymmetricEncryption")
    XCTAssertEqual(SecurityOperation.keyGeneration.rawValue, "keyGeneration")
    XCTAssertEqual(SecurityOperation.hashing.rawValue, "hashing")
  }

  func testSecurityOperationEquatable() {
    // Test operations are equatable
    let op1=SecurityOperation.asymmetricEncryption
    let op2=SecurityOperation.asymmetricEncryption
    let op3=SecurityOperation.symmetricDecryption

    XCTAssertEqual(op1, op2)
    XCTAssertNotEqual(op1, op3)
  }

  // MARK: - SecurityConfigDTO Tests

  func testSecurityConfigDTODefaults() {
    // Test default configuration
    let config=SecurityConfigDTO.aesGCM()

    XCTAssertEqual(config.algorithm, "AES-GCM")
    XCTAssertEqual(config.keySizeInBits, 256)
    XCTAssertNil(config.initializationVector)
  }

  func testSecurityConfigDTOEquatable() {
    // Test configurations are equatable
    let config1=SecurityConfigDTO(algorithm: "AES", keySizeInBits: 256)
    let config2=SecurityConfigDTO(algorithm: "AES", keySizeInBits: 256)
    let config3=SecurityConfigDTO(algorithm: "RSA", keySizeInBits: 2048)

    XCTAssertEqual(config1, config2)
    XCTAssertNotEqual(config1, config3)
  }

  // MARK: - SecurityResultDTO Tests

  func testSuccessResultCreation() {
    // Test successful result creation
    let data=SecureBytes(bytes: [1, 2, 3])
    let result=SecurityResultDTO.success(data: data)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.data, data)
    XCTAssertNil(result.error)
  }

  func testFailureResultCreation() {
    // Test failure result creation
    let error=UmbraErrors.Security.Protocols.internalError("Encryption failed: " + "test")
    let result=SecurityResultDTO.failure(error: error, details: "Operation failed")

    XCTAssertFalse(result.success)
    XCTAssertNil(result.data)
    XCTAssertEqual(result.error, error)
  }
}
