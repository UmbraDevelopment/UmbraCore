/**
 # API Operation Protocol
 
 Defines the base protocol for all API operations in the Umbra system.
 This protocol provides a type-safe way to define request/response pairs
 for operations across different domains.
 
 Each API operation must define its own result type, providing strict
 type safety across the API surface.
 
 ## Usage Example
 
 ```swift
 struct ListRepositoriesOperation: APIOperation {
     typealias ResultType = [RepositoryInfo]
     
     let includeDetails: Bool
     let filterStatus: RepositoryStatus?
 }
 ```
 */
public protocol APIOperation: Sendable {
    /// The return type for this operation
    associatedtype ResultType: Sendable
}

/**
 # Domain-Specific API Operation Protocol
 
 Extends the base APIOperation protocol with domain-specific typing.
 This allows operations to be properly categorised and routed to
 the appropriate domain handlers.
 
 ## Domain Categorisation
 
 Operations are categorised by domain to ensure proper organisation
 and routing. Each domain has its own set of operations and handlers.
 
 ## Usage Example
 
 ```swift
 struct ListRepositoriesOperation: RepositoryAPIOperation {
     typealias ResultType = [RepositoryInfo]
     
     let includeDetails: Bool
     let filterStatus: RepositoryStatus?
 }
 ```
 */
public protocol DomainAPIOperation: APIOperation {
    /// The domain this operation belongs to
    static var domain: APIDomain { get }
}

/**
 # API Operation Domains
 
 Defines the available domains for API operations.
 Each domain represents a logical grouping of related operations.
 */
public enum APIDomain: String, Sendable {
    /// Operations related to repository management
    case repository
    
    /// Operations related to backup and snapshot management
    case backup
    
    /// Operations related to security and encryption
    case security
    
    /// Operations related to system configuration
    case system
    
    /// Operations related to user preferences
    case preferences
    
    /// Operations related to the application lifecycle
    case application
}

/**
 # API Result Type
 
 A generic result type for API operations, providing a standardised
 way to handle success and failure cases with rich error information.
 
 ## Usage Example
 
 ```swift
 func handleOperation(operation: SomeOperation) async -> APIResult<SomeOperation.ResultType> {
     do {
         let result = try await performOperation(operation)
         return .success(result)
     } catch {
         return .failure(APIError.operationFailed(error))
     }
 }
 ```
 */
public enum APIResult<Value: Sendable>: Sendable {
    /// The operation was successful
    case success(Value)
    
    /// The operation failed
    case failure(APIError)
    
    /**
     Extracts the value from a successful result, or throws the error from a failure.
     
     - Returns: The successful value
     - Throws: The error if the result is a failure
     */
    public func get() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /**
     Maps the value of a successful result using the given transformation.
     
     - Parameter transform: A closure that takes the successful value and returns a new value
     - Returns: A new result with the transformed value, or the original failure
     */
    public func map<NewValue: Sendable>(_ transform: (Value) -> NewValue) -> APIResult<NewValue> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /**
     Checks if this result is a success.
     
     - Returns: True if the result is a success, false otherwise
     */
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /**
     Checks if this result is a failure.
     
     - Returns: True if the result is a failure, false otherwise
     */
    public var isFailure: Bool {
        return !isSuccess
    }
}
