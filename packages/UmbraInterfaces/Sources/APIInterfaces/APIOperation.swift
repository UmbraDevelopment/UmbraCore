import Darwin

/**
 # API Operation Protocol

 Defines the base protocol for all API operations in the Umbra system.
 This protocol provides a type-safe way to define request/response pairs
 for operations across different domains.

 Each API operation must define its own result type, providing strict
 type safety across the API surface.

 ## Privacy Considerations

 When implementing API operations:
 - Define clear privacy levels for all fields in the operation
 - Mark sensitive fields with appropriate attributes for logging
 - Consider using opaque identifiers instead of direct values for sensitive data
 - Implement proper data sanitisation for inputs and outputs

 ## Concurrency Safety

 All API operations must be Sendable to ensure they can be safely used
 across concurrency boundaries. Use immutable value types and consider
 implementing custom Sendable conformance if needed.

 ## Usage Example

 ```swift
 struct ListRepositoriesOperation: APIOperation {
     typealias ResultType = [RepositoryInfo]

     let includeDetails: Bool
     let filterStatus: RepositoryStatus?
     
     /// Privacy metadata for this operation
     var privacyMetadata: APIOperationPrivacyMetadata {
         return .init(
             sensitiveParameters: [],
             loggableResponseFields: ["id", "name", "status"],
             privacyLevel: .standard
         )
     }
 }
 ```
 */
public protocol APIOperation: Sendable {
  /// The return type for this operation
  associatedtype ResultType: Sendable
  
  /// Unique identifier for this operation instance
  var operationId: String { get }
  
  /// Privacy metadata for this operation
  var privacyMetadata: APIOperationPrivacyMetadata { get }
}

/// Operation ID generation
private enum OperationIDGenerator {
  /// Thread-safe atomic counter
  @Sendable private static var counter = 0
  
  /// Internal lock for thread safety
  private static let counterLock = Lock()
  
  /// Generate a unique operation ID using a counter and timestamp
  static func generateID() -> String {
    let count = counterLock.withLock {
      counter += 1
      return counter
    }
    
    // Use uptime in milliseconds as a timestamp component
    let timestamp = UptimeProvider.millisecondsSinceStart
    return "\(timestamp)-\(count)"
  }
}

/// Simple lock for thread safety
private final class Lock {
  private var _lock = OS_UNFAIR_LOCK_INIT
  
  func withLock<T>(_ work: () -> T) -> T {
    os_unfair_lock_lock(&_lock)
    defer { os_unfair_lock_unlock(&_lock) }
    return work()
  }
}

/// Provides system uptime without Foundation dependencies
private enum UptimeProvider {
  /// Get milliseconds since system boot
  static var millisecondsSinceStart: UInt64 {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    let time = mach_absolute_time()
    let nanos = time * UInt64(info.numer) / UInt64(info.denom)
    return nanos / 1_000_000
  }
}

/// Default implementation for operationId
public extension APIOperation {
  var operationId: String {
    OperationIDGenerator.generateID()
  }
  
  var privacyMetadata: APIOperationPrivacyMetadata {
    .standard
  }
}

/**
 # Privacy Metadata for API Operations
 
 Defines the privacy characteristics of an API operation to ensure
 proper handling of sensitive data in logs and error messages.
 */
public struct APIOperationPrivacyMetadata: Sendable, Equatable {
  /// Standard metadata with default privacy settings
  public static let standard = APIOperationPrivacyMetadata()
  
  /// Highly sensitive metadata for security operations
  public static let sensitive = APIOperationPrivacyMetadata(
    sensitiveParameters: ["*"],
    loggableResponseFields: [],
    privacyLevel: .sensitive
  )
  
  /// Parameters that should be treated as sensitive
  public let sensitiveParameters: [String]
  
  /// Response fields that are safe to log
  public let loggableResponseFields: [String]
  
  /// Overall privacy level for this operation
  public let privacyLevel: APIPrivacyLevel
  
  /// Creates new API operation privacy metadata
  public init(
    sensitiveParameters: [String] = [],
    loggableResponseFields: [String] = ["*"],
    privacyLevel: APIPrivacyLevel = .standard
  ) {
    self.sensitiveParameters = sensitiveParameters
    self.loggableResponseFields = loggableResponseFields
    self.privacyLevel = privacyLevel
  }
}

/**
 # Privacy Level for API Operations
 
 Defines the overall privacy sensitivity of an API operation.
 */
public enum APIPrivacyLevel: String, Sendable, Equatable, Comparable {
  /// Public data that can be freely logged
  case `public`
  
  /// Standard operational data with normal privacy requirements
  case standard
  
  /// Sensitive data requiring redaction in logs
  case sensitive
  
  /// Highly sensitive data requiring special handling
  case restricted
  
  public static func < (lhs: APIPrivacyLevel, rhs: APIPrivacyLevel) -> Bool {
    let order: [APIPrivacyLevel] = [.public, .standard, .sensitive, .restricted]
    guard let lhsIndex = order.firstIndex(of: lhs),
          let rhsIndex = order.firstIndex(of: rhs) else {
      return false
    }
    return lhsIndex < rhsIndex
  }
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
public enum APIDomain: String, Sendable, Equatable, CaseIterable {
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
  
  /// Operations related to authentication and authorization
  case authentication
  
  /// Operations related to account management
  case account
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
      case let .success(value):
        return value
      case let .failure(error):
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
      case let .success(value):
        return .success(transform(value))
      case let .failure(error):
        return .failure(error)
    }
  }
  
  /**
   Maps the error of a failure result using the given transformation.
   
   - Parameter transform: A closure that takes the error and returns a new error
   - Returns: A new result with the transformed error, or the original success
   */
  public func mapError(_ transform: (APIError) -> APIError) -> APIResult<Value> {
    switch self {
      case let .success(value):
        return .success(value)
      case let .failure(error):
        return .failure(transform(error))
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
  
  /**
   Retrieve the successful value if available.
   
   - Returns: The successful value, or nil if this result is a failure
   */
  public var value: Value? {
    switch self {
      case let .success(value):
        return value
      case .failure:
        return nil
    }
  }
  
  /**
   Retrieve the error if available.
   
   - Returns: The error, or nil if this result is a success
   */
  public var error: APIError? {
    switch self {
      case .success:
        return nil
      case let .failure(error):
        return error
    }
  }
}
