import Foundation

/**
 * Padding modes for block cipher operations.
 *
 * This enum defines the various padding schemes that can be used
 * with block ciphers when the plaintext length is not a multiple
 * of the block size.
 */
public enum PaddingMode: String, Sendable, Equatable, CaseIterable {
  /// PKCS#7 padding (RFC 5652)
  case pkcs7

  /// Zero padding (fills remaining bytes with zeros)
  case zeroPadding

  /// ANSI X.923 padding (zeros with length in last byte)
  case ansiX923

  /// ISO/IEC 7816-4 padding (0x80 followed by zeros)
  case iso7816

  /// No padding (plaintext must be a multiple of block size)
  case none
}
