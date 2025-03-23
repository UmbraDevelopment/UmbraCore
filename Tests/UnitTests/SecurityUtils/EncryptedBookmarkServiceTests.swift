@testable import CryptoTypes
import ErrorHandlingDomains
@testable import SecurityTypes
@testable import UmbraCrypto
@testable import UmbraMocks
@testable import UmbraSecurityUtils
import XCTest

final class EncryptedBookmarkServiceTests: XCTestCase {
  var cryptoService: CryptoServiceProtocol!
  var bookmarkService: SecurityBookmarkService!
  var credentialManager: CredentialManager!
  var encryptedBookmarkService: EncryptedBookmarkService!
  var mockKeychain: MockKeychain!
  var testFileURL: URL!
  var testFileData: String!
  var testDirectory: URL!

  override func setUp() async throws {
    // Create test directory
    let tempDir=URL(fileURLWithPath: NSTemporaryDirectory())
    testDirectory=tempDir.appendingPathComponent("UmbraSecurityTests", isDirectory: true)
    try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)

    // Create test file
    testFileURL=URL(fileURLWithPath: testDirectory.path).appendingPathComponent("test_file.txt")
    testFileData="Test file content"
    try testFileData.write(to: testFileURL, atomically: true, encoding: .utf8)

    // Set file permissions
    try FileManager.default.setAttributes([
      .posixPermissions: 0o644
    ], ofItemAtPath: testFileURL.path)

    // Set up services
    mockKeychain=MockKeychain()
    cryptoService=CryptoService()
    credentialManager=CredentialManager(cryptoService: cryptoService, keychain: mockKeychain)
    bookmarkService=SecurityBookmarkService()
    encryptedBookmarkService=EncryptedBookmarkService(
      cryptoService: cryptoService,
      bookmarkService: bookmarkService,
      credentialManager: credentialManager
    )
  }

  override func tearDown() async throws {
    try? FileManager.default.removeItem(at: testDirectory)
    testFileURL=nil
    testFileData=nil
  }

  func testBookmarkManagement() async throws {
    // Create and save encrypted bookmark
    let identifier="test_bookmark"
    try await encryptedBookmarkService.saveBookmark(for: testFileURL, withIdentifier: identifier)

    // Resolve bookmark
    let resolvedURL=try await encryptedBookmarkService.resolveBookmark(withIdentifier: identifier)
    XCTAssertEqual(resolvedURL.path, testFileURL.path)

    // Delete bookmark
    try await encryptedBookmarkService.deleteBookmark(withIdentifier: identifier)

    // Verify deletion
    do {
      _=try await encryptedBookmarkService.resolveBookmark(withIdentifier: identifier)
      XCTFail("Expected error resolving deleted bookmark")
    } catch let error as SecurityError {
      XCTAssertEqual(error.localizedDescription, "Bookmark not found: \(identifier)")
    }
  }
}
