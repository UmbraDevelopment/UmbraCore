import Foundation
import ErrorCoreTypes

/**
 # ErrorHandlerProtocol
 
 Protocol defining requirements for error handler components.
 
 This protocol establishes a consistent interface for handling errors across
 the system. It follows the Alpha Dot Five architecture by separating the
 error handling interface from its implementation.
 */
public protocol ErrorHandlerProtocol: Sendable {
    /**
     Handles an error according to the implementation's strategy.
     
     This method should take appropriate action to process the error, which may include
     logging, recovery attempts, user notification, or other contextual handling.
     
     - Parameters:
        - error: The error to handle
        - source: Optional string identifying the error source
        - metadata: Additional contextual information about the error
     */
    func handle<E: Error>(
        _ error: E,
        source: String?,
        metadata: [String: String]
    ) async
    
    /**
     Handles an error with a context.
     
     This is a convenience method that extracts source and metadata from the context.
     
     - Parameters:
        - error: The error to handle
        - context: Contextual information about the error
     */
    func handle<E: Error>(
        _ error: E,
        context: ErrorContext
    ) async
}
