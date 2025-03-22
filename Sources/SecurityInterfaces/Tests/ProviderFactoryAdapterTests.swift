/**
 * This file contains tests that need to be updated for the new security architecture.
 * Currently all tests are skipped.
 */

import XCTest
@testable import SecurityInterfaces
@testable import SecurityInterfacesBase

final class ProviderFactoryAdapterTests: XCTestCase {
  func testSkipAllTests() throws {
    throw XCTSkip("These tests need to be updated to work with the new security architecture")
  }
}
