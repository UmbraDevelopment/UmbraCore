import CryptoSwiftFoundationIndependent
import SecurityImplementation
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

// Mock storage implementation using actor for thread safety
private actor MockSecureStorageActor {
  private var storage: [String: SecureBytes]=[:]

  func storeData(_ data: SecureBytes, identifier: String) -> KeyStorageResult {
    storage[identifier]=data
    return .success
  }

  func retrieveData(identifier: String) -> KeyRetrievalResult {
    guard let data=storage[identifier] else {
      return .failure(.keyNotFound)
    }
    return .success(data)
  }

  func deleteData(identifier: String) -> KeyDeletionResult {
    if storage.removeValue(forKey: identifier) != nil {
      return .success
    }
    return .failure(.keyNotFound)
  }
}

// Wrapper class that conforms to SecureStorageProtocol
private final class MockSecureStorage: SecureStorageProtocol, Sendable {
  private let actor=MockSecureStorageActor()

  func storeSecurely(data: SecureBytes, identifier: String) async -> KeyStorageResult {
    await actor.storeData(data, identifier: identifier)
  }

  func retrieveSecurely(identifier: String) async -> KeyRetrievalResult {
    await actor.retrieveData(identifier: identifier)
  }

  func deleteSecurely(identifier: String) async -> KeyDeletionResult {
    await actor.deleteData(identifier: identifier)
  }
}

final class KeyManagementTests: XCTestCase {
  private var keyManagement: KeyManagementImpl!

  override func setUp() {
    super.setUp()
    keyManagement=KeyManagementImpl(secureStorage: MockSecureStorage())
  }

  override func tearDown() {
    keyManagement=nil
    super.tearDown()
  }

  // MARK: - Key Storage Tests

  func testStoreAndRetrieveKey() async {
    // Create test key
    let testKey=SecureBytes(bytes: CryptoWrapper.generateRandomKey(size: 32))
    let keyID="test-key-\(UUID().uuidString)"

    // Store the key
    let storeResult=await keyManagement.storeKey(testKey, withIdentifier: keyID)
    if case .failure=storeResult {
      XCTFail("Key storage should succeed")
    }

    // Retrieve the key
    let retrieveResult=await keyManagement.retrieveKey(withIdentifier: keyID)

    guard case let .success(retrievedKey)=retrieveResult else {
      XCTFail("Key retrieval should succeed")
      return
    }

    // Verify retrieved key matches original
    XCTAssertEqual(retrievedKey, testKey)
  }

  func testKeyNotFound() async {
    let nonExistentKeyID="non-existent-key"

    // Try to retrieve a key that doesn't exist
    let retrieveResult=await keyManagement.retrieveKey(withIdentifier: nonExistentKeyID)

    if case .success=retrieveResult {
      XCTFail("Retrieval of non-existent key should fail")
    } else if case .failure=retrieveResult {
      // This is the expected path
    } else {
      XCTFail("Should fail with storage operation failed error")
    }
  }

  // MARK: - Key Rotation Tests

  func testKeyRotation() async {
    // Create initial test key and encrypted data
    let initialKey=SecureBytes(bytes: CryptoWrapper.generateRandomKey(size: 32))
    let testData=SecureBytes(bytes: Array("Sensitive data to be encrypted".utf8))
    let keyID="rotation-test-key-\(UUID().uuidString)"

    // Encrypt data with initial key
    let iv=CryptoWrapper.generateRandomIVSecure()

    // For debugging
    print("IV size: \(iv.count)")
    print("Initial key size: \(initialKey.count)")

    let encryptionResult=Result { try CryptoWrapper.encryptAES_GCM(
      data: testData,
      key: initialKey,
      iv: iv
    )
    }

    guard case let .success(encryptedData)=encryptionResult else {
      if case let .failure(error)=encryptionResult {
        XCTFail("Failed to encrypt data: \(error)")
      } else {
        XCTFail("Unexpected encryption result")
      }
      return
    }

    // For debugging
    print("Encrypted data size: \(encryptedData.count)")

    let combinedData=SecureBytes.combine(iv, encryptedData)

    // Store the initial key
    let storeResult=await keyManagement.storeKey(initialKey, withIdentifier: keyID)
    guard case .success=storeResult else {
      if case let .failure(error)=storeResult {
        XCTFail("Failed to store key: \(error)")
      } else {
        XCTFail("Unexpected storage result")
      }
      return
    }

    // Retrieve and verify key is stored correctly
    let retrieveResult=await keyManagement.retrieveKey(withIdentifier: keyID)
    guard case let .success(retrievedKey)=retrieveResult else {
      if case let .failure(error)=retrieveResult {
        XCTFail("Failed to retrieve key: \(error)")
      } else {
        XCTFail("Unexpected retrieval result")
      }
      return
    }

    XCTAssertEqual(retrievedKey, initialKey, "Retrieved key should match initial key")

    // Perform key rotation
    print("Combined data size before rotation: \(combinedData.count)")
    let rotationResult=await keyManagement.rotateKey(
      withIdentifier: keyID,
      dataToReencrypt: combinedData
    )

    guard case let .success((newKey, reencryptedData))=rotationResult else {
      if case let .failure(error)=rotationResult {
        XCTFail("Key rotation failed: \(error)")
      } else {
        XCTFail("Unexpected rotation result")
      }
      return
    }

    guard let reencryptedData else {
      XCTFail("Key rotation should return reencrypted data")
      return
    }

    // Verify the reencrypted data is different
    XCTAssertNotEqual(reencryptedData, combinedData)

    // Verify we can decrypt the reencrypted data with the new key
    // Extract IV (first 12 bytes) and ciphertext
    let ivSize=12 // AES GCM IV size is 12 bytes
    guard reencryptedData.count > ivSize else {
      XCTFail("Reencrypted data is too short: \(reencryptedData.count) bytes")
      return
    }

    do {
      let (newIv, newCiphertext)=try reencryptedData.split(at: ivSize)

      print("New IV size: \(newIv.count)")
      print("New ciphertext size: \(newCiphertext.count)")

      // Decrypt with new key
      let decryptResult=Result { try CryptoWrapper.decryptAES_GCM(
        data: newCiphertext,
        key: newKey,
        iv: newIv
      )
      }

      switch decryptResult {
        case let .success(decryptedData):
          // Verify decrypted data matches original
          XCTAssertEqual(decryptedData, testData)
        case let .failure(error):
          XCTFail("Failed to decrypt after key rotation: \(error)")
      }
    } catch {
      XCTFail("Failed to split reencrypted data: \(error)")
    }
  }

  // MARK: - Key Deletion Tests

  func testKeyDeletion() async {
    // Create and store test key
    let testKey=SecureBytes(bytes: CryptoWrapper.generateRandomKey(size: 32))
    let keyID="deletion-test-key-\(UUID().uuidString)"

    // Store the key
    _=await keyManagement.storeKey(testKey, withIdentifier: keyID)

    // Delete the key
    let deleteResult=await keyManagement.deleteKey(withIdentifier: keyID)
    if case .failure=deleteResult {
      XCTFail("Key deletion should succeed")
    }

    // Verify key cannot be retrieved
    let retrieveResult=await keyManagement.retrieveKey(withIdentifier: keyID)

    if case .success=retrieveResult {
      XCTFail("Key should not be retrievable after deletion")
    }
  }
}
