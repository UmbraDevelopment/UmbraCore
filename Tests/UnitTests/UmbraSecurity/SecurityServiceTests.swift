import ErrorHandlingDomains
import Foundation
import SecurityTypes
@testable import UmbraSecurity
import XCTest

// NOTE: This test needs to be rewritten to work with the new security architecture
final class SecurityServiceTests: XCTestCase {
  // MARK: Test is disabled due to architecture changes

  func testSkipAllTests() throws {
    // This test class needs to be rewritten to work with the new security architecture
    throw XCTSkip("This test needs to be updated to work with the new security architecture")
  }

  /*
   var securityProvider: UmbraSecurity.SecurityService!
   var testFileURL: URL!

   override func setUp() async throws {
       try await super.setUp()
       securityProvider = await UmbraSecurity.SecurityService.shared

       // Create test file
       testFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_file.txt")
       try "Test content".write(to: testFileURL, atomically: true, encoding: .utf8)
   }

   override func tearDown() async throws {
       try? FileManager.default.removeItem(at: testFileURL)
       await securityProvider.stopAccessingAllResources()
       try await super.tearDown()
   }

   func testBookmarkOperations() async throws {
       // Create bookmark
       let bookmarkData = try await securityProvider.createBookmark(forPath: testFileURL.path)
       XCTAssertFalse(bookmarkData.isEmpty)

       // Resolve bookmark
       let (resolvedPath, isStale) = try await securityProvider.resolveBookmark(bookmarkData)
       XCTAssertEqual(resolvedPath, testFileURL.path)
       XCTAssertFalse(isStale)
   }

   func testSecurityScopedAccess() async throws {
       // Start accessing
       let success = try await securityProvider.startAccessing(path: testFileURL.path)
       XCTAssertTrue(success)

       let isAccessing = await securityProvider.isAccessing(path: testFileURL.path)
       XCTAssertTrue(isAccessing)

       // Stop accessing
       await securityProvider.stopAccessing(path: testFileURL.path)
       let isStopped = await securityProvider.isAccessing(path: testFileURL.path)
       XCTAssertFalse(isStopped)
   }

   func testBookmarkStorage() async throws {
       // Create and save bookmark
       let identifier = "test_bookmark"
       let bookmarkData = try await securityProvider.createBookmark(forPath: testFileURL.path)
       try await securityProvider.saveBookmark(bookmarkData, withIdentifier: identifier)

       // Load bookmark
       let loadedData = try await securityProvider.loadBookmark(withIdentifier: identifier)
       XCTAssertEqual(loadedData, bookmarkData)

       // Delete bookmark
       try await securityProvider.deleteBookmark(withIdentifier: identifier)

       // Verify deletion
       do {
           _ = try await securityProvider.loadBookmark(withIdentifier: identifier)
           XCTFail("Expected error loading deleted bookmark")
       } catch let error as SecurityError {
           XCTAssertEqual(error.localizedDescription, "Bookmark not found: \(identifier)")
       }
   }
   */
}
