import DateTimeTypes
import Foundation
import LoggingTypes

/**
 # CryptoEventDTO

 Data transfer object representing a cryptographic operation event.

 This DTO provides a Foundation-independent way to represent events
 occurring during cryptographic operations for monitoring purposes.
 It includes details about the operation type, status, and context.
 */
public struct CryptoEventDTO: Sendable, Equatable {
  /// Unique identifier for the event
  public let identifier: String

  /// Type of the event
  public let eventType: CryptoEventType

  /// When the event occurred
  public let timestamp: TimePointDTO

  /// Status of the operation
  public let status: CryptoOperationStatus

  /// The operation being performed
  public let operation: String

  /// Key identifier associated with the operation, if any
  public let keyIdentifier: String?

  /// Additional metadata about the event
  public let metadata: LogMetadataDTOCollection

  /**
   Creates a new CryptoEventDTO.

   - Parameters:
      - identifier: Unique identifier for the event
      - eventType: Type of the event
      - timestamp: When the event occurred
      - status: Status of the operation
      - operation: The operation being performed
      - keyIdentifier: Key identifier associated with the operation, if any
      - metadata: Additional metadata about the event
   */
  public init(
    identifier: String,
    eventType: CryptoEventType,
    timestamp: TimePointDTO,
    status: CryptoOperationStatus,
    operation: String,
    keyIdentifier: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.identifier=identifier
    self.eventType=eventType
    self.timestamp=timestamp
    self.status=status
    self.operation=operation
    self.keyIdentifier=keyIdentifier
    self.metadata=metadata
  }

  /// Creates an operation start event
  public static func operationStart(
    operation: String,
    keyIdentifier: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CryptoEventDTO {
    CryptoEventDTO(
      identifier: UUID().uuidString,
      eventType: .operation,
      timestamp: TimePointDTO.now(),
      status: .started,
      operation: operation,
      keyIdentifier: keyIdentifier,
      metadata: metadata
    )
  }

  /// Creates an operation success event
  public static func operationSuccess(
    operation: String,
    keyIdentifier: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CryptoEventDTO {
    CryptoEventDTO(
      identifier: UUID().uuidString,
      eventType: .operation,
      timestamp: TimePointDTO.now(),
      status: .succeeded,
      operation: operation,
      keyIdentifier: keyIdentifier,
      metadata: metadata
    )
  }

  /// Creates an operation failure event
  public static func operationFailure(
    operation: String,
    keyIdentifier: String?=nil,
    errorMessage: String,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CryptoEventDTO {
    var updatedMetadata=metadata
    updatedMetadata=updatedMetadata.withPrivate(key: "error", value: errorMessage)

    return CryptoEventDTO(
      identifier: UUID().uuidString,
      eventType: .operation,
      timestamp: TimePointDTO.now(),
      status: .failed,
      operation: operation,
      keyIdentifier: keyIdentifier,
      metadata: updatedMetadata
    )
  }

  /// Creates a key management event
  public static func keyManagement(
    operation: String,
    keyIdentifier: String,
    status: CryptoOperationStatus,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CryptoEventDTO {
    CryptoEventDTO(
      identifier: UUID().uuidString,
      eventType: .keyManagement,
      timestamp: TimePointDTO.now(),
      status: status,
      operation: operation,
      keyIdentifier: keyIdentifier,
      metadata: metadata
    )
  }

  /// Creates a security event
  public static func security(
    operation: String,
    status: CryptoOperationStatus,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) -> CryptoEventDTO {
    CryptoEventDTO(
      identifier: UUID().uuidString,
      eventType: .security,
      timestamp: TimePointDTO.now(),
      status: status,
      operation: operation,
      keyIdentifier: nil,
      metadata: metadata
    )
  }
}

/// Types of crypto events
public enum CryptoEventType: String, Sendable, Equatable {
  case operation // Standard crypto operation (encrypt, decrypt, hash, etc.)
  case keyManagement // Key generation, rotation, deletion, etc.
  case security // Security-related events (access control, validation)
  case system // System events (service start/stop, configuration)
}

/// Status of a crypto operation
public enum CryptoOperationStatus: String, Sendable, Equatable {
  case started // Operation has started
  case succeeded // Operation completed successfully
  case failed // Operation failed
  case cancelled // Operation was cancelled
  case pending // Operation is waiting for resources or approval
}
