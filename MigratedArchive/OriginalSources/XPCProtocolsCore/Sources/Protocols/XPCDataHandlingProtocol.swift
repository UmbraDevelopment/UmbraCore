/**
 # XPC Data Handling Protocol

 This file defines a standardised approach to data handling and conversion
 across XPC services. It provides methods for converting between different
 data types like [UInt8], Data, and SecureBytes.

 ## Features

 * Conversion between [UInt8] arrays and Data
 * Conversion between various data types and SecureBytes
 * Default implementations for common data handling patterns

 ## Protocol Usage

 This protocol can be adopted by any XPC service to ensure consistent data
 handling patterns across the codebase.
 */

import Foundation
import UmbraCoreTypes

/// Protocol for handling data conversion between different types
/// This protocol defines methods for converting between different data formats
/// used in XPC communication, including `Data` and `SecureBytes`.
public protocol XPCDataHandlingProtocol {
  /// Convert a byte array to Data
  /// - Parameter bytes: Byte array to convert
  /// - Returns: A Data object containing the bytes
  func convertBytesToData(_ bytes: [UInt8]) -> Data

  /// Convert Data to a byte array
  /// - Parameter data: Data to convert
  /// - Returns: A byte array containing the bytes from the Data object
  func convertDataToBytes(_ data: Data) -> [UInt8]

  /// Convert a byte array to SecureBytes
  /// - Parameter bytes: Byte array to convert
  /// - Returns: A SecureBytes object containing the bytes
  func convertBytesToSecureBytes(_ bytes: [UInt8]) -> SecureBytes

  /// Convert Data to SecureBytes
  /// - Parameter data: Data to convert
  /// - Returns: A SecureBytes object containing the bytes from the Data object
  func convertDataToSecureBytes(_ data: Data) -> SecureBytes

  /// Convert SecureBytes to Data
  /// - Parameter secureBytes: SecureBytes to convert
  /// - Returns: A Data object containing the bytes
  func convertSecureBytesToData(_ secureBytes: SecureBytes) -> Data

  /// Convert SecureBytes to bytes
  /// - Parameter secureBytes: SecureBytes to convert
  /// - Returns: A byte array containing the bytes
  func convertSecureBytesToBytes(_ secureBytes: SecureBytes) -> [UInt8]
}
