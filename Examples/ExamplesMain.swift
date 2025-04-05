import Foundation
import UmbraErrors
import UmbraErrorsCore

// This is the main entry point for the Examples executable
@main
struct ExamplesRunner {
  // The main function that runs all examples
  static func main() {
    print("Running UmbraCore Examples")
    print("==========================")

    // Call individual example runners
    // Add more example runners here as they are developed

    // Security bridge examples
    print("\nRunning Security Bridge Examples:")
    // Call each individual function instead of using the namespace
    runSecurityExamples()

    print("\nAll examples completed successfully.")
  }

  // Example implementation that calls security examples directly
  static func runSecurityExamples() {
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

    print("\n=== Security Configuration Example ===")

    // Create a security configuration with parameters
    let parameters=[
      "iv_size": "12",
      "auth_tag_length": "16"
    ]
    print("Security config parameters: \(parameters)")
  }
}
