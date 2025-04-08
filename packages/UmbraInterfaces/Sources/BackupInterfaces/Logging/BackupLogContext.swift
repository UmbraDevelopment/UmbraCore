import Foundation
import LoggingTypes

/**
 * Protocol for backup log contexts.
 *
 * This protocol defines the interface for log contexts used in backup operations,
 * allowing for structured logging with appropriate privacy classifications.
 */
public protocol BackupLogContext: LogContextDTO {
  /**
   * Adds an operation name to the context.
   *
   * - Parameter operation: The operation name
   * - Returns: A new context with the operation name added
   */
  func withOperation(_ operation: String) -> Self

  /**
   * Adds a public metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  func withPublic(key: String, value: String) -> Self

  /**
   * Adds a private metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  func withPrivate(key: String, value: String) -> Self

  /**
   * Adds a sensitive metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  func withSensitive(key: String, value: String) -> Self

  /**
   * Adds a hashed metadata value to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the metadata added
   */
  func withHashed(key: String, value: String) -> Self
}
