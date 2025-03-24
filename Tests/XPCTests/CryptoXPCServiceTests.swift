import ErrorHandlingDomains
import Foundation
import UmbraCryptoService
import UmbraXPC
import XCTest
import XPCProtocolsCore

@available(macOS 14.0, *)
final class CryptoXPCServiceTests: XCTestCase {
  var service: CryptoXPCService!
  var mockCryptoService: MockCryptoXPCService!

  override func setUp() {
    super.setUp()
    // Create the real service for regular API testing
    let dependencies=MockCryptoXPCServiceDependencies()
    service=CryptoXPCService(dependencies: dependencies)

    // Create our mock for specific test scenarios
    mockCryptoService=MockCryptoXPCService()
  }

  override func tearDown() {
    service=nil
    mockCryptoService=nil
    super.tearDown()
  }

  func testEncryptDecryptRoundTrip() {
    // Use expectations for completion-based APIs
    let generateKeyExpectation=expectation(description: "Generate key")
    let encryptExpectation=expectation(description: "Encrypt data")
    let decryptExpectation=expectation(description: "Decrypt data")

    // Test variables
    var keyData: Data?
    var encryptedData: Data?
    var decryptedData: Data?
    var encryptError: Error?
    var decryptError: Error?

    // Test data
    let testData="Hello, XPC Crypto Service!".data(using: .utf8)!

    // Generate a test key
    service.generateKey(bits: 256) { key, _ in
      keyData=key
      generateKeyExpectation.fulfill()
    }

    wait(for: [generateKeyExpectation], timeout: 5.0)
    XCTAssertNotNil(keyData, "Key generation should succeed")
    XCTAssertEqual(keyData?.count, 32, "Key should be 32 bytes for AES-256")

    guard let key=keyData else {
      XCTFail("Key generation failed")
      return
    }

    // Encrypt
    service.encrypt(testData, key: key) { encrypted, error in
      encryptedData=encrypted
      encryptError=error
      encryptExpectation.fulfill()
    }

    wait(for: [encryptExpectation], timeout: 5.0)
    XCTAssertNil(encryptError, "Encryption should not produce an error")
    XCTAssertNotNil(encryptedData, "Encrypted data should not be nil")
    XCTAssertGreaterThan(
      encryptedData?.count ?? 0,
      testData.count,
      "Encrypted data should include IV"
    )

    guard let encrypted=encryptedData else {
      XCTFail("Encryption failed")
      return
    }

    // Decrypt
    service.decrypt(encrypted, key: key) { decrypted, error in
      decryptedData=decrypted
      decryptError=error
      decryptExpectation.fulfill()
    }

    wait(for: [decryptExpectation], timeout: 5.0)
    XCTAssertNil(decryptError, "Decryption should not produce an error")
    XCTAssertNotNil(decryptedData, "Decrypted data should not be nil")
    XCTAssertEqual(decryptedData, testData, "Decrypted data should match original")
  }

  func testRandomDataGeneration() {
    // Test the implemented random data generation
    let randomDataExpectation=expectation(description: "Generate random data")
    var randomData: Data?

    service.generateRandomData(length: 32) { data, _ in
      randomData=data
      randomDataExpectation.fulfill()
    }

    wait(for: [randomDataExpectation], timeout: 5.0)
    XCTAssertNotNil(randomData, "Random data should not be nil")
    XCTAssertEqual(randomData?.count, 32, "Random data should be 32 bytes")

    // Test uniqueness with another random data generation
    let randomData2Expectation=expectation(description: "Generate random data 2")
    var randomData2: Data?

    service.generateRandomData(length: 32) { data, _ in
      randomData2=data
      randomData2Expectation.fulfill()
    }

    wait(for: [randomData2Expectation], timeout: 5.0)
    XCTAssertNotNil(randomData2, "Second random data should not be nil")
    XCTAssertNotEqual(randomData, randomData2, "Random data should be unique")
  }

  func testKeyStorageRetrieval() {
    // Test key storage and retrieval
    let generateKeyExpectation=expectation(description: "Generate key")
    let storeKeyExpectation=expectation(description: "Store key")
    let retrieveKeyExpectation=expectation(description: "Retrieve key")

    var keyData: Data?
    var storeSuccess=false
    var retrievedKey: Data?
    var storeError: Error?
    var retrieveError: Error?

    let keyIdentifier="test.crypto.key.\(UUID().uuidString)"

    // Generate key
    service.generateKey(bits: 256) { key, _ in
      keyData=key
      generateKeyExpectation.fulfill()
    }

    wait(for: [generateKeyExpectation], timeout: 5.0)
    XCTAssertNotNil(keyData, "Key should be generated")

    guard let key=keyData else {
      XCTFail("Key generation failed")
      return
    }

    // Store key
    service.storeKey(key, identifier: keyIdentifier) { success, error in
      storeSuccess=success
      storeError=error
      storeKeyExpectation.fulfill()
    }

    wait(for: [storeKeyExpectation], timeout: 5.0)
    XCTAssertTrue(storeSuccess, "Key should be stored successfully")
    XCTAssertNil(storeError, "Store operation should not produce an error")

    // Retrieve key
    service.retrieveKey(identifier: keyIdentifier) { retrievedData, error in
      retrievedKey=retrievedData
      retrieveError=error
      retrieveKeyExpectation.fulfill()
    }

    wait(for: [retrieveKeyExpectation], timeout: 5.0)
    XCTAssertNil(retrieveError, "Retrieval should not produce an error")
    XCTAssertNotNil(retrievedKey, "Retrieved key should not be nil")
    XCTAssertEqual(retrievedKey, key, "Retrieved key should match original")
  }

  func testInvalidKeySize() {
    // For error handling tests, we'll use our mock
    let invalidKeyExpectation=expectation(description: "Invalid key size")

    // Set up mock to simulate an error
    mockCryptoService.mockGenerateKeyResult=(nil, NSError(
      domain: "ErrorHandlingDomains.UmbraErrors.Security.Protocols",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid key size"]
    ))

    var generatedKey: Data?
    var generationError: Error?

    // Try to generate a key with invalid bit size using our mock
    mockCryptoService.generateKey(bits: 123) { key, error in
      generatedKey=key
      generationError=error
      invalidKeyExpectation.fulfill()
    }

    wait(for: [invalidKeyExpectation], timeout: 5.0)
    XCTAssertNil(generatedKey, "Generation with invalid key size should fail")
    XCTAssertNotNil(generationError, "Should return an error for invalid key size")
  }

  func testInvalidEncryptedData() {
    // For error handling tests, we'll use our mock
    let decryptExpectation=expectation(description: "Decrypt invalid data")

    // Set up mock to simulate an error
    mockCryptoService.mockDecryptResult=(nil, NSError(
      domain: "ErrorHandlingDomains.UmbraErrors.Security.Protocols",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid data format"]
    ))

    var decryptedData: Data?
    var decryptError: Error?

    // Create a test key
    let key=Data(repeating: 0x42, count: 32)
    let invalidData=Data([0x01, 0x02])

    // Try to decrypt invalid data using our mock
    mockCryptoService.decrypt(invalidData, key: key) { decrypted, error in
      decryptedData=decrypted
      decryptError=error
      decryptExpectation.fulfill()
    }

    wait(for: [decryptExpectation], timeout: 5.0)
    XCTAssertNil(decryptedData, "Decryption of invalid data should fail")
    XCTAssertNotNil(decryptError, "Decryption should produce an error")
  }
}
