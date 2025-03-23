/// SecurityProtocolsCore
///
/// Provides core protocols and types for security-related operations in UmbraCore.
/// This module defines service boundaries, data transfer objects, and error types
/// for cryptographic operations, key management, and secure data handling.
///
/// This module is designed to be fully FoundationIndependent.
/// It serves as a foundation for concrete implementations that can be either
/// Foundation-dependent or FoundationIndependent as required.

import UmbraCoreTypes

/// Module information and version details
public enum ModuleInfo {
  /// Current module version
  public static let version="1.0.0"
}

// Export key types and protocols
public typealias SecurityResult=SecurityResultDTO
public typealias SecurityConfig=SecurityConfigDTO
