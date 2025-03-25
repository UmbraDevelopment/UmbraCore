import Foundation
import SecurityBridge
@testable import SecurityInterfaces
import SecurityProtocolsCore
import UmbraCoreTypes
import XCTest
import XPCProtocolsCore

/// Tests for the /// Tests for the SecurityProviderAdapter implementations implementations
class ProviderFactoryTests: XCTestCase {
  // MARK: - // MARK: - SecurityProviderAdapter.shared Tests Tests

  func testCreateDefaultSecurityProvider() {
    // Create the factory
    let factory=StandardSecurityProviderFactory()

    // Get a provider using default configuration
    let provider=factory.createDefaultSecurityProvider()

    // Verify we got a valid provider
    XCTAssertNotNil(provider)
    XCTAssertNotNil(provider.cryptoService)
    XCTAssertNotNil(provider.keyManager)
  }

  func testCreateSecurityProviderWithConfig() {
    // Create the factory
    let factory=StandardSecurityProviderFactory()

    // Create a custom configuration
    let config=SecurityConfiguration(
      securityLevel: .advanced,
      encryptionAlgorithm: "AES-GCM-256",
      hashAlgorithm: "SHA-512",
      options: ["keyRotation": "enabled"]
    )

    // Get a provider using the custom configuration
    let provider=factory.createSecurityProvider(config: config)

    // Verify we got a valid provider
    XCTAssertNotNil(provider)
    XCTAssertNotNil(provider.cryptoService)
    XCTAssertNotNil(provider.keyManager)
  }

  func testStaticCreateProvider() {
    do {
      // Use the static factory method
      let provider=try StandardSecurityProviderFactory.createProvider(ofType: "default")

      // Verify we got a valid provider
      XCTAssertNotNil(provider)

      // Test that we can access the provider's methods
      XCTAssertNotNil(provider.getXPCService())
    } catch {
      XCTFail("Failed to create provider: \(error)")
    }
  }

  func testProtocolExtensionCreateProvider() {
    do {
      // Use the protocol extension static method
      let provider=try SecurityProviderFactory.createProvider(ofType: "default")

      // Verify we got a valid provider
      XCTAssertNotNil(provider)

      // Test that we can access the provider's methods
      XCTAssertNotNil(provider.getXPCService())
    } catch {
      XCTFail("Failed to create provider: \(error)")
    }
  }

  // MARK: - Provider Operation Tests

  func testProviderOperations() async {
    do {
      // Use the static factory method
      let provider=try StandardSecurityProviderFactory.createProvider(ofType: "default")

      // Perform a basic operation
      let result=await provider.performSecureOperation(
        operationName: "test",
        options: ["key": "test_key"]
      )

      // Verify the result
      XCTAssertTrue(result.success, "The operation should succeed")
    } catch {
      XCTFail("Failed to create provider: \(error)")
    }
  }

  func testDummyProviderImplementation() async {
    // Get a provider via the factory
    let factory=StandardSecurityProviderFactory()
    let provider=factory.createDefaultSecurityProvider()

    // Test the crypto service
    let keyResult=await provider.cryptoService.generateKey()

    switch keyResult {
      case let .success(key):
        XCTAssertNotNil(key)
        XCTAssertEqual(key.count, 32, "Expected a 32-byte key")
      case let .failure(error):
        XCTFail("Key generation should succeed, but got error: \(error)")
    }

    // Test performing an operation
    let operationConfig=provider.createSecureConfig(options: nil)
    let operationResult=await provider.performSecureOperation(
      operation: .hash,
      config: operationConfig
    )

    XCTAssertTrue(operationResult.success, "The operation should succeed")
  }

  // MARK: - Multiple Provider Types

  func testCreateDifferentProviderTypes() {
    // Try creating providers with different type strings
    do {
      let provider1=try StandardSecurityProviderFactory.createProvider(ofType: "default")
      XCTAssertNotNil(provider1)

      let provider2=try StandardSecurityProviderFactory.createProvider(ofType: "test")
      XCTAssertNotNil(provider2)

      // In the current implementation, these would be the same type of provider
      // but we're testing the factory pattern works correctly
      XCTAssertTrue(type(of: provider1) == type(of: provider2))
    } catch {
      XCTFail("Failed to create providers: \(error)")
    }
  }

  // MARK: - Error Handling

  func testProviderOperationErrorHandling() async {
    do {
      // Use the static factory method
      let provider=try StandardSecurityProviderFactory.createProvider(ofType: "default")

      // Perform an operation that might fail (in this case it won't since we're using a dummy)
      // but we're testing the error handling pattern
      let result=await provider.performSecureOperation(
        operationName: "invalid_operation",
        options: [:]
      )

      // Just verify we got a result
      XCTAssertNotNil(result)
    } catch {
      XCTFail("Failed to create provider: \(error)")
    }
  }
}

// MARK: - Helpers

extension XCTest {
  func XCTAssertNotThrows(_ expression: @autoclosure () throws -> some Any, _ message: String="") {
    do {
      _=try expression()
    } catch {
      XCTFail("\(message): \(error)")
    }
  }
}
