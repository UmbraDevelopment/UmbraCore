import CryptoSwiftFoundationIndependent
import SecurityImplementation
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

final class CryptoServiceTests: XCTestCase {
  private var cryptoService: CryptoServiceImpl!

  override func setUp() {
    super.setUp()
    cryptoService=CryptoServiceImpl()
  }

  override func tearDown() {
    cryptoService=nil
    super.tearDown()
  }

  // MARK: - Test Key Generation

  func testGenerateKey() async {
    let result=await cryptoService.generateKey()

    // Verify success case
    switch result {
      case let .success(key):
        XCTAssertEqual(key.count, 32) // AES-256 key should be 32 bytes
      case let .failure(error):
        XCTFail("Key generation should succeed, but failed with: \(error)")
    }
  }

  // MARK: - Test Symmetric Encryption/Decryption

  func testEncryptAndDecryptSymmetric() async {
    // Generate test data
    let plaintext=SecureBytes(bytes: Array("Test secure message".utf8))

    // Generate a key
    let keyResult=await cryptoService.generateKey()

    guard case let .success(key)=keyResult else {
      XCTFail("Failed to generate key")
      return
    }

    // Encrypt the plaintext
    let config=SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: 256
    )
    let encryptResult=await cryptoService.encryptSymmetric(
      data: plaintext,
      key: key,
      config: config
    )

    // Verify encryption was successful
    switch encryptResult {
      case let .success(encryptedData):
        // Verify encrypted data is not empty and is different from plaintext
        XCTAssertFalse(encryptedData.isEmpty, "Encrypted data should not be empty")
        XCTAssertNotEqual(
          encryptedData,
          plaintext,
          "Encrypted data should be different from plaintext"
        )

        // Now decrypt the encrypted data
        let decryptResult=await cryptoService.decryptSymmetric(
          data: encryptedData,
          key: key,
          config: config
        )

        // Verify decryption was successful
        switch decryptResult {
          case let .success(decryptedData):
            // Verify decrypted data matches original plaintext
            XCTAssertEqual(
              decryptedData,
              plaintext,
              "Decrypted data should match original plaintext"
            )
          case let .failure(error):
            XCTFail("Decryption failed with error: \(error)")
        }
      case let .failure(error):
        XCTFail("Encryption failed with error: \(error)")
    }
  }

  // MARK: - Test Hashing

  func testHash() async {
    // Create test data
    let data=SecureBytes(bytes: Array("Data to hash".utf8))

    // Hash the data with SHA-256 config
    let config=SecurityConfigDTO(
      algorithm: "SHA-256",
      keySizeInBits: 256
    )
    let result=await cryptoService.hash(data: data, config: config)

    // Verify hashing was successful
    switch result {
      case let .success(hash):
        // Verify hash has expected length for SHA-256 (32 bytes)
        XCTAssertEqual(hash.count, 32, "SHA-256 hash should be 32 bytes")

        // Hash the same data again
        let repeatResult=await cryptoService.hash(data: data, config: config)

        // Verify repeat hashing was successful
        switch repeatResult {
          case let .success(repeatHash):
            // Verify hash consistency (same data should produce same hash)
            XCTAssertEqual(hash, repeatHash, "Same data should produce the same hash")

            // Hash different data
            let differentData=SecureBytes(bytes: Array("Different data".utf8))
            let differentResult=await cryptoService.hash(data: differentData, config: config)

            // Verify different data hashing was successful
            switch differentResult {
              case let .success(differentHash):
                // Verify different data produces different hash
                XCTAssertNotEqual(
                  hash,
                  differentHash,
                  "Different data should produce different hash"
                )
              case let .failure(error):
                XCTFail("Different data hashing failed with error: \(error)")
            }
          case let .failure(error):
            XCTFail("Repeat hashing failed with error: \(error)")
        }
      case let .failure(error):
        XCTFail("Hashing failed with error: \(error)")
    }
  }

  // MARK: - Test Error Cases

  func testInvalidKey() async {
    // Generate test data
    let plaintext=SecureBytes(bytes: Array("Test secure message".utf8))

    // Create an invalid key (wrong size)
    let invalidKey=SecureBytes(bytes: Array("tooShort".utf8)) // Only 8 bytes

    // Create config
    let config=SecurityConfigDTO(
      algorithm: "AES-GCM",
      keySizeInBits: 256
    )

    // Attempt to encrypt with invalid key
    let encryptResult=await cryptoService.encryptSymmetric(
      data: plaintext,
      key: invalidKey,
      config: config
    )

    // Verify encryption fails with appropriate error
    switch encryptResult {
      case .success:
        XCTFail("Encryption with invalid key should fail but succeeded")
      case .failure:
        // Test passes - encryption with invalid key should fail
        break
    }
  }
}
