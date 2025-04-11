import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/**
 Extracts and validates data from security configuration metadata.

 This utility class provides methods to safely extract and validate
 data from the metadata dictionary in SecurityConfigDTO objects,
 ensuring type safety and proper error handling.
 */
public struct SecurityMetadataExtractor {

  /// Configuration containing the metadata
  private let config: SecurityConfigDTO

  /**
   Initialises a new metadata extractor.

   - Parameter config: The security configuration containing metadata
   */
  public init(config: SecurityConfigDTO) {
    self.config=config
  }

  /**
   Extracts a required string value from metadata.

   - Parameters:
      - key: The metadata key to extract
      - errorMessage: Custom error message if the key is missing
   - Returns: The extracted string value
   - Throws: SecurityError.invalidInput if the key is missing
   */
  public func requiredString(
    forKey key: String,
    errorMessage: String?=nil
  ) throws -> String {
    guard let value=config.options?.metadata?[key] else {
      throw CoreSecurityTypes.SecurityError.invalidInput(
        reason: errorMessage ?? "Required metadata key '\(key)' is missing"
      )
    }
    return value
  }

  /**
   Extracts an optional string value from metadata.

   - Parameter key: The metadata key to extract
   - Returns: The extracted string value or nil if not present
   */
  public func optionalString(forKey key: String) -> String? {
    config.options?.metadata?[key]
  }

  /**
   Extracts a required Data object from base64-encoded metadata.

   - Parameters:
      - key: The metadata key to extract
      - errorMessage: Custom error message if the key is missing or invalid
   - Returns: The decoded Data object
   - Throws: SecurityError if the key is missing or the data is invalid
   */
  public func requiredData(
    forKey key: String,
    errorMessage: String?=nil
  ) throws -> Data {
    let base64String=try requiredString(
      forKey: key,
      errorMessage: errorMessage ?? "Required data for '\(key)' is missing"
    )

    guard let data=Data(base64Encoded: base64String) else {
      throw CoreSecurityTypes.SecurityError.invalidInput(
        reason: "Invalid base64 encoding for '\(key)'"
      )
    }

    return data
  }

  /**
   Extracts an optional Data object from base64-encoded metadata.

   - Parameter key: The metadata key to extract
   - Returns: The decoded Data object or nil if not present or invalid
   */
  public func optionalData(forKey key: String) -> Data? {
    guard let base64String=optionalString(forKey: key) else {
      return nil
    }

    return Data(base64Encoded: base64String)
  }

  /**
   Extracts a required integer value from metadata.

   - Parameters:
      - key: The metadata key to extract
      - errorMessage: Custom error message if the key is missing or invalid
   - Returns: The extracted integer value
   - Throws: SecurityError if the key is missing or the value is invalid
   */
  public func requiredInt(
    forKey key: String,
    errorMessage: String?=nil
  ) throws -> Int {
    let stringValue=try requiredString(
      forKey: key,
      errorMessage: errorMessage ?? "Required integer for '\(key)' is missing"
    )

    guard let intValue=Int(stringValue) else {
      throw CoreSecurityTypes.SecurityError.invalidInput(
        reason: "Invalid integer format for '\(key)': \(stringValue)"
      )
    }

    return intValue
  }

  /**
   Extracts an optional integer value from metadata.

   - Parameter key: The metadata key to extract
   - Returns: The extracted integer value or nil if not present or invalid
   */
  public func optionalInt(forKey key: String) -> Int? {
    guard let stringValue=optionalString(forKey: key) else {
      return nil
    }

    return Int(stringValue)
  }

  /**
   Extracts a required identifier from metadata.

   - Parameters:
      - key: The metadata key to extract
      - errorMessage: Custom error message if the key is missing or invalid
   - Returns: The extracted identifier string
   - Throws: SecurityError if the key is missing or the identifier is invalid
   */
  public func requiredIdentifier(
    forKey key: String,
    errorMessage: String?=nil
  ) throws -> String {
    let identifier=try requiredString(
      forKey: key,
      errorMessage: errorMessage ?? "Required identifier '\(key)' is missing"
    )

    guard !identifier.isEmpty else {
      throw CoreSecurityTypes.SecurityError.invalidInput(
        reason: "Identifier '\(key)' cannot be empty"
      )
    }

    return identifier
  }
}
