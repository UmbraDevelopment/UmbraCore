import Foundation
import KeychainInterfaces

/**
 # KeychainAccessOptionsAdapter

 Extension to provide conversion methods for KeychainInterfaces.KeychainAccessOptions
 This adapter ensures backward compatibility with existing code while using
 the canonical KeychainAccessOptions from KeychainInterfaces.
 */

// Extension to provide additional utility methods for KeychainAccessOptions
extension KeychainInterfaces.KeychainAccessOptions {
  /**
   Helper method to convert KeychainAccessOptions to Security framework constants.
   This provides backward compatibility with any implementation-specific code.

   - Returns: The corresponding Security framework constant
   */
  func toSecurityConstants() -> CFString {
    toSecurityAccessibility()
  }
}

// We removed the typealias as per requirements to reference resources directly
// All code should directly reference KeychainInterfaces.KeychainAccessOptions
