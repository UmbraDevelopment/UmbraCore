@testable import CryptoTypes
import SecurityTypes
import UmbraMocks
import XCTest

final class CredentialManagerTests: XCTestCase {
  var mockKeychain: MockKeychain!
  var mockCryptoService: MockCryptoService!
  var credentialManager: CredentialManager!

  override func setUp() async throws {
    mockKeychain = MockKeychain()
    mockCryptoService = MockCryptoService()
    credentialManager = CredentialManager(
      cryptoService: mockCryptoService,
      keychain: mockKeychain
    )
  }

  override func tearDown() async throws {
    await mockKeychain.reset()
    credentialManager = nil
    mockCryptoService = nil
  }

  func testCredentialStorage() async throws {
    let testCredential = "test_credential"
    let identifier = "test_id"

    try await credentialManager.store(credential: testCredential, withIdentifier: identifier)
    let storedCredential: String = try await credentialManager.retrieve(withIdentifier: identifier)
    XCTAssertEqual(
      storedCredential,
      testCredential,
      "Retrieved credential should match stored credential"
    )
  }

  func testCredentialDeletion() async throws {
    let testCredential = "test_credential"
    let identifier = "test_id"

    try await credentialManager.store(credential: testCredential, withIdentifier: identifier)
    try await credentialManager.delete(withIdentifier: identifier)

    do {
      let _: String = try await credentialManager.retrieve(withIdentifier: identifier)
      XCTFail("Should throw error for deleted credential")
    } catch let error as CryptoError {
      if case .keyNotFound = error {
        // Expected error
      } else {
        XCTFail("Error should be CryptoError.keyNotFound, got \(error)")
      }
    } catch {
      XCTFail("Error should be CryptoError.keyNotFound, got \(error)")
    }
  }

  func testCredentialUpdate() async throws {
    let testCredential = "test_credential"
    let updatedCredential = "updated_credential"
    let identifier = "test_id"

    try await credentialManager.store(credential: testCredential, withIdentifier: identifier)
    try await credentialManager.store(credential: updatedCredential, withIdentifier: identifier)

    let retrievedCredential: String = try await credentialManager.retrieve(withIdentifier: identifier)
    XCTAssertEqual(
      retrievedCredential,
      updatedCredential,
      "Retrieved credential should match updated credential"
    )
  }

  func testNonexistentCredential() async throws {
    do {
      let _: String = try await credentialManager.retrieve(withIdentifier: "nonexistent")
      XCTFail("Should throw error for nonexistent credential")
    } catch let error as CryptoError {
      if case .keyNotFound = error {
        // Expected error
      } else {
        XCTFail("Error should be CryptoError.keyNotFound, got \(error)")
      }
    } catch {
      XCTFail("Error should be CryptoError.keyNotFound, got \(error)")
    }
  }

  func testCredentialExists() async throws {
    let identifier = "test_id"
    let credential = "test_credential"

    let exists = await credentialManager.exists(withIdentifier: identifier)
    XCTAssertFalse(exists, "Credential should not exist initially")

    try await credentialManager.store(credential: credential, withIdentifier: identifier)
    let existsAfterStore = await credentialManager.exists(withIdentifier: identifier)
    XCTAssertTrue(existsAfterStore, "Credential should exist after storage")

    try await credentialManager.delete(withIdentifier: identifier)
    let existsAfterDelete = await credentialManager.exists(withIdentifier: identifier)
    XCTAssertFalse(existsAfterDelete, "Credential should not exist after deletion")
  }
}
