import Foundation

// Import CoreErrors for migration
import CoreErrors

/// Errors that can occur during cryptographic operations
///
/// @deprecated This will be replaced by CoreErrors.CryptoError in a future version.
/// New code should use CoreErrors.CryptoError directly.
@available(
  *,
  deprecated,
  message: "This will be replaced by CoreErrors.CryptoError in a future version. Use CoreErrors.CryptoError directly."
)
public typealias CryptoError = CoreErrors.CryptoError
