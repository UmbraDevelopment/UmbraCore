import Foundation

/**
 # SecurityConfigOptions

 A Sendable-compliant structure for configuring security operations with type-safe options.

 This structure replaces the use of non-Sendable dictionaries for passing configuration options
 across actor boundaries, providing compile-time type safety and actor isolation compliance.
 */
public struct SecurityConfigOptions: Sendable, Equatable {
  /// Algorithm to use for cryptographic operations (e.g., "AES", "RSA", "ChaCha20")
  public var algorithm: String?

  /// Key size in bits (e.g., 128, 256, 2048)
  public var keySize: Int?

  /// Mode of operation for block ciphers (e.g., "GCM", "CBC")
  public var mode: String?

  /// Hash algorithm for hashing operations (e.g., "SHA256", "SHA512")
  public var hashAlgorithm: String?

  /// Identifier for keys, data, or operations
  public var identifier: String?

  /// Base64-encoded data for operations
  public var dataBase64: String?

  /// Hexadecimal-encoded data for operations
  public var dataHex: String?

  /// Base64-encoded key data
  public var keyBase64: String?

  /// Identifier for key retrieval
  public var keyIdentifier: String?

  /// Base64-encoded signature data
  public var signatureBase64: String?

  /// Additional string-based options
  public var additionalOptions: [String: String]

  /**
   Initialises a new SecurityConfigOptions with default values.

   All fields are optional and can be set after initialisation.
   */
  public init(
    algorithm: String?=nil,
    keySize: Int?=nil,
    mode: String?=nil,
    hashAlgorithm: String?=nil,
    identifier: String?=nil,
    dataBase64: String?=nil,
    dataHex: String?=nil,
    keyBase64: String?=nil,
    keyIdentifier: String?=nil,
    signatureBase64: String?=nil,
    additionalOptions: [String: String]=[:]
  ) {
    self.algorithm=algorithm
    self.keySize=keySize
    self.mode=mode
    self.hashAlgorithm=hashAlgorithm
    self.identifier=identifier
    self.dataBase64=dataBase64
    self.dataHex=dataHex
    self.keyBase64=keyBase64
    self.keyIdentifier=keyIdentifier
    self.signatureBase64=signatureBase64
    self.additionalOptions=additionalOptions
  }

  /**
   Converts legacy dictionary options to this structured format.

   - Parameter dictionary: The legacy [String: Any] options dictionary
   - Returns: A new SecurityConfigOptions instance
   */
  public static func from(dictionary options: [String: Any]?) -> SecurityConfigOptions {
    guard let options else {
      return SecurityConfigOptions()
    }

    var result=SecurityConfigOptions()

    // Extract type-specific values
    result.algorithm=options["algorithm"] as? String
    result.keySize=options["keySize"] as? Int
    result.mode=options["mode"] as? String
    result.hashAlgorithm=options["hashAlgorithm"] as? String
    result.identifier=options["identifier"] as? String
    result.dataBase64=options["dataBase64"] as? String
    result.dataHex=options["dataHex"] as? String
    result.keyBase64=options["keyBase64"] as? String
    result.keyIdentifier=options["keyIdentifier"] as? String
    result.signatureBase64=options["signatureBase64"] as? String

    // Convert other string values to additionalOptions
    for (key, value) in options {
      // Skip already processed keys
      if
        [
          "algorithm",
          "keySize",
          "mode",
          "hashAlgorithm",
          "identifier",
          "dataBase64",
          "dataHex",
          "keyBase64",
          "keyIdentifier",
          "signatureBase64"
        ].contains(key)
      {
        continue
      }

      // Only add string values to additionalOptions
      if let stringValue=value as? String {
        result.additionalOptions[key]=stringValue
      } else {
        // Convert non-string values to string representation
        result.additionalOptions[key]=String(describing: value)
      }
    }

    return result
  }

  /**
   Converts to a legacy dictionary format for backward compatibility.

   - Returns: A dictionary containing all the options
   */
  public func toDictionary() -> [String: Any] {
    var result: [String: Any]=[:]

    // Add primary fields if they have values
    if let algorithm { result["algorithm"]=algorithm }
    if let keySize { result["keySize"]=keySize }
    if let mode { result["mode"]=mode }
    if let hashAlgorithm { result["hashAlgorithm"]=hashAlgorithm }
    if let identifier { result["identifier"]=identifier }
    if let dataBase64 { result["dataBase64"]=dataBase64 }
    if let dataHex { result["dataHex"]=dataHex }
    if let keyBase64 { result["keyBase64"]=keyBase64 }
    if let keyIdentifier { result["keyIdentifier"]=keyIdentifier }
    if let signatureBase64 { result["signatureBase64"]=signatureBase64 }

    // Add additional options
    for (key, value) in additionalOptions {
      result[key]=value
    }

    return result
  }

  /**
   Gets a value from options by key, with type conversion.

   - Parameters:
     - key: The key to look up
     - defaultValue: Optional default value if key is not found
   - Returns: The value if found and convertible to T, otherwise defaultValue
   */
  public func get<T>(_ key: String, defaultValue: T?=nil) -> T? {
    // Check primary fields first
    switch key {
      case "algorithm":
        return algorithm as? T ?? defaultValue
      case "keySize":
        return keySize as? T ?? defaultValue
      case "mode":
        return mode as? T ?? defaultValue
      case "hashAlgorithm":
        return hashAlgorithm as? T ?? defaultValue
      case "identifier":
        return identifier as? T ?? defaultValue
      case "dataBase64":
        return dataBase64 as? T ?? defaultValue
      case "dataHex":
        return dataHex as? T ?? defaultValue
      case "keyBase64":
        return keyBase64 as? T ?? defaultValue
      case "keyIdentifier":
        return keyIdentifier as? T ?? defaultValue
      case "signatureBase64":
        return signatureBase64 as? T ?? defaultValue
      default:
        // Check additional options
        if let value=additionalOptions[key] {
          // Try to convert string to requested type
          if T.self == String.self {
            return value as? T
          } else if T.self == Int.self, let intValue=Int(value) {
            return intValue as? T
          } else if T.self == Double.self, let doubleValue=Double(value) {
            return doubleValue as? T
          } else if T.self == Bool.self, let boolValue=Bool(value) {
            return boolValue as? T
          }
        }
        return defaultValue
    }
  }
}
