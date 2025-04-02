import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/// Data transfer object for security configuration.
/// This is a simplified implementation for the Alpha Dot Five architecture refactoring.
public struct SecurityConfigurationDTO: Sendable, Equatable {
  /// The security level to use
  public let securityLevel: CoreSecurityTypes.SecurityLevelDTO

  /// The logging level for security operations
  public let loggingLevel: CoreSecurityTypes.SecurityLogLevelDTO

  /// Options for secure random number generation
  public let randomizationOptions: CoreSecurityTypes.RandomizationOptionsDTO

  /// Creates a new security configuration
  /// - Parameters:
  ///   - securityLevel: The security level to use
  ///   - loggingLevel: The logging level for security operations
  ///   - randomizationOptions: Options for secure random number generation
  public init(
    securityLevel: CoreSecurityTypes.SecurityLevelDTO = .standard,
    loggingLevel: CoreSecurityTypes.SecurityLogLevelDTO = .warning,
    randomizationOptions: CoreSecurityTypes.RandomizationOptionsDTO = .default
  ) {
    self.securityLevel=securityLevel
    self.loggingLevel=loggingLevel
    self.randomizationOptions=randomizationOptions
  }

  /// Default configuration
  public static let `default`=SecurityConfigurationDTO()

  /// High security configuration
  public static let highSecurity=SecurityConfigurationDTO(
    securityLevel: .high,
    loggingLevel: .debug,
    randomizationOptions: .highEntropy
  )

  /// Performance optimized configuration
  public static let performance=SecurityConfigurationDTO(
    securityLevel: .basic,
    loggingLevel: .error,
    randomizationOptions: .fast
  )
}

/// The type of security event
public enum SecurityEventTypeDTO: String, Sendable, Equatable, CaseIterable {
  /// Initialisation event
  case initialisation

  /// Configuration event
  case configuration

  /// Operation event
  case operation

  /// Error event
  case error

  /// Warning event
  case warning
}

/// The severity level of a security event
public enum SecurityEventSeverityDTO: String, Sendable, Equatable, CaseIterable, Comparable {
  /// Debug level event
  case debug

  /// Informational level event
  case informational

  /// Warning level event
  case warning

  /// Error level event
  case error

  /// Critical level event
  case critical

  public static func < (lhs: SecurityEventSeverityDTO, rhs: SecurityEventSeverityDTO) -> Bool {
    let order: [SecurityEventSeverityDTO]=[.debug, .informational, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/// Security event data transfer object
public struct SecurityEventDTO: Sendable, Equatable {
  /// The unique identifier for this event
  public let eventIdentifier: String

  /// The type of security event
  public let eventType: SecurityEventTypeDTO

  /// The timestamp of the event in ISO8601 format
  public let timestampISO8601: String

  /// The severity level of the event
  public let severityLevel: SecurityEventSeverityDTO

  /// The event message
  public let eventMessage: String

  /// Additional contextual information about the event
  public let contextInformation: [String: String]

  /// Whether the event contains sensitive information
  public let containsSensitiveInformation: Bool

  /// The source component that generated the event
  public let sourceComponent: String

  /// Creates a new security event
  /// - Parameters:
  ///   - eventIdentifier: The unique identifier for this event
  ///   - eventType: The type of security event
  ///   - timestampISO8601: The timestamp of the event in ISO8601 format
  ///   - severityLevel: The severity level of the event
  ///   - eventMessage: The event message
  ///   - contextInformation: Additional contextual information about the event
  ///   - containsSensitiveInformation: Whether the event contains sensitive information
  ///   - sourceComponent: The source component that generated the event
  public init(
    eventIdentifier: String,
    eventType: SecurityEventTypeDTO,
    timestampISO8601: String,
    severityLevel: SecurityEventSeverityDTO,
    eventMessage: String,
    contextInformation: [String: String],
    containsSensitiveInformation: Bool,
    sourceComponent: String
  ) {
    self.eventIdentifier=eventIdentifier
    self.eventType=eventType
    self.timestampISO8601=timestampISO8601
    self.severityLevel=severityLevel
    self.eventMessage=eventMessage
    self.contextInformation=contextInformation
    self.containsSensitiveInformation=containsSensitiveInformation
    self.sourceComponent=sourceComponent
  }
}

/// Security context data transfer object
public struct SecurityContextDTO: Sendable, Equatable {
  /// The operation type
  public let operationType: SecurityOperationTypeDTO

  /// The security level
  public let securityLevel: CoreSecurityTypes.SecurityLevelDTO

  /// The key identifier
  public let keyIdentifier: String

  /// The crypto options
  public let cryptoOptions: [String: String]

  /// Additional metadata
  public let metadata: [String: String]

  /// Creates a new security context
  /// - Parameters:
  ///   - operationType: The operation type
  ///   - securityLevel: The security level
  ///   - keyIdentifier: The key identifier
  ///   - cryptoOptions: The crypto options
  ///   - metadata: Additional metadata
  public init(
    operationType: SecurityOperationTypeDTO,
    securityLevel: CoreSecurityTypes.SecurityLevelDTO = .standard,
    keyIdentifier: String,
    cryptoOptions: [String: String]=[:],
    metadata: [String: String]=[:]
  ) {
    self.operationType=operationType
    self.securityLevel=securityLevel
    self.keyIdentifier=keyIdentifier
    self.cryptoOptions=cryptoOptions
    self.metadata=metadata
  }
}

/// The type of security operation
public enum SecurityOperationTypeDTO: String, Sendable, Equatable, CaseIterable {
  /// Encryption operation
  case encryption

  /// Decryption operation
  case decryption

  /// Hashing operation
  case hashing

  /// Signature operation
  case signature

  /// Verification operation
  case verification

  /// Key generation operation
  case keyGeneration

  /// Key retrieval operation
  case keyRetrieval
}

/// Event subscription filter data transfer object
public struct SecurityEventFilterDTO: Sendable, Equatable {
  /// The minimum severity level to include
  public let minimumSeverityLevel: SecurityEventSeverityDTO?

  /// Whether to include sensitive information
  public let includeSensitiveInformation: Bool

  /// Creates a new security event filter
  /// - Parameters:
  ///   - minimumSeverityLevel: The minimum severity level to include
  ///   - includeSensitiveInformation: Whether to include sensitive information
  public init(
    minimumSeverityLevel: SecurityEventSeverityDTO?=nil,
    includeSensitiveInformation: Bool=false
  ) {
    self.minimumSeverityLevel=minimumSeverityLevel
    self.includeSensitiveInformation=includeSensitiveInformation
  }
}

/// Security version data transfer object
public struct SecurityVersionDTO: Sendable, Equatable {
  /// The version string
  public let version: String

  /// The build number
  public let buildNumber: String

  /// The build date in ISO8601 format
  public let buildDate: String

  /// The architecture
  public let architecture: String

  /// The capabilities
  public let capabilities: [String]

  /// Creates a new security version
  /// - Parameters:
  ///   - version: The version string
  ///   - buildNumber: The build number
  ///   - buildDate: The build date in ISO8601 format
  ///   - architecture: The architecture
  ///   - capabilities: The capabilities
  public init(
    version: String,
    buildNumber: String,
    buildDate: String,
    architecture: String,
    capabilities: [String]
  ) {
    self.version=version
    self.buildNumber=buildNumber
    self.buildDate=buildDate
    self.architecture=architecture
    self.capabilities=capabilities
  }
}
