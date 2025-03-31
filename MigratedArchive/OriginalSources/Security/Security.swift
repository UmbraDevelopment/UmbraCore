import Foundation
import SecurityInterfaces
import UmbraLogging

/// Security is the main entry point for the consolidated security framework.
/// It provides access to all security-related functionality including:
/// - Cryptographic operations (encryption, decryption, signing, etc.)
/// - Key management
/// - Security protocols
/// - Bridge adapters for platform-specific implementations
public enum Security {
  /// Logger for Security module operations
  private static let logger=Logger(category: "Security")

  /// Initialises the Security module
  /// This method should be called early in the application lifecycle
  public static func initialise() {
    logger.info("Security module initialised")
  }

  /// Version information for the Security module
  public static let version="1.0.0"
}

/// Export all submodules to make them accessible through the main Security module
@_exported import struct SecurityProtocolsCore.SecureData
