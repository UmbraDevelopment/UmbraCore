import CoreSecurityTypes
import Foundation
import UnifiedCryptoTypes

/**
 Options for decryption operations in the crypto services.

 These options control the algorithm, mode, and additional parameters used for decryption.
 
 NOTE: This implementation is being deprecated in favour of using UnifiedCryptoTypes.EncryptionOptions,
 which can be used for both encryption and decryption operations.
 */
@available(*, deprecated, message: "Use UnifiedCryptoTypes.EncryptionOptions instead")
public typealias DecryptionOptions = UnifiedCryptoTypes.EncryptionOptions

// Implementation note: We're now using the canonical type from UnifiedCryptoTypes rather than
// defining another duplicate struct with the same name, which was causing compile errors.
