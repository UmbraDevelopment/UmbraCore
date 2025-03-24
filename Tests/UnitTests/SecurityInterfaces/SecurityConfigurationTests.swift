import Foundation
@testable import SecurityInterfaces
import SecurityProtocolsCore
import XCTest

/// Tests for the SecurityConfiguration implementation
class SecurityConfigurationTests: XCTestCase {
  // MARK: - Predefined Configuration Tests

  func testDefaultConfiguration() {
    let defaultConfig=SecurityConfiguration.default

    XCTAssertEqual(defaultConfig.securityLevel, .standard)
    XCTAssertEqual(defaultConfig.encryptionAlgorithm, "AES-256")
    XCTAssertEqual(defaultConfig.hashAlgorithm, "SHA-256")
    XCTAssertNil(defaultConfig.options)
  }

  func testMinimalConfiguration() {
    let minimalConfig=SecurityConfiguration.minimal

    XCTAssertEqual(minimalConfig.securityLevel, .basic)
    XCTAssertEqual(minimalConfig.encryptionAlgorithm, "AES-128")
    XCTAssertEqual(minimalConfig.hashAlgorithm, "SHA-1")
    XCTAssertNil(minimalConfig.options)
  }

  func testMaximumConfiguration() {
    let maxConfig=SecurityConfiguration.maximum

    XCTAssertEqual(maxConfig.securityLevel, .maximum)
    XCTAssertEqual(maxConfig.encryptionAlgorithm, "AES-GCM-256")
    XCTAssertEqual(maxConfig.hashAlgorithm, "SHA-512")
    XCTAssertNotNil(maxConfig.options)
    XCTAssertEqual(maxConfig.options?["keyRotation"], "enabled")
    XCTAssertEqual(maxConfig.options?["remoteAttestation"], "required")
  }

  // MARK: - Custom Configuration Tests

  func testCustomConfiguration() {
    let customOptions=["testMode": "enabled", "loggingLevel": "verbose"]
    let customConfig=SecurityConfiguration(
      securityLevel: .advanced,
      encryptionAlgorithm: "ChaCha20-Poly1305",
      hashAlgorithm: "SHA-384",
      options: customOptions
    )

    XCTAssertEqual(customConfig.securityLevel, .advanced)
    XCTAssertEqual(customConfig.encryptionAlgorithm, "ChaCha20-Poly1305")
    XCTAssertEqual(customConfig.hashAlgorithm, "SHA-384")
    XCTAssertNotNil(customConfig.options)
    XCTAssertEqual(customConfig.options?["testMode"], "enabled")
    XCTAssertEqual(customConfig.options?["loggingLevel"], "verbose")
  }

  // MARK: - Dictionary Conversion Tests

  func testToDictionaryWithoutOptions() {
    let config=SecurityConfiguration(
      securityLevel: .standard,
      encryptionAlgorithm: "AES-256",
      hashAlgorithm: "SHA-256",
      options: nil
    )

    let dict=config.toDictionary()

    XCTAssertEqual(dict["securityLevel"] as? Int, SecurityLevel.standard.rawValue)
    XCTAssertEqual(dict["encryptionAlgorithm"] as? String, "AES-256")
    XCTAssertEqual(dict["hashAlgorithm"] as? String, "SHA-256")
    XCTAssertEqual(dict.count, 3, "Should only have the three base properties without options")
  }

  func testToDictionaryWithOptions() {
    let config=SecurityConfiguration(
      securityLevel: .advanced,
      encryptionAlgorithm: "AES-GCM-256",
      hashAlgorithm: "SHA-512",
      options: ["keyRotation": "enabled", "remoteAttestation": "optional"]
    )

    let dict=config.toDictionary()

    XCTAssertEqual(dict["securityLevel"] as? Int, SecurityLevel.advanced.rawValue)
    XCTAssertEqual(dict["encryptionAlgorithm"] as? String, "AES-GCM-256")
    XCTAssertEqual(dict["hashAlgorithm"] as? String, "SHA-512")
    XCTAssertEqual(dict["keyRotation"] as? String, "enabled")
    XCTAssertEqual(dict["remoteAttestation"] as? String, "optional")
    XCTAssertEqual(dict.count, 5, "Should have the three base properties plus the two options")
  }

  // MARK: - SecurityProtocolsCore Conversion Tests

  func testToSecurityProtocolsConfig() {
    // Test basic security level
    var config=SecurityConfiguration(
      securityLevel: .basic,
      encryptionAlgorithm: "AES-128",
      hashAlgorithm: "SHA-1",
      options: nil
    )

    var spcConfig=config.toSecurityProtocolsConfig()
    XCTAssertEqual(spcConfig.algorithm, "AES-128")
    XCTAssertEqual(spcConfig.keySizeInBits, 128)

    // Test standard security level
    config=SecurityConfiguration(
      securityLevel: .standard,
      encryptionAlgorithm: "AES-256",
      hashAlgorithm: "SHA-256",
      options: nil
    )

    spcConfig=config.toSecurityProtocolsConfig()
    XCTAssertEqual(spcConfig.algorithm, "AES-256")
    XCTAssertEqual(spcConfig.keySizeInBits, 256)

    // Test advanced security level
    config=SecurityConfiguration(
      securityLevel: .advanced,
      encryptionAlgorithm: "AES-GCM-256",
      hashAlgorithm: "SHA-512",
      options: nil
    )

    spcConfig=config.toSecurityProtocolsConfig()
    XCTAssertEqual(spcConfig.algorithm, "AES-GCM-256")
    XCTAssertEqual(spcConfig.keySizeInBits, 512)

    // Test maximum security level
    config=SecurityConfiguration(
      securityLevel: .maximum,
      encryptionAlgorithm: "ChaCha20-Poly1305",
      hashAlgorithm: "SHA-512",
      options: nil
    )

    spcConfig=config.toSecurityProtocolsConfig()
    XCTAssertEqual(spcConfig.algorithm, "ChaCha20-Poly1305")
    XCTAssertEqual(spcConfig.keySizeInBits, 512)
  }

  // MARK: - Codable Tests

  func testCodableConformance() {
    let original=SecurityConfiguration(
      securityLevel: .advanced,
      encryptionAlgorithm: "AES-GCM-256",
      hashAlgorithm: "SHA-512",
      options: ["keyRotation": "enabled", "remoteAttestation": "optional"]
    )

    // Encode
    let encoder=JSONEncoder()
    var encodedData: Data

    do {
      encodedData=try encoder.encode(original)
    } catch {
      XCTFail("Failed to encode SecurityConfiguration: \(error)")
      return
    }

    // Decode
    let decoder=JSONDecoder()

    do {
      let decoded=try decoder.decode(SecurityConfiguration.self, from: encodedData)

      // Verify decoded matches original
      XCTAssertEqual(decoded.securityLevel, original.securityLevel)
      XCTAssertEqual(decoded.encryptionAlgorithm, original.encryptionAlgorithm)
      XCTAssertEqual(decoded.hashAlgorithm, original.hashAlgorithm)
      XCTAssertEqual(decoded.options?["keyRotation"], original.options?["keyRotation"])
      XCTAssertEqual(decoded.options?["remoteAttestation"], original.options?["remoteAttestation"])
    } catch {
      XCTFail("Failed to decode SecurityConfiguration: \(error)")
    }
  }

  // MARK: - SecurityLevel Tests

  func testSecurityLevels() {
    XCTAssertEqual(SecurityLevel.basic.rawValue, 0)
    XCTAssertEqual(SecurityLevel.standard.rawValue, 1)
    XCTAssertEqual(SecurityLevel.advanced.rawValue, 2)
    XCTAssertEqual(SecurityLevel.maximum.rawValue, 3)
  }
}
