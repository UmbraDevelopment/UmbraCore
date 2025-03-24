import Foundation
@testable import ResticCLIHelper
@testable import ResticCLIHelperTypes
import ResticTypes
import UmbraTestKit
import XCTest

/// Base test case for restic CLI tests
class ResticTestCase: XCTestCase {
  var mockRepository: TestRepository!
  var helper: ResticCLIHelper!

  override func setUp() async throws {
    try await super.setUp()
    mockRepository=try await TestRepository.create()
    helper=try ResticCLIHelper(executablePath: "/opt/homebrew/bin/restic")
  }

  override func tearDown() async throws {
    try? mockRepository.cleanup()
    try await super.tearDown()
  }
}
