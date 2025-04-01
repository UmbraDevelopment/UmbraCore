import CryptoTypes
import Foundation

/// Data transfer object representing the security context for operations.
///
/// This DTO serves as a bridge between high-level security services and
/// low-level cryptographic operations, providing all necessary context
/// for correctly applying security policies while delegating cryptographic
/// operations to the appropriate services.
public struct SecurityContextDTO: Sendable, Equatable {
  /// The security level to apply for this operation
  public let securityLevel: SecurityLevelDTO

  /// The type of security operation being performed
  public let operationType: SecurityOperationTypeDTO

  /// An identifier for the resource being secured
  public let resourceIdentifier: String?

  /// The access context determining how and by whom the resource can be accessed
  public let accessContext: AccessContextDTO?

  /// Whether this operation should be included in the audit trail
  public let auditTrail: Bool

  /// The identifier of the cryptographic key to use
  public let keyIdentifier: String

  /// Additional cryptographic operation options
  public let cryptoOptions: CryptoOperationOptionsDTO?

  /// Context-specific metadata for the security operation
  public let metadata: [String: String]

  /// Creates a new security context
  /// - Parameters:
  ///   - securityLevel: The security level to apply
  ///   - operationType: The type of security operation
  ///   - resourceIdentifier: An identifier for the resource being secured
  ///   - accessContext: The access context for the resource
  ///   - auditTrail: Whether to include in audit trail
  ///   - keyIdentifier: The cryptographic key identifier
  ///   - cryptoOptions: Additional cryptographic options
  ///   - metadata: Context-specific metadata
  public init(
    securityLevel: SecurityLevelDTO,
    operationType: SecurityOperationTypeDTO,
    resourceIdentifier: String?=nil,
    accessContext: AccessContextDTO?=nil,
    auditTrail: Bool=true,
    keyIdentifier: String,
    cryptoOptions: CryptoOperationOptionsDTO?=nil,
    metadata: [String: String]=[:]
  ) {
    self.securityLevel=securityLevel
    self.operationType=operationType
    self.resourceIdentifier=resourceIdentifier
    self.accessContext=accessContext
    self.auditTrail=auditTrail
    self.keyIdentifier=keyIdentifier
    self.cryptoOptions=cryptoOptions
    self.metadata=metadata
  }

  /// Creates a standard security context for data encryption
  /// - Parameters:
  ///   - keyIdentifier: The encryption key identifier
  ///   - resourceIdentifier: Optional resource identifier
  /// - Returns: A configured security context
  public static func standardEncryption(
    keyIdentifier: String,
    resourceIdentifier: String?=nil
  ) -> SecurityContextDTO {
    SecurityContextDTO(
      securityLevel: .standard,
      operationType: .encryption,
      resourceIdentifier: resourceIdentifier,
      keyIdentifier: keyIdentifier,
      cryptoOptions: CryptoOperationOptionsDTO.standardGCM()
    )
  }

  /// Creates a standard security context for data decryption
  /// - Parameters:
  ///   - keyIdentifier: The decryption key identifier
  ///   - resourceIdentifier: Optional resource identifier
  /// - Returns: A configured security context
  public static func standardDecryption(
    keyIdentifier: String,
    resourceIdentifier: String?=nil
  ) -> SecurityContextDTO {
    SecurityContextDTO(
      securityLevel: .standard,
      operationType: .decryption,
      resourceIdentifier: resourceIdentifier,
      keyIdentifier: keyIdentifier,
      cryptoOptions: CryptoOperationOptionsDTO.standardGCM()
    )
  }

  /// Creates a high-security context for sensitive data encryption
  /// - Parameters:
  ///   - keyIdentifier: The encryption key identifier
  ///   - resourceIdentifier: Optional resource identifier
  ///   - accessContext: Optional access context
  /// - Returns: A configured security context
  public static func highSecurityEncryption(
    keyIdentifier: String,
    resourceIdentifier: String?=nil,
    accessContext: AccessContextDTO?=nil
  ) -> SecurityContextDTO {
    SecurityContextDTO(
      securityLevel: .high,
      operationType: .encryption,
      resourceIdentifier: resourceIdentifier,
      accessContext: accessContext,
      keyIdentifier: keyIdentifier,
      cryptoOptions: CryptoOperationOptionsDTO.standardGCM()
    )
  }

  /// Creates a security context for data integrity verification
  /// - Parameters:
  ///   - keyIdentifier: The key identifier for verification
  ///   - resourceIdentifier: Optional resource identifier
  /// - Returns: A configured security context
  public static func integrityVerification(
    keyIdentifier: String,
    resourceIdentifier: String?=nil
  ) -> SecurityContextDTO {
    SecurityContextDTO(
      securityLevel: .standard,
      operationType: .verification,
      resourceIdentifier: resourceIdentifier,
      auditTrail: true,
      keyIdentifier: keyIdentifier,
      metadata: ["verification_type": "integrity"]
    )
  }
}

/// The type of security operation being performed
public enum SecurityOperationTypeDTO: String, Sendable, Equatable, CaseIterable {
  /// Encryption operation
  case encryption="Encryption"

  /// Decryption operation
  case decryption="Decryption"

  /// Verification operation
  case verification="Verification"

  /// Authentication operation
  case authentication="Authentication"

  /// Authorisation operation
  case authorisation="Authorisation"

  /// Access control operation
  case accessControl="AccessControl"

  /// Audit operation
  case audit="Audit"

  /// Key management operation
  case keyManagement="KeyManagement"
}

/// Data transfer object representing the access context for a security operation
public struct AccessContextDTO: Sendable, Equatable {
  /// The identity of the accessor
  public let accessorIdentity: String

  /// The type of access being requested
  public let accessType: AccessTypeDTO

  /// The duration for which access is granted
  public let accessDuration: TimeInterval?

  /// Additional access constraints
  public let constraints: [String: String]

  /// Creates a new access context
  /// - Parameters:
  ///   - accessorIdentity: The identity of the accessor
  ///   - accessType: The type of access being requested
  ///   - accessDuration: The duration for which access is granted
  ///   - constraints: Additional access constraints
  public init(
    accessorIdentity: String,
    accessType: AccessTypeDTO,
    accessDuration: TimeInterval?=nil,
    constraints: [String: String]=[:]
  ) {
    self.accessorIdentity=accessorIdentity
    self.accessType=accessType
    self.accessDuration=accessDuration
    self.constraints=constraints
  }
}

/// The type of access being requested
public enum AccessTypeDTO: String, Sendable, Equatable, CaseIterable {
  /// Read-only access
  case read="Read"

  /// Write access
  case write="Write"

  /// Execute access
  case execute="Execute"

  /// Administrative access
  case admin="Admin"
}
