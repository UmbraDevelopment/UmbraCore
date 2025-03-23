import ErrorHandlingDomains
@testable import SecurityInterfaces
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest

/// Tests for the SecurityProviderBase protocol and its adapter functionality
class SecurityProviderBaseTests: XCTestCase {
  // MARK: - Adapter Creation Tests

  func testAdapterCreation() {
    // Create a mock base provider
    let baseProvider=MockSecurityProviderBase()

    // Convert to the modern provider interface
    let modernProvider=baseProvider.asModernProvider()

    // Verify we got a valid provider
    XCTAssertNotNil(modernProvider)
  }
}

// MARK: - Test Helpers

/// Mock implementation of SecurityProviderBase for testing
private final class MockSecurityProviderBase: SecurityInterfaces.SecurityProviderBase {
  func resetSecurityData() async -> Result<Void, SecurityInterfaces.SecurityError> {
    .success(())
  }

  func getHostIdentifier() async -> Result<String, SecurityInterfaces.SecurityError> {
    .success("TEST-HOST-ID")
  }

  func registerClient(bundleIdentifier _: String) async
  -> Result<Bool, SecurityInterfaces.SecurityError> {
    .success(true)
  }

  func requestKeyRotation(keyID _: String) async -> Result<Void, SecurityInterfaces.SecurityError> {
    .success(())
  }

  func notifyKeyCompromise(keyID _: String) async
  -> Result<Void, SecurityInterfaces.SecurityError> {
    .success(())
  }
}
