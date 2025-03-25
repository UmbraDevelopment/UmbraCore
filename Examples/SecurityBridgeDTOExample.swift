
import Foundation
import SecurityBridge
import SecurityProtocolsCore
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/// Security Bridge examples demonstrating how to use the security operations.
enum SecurityBridgeDTOExample {
  /// This example demonstrates how to use security operations.
  /// It shows how security types work.

  // Example 1: Working with security errors
  static func errorHandlingExample() {
    print("=== Error Handling Example ===")

    // Create a native security error
    let nativeError=UmbraErrors.Security.Protocols.invalidFormat(reason: "Invalid key format")
    print("Native error: \(nativeError)")

    // Convert the error to an NSError for Foundation APIs
    let nsError=NSError(
      domain: "com.umbra.security",
      code: 1001,
      userInfo: [NSLocalizedDescriptionKey: "Failed to generate key"]
    )
    print("Converted to NSError: \(nsError)")
  }

  // Example 2: Using security configuration
  static func securityConfigExample() {
    print("\n=== Security Configuration Example ===")

    // Create a security configuration with parameters
    let parameters=[
      "iv_size": "12",
      "auth_tag_length": "16"
    ]
    print("Security config parameters: \(parameters)")
  }

  // Helper function to create random secure bytes for examples
  static func createRandomSecureBytes(count: Int) -> SecureBytes {
    var bytes=[UInt8](repeating: 0, count: count)
    for i in 0..<count {
      bytes[i]=UInt8.random(in: 0...255)
    }
    return SecureBytes(bytes: bytes)
  }

  // Run the examples
  static func runSecurityExamples() {
    errorHandlingExample()
    securityConfigExample()
  }

  // This is a main entry point function that runs the examples
  public static func main() {
    runSecurityExamples()
  }
}
