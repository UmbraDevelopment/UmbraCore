/**
 # API Service Protocol

 Defines the core interface for executing API operations in the Umbra system.
 This protocol provides a unified entry point for all API operations,
 with strong typing and structured error handling.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for network operations:

 ```swift
 actor APIServiceActor: APIService {
     // Private state should be isolated within the actor
     private let networkClient: NetworkClient
     private let logger: PrivacyAwareLoggingProtocol

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class APIServiceImpl: APIService {
     private let actor: APIServiceActor

     // Forward all protocol methods to the actor
     public func execute<T>(_ operation: T) async throws -> T.ResultType where T: APIOperation {
         try await actor.execute(operation)
     }
 }
 ```

 ## Privacy Considerations

 API operations often handle sensitive data. Implementations must:
 - Use privacy-aware logging for all API request and response payloads
 - Apply proper redaction to sensitive fields in logs
 - Never log authentication tokens, passwords, or other credentials
 - Implement proper error handling that doesn't expose sensitive information

 ## Operation Execution

 Operations are executed asynchronously, with results returned using
 Swift's structured concurrency model.

 ## Usage Example

 ```swift
 let apiService = await APIServices.createService()

 let operation = ListRepositoriesOperation(includeDetails: true)
 let result = try await apiService.execute(operation, options: .init(timeout: 30))
 ```
 */
public protocol APIService: Sendable {
  /**
   Executes an API operation and returns the result.

   - Parameters:
      - operation: The operation to execute
      - options: Configuration options for execution

   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  func execute<T: APIOperation>(
    _ operation: T,
    options: APIExecutionOptions?
  ) async throws -> T.ResultType

  /**
   Executes an API operation and returns a result that can be success or failure.

   This method does not throw errors, but instead returns them wrapped in an APIResult.

   - Parameters:
      - operation: The operation to execute
      - options: Configuration options for execution

   - Returns: An APIResult containing either the operation result or an error
   */
  func executeWithResult<T: APIOperation>(
    _ operation: T,
    options: APIExecutionOptions?
  ) async -> APIResult<T.ResultType>

  /**
   Cancels all in-progress API operations.

   - Parameter options: Configuration options for cancellation
   */
  func cancelAllOperations(options: APICancellationOptions?) async

  /**
   Cancels a specific API operation by its identifier.

   - Parameters:
      - operationId: The identifier of the operation to cancel
      - options: Configuration options for cancellation

   - Returns: True if the operation was found and cancelled, false otherwise
   */
  func cancelOperation(
    withID operationID: String,
    options: APICancellationOptions?
  ) async -> Bool
}

/**
 # Domain-Specific API Service Protocol

 Extends the base APIService protocol with domain-specific typing.
 This allows services to specialise in handling operations for a specific domain.

 ## Actor-Based Implementation

 Domain-specific API services should follow the same actor-based implementation
 pattern as the base APIService.

 ## Domain Specialisation

 Each domain-specific service handles operations for a particular domain,
 providing specialised processing and error handling.

 ## Usage Example

 ```swift
 let repositoryService = await APIServices.createRepositoryService()

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

/**
 Options for configuring API operation execution.
 */
public struct APIExecutionOptions: Sendable, Equatable {
  /// Standard options for most operations
  public static let standard=APIExecutionOptions()

  /// Default timeout in seconds
  public static let defaultTimeout=60

  /// Timeout in seconds (nil means no timeout)
  public let timeout: Int?

  /// Whether to retry failed operations
  public let retryEnabled: Bool

  /// Maximum number of retry attempts
  public let maxRetries: Int

  /// Priority level for the operation
  public let priority: APIPriority

  /// Whether to use cached responses if available
  public let useCache: Bool

  /// Authentication level required for this operation
  public let authenticationLevel: APIAuthenticationLevel

  /// Additional request headers
  public let additionalHeaders: [String: String]

  /// Creates new API execution options
  public init(
    timeout: Int?=defaultTimeout,
    retryEnabled: Bool=true,
    maxRetries: Int=3,
    priority: APIPriority = .normal,
    useCache: Bool=true,
    authenticationLevel: APIAuthenticationLevel = .standard,
    additionalHeaders: [String: String]=[:]
  ) {
    self.timeout=timeout
    self.retryEnabled=retryEnabled
    self.maxRetries=maxRetries
    self.priority=priority
    self.useCache=useCache
    self.authenticationLevel=authenticationLevel
    self.additionalHeaders=additionalHeaders
  }
}

/**
 Priority levels for API operations.
 */
public enum APIPriority: String, Sendable, Equatable, Comparable {
  /// High priority operations - for critical user-facing tasks
  case high

  /// Normal priority operations - default for most operations
  case normal

  /// Low priority operations - for background tasks
  case low

  /// Background priority operations - for maintenance and housekeeping
  case background

  public static func < (lhs: APIPriority, rhs: APIPriority) -> Bool {
    let order: [APIPriority]=[.background, .low, .normal, .high]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}

/**
 Authentication levels for API operations.
 */
public enum APIAuthenticationLevel: String, Sendable, Equatable {
  /// No authentication required
  case none

  /// Standard authentication (default user credentials)
  case standard

  /// Elevated privileges required
  case elevated

  /// Administrative privileges required
  case administrative
}

/**
 Options for API operation cancellation.
 */
public struct APICancellationOptions: Sendable, Equatable {
  /// Whether to force immediate cancellation
  public let force: Bool

  /// Whether to wait for cancellation to complete
  public let waitForCompletion: Bool

  /// Timeout in seconds for waiting (nil means no timeout)
  public let timeout: Int?

  /// Creates new API cancellation options
  public init(
    force: Bool=false,
    waitForCompletion: Bool=true,
    timeout: Int?=5
  ) {
    self.force=force
    self.waitForCompletion=waitForCompletion
    self.timeout=timeout
  }
}
