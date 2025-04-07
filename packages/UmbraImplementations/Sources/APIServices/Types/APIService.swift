import APIInterfaces
import Foundation
import LoggingInterfaces

/**
 * Core API service protocol implementation for the Alpha Dot Five architecture.
 *
 * This service handles API operations within the system using domain-specific handlers.
 */
public protocol APIService {
  /**
   * Execute an API operation.
   *
   * @param operation The operation to execute
   * @return The result of the operation
   * @throws If the operation fails
   */
  func execute<T: APIOperation>(_ operation: T) async throws -> Any

  /**
   * Check if the API service supports a given operation.
   *
   * @param operation The operation to check
   * @return True if the operation is supported
   */
  func supports<T: APIOperation>(_ operation: T) -> Bool
}

/**
 * Common protocol for API operation handlers.
 */
public protocol APIOperationHandler {
  /**
   * Execute an API operation.
   *
   * @param operation The operation to execute
   * @return The result of the operation
   * @throws If the operation fails
   */
  func execute<T: APIOperation>(_ operation: T) async throws -> Any
}

/**
 * Protocol for domain-specific handlers that process API operations.
 */
public protocol DomainHandler: APIOperationHandler {
  /**
   * The logger instance used by this handler.
   */
  var logger: LoggingProtocol { get }

  /**
   * Check if this handler supports a given operation.
   *
   * @param operation The operation to check
   * @return True if the operation is supported
   */
  func supports<T: APIOperation>(_ operation: T) -> Bool
}

/**
 * Extension adding default implementations for domain handlers.
 */
extension DomainHandler {
  public func supports(_: some APIOperation) -> Bool {
    true // By default, a handler supports all operations in its domain
  }
}
