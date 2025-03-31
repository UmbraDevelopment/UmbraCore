import CoreTypesInterfaces
import FoundationBridgeTypes
import SecurityInterfaces
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore
import XPCProtocolsCore

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

// MARK: - SecurityConfigDTO Extensions

extension SecurityConfigDTO {
  /// Converts to BinaryData format for cross-module transport
  /// - Returns: BinaryData representation of this config
  public func toBinaryData() -> CoreTypesInterfaces.BinaryData {
    // Simply encode the algorithm name as a fallback - actual serialization implementation
    // would need to be added separately based on actual required format
    let algorithmBytes=Array(algorithm.utf8)
    return CoreTypesInterfaces.BinaryData(bytes: algorithmBytes)
  }

  /// Create a copy with modified input data
  /// - Parameter data: BinaryData to use as input
  /// - Returns: New config with updated input data
  public func withBinaryInputData(_ data: CoreTypesInterfaces.BinaryData) -> SecurityConfigDTO {
    let secureBytes=SecureBytes(bytes: data.rawBytes)
    return withInputData(secureBytes)
  }

  /// Create a copy with modified key
  /// - Parameter key: BinaryData key
  /// - Returns: New config with updated key
  public func withBinaryKey(_ key: CoreTypesInterfaces.BinaryData) -> SecurityConfigDTO {
    let secureBytes=SecureBytes(bytes: key.rawBytes)
    return withKey(secureBytes)
  }
}

// MARK: - SecurityResultDTO Extensions

extension SecurityResultDTO {
  /// Convert result data to BinaryData
  /// - Returns: BinaryData representation or nil if no data
  public func resultToBinaryData() -> CoreTypesInterfaces.BinaryData? {
    guard let data else { return nil }

    // Access each byte in the secure bytes and create a new array
    var bytes=[UInt8]()
    for i in 0..<data.count {
      bytes.append(data[i])
    }
    return CoreTypesInterfaces.BinaryData(bytes: bytes)
  }

  /// Create error-mapped CoreResult
  /// - Returns: Result type with error mapping
  public func toCoreResult() -> Result<CoreTypesInterfaces.BinaryData?, UmbraErrors.Security.Core> {
    // Handle error case
    if let error {
      let mappedError=SecurityErrorMapper.toCoreError(error)
      return .failure(mappedError)
    }

    // Handle success with optional data
    return .success(resultToBinaryData())
  }

  /// Create a generic error-mapped Result with value conversion
  /// - Parameter transform: Transformation function for the result value
  /// - Returns: Result with mapped error and transformed value
  public func toCoreResult<T>(_ transform: (SecurityResultDTO) -> T?)
  -> Result<T, UmbraErrors.Security.Core> {
    // Handle error case
    if let error {
      let mappedError=SecurityErrorMapper.toCoreError(error)
      return .failure(mappedError)
    }

    // Transform the result data
    if let transformed=transform(self) {
      return .success(transformed)
    }

    // Default error case if transformation fails
    return .failure(UmbraErrors.Security.Core.internalError(reason: "Invalid data format"))
  }
}
