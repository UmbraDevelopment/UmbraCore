import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
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
    self.domain = domain
    self.code = code
    self.description = description
  }
}

// DTOs for XPC protocol communications
public enum XPCProtocolDTOs {
  /// DTO representing security error information
  public struct SecurityErrorDTO: Codable, Sendable {
    /// Error code
    public let code: Int

    /// Error message
    public let message: String

    /// Additional details
    public let details: [String: String]

    /// Create a new security error DTO
    /// - Parameters:
    ///   - code: Error code
    ///   - message: Error message
    ///   - details: Additional details
    public init(code: Int, message: String, details: [String: String] = [:]) {
      self.code = code
      self.message = message
      self.details = details
    }
  }

  /// DTO representing status information
  public struct StatusDTO: Codable, Sendable {
    /// Status code
    public let code: Int

    /// Status message
    public let message: String

    /// Additional details
    public let details: [String: String]

    /// Create a new status DTO
    /// - Parameters:
    ///   - code: Status code
    ///   - message: Status message
    ///   - details: Additional details
    public init(code: Int, message: String, details: [String: String] = [:]) {
      self.code = code
      self.message = message
      self.details = details
    }
  }

  /// Conversion utilities for security errors
  public enum SecurityErrorConverter {
    /// Convert a security error to DTO
    /// - Parameter error: The XPC security error to convert
    /// - Returns: A foundation-independent SecurityErrorDTO
    public static func toDTO(
      _ error: ErrorHandlingDomains.UmbraErrors.Security
        .Protocols
    ) -> SecurityErrorDTO {
      switch error {
        case let .internalError(message):
          SecurityErrorDTO(
            code: 10_000,
            message: message
          )
        case let .invalidInput(message):
          SecurityErrorDTO(
            code: 1_001,
            message: message
          )
        case let .encryptionFailed(message):
          SecurityErrorDTO(
            code: 1_003,
            message: message,
            details: ["operation": "encryption"]
          )
        case let .decryptionFailed(message):
          SecurityErrorDTO(
            code: 1_003,
            message: message,
            details: ["operation": "decryption"]
          )
        case let .storageOperationFailed(message):
          SecurityErrorDTO(
            code: 1_003,
            message: message,
            details: ["operation": "storage"]
          )
        case let .invalidFormat(reason):
          SecurityErrorDTO(
            code: 1_001,
            message: reason
          )
        case let .unsupportedOperation(name):
          SecurityErrorDTO(
            code: 1_006,
            message: "Operation not supported: \(name)"
          )
        case let .notImplemented(message):
          SecurityErrorDTO(
            code: 1_006,
            message: "Not implemented: \(message)"
          )
        default:
          SecurityErrorDTO(
            code: 10_000,
            message: "Unknown error"
          )
      }
    }

    /// Convert a security error DTO to security error
    /// - Parameter dto: The security error DTO to convert
    /// - Returns: An ErrorHandlingDomains.UmbraErrors.Security.Protocols
    public static func fromDTO(_ dto: SecurityErrorDTO) -> ErrorHandlingDomains.UmbraErrors.Security
    .Protocols {
      // Match error code to a specific error type
      if dto.code == 1_001 {
        return .invalidInput(dto.message)
      } else if dto.code == 1_002 {
        return .invalidState(state: "unknown", expectedState: dto.message)
      } else if dto.code == 1_003 {
        let operation = dto.details["operation"] ?? "unknown"
        if operation == "encryption" {
          return .encryptionFailed(dto.message)
        } else if operation == "decryption" {
          return .decryptionFailed(dto.message)
        } else {
          return .storageOperationFailed(dto.message)
        }
      } else if dto.code == 1_004 {
        return .notImplemented(dto.message)
      } else if dto.code == 1_005 {
        return .invalidFormat(reason: dto.message)
      }

      // Default fallback if we couldn't determine a specific error
      return .internalError(dto.message)
    }
  }

  /// DTO representing service status information
  public struct ServiceStatusDTO: Codable, Sendable, Equatable {
    /// Status code
    public let code: Int

    /// Status message
    public let message: String

    /// Timestamp
    public let timestamp: Date

    /// Protocol version
    public let protocolVersion: String

    /// Service version
    public let serviceVersion: String

    /// Additional details
    public let details: [String: String]

    /// Create a new status DTO
    /// - Parameters:
    ///   - code: Status code
    ///   - message: Status message
    ///   - timestamp: Status timestamp
    ///   - protocolVersion: Protocol version
    ///   - serviceVersion: Service version
    ///   - details: Additional details
    public init(
      code: Int,
      message: String,
      timestamp: Date = Date(),
      protocolVersion: String,
      serviceVersion: String,
      details: [String: String] = [:]
    ) {
      self.code = code
      self.message = message
      self.timestamp = timestamp
      self.protocolVersion = protocolVersion
      self.serviceVersion = serviceVersion
      self.details = details
    }

    /// Create a standard "service is running" status
    /// - Parameters:
    ///   - protocolVersion: Protocol version
    ///   - serviceVersion: Service version
    ///   - details: Additional details
    /// - Returns: A standard service running status DTO
    public static func current(
      protocolVersion: String,
      serviceVersion: String,
      details: [String: String] = [:]
    ) -> ServiceStatusDTO {
      ServiceStatusDTO(
        code: 200,
        message: "Service is running",
        timestamp: Date(),
        protocolVersion: protocolVersion,
        serviceVersion: serviceVersion,
        details: details
      )
    }
  }
}
