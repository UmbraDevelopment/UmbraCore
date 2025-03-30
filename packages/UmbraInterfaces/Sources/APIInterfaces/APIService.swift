/**
 # API Service Protocol
 
 Defines the core interface for executing API operations in the Umbra system.
 This protocol provides a unified entry point for all API operations,
 with strong typing and structured error handling.
 
 ## Operation Execution
 
 Operations are executed asynchronously, with results returned using
 Swift's structured concurrency model.
 
 ## Usage Example
 
 ```swift
 let apiService = APIServices.createService()
 
 let operation = ListRepositoriesOperation(includeDetails: true)
 let repositories = try await apiService.execute(operation)
 ```
 */
public protocol APIService: Sendable {
    /**
     Executes an API operation and returns the result.
     
     - Parameter operation: The operation to execute
     
     - Returns: The result of the operation
     - Throws: APIError if the operation fails
     */
    func execute<T: APIOperation>(_ operation: T) async throws -> T.ResultType
    
    /**
     Executes an API operation with a timeout.
     
     - Parameters:
        - operation: The operation to execute
        - timeoutSeconds: The timeout in seconds
     
     - Returns: The result of the operation
     - Throws: APIError.operationTimedOut if the operation times out, or another APIError if it fails
     */
    func execute<T: APIOperation>(
        _ operation: T,
        timeoutSeconds: Int
    ) async throws -> T.ResultType
    
    /**
     Executes an API operation and returns a result that can be success or failure.
     
     This method does not throw errors, but instead returns them wrapped in an APIResult.
     
     - Parameter operation: The operation to execute
     
     - Returns: An APIResult containing either the operation result or an error
     */
    func executeWithResult<T: APIOperation>(_ operation: T) async -> APIResult<T.ResultType>
}

/**
 # Domain-Specific API Service Protocol
 
 Extends the base APIService protocol with domain-specific typing.
 This allows services to specialise in handling operations for a specific domain.
 
 ## Domain Specialisation
 
 Each domain-specific service handles operations for a particular domain,
 providing specialised processing and error handling.
 
 ## Usage Example
 
 ```swift
 let repositoryService = APIServices.createRepositoryService()
 
 let operation = ListRepositoriesOperation(includeDetails: true)
 let repositories = try await repositoryService.execute(operation)
 ```
 */
public protocol DomainAPIService<SupportedDomain>: APIService {
    /// The domain this service supports
    associatedtype SupportedDomain: APIOperation
    
    /**
     Checks if this service supports the given operation.
     
     - Parameter operation: The operation to check
     
     - Returns: True if the operation is supported, false otherwise
     */
    func supports<T: APIOperation>(_ operation: T) -> Bool
}
