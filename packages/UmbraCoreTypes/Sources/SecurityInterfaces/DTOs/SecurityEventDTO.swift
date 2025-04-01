import Foundation

/// Data transfer object representing a security-related event.
///
/// This type captures details about security events occurring within the security service,
/// providing a structured way to communicate these events to subscribers.
public struct SecurityEventDTO: Sendable, Equatable {
  /// Unique identifier for the event
  public let eventIdentifier: String

  /// The type of security event
  public let eventType: SecurityEventTypeDTO

  /// The timestamp when the event occurred
  public let timestampISO8601: String

  /// The severity level of the event
  public let severityLevel: SecurityEventSeverityDTO

  /// A human-readable message describing the event
  public let eventMessage: String

  /// Additional context information about the event
  public let contextInformation: [String: String]

  /// Flag indicating whether the event contains sensitive information
  public let containsSensitiveInformation: Bool

  /// The source component that generated the event
  public let sourceComponent: String

  /// Creates a new security event
  /// - Parameters:
  ///   - eventIdentifier: Unique identifier for the event
  ///   - eventType: The type of security event
  ///   - timestampISO8601: The timestamp when the event occurred
  ///   - severityLevel: The severity level of the event
  ///   - eventMessage: A human-readable message describing the event
  ///   - contextInformation: Additional context information about the event
  ///   - containsSensitiveInformation: Flag indicating whether the event contains sensitive
  /// information
  ///   - sourceComponent: The source component that generated the event
  public init(
    eventIdentifier: String,
    eventType: SecurityEventTypeDTO,
    timestampISO8601: String,
    severityLevel: SecurityEventSeverityDTO,
    eventMessage: String,
    contextInformation: [String: String]=[:],
    containsSensitiveInformation: Bool=false,
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

/// The type of security event
public enum SecurityEventTypeDTO: String, Sendable, Equatable, CaseIterable {
  /// Initialisation of a security component
  case initialisation="Initialisation"

  /// Shutdown of a security component
  case shutdown="Shutdown"

  /// Configuration change
  case configurationChange="ConfigurationChange"

  /// Encryption operation
  case encryption="Encryption"

  /// Decryption operation
  case decryption="Decryption"

  /// Key generation
  case keyGeneration="KeyGeneration"

  /// Hash computation
  case hashComputation="HashComputation"

  /// Random number generation
  case randomGeneration="RandomGeneration"

  /// Security verification
  case verification="Verification"

  /// Security policy enforcement
  case policyEnforcement="PolicyEnforcement"

  /// Authentication event
  case authentication="Authentication"

  /// Authorisation event
  case authorisation="Authorisation"

  /// Security error
  case error="Error"

  /// Security warning
  case warning="Warning"

  /// Security information
  case information="Information"

  /// Audit event
  case audit="Audit"

  /// Security intrusion attempt
  case intrusionAttempt="IntrusionAttempt"
}

/// The severity level of a security event
public enum SecurityEventSeverityDTO: String, Sendable, Equatable, CaseIterable, Comparable {
  /// Critical severity - immediate attention required
  case critical="Critical"

  /// High severity - urgent attention required
  case high="High"

  /// Medium severity - attention required
  case medium="Medium"

  /// Low severity - routine attention
  case low="Low"

  /// Informational severity - no action required
  case informational="Informational"

  /// Implementation of Comparable
  public static func < (lhs: SecurityEventSeverityDTO, rhs: SecurityEventSeverityDTO) -> Bool {
    let order: [SecurityEventSeverityDTO]=[.informational, .low, .medium, .high, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/// Data transfer object representing criteria for filtering security events.
///
/// This type allows subscribers to specify which security events they are
/// interested in receiving, based on various filtering criteria.
public struct SecurityEventFilterDTO: Sendable, Equatable {
  /// The types of events to include (nil means all types)
  public let includeEventTypes: [SecurityEventTypeDTO]?

  /// The minimum severity level to include
  public let minimumSeverityLevel: SecurityEventSeverityDTO?

  /// The source components to include (nil means all sources)
  public let includeSourceComponents: [String]?

  /// Flag indicating whether to include events with sensitive information
  public let includeSensitiveInformation: Bool

  /// Start time for events to include (ISO8601 format)
  public let startTimeISO8601: String?

  /// End time for events to include (ISO8601 format)
  public let endTimeISO8601: String?

  /// Creates a new security event filter
  /// - Parameters:
  ///   - includeEventTypes: The types of events to include (nil means all types)
  ///   - minimumSeverityLevel: The minimum severity level to include
  ///   - includeSourceComponents: The source components to include (nil means all sources)
  ///   - includeSensitiveInformation: Flag indicating whether to include events with sensitive
  /// information
  ///   - startTimeISO8601: Start time for events to include (ISO8601 format)
  ///   - endTimeISO8601: End time for events to include (ISO8601 format)
  public init(
    includeEventTypes: [SecurityEventTypeDTO]?=nil,
    minimumSeverityLevel: SecurityEventSeverityDTO?=nil,
    includeSourceComponents: [String]?=nil,
    includeSensitiveInformation: Bool=false,
    startTimeISO8601: String?=nil,
    endTimeISO8601: String?=nil
  ) {
    self.includeEventTypes=includeEventTypes
    self.minimumSeverityLevel=minimumSeverityLevel
    self.includeSourceComponents=includeSourceComponents
    self.includeSensitiveInformation=includeSensitiveInformation
    self.startTimeISO8601=startTimeISO8601
    self.endTimeISO8601=endTimeISO8601
  }

  /// Filter that includes all events (no filtering)
  public static let allEvents=SecurityEventFilterDTO(
    includeEventTypes: nil,
    minimumSeverityLevel: nil,
    includeSourceComponents: nil,
    includeSensitiveInformation: true,
    startTimeISO8601: nil,
    endTimeISO8601: nil
  )

  /// Filter that includes only critical events
  public static let criticalEventsOnly=SecurityEventFilterDTO(
    includeEventTypes: nil,
    minimumSeverityLevel: .critical,
    includeSourceComponents: nil,
    includeSensitiveInformation: true,
    startTimeISO8601: nil,
    endTimeISO8601: nil
  )

  /// Filter that includes high and critical events
  public static let highPriorityEvents=SecurityEventFilterDTO(
    includeEventTypes: nil,
    minimumSeverityLevel: .high,
    includeSourceComponents: nil,
    includeSensitiveInformation: true,
    startTimeISO8601: nil,
    endTimeISO8601: nil
  )

  /// Filter that excludes informational events
  public static let excludeInformational=SecurityEventFilterDTO(
    includeEventTypes: nil,
    minimumSeverityLevel: .low,
    includeSourceComponents: nil,
    includeSensitiveInformation: false,
    startTimeISO8601: nil,
    endTimeISO8601: nil
  )
}
