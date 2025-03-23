@testable import CoreTypesImplementation
import CoreTypesInterfaces
import XCTest

final class CoreProviderTests: XCTestCase {
  func testDefaultProvider() async {
    let provider=CoreTypesFactory.createDefaultProvider()

    XCTAssertEqual(provider.providerID, "com.umbra.core.default.provider")
    XCTAssertEqual(provider.providerName, "Umbra Default Security Provider")
    XCTAssertTrue(!provider.providerVersion.isEmpty)

    let isAvailable=await provider.isAvailable()
    XCTAssertTrue(isAvailable)

    let resetResult=await provider.reset()
    switch resetResult {
      case .success:
        XCTAssertTrue(true) // Expected success
      case let .failure(error):
        XCTFail("Reset should succeed but failed with: \(error)")
    }

    let capabilities=await provider.getCapabilities()
    XCTAssertTrue(capabilities.contains(CoreCapability.encryption))
    XCTAssertTrue(capabilities.contains(CoreCapability.decryption))
    XCTAssertTrue(capabilities.contains(CoreCapability.keyGeneration))
    XCTAssertTrue(capabilities.contains(CoreCapability.randomGeneration))
    XCTAssertTrue(capabilities.contains(CoreCapability.hashing))
  }

  func testConfigurableProvider() async {
    let config=ProviderConfiguration(
      providerID: "com.umbra.test.provider",
      providerName: "Test Provider",
      providerVersion: "2.0.0",
      capabilities: [CoreCapability.encryption, CoreCapability.hashing]
    )

    let provider=CoreTypesFactory.createProvider(configuration: config)

    XCTAssertEqual(provider.providerID, "com.umbra.test.provider")
    XCTAssertEqual(provider.providerName, "Test Provider")
    XCTAssertEqual(provider.providerVersion, "2.0.0")

    let isAvailable=await provider.isAvailable()
    XCTAssertTrue(isAvailable)

    let capabilities=await provider.getCapabilities()
    XCTAssertEqual(capabilities.count, 2)
    XCTAssertTrue(capabilities.contains(CoreCapability.encryption))
    XCTAssertTrue(capabilities.contains(CoreCapability.hashing))
    XCTAssertFalse(capabilities.contains(CoreCapability.decryption))
  }
}
