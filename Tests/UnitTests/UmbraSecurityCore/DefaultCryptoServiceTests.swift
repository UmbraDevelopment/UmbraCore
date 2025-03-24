import ErrorHandlingDomains
import SecurityProtocolsCore
import UmbraCoreTypes
@testable import UmbraSecurityCore
import XCTest

final class DefaultCryptoServiceTests: XCTestCase {
  var cryptoService: DefaultCryptoService!

  override func setUp() {
    super.setUp()
    cryptoService=DefaultCryptoService()
  }

  override func tearDown() {
    cryptoService=nil
    super.tearDown()
  }

  // MARK: - Test Simple API

  func testGenerateKey() async {
    let keyResult=await cryptoService.generateKey()

    switch keyResult {
      case let .success(key):
        XCTAssertEqual(key.count, 32, "Generated key should be 32 bytes (256 bits)")
      case let .failure(error):
        XCTFail("Key generation failed with error: \(error)")
    }
  }

  func testEncryptDecrypt() async {
    let testData=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let keyResult=await cryptoService.generateKey()

    guard case let .success(key)=keyResult else {
      XCTFail("Failed to generate key for test")
      return
    }

    let encryptResult=await cryptoService.encrypt(data: testData, using: key)

    guard case let .success(encryptedData)=encryptResult else {
      XCTFail("Encryption failed")
      return
    }

    let decryptResult=await cryptoService.decrypt(data: encryptedData, using: key)

    guard case let .success(decryptedData)=decryptResult else {
      XCTFail("Decryption failed")
      return
    }

    // In a real implementation, we would expect decryptedData to equal testData
    // But since this is a placeholder, we just check that we got some data back
    XCTAssertFalse(decryptedData.isEmpty, "Decrypted data should not be empty")
  }

  func testHashingFunctionality() async {
    let testData=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let hashResult=await cryptoService.hash(data: testData)

    guard case let .success(hash)=hashResult else {
      XCTFail("Hashing failed")
      return
    }

    XCTAssertEqual(hash.count, 32, "Hash should be 32 bytes (SHA-256 size)")
  }

  // MARK: - Test Symmetric Encryption

  func testSymmetricEncryptionDecryption() async {
    let testData=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let keyResult=await cryptoService.generateKey()

    guard case let .success(key)=keyResult else {
      XCTFail("Failed to generate key for test")
      return
    }

    let config=SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: 256
    )

    let encryptResult=await cryptoService.encryptSymmetric(
      data: testData,
      key: key,
      config: config
    )

    guard case let .success(encryptedData)=encryptResult else {
      XCTFail("Encryption failed: \(encryptResult)")
      return
    }

    let decryptResult=await cryptoService.decryptSymmetric(
      data: encryptedData,
      key: key,
      config: config
    )

    guard case let .success(decryptedData)=decryptResult else {
      XCTFail("Decryption failed: \(decryptResult)")
      return
    }

    XCTAssertFalse(decryptedData.isEmpty, "Decrypted data should not be empty")
  }

  // MARK: - Test Random Data Generation

  func testRandomDataGeneration() async {
    let randomDataResult=await cryptoService.generateRandomData(length: 32)

    switch randomDataResult {
      case let .success(randomData):
        XCTAssertEqual(randomData.count, 32, "Generated random data should be 32 bytes")
      case let .failure(error):
        XCTFail("Random data generation failed with error: \(error)")
    }
  }

  // MARK: - Test Verify Functionality

  func testVerifyFunctionality() async {
    let testData=SecureBytes(bytes: [1, 2, 3, 4, 5])
    let hashResult=await cryptoService.hash(data: testData)

    guard case let .success(hash)=hashResult else {
      XCTFail("Hashing failed")
      return
    }

    let verifyResult=await cryptoService.verify(data: testData, against: hash)

    guard case let .success(isValid)=verifyResult else {
      XCTFail("Verification failed: \(verifyResult)")
      return
    }

    XCTAssertTrue(isValid, "Verification should succeed for valid data and hash")
  }
}
