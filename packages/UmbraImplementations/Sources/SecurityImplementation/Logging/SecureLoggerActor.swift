import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces

/**
 Secure logger actor for privacy-aware security operations.

 This actor provides a secure logging interface that ensures sensitive data
 is properly handled with appropriate privacy controls. It implements enhanced
 security event logging for compliance and auditing purposes.

 The SecureLoggerActor wraps a LoggingProtocol and provides additional
 security-focused logging methods.
 */
public actor SecureLoggerActor {
  // MARK: - Properties

  /// The base logger used for all logging operations
  private let baseLogger: LoggingProtocol

  /// Domain name for all log contexts
  private let domainName="Security"

  // MARK: - Initialisation

  /**
   Creates a new secure logger actor.

   - Parameter baseLogger: The logger to use for logging
   */
  public init(baseLogger: LoggingProtocol) {
    self.baseLogger=baseLogger
  }

  // MARK: - Security Logging Methods

  /**
   Logs a security event with detailed context.

   - Parameters:
     - action: The security action being performed
     - status: The status of the security event
     - subject: Optional identity of the subject performing the action
     - resource: Optional identifier of the resource being accessed
     - additionalMetadata: Additional metadata about the event
   */
  public func securityEvent(
    action: String,
    status: SecurityEventStatus,
    subject: String?=nil,
    resource: String?=nil,
    additionalMetadata: [String: PrivacyTaggedValue]=[:]
  ) async {
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "action", value: action)
      .withPublic(key: "status", value: status.rawValue)

    if let subject {
      metadata=metadata.withPrivate(key: "subject", value: subject)
    }

    if let resource {
      metadata=metadata.withSensitive(key: "resource", value: resource)
    }

    // Add all additional metadata with their respective privacy levels
    for (key, taggedValue) in additionalMetadata {
      metadata=metadata.with(
        key: key,
        value: taggedValue.value.stringValue,
        privacyLevel: taggedValue.privacyLevel == .public ? .public :
          (taggedValue.privacyLevel == .private ? .private : .sensitive)
      )
    }

    let context=SecurityLogContext(
      operation: action,
      component: "SecurityService",
      metadata: metadata
    )

    // Log at appropriate level based on status
    switch status {
      case .success:
        await baseLogger.info("Security event: \(action) completed successfully", context: context)
      case .failure:
        await baseLogger.error("Security event: \(action) failed", context: context)
      case .denied:
        await baseLogger.warning("Security event: \(action) was denied", context: context)
      case .attempted:
        await baseLogger.info("Security event: \(action) was attempted", context: context)
    }
  }

  /**
   Logs an authentication event.

   - Parameters:
     - status: The authentication status
     - subject: The identity that was authenticated
     - method: The authentication method used
     - additionalMetadata: Additional metadata about the authentication
   */
  public func authenticationEvent(
    status: SecurityEventStatus,
    subject: String,
    method: String,
    additionalMetadata: [String: PrivacyTaggedValue]=[:]
  ) async {
    var combinedMetadata=additionalMetadata
    combinedMetadata["method"]=PrivacyTaggedValue(value: PrivacyMetadataValue.string(method),
                                                  privacyLevel: .public)

    await securityEvent(
      action: "Authentication",
      status: status,
      subject: subject,
      additionalMetadata: combinedMetadata
    )
  }

  /**
   Logs an authorisation event.

   - Parameters:
     - status: The authorisation status
     - subject: The identity requesting access
     - resource: The resource being accessed
     - permission: The permission being requested
     - additionalMetadata: Additional metadata about the authorisation
   */
  public func authorisationEvent(
    status: SecurityEventStatus,
    subject: String,
    resource: String,
    permission: String,
    additionalMetadata: [String: PrivacyTaggedValue]=[:]
  ) async {
    var combinedMetadata=additionalMetadata
    combinedMetadata["permission"]=PrivacyTaggedValue(value: PrivacyMetadataValue
      .string(permission),
      privacyLevel: .public)

    await securityEvent(
      action: "Authorisation",
      status: status,
      subject: subject,
      resource: resource,
      additionalMetadata: combinedMetadata
    )
  }

  /**
   Logs a data access event.

   - Parameters:
     - status: The access status
     - subject: The identity accessing the data
     - resource: The data resource being accessed
     - operation: The operation being performed (read, write, delete)
     - additionalMetadata: Additional metadata about the access
   */
  public func dataAccessEvent(
    status: SecurityEventStatus,
    subject: String,
    resource: String,
    operation: String,
    additionalMetadata: [String: PrivacyTaggedValue]=[:]
  ) async {
    var combinedMetadata=additionalMetadata
    combinedMetadata["operation"]=PrivacyTaggedValue(value: PrivacyMetadataValue.string(operation),
                                                     privacyLevel: .public)

    await securityEvent(
      action: "DataAccess",
      status: status,
      subject: subject,
      resource: resource,
      additionalMetadata: combinedMetadata
    )
  }

  /**
   Logs a crypto operation event.

   - Parameters:
     - status: The operation status
     - operation: The cryptographic operation performed
     - algorithm: The algorithm used
     - additionalMetadata: Additional metadata about the operation
   */
  public func cryptoOperationEvent(
    status: SecurityEventStatus,
    operation: String,
    algorithm: String,
    additionalMetadata: [String: PrivacyTaggedValue]=[:]
  ) async {
    var combinedMetadata=additionalMetadata
    combinedMetadata["algorithm"]=PrivacyTaggedValue(value: PrivacyMetadataValue.string(algorithm),
                                                     privacyLevel: .public)

    await securityEvent(
      action: "CryptoOperation:\(operation)",
      status: status,
      additionalMetadata: combinedMetadata
    )
  }
}

/**
 Security event status for logging.
 */
public enum SecurityEventStatus: String, Sendable, Equatable, CaseIterable {
  /// The operation completed successfully
  case success

  /// The operation failed
  case failure

  /// The operation was denied due to policy or permission
  case denied

  /// The operation was attempted but not completed
  case attempted
}

// SecurityLogContext has been moved to Utilities/SecurityLogContext.swift

/**
 A value with associated privacy level for secure logging.
 */
public struct PrivacyTaggedValue: Sendable, Equatable {
  /// The privacy metadata value
  public let value: PrivacyMetadataValue

  /// The privacy level for this value
  public let privacyLevel: LoggingTypes.LogPrivacy

  /**
   Creates a new privacy-tagged value.

   - Parameters:
     - value: The value to tag
     - privacyLevel: The privacy level for this value
   */
  public init(value: PrivacyMetadataValue, privacyLevel: LoggingTypes.LogPrivacy) {
    self.value=value
    self.privacyLevel=privacyLevel
  }

  /// Equatable conformance
  public static func == (lhs: PrivacyTaggedValue, rhs: PrivacyTaggedValue) -> Bool {
    lhs.value == rhs.value && lhs.privacyLevel == rhs.privacyLevel
  }
}

/**
 Type-safe privacy metadata value.
 */
public enum PrivacyMetadataValue: Sendable, Equatable {
  /// String value
  case string(String)

  /// Boolean value
  case bool(Bool)

  /// Numeric value (as String for consistency)
  case number(String)

  /// String representation of this value
  var stringValue: String {
    switch self {
      case let .string(value):
        value
      case let .bool(value):
        value ? "true" : "false"
      case let .number(value):
        value
    }
  }
}
