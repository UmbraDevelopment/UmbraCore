import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * Implementation of the BackupLogContext protocol.
 *
 * This struct provides a concrete implementation of the BackupLogContext protocol,
 * allowing for structured logging with appropriate privacy classifications.
 */
public struct BackupLogContextImpl: BackupLogContext, Sendable {
  /// The domain name for the log context
  public let domainName: String

  /// The source of the log
  public let source: String

  /// The metadata collection
  public let metadata: LogMetadataDTOCollection

  /**
   * Initialises a new backup log context.
   *
   * - Parameters:
   *   - domainName: The domain name for the log context
   *   - source: The source of the log
   *   - metadata: The metadata collection
   */
  public init(
    domainName: String,
    source: String,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.domainName=domainName
    self.source=source
    self.metadata=metadata
  }

  /**
   * Adds an operation name to the context.
   *
   * - Parameter operation: The operation name
   * - Returns: A new context with the operation name added
   */
  public func withOperation(_ operation: String) -> Self {
    withPublic(key: "operation", value: operation)
  }

  /**
   * Adds a public metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  public func withPublic(key: String, value: String) -> Self {
    var newMetadata=metadata
    newMetadata.add(key: key, value: value, privacy: .public)
    return BackupLogContextImpl(domainName: domainName, source: source, metadata: newMetadata)
  }

  /**
   * Adds a private metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  public func withPrivate(key: String, value: String) -> Self {
    var newMetadata=metadata
    newMetadata.add(key: key, value: value, privacy: .private)
    return BackupLogContextImpl(domainName: domainName, source: source, metadata: newMetadata)
  }

  /**
   * Adds a sensitive metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  public func withSensitive(key: String, value: String) -> Self {
    var newMetadata=metadata
    newMetadata.add(key: key, value: value, privacy: .sensitive)
    return BackupLogContextImpl(domainName: domainName, source: source, metadata: newMetadata)
  }

  /**
   * Adds a hashed metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  public func withHashed(key: String, value: String) -> Self {
    var newMetadata=metadata
    newMetadata.add(key: key, value: value, privacy: .hash)
    return BackupLogContextImpl(domainName: domainName, source: source, metadata: newMetadata)
  }

  /**
   * Gets the metadata collection.
   *
   * - Returns: The metadata collection
   */
  public func getMetadata() -> MetadataCollection {
    metadata
  }
}
