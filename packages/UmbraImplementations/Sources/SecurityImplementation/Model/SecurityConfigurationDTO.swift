import Foundation
import LoggingTypes
import SecurityInterfaces

/**
 This file is deprecated.

 Please use SecurityConfigurationDTO from the SecurityInterfaces module.

 This file is kept for temporary backwards compatibility and will be removed
 in a future update.
 */

// Use SecurityConfigurationDTO from SecurityInterfaces instead

/**
 Security level for cryptographic operations.

 - standard: Standard security suitable for most use cases
 - high: Enhanced security with stronger algorithms and more verification
 - maximum: Maximum security with hardware-backed operations where available
 */
public enum SecurityLevelDTO: String, Sendable, Equatable, CaseIterable {
  /// Standard security suitable for most use cases
  case standard

  /// Enhanced security with stronger algorithms and more verification
  case high

  /// Maximum security with hardware-backed operations where available
  case maximum
}

/**
 Logging level for security operations.

 - debug: Detailed information for debugging purposes
 - info: General information about the system's operation
 - warning: Potentially harmful situations that don't affect operation
 - error: Error events that might still allow the system to continue
 - critical: Severe error events that may cause the system to terminate
 */
public enum SecurityLogLevelDTO: String, Sendable, Equatable, CaseIterable {
  /// Detailed information for debugging purposes
  case debug

  /// General information about the system's operation
  case info

  /// Potentially harmful situations that don't affect operation
  case warning

  /// Error events that might still allow the system to continue
  case error

  /// Severe error events that may cause the system to terminate
  case critical
}
