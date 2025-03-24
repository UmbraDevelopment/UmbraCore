import ErrorHandlingDomains
import Foundation

/// Provides isolated error mapping functionality for test code
/// Prevents direct imports of multiple conflicting modules in test files
public enum TestErrorMapper {
  /// Maps an error from ErrorHandlingDomains to a test-suitable NSError
  /// - Parameter error: The source error
  /// - Returns: A mapped NSError with appropriate domain and message
  public static func mapToNSError(_ error: Error) -> NSError {
    let errorDomain="com.umbracore.security.test"

    // Extract description from the original error
    var description="\(error)"
    var code=1001

    // Handle specific error types from ErrorHandlingDomains
    if let securityError=error as? UmbraErrors.Security.Protocols {
      switch securityError {
        case let .invalidFormat(reason):
          description="Invalid format: \(reason)"
          code=4001
        case let .missingProtocolImplementation(protocolName):
          description="Missing protocol implementation: \(protocolName)"
          code=4002
        case let .unsupportedOperation(name):
          description="Unsupported operation: \(name)"
          code=4003
        case let .incompatibleVersion(version):
          description="Incompatible version: \(version)"
          code=4004
        case let .invalidState(state, expectedState):
          description="Invalid state: \(state), expected: \(expectedState)"
          code=4005
        case let .internalError(message):
          description="Internal error: \(message)"
          code=4999
        case let .invalidInput(details):
          description="Invalid input: \(details)"
          code=4006
        case let .encryptionFailed(reason):
          description="Encryption failed: \(reason)"
          code=5000
        case let .decryptionFailed(reason):
          description="Decryption failed: \(reason)"
          code=5001
        case let .randomGenerationFailed(reason):
          description="Random generation failed: \(reason)"
          code=5002
        case let .storageOperationFailed(reason):
          description="Storage operation failed: \(reason)"
          code=5003
        case let .serviceError(details):
          description="Service error: \(details)"
          code=5004
        case let .notImplemented(feature):
          description="Not implemented: \(feature)"
          code=5005
        @unknown default:
          description="Unknown security protocol error: \(securityError)"
      }
    }

    // Create the NSError with localised description
    let userInfo: [String: Any]=[
      NSLocalizedDescriptionKey: description
    ]

    return NSError(domain: errorDomain, code: code, userInfo: userInfo)
  }

  /// Tests if an error contains a specific substring in its description
  /// - Parameters:
  ///   - error: The error to check
  ///   - substring: The substring to look for
  /// - Returns: True if the error description contains the substring
  public static func errorContains(_ error: Error, substring: String) -> Bool {
    "\(error)".contains(substring)
  }
}
