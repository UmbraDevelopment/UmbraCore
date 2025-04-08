import APIInterfaces
import Foundation
import LoggingInterfaces

/**
 # Domain Handler Protocol
 
 Defines a common interface for all domain handlers within the Alpha Dot Five architecture.
 This protocol standardises the handling of operations, error mapping, and caching
 across all domain handlers.
 
 ## Actor-Based Concurrency
 
 Implementations should be actors to ensure thread safety and memory isolation
 throughout all operations. The actor-based design provides automatic synchronisation
 and eliminates potential race conditions when handling concurrent requests.
 
 ## Privacy-Enhanced Logging
 
 All operations should be logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.
 */
public protocol DomainHandlerProtocol: Sendable {
  /// The domain name for this handler
  var domain: String { get }
  
  /**
   Handles an API operation and returns its result.
   
   - Parameter operation: The operation to handle
   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  func handleOperation<T: APIOperation>(operation: T) async throws -> Any
  
  /**
   Determines if this handler supports the given operation.
   
   - Parameter operation: The operation to check support for
   - Returns: true if the operation is supported, false otherwise
   */
  func supports(_ operation: some APIOperation) -> Bool
  
  /**
   Executes a batch of operations more efficiently than individual execution.
   
   - Parameter operations: Array of operations to execute
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any]
  
  /**
   Clears any cached data held by the handler.
   */
  func clearCache() async
}

/**
 Extension providing default implementations for some methods.
 */
public extension DomainHandlerProtocol {
  /**
   Default implementation for batch execution that processes operations individually.
   Override this method to provide optimised batch processing.
   
   - Parameter operations: Array of operations to execute
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any] {
    var results: [String: Any] = [:]
    
    for operation in operations {
      if let operationWithId = operation as? OperationWithId {
        let result = try await handleOperation(operation: operation)
        results[operationWithId.operationId] = result
      }
    }
    
    return results
  }
  
  /**
   Default implementation for clearing cache that does nothing.
   Override this method if the handler implements caching.
   */
  func clearCache() async {
    // Default implementation does nothing
  }
}

/**
 Protocol for operations that have an identifier.
 */
public protocol OperationWithId: APIOperation {
  /// Unique identifier for the operation
  var operationId: String { get }
}
