import CoreDTOs
import Foundation
import SecurityBridge
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

final class DTOAdaptersTests: XCTestCase {
  // MARK: - Error DTO Tests

  func testErrorDTOConversion() {
    // Create a native error
    let nativeError=UmbraErrors.Security.Protocols.invalidFormat(reason: "Test reason")

    // Convert to DTO
    let errorDTO=SecurityBridge.DTOAdapters.toErrorDTO(error: nativeError)

    // Verify properties
    XCTAssertEqual(errorDTO.domain, "UmbraCore.Security.Protocols")
    XCTAssertEqual(errorDTO.message, "Invalid format: Test reason")
    XCTAssertTrue(errorDTO.details.keys.contains("reason"))
    XCTAssertEqual(errorDTO.details["reason"], "Test reason")

    // Convert back
    let convertedError=SecurityBridge.DTOAdapters.fromErrorDTO(dto: errorDTO)

    // Verify the error type
    XCTAssertTrue(convertedError is NSError)

    let nsError=convertedError as NSError
    XCTAssertEqual(nsError.domain, errorDTO.domain)
    XCTAssertEqual(nsError.code, Int(errorDTO.code))
    XCTAssertEqual(nsError.localizedDescription, errorDTO.message)
  }

  func testDirectErrorDTOCreation() {
    // Create DTO directly
    let errorDTO=SecurityErrorDTO.keyError(
      message: "Key error test",
      details: ["algorithm": "RSA", "keySize": "2048"]
    )

    // Verify properties
    XCTAssertEqual(errorDTO.domain, "UmbraCore.Security")
    XCTAssertEqual(errorDTO.message, "Key error test")
    XCTAssertEqual(errorDTO.details["algorithm"], "RSA")
    XCTAssertEqual(errorDTO.details["keySize"], "2048")

    // Convert to NSError
    let nsError=FoundationConversions.toNSError(errorDTO: errorDTO)

    // Verify properties
    XCTAssertEqual(nsError.domain, errorDTO.domain)
    XCTAssertEqual(nsError.code, Int(errorDTO.code))
    XCTAssertEqual(nsError.localizedDescription, errorDTO.message)
  }

  // MARK: - Config DTO Tests

  func testEncryptionConfigConversion() {
    // Create a native encryption config
    let key=SecureBytes(bytes: Array(repeating: UInt8(1), count: 32))
    let iv=SecureBytes(bytes: Array(repeating: UInt8(2), count: 12))

    let nativeConfig=SecurityProtocols.EncryptionConfig(
      algorithm: .aes256GCM,
      keySizeInBits: 256,
      key: key,
      initializationVector: iv,
      ivSizeBytes: 12,
      authenticationTagLength: 16
    )

    // Convert to DTO
    let configDTO=SecurityBridge.DTOAdapters.toDTO(config: nativeConfig)

    // Verify properties
    XCTAssertEqual(configDTO.algorithm, "AES-256-GCM")
    XCTAssertEqual(configDTO.keySizeInBits, 256)
    XCTAssertEqual(configDTO.options["ivSize"], "12")
    XCTAssertEqual(configDTO.options["authTagLength"], "16")
    XCTAssertTrue(configDTO.inputData != nil)

    // Convert back
    let convertedConfig=SecurityBridge.DTOAdapters.fromDTO(config: configDTO)

    // Verify properties
    XCTAssertEqual(convertedConfig.algorithm, .aes256GCM)
    XCTAssertEqual(convertedConfig.keySizeInBits, 256)
    XCTAssertEqual(convertedConfig.ivSizeBytes, 12)
    XCTAssertEqual(convertedConfig.authenticationTagLength, 16)
  }

  func testKeyConfigConversion() {
    // Create a native key config
    let nativeConfig=SecurityProtocols.KeyConfig(
      algorithm: .rsa,
      keySizeInBits: 2048
    )

    // Convert to DTO
    let configDTO=SecurityBridge.DTOAdapters.toDTO(config: nativeConfig)

    // Verify properties
    XCTAssertEqual(configDTO.algorithm, "RSA")
    XCTAssertEqual(configDTO.keySizeInBits, 2048)

    // Convert back
    let convertedConfig=SecurityBridge.DTOAdapters.keyConfigFromDTO(config: configDTO)

    // Verify properties
    XCTAssertEqual(convertedConfig.algorithm, .rsa)
    XCTAssertEqual(convertedConfig.keySizeInBits, 2048)
  }

  // MARK: - XPC Conversion Tests

  func testErrorDTOXPCConversion() {
    // Create error DTO
    let errorDTO=SecurityErrorDTO.encryptionError(
      message: "Encryption failed",
      details: ["operation": "encrypt", "data": "sensitive"]
    )

    // Convert to XPC dictionary
    let xpcDict=SecurityBridge.DTOAdapters.toXPC(error: errorDTO)

    // Verify dictionary structure
    XCTAssertEqual(xpcDict["domain"] as? String, errorDTO.domain)
    XCTAssertEqual(xpcDict["code"] as? Int32, errorDTO.code)
    XCTAssertEqual(xpcDict["message"] as? String, errorDTO.message)

    // Convert back
    let convertedDTO=SecurityBridge.DTOAdapters.errorFromXPC(dictionary: xpcDict)

    // Verify DTO properties
    XCTAssertEqual(convertedDTO.domain, errorDTO.domain)
    XCTAssertEqual(convertedDTO.code, errorDTO.code)
    XCTAssertEqual(convertedDTO.message, errorDTO.message)
    XCTAssertEqual(convertedDTO.details["operation"], "encrypt")
    XCTAssertEqual(convertedDTO.details["data"], "sensitive")
  }

  func testConfigDTOXPCConversion() {
    // Create config DTO
    let configDTO=SecurityConfigDTO(
      algorithm: "AES-256-GCM",
      keySizeInBits: 256,
      options: ["mode": "GCM", "padding": "PKCS7"],
      inputData: Array(repeating: UInt8(0xA), count: 16)
    )

    // Convert to XPC dictionary
    let xpcDict=SecurityBridge.DTOAdapters.toXPC(config: configDTO)

    // Verify dictionary structure
    XCTAssertEqual(xpcDict["algorithm"] as? String, configDTO.algorithm)
    XCTAssertEqual(xpcDict["keySizeInBits"] as? Int, configDTO.keySizeInBits)
    XCTAssertNotNil(xpcDict["options"])
    XCTAssertNotNil(xpcDict["inputData"])

    // Convert back
    let convertedDTO=SecurityBridge.DTOAdapters.configFromXPC(dictionary: xpcDict)

    // Verify DTO properties
    XCTAssertEqual(convertedDTO.algorithm, configDTO.algorithm)
    XCTAssertEqual(convertedDTO.keySizeInBits, configDTO.keySizeInBits)
    XCTAssertEqual(convertedDTO.options["mode"], "GCM")
    XCTAssertEqual(convertedDTO.options["padding"], "PKCS7")
    XCTAssertEqual(convertedDTO.inputData, configDTO.inputData)
  }

  func testOperationResultDTOXPCConversion() {
    // Create success result
    let successResult=OperationResultDTO<String>.success("Operation successful")

    // Convert to XPC
    let successDict=SecurityBridge.DTOAdapters.toXPC(result: successResult)

    // Verify dictionary structure
    XCTAssertEqual(successDict["status"] as? String, "success")
    XCTAssertNil(successDict["error"])
    XCTAssertNotNil(successDict["value"])

    // Convert back
    let convertedSuccess=SecurityBridge.DTOAdapters.operationResultFromXPC(
      dictionary: successDict,
      type: String.self
    )

    // Verify result
    XCTAssertTrue(convertedSuccess.isSuccess)
    XCTAssertFalse(convertedSuccess.isFailure)
    XCTAssertEqual(convertedSuccess.value, "Operation successful")

    // Create failure result
    let errorDTO=SecurityErrorDTO.generalError(message: "Test error")
    let failureResult=OperationResultDTO<String>.failure(errorDTO)

    // Convert to XPC
    let failureDict=SecurityBridge.DTOAdapters.toXPC(result: failureResult)

    // Verify dictionary structure
    XCTAssertEqual(failureDict["status"] as? String, "failure")
    XCTAssertNotNil(failureDict["error"])
    XCTAssertNil(failureDict["value"])

    // Convert back
    let convertedFailure=SecurityBridge.DTOAdapters.operationResultFromXPC(
      dictionary: failureDict,
      type: String.self
    )

    // Verify result
    XCTAssertFalse(convertedFailure.isSuccess)
    XCTAssertTrue(convertedFailure.isFailure)
    XCTAssertNil(convertedFailure.value)
    XCTAssertEqual(convertedFailure.error?.message, "Test error")
  }
}
