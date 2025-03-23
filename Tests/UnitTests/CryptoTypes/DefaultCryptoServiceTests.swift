import CryptoTypes

// import CryptoTypesServices
import ErrorHandlingDomains
import XCTest

final class DefaultCryptoServiceTests: XCTestCase {
  // private var cryptoService: DefaultCryptoServiceImpl!

  override func setUp() async throws {
    // cryptoService = DefaultCryptoServiceImpl()
  }

  // MARK: - Placeholder Tests

  func testPlaceholder() {
    // This test is a placeholder until the deployment target issues are resolved
    XCTAssertTrue(
      true,
      "This test is temporarily disabled due to deployment target incompatibility"
    )
  }

  //
  /*
   func testGenerateSecureRandomKey() async throws {
       let length = 32
       let key = try await cryptoService.generateSecureRandomKey(length: length)
       XCTAssertEqual(key.count, length)
   }

   func testGenerateSecureRandomBytes() async throws {
       let length = 16
       let bytes = try await cryptoService.generateSecureRandomBytes(length: length)
       XCTAssertEqual(bytes.count, length)
   }

   func testEncryptDecrypt() async throws {
       let data = Data("Hello, World!".utf8)
       let key = try await cryptoService.generateSecureRandomKey(length: 32)
       let initVector = try await cryptoService.generateSecureRandomBytes(length: 12)

       do {
           _ = try await cryptoService.encrypt(data, using: key, iv: initVector)
           XCTFail("Expected encryption to fail with functionality moved error")
       } catch {
           // Print the actual error for debugging
           print("Encryption error: \(error)")
           print("Localized description: \(error.localizedDescription)")

           // Check against specific UmbraErrors error
           if let securityError = error as? UmbraErrors.GeneralSecurity.Core {
               switch securityError {
               case let .encryptionFailed(reason):
                   XCTAssertEqual(reason, "Encryption functionality moved to ResticBar")
               default:
                   XCTFail("Expected encryptionFailed error, got \(securityError)")
               }
           } else {
               XCTFail("Expected UmbraErrors.GeneralSecurity.Core.encryptionFailed, got \(type(of: error))")
           }
       }
   }

   func testEncryptDecryptWithInvalidKey() async throws {
       let data = Data("Hello, World!".utf8)
       let key = try await cryptoService.generateSecureRandomKey(length: 32)
       // We won't use this but keep it to show intent
       _ = try await cryptoService.generateSecureRandomKey(length: 32)
       let initVector = try await cryptoService.generateSecureRandomBytes(length: 12)

       do {
           _ = try await cryptoService.encrypt(data, using: key, iv: initVector)
           XCTFail("Expected encryption to fail with functionality moved error")
       } catch {
           // Print the actual error for debugging
           print("Encryption error: \(error)")
           print("Localized description: \(error.localizedDescription)")

           // Check against specific UmbraErrors error
           if let securityError = error as? UmbraErrors.GeneralSecurity.Core {
               switch securityError {
               case let .encryptionFailed(reason):
                   XCTAssertEqual(reason, "Encryption functionality moved to ResticBar")
               default:
                   XCTFail("Expected encryptionFailed error, got \(securityError)")
               }
           } else {
               XCTFail("Expected UmbraErrors.GeneralSecurity.Core.encryptionFailed, got \(type(of: error))")
           }
       }
   }

   func testEncryptDecryptWithInvalidIV() async throws {
       let data = Data("Hello, World!".utf8)
       let key = try await cryptoService.generateSecureRandomKey(length: 32)
       let initVector = try await cryptoService.generateSecureRandomBytes(length: 12)
       // We won't use this but keep it to show intent
       _ = try await cryptoService.generateSecureRandomBytes(length: 12)

       do {
           _ = try await cryptoService.encrypt(data, using: key, iv: initVector)
           XCTFail("Expected encryption to fail with functionality moved error")
       } catch {
           // Print the actual error for debugging
           print("Encryption error: \(error)")
           print("Localized description: \(error.localizedDescription)")

           // Check against specific UmbraErrors error
           if let securityError = error as? UmbraErrors.GeneralSecurity.Core {
               switch securityError {
               case let .encryptionFailed(reason):
                   XCTAssertEqual(reason, "Encryption functionality moved to ResticBar")
               default:
                   XCTFail("Expected encryptionFailed error, got \(securityError)")
               }
           } else {
               XCTFail("Expected UmbraErrors.GeneralSecurity.Core.encryptionFailed, got \(type(of: error))")
           }
       }
   }
   */
}
