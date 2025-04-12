import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 Protocol for all logging commands.
 
 This protocol defines the contract that all logging commands must adhere to,
 following the command pattern architecture.
 */
public protocol LogCommand {
    /// The type of result that the command produces
    associatedtype ResultType
    
    /**
     Executes the command.
     
     - Parameter context: The logging context for the operation
     - Returns: The result of the command execution
     - Throws: Error if the command execution fails
     */
    func execute(context: LoggingInterfaces.LogContextDTO) async throws -> ResultType
}
