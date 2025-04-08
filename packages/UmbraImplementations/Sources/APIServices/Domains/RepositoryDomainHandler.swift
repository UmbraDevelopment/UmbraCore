import APIInterfaces
import ErrorCoreTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces
import UmbraErrors

/**
 # Repository Domain Handler

 Handles repository-related API operations within the Alpha Dot Five architecture.
 This implementation provides operations for repository management, including
 creation, retrieval, updates, and deletion with proper privacy controls.

 ## Privacy-Enhanced Logging

 All operations are logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.

 ## Thread Safety

 This handler is implemented as an actor to ensure thread safety and memory isolation
 throughout all operations. The actor-based design provides automatic synchronisation
 and eliminates potential race conditions when handling concurrent requests.
 */
public actor RepositoryDomainHandler: DomainHandler {
  /// Repository service for storage operations
  private let repositoryService: RepositoryServiceProtocol
  
  /// Base domain handler for common functionality
  private let baseDomainHandler: BaseDomainHandler
  
  /// Cache for repository information to improve performance of repeated requests
  private var repositoryCache: [String: (RepositoryInfo, Date)] = [:]
  
  /// Cache time-to-live in seconds
  private let cacheTTL: TimeInterval = 60 // 1 minute

  /**
   Initialises a new repository domain handler.

   - Parameters:
      - service: The repository service implementation
      - logger: Optional logger for privacy-aware operation recording
   */
  public init(
    service: RepositoryServiceProtocol,
    logger: (any LoggingProtocol)?=nil
  ) {
    repositoryService = service
    baseDomainHandler = BaseDomainHandler(domain: APIDomain.repository.rawValue, logger: logger)
  }

  // MARK: - DomainHandler Conformance
  public nonisolated var domain: String { APIDomain.repository.rawValue }

  public func handleOperation<T: APIOperation>(operation: T) async throws -> Any {
    // Call the existing execute method
    return try await execute(operation)
  }

  /**
   Executes a repository operation and returns its result.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  public func execute(_ operation: some APIOperation) async throws -> Any {
    // Get operation name once for reuse
    let operationName = String(describing: type(of: operation))
    
    // Log operation start with optimised metadata creation
    await baseDomainHandler.logOperationStart(operationName: operationName, source: "RepositoryDomainHandler")
    
    do {
      // Execute the appropriate operation based on type
      let result = try await executeRepositoryOperation(operation)
      
      // Log success with optimised metadata creation
      await baseDomainHandler.logOperationSuccess(operationName: operationName, source: "RepositoryDomainHandler")
      
      return result
    } catch {
      // Log failure with optimised metadata creation
      await baseDomainHandler.logOperationFailure(
        operationName: operationName,
        error: error,
        source: "RepositoryDomainHandler"
      )
      
      // Map to appropriate API error and rethrow
      throw mapToAPIError(error)
    }
  }

  /**
   Determines if this handler supports the given operation.

   - Parameter operation: The operation to check support for
   - Returns: true if the operation is supported, false otherwise
   */
  public nonisolated func supports(_ operation: some APIOperation) -> Bool {
    operation is any RepositoryAPIOperation
  }

  // MARK: - Private Helper Methods
  
  /**
   Retrieves a repository from the cache if available and not expired.
   
   - Parameter id: The repository ID
   - Returns: The cached repository if available, nil otherwise
   */
  private func getCachedRepository(id: String) -> RepositoryInfo? {
    if let (info, timestamp) = repositoryCache[id],
       Date().timeIntervalSince(timestamp) < cacheTTL {
      return info
    }
    return nil
  }
  
  /**
   Caches a repository for future use.
   
   - Parameters:
     - id: The repository ID
     - info: The repository information to cache
   */
  private func cacheRepository(id: String, info: RepositoryInfo) {
    repositoryCache[id] = (info, Date())
  }
  
  /**
   Clears all cached repositories.
   */
  public func clearCache() {
    repositoryCache.removeAll()
  }

  /**
   Routes the operation to the appropriate handler method based on its type.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails or is unsupported
   */
  private func executeRepositoryOperation(_ operation: some APIOperation) async throws -> Any {
    switch operation {
      case let op as ListRepositoriesOperation:
        return try await handleListRepositories(op)
      case let op as GetRepositoryOperation:
        // Check cache first for better performance
        if let cachedRepository = getCachedRepository(id: op.repositoryID) {
          // Log cache hit if needed
          await baseDomainHandler.logDebug(
            message: "Retrieved repository from cache",
            operationName: "getRepository",
            source: "RepositoryDomainHandler",
            additionalMetadata: LogMetadataDTOCollection()
              .withPublic(key: "repository_id", value: op.repositoryID)
              .withPublic(key: "cache_hit", value: "true")
          )
          return cachedRepository
        }
        return try await handleGetRepository(op)
      case let op as CreateRepositoryOperation:
        let result = try await handleCreateRepository(op)
        // Cache the result for future use
        if let repositoryInfo = result as? RepositoryInfo {
          cacheRepository(id: repositoryInfo.id, info: repositoryInfo)
        }
        return result
      case let op as UpdateRepositoryOperation:
        let result = try await handleUpdateRepository(op)
        // Update cache with new information
        if let repositoryInfo = result as? RepositoryInfo {
          cacheRepository(id: repositoryInfo.id, info: repositoryInfo)
        }
        return result
      case let op as DeleteRepositoryOperation:
        // Invalidate cache entry for this repository
        repositoryCache.removeValue(forKey: op.repositoryID)
        return try await handleDeleteRepository(op)
      default:
        throw APIError.operationNotSupported(
          message: "Unsupported repository operation: \(type(of: operation))",
          code: "REPOSITORY_OPERATION_NOT_SUPPORTED"
        )
    }
  }

  /**
   Maps domain-specific errors to standardised API errors.

   - Parameter error: The original error
   - Returns: An APIError instance
   */
  private func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError = error as? APIError {
      return apiError
    }

    // Handle specific repository error types
    if let repoError = error as? RepositoryError {
      return mapRepositoryError(repoError)
    }

    // Default to a generic error for unhandled error types
    return APIError.internalError(
      message: "An unexpected error occurred: \(error.localizedDescription)",
      underlyingError: error
    )
  }
  
  /**
   Maps RepositoryError to standardised APIError.
   
   - Parameter error: The repository error to map
   - Returns: An APIError instance
   */
  private func mapRepositoryError(_ error: RepositoryError) -> APIError {
    switch error {
      case .notFound:
        return APIError.resourceNotFound(
          message: "Repository not found",
          identifier: "unknown"
        )
      case .duplicateIdentifier:
        return APIError.conflict(
          message: "Repository already exists with this identifier",
          details: "A repository with the given identifier is already registered",
          code: "REPOSITORY_ALREADY_EXISTS"
        )
      case .locked:
        return APIError.conflict(
          message: "Repository is locked by another operation",
          details: "Try again later when the repository is not in use",
          code: "REPOSITORY_LOCKED"
        )
      case .invalidRepository:
        return APIError.validationError(
          message: "Invalid repository configuration",
          details: "The repository configuration is invalid or incomplete",
          code: "INVALID_REPOSITORY"
        )
      case .accessDenied:
        return APIError.accessDenied(
          message: "Access denied to repository",
          details: "The application does not have permission to access this repository",
          code: "REPOSITORY_ACCESS_DENIED"
        )
      case .networkError:
        return APIError.networkError(
          message: "Network error accessing repository",
          details: "A network error occurred while trying to access the repository",
          code: "REPOSITORY_NETWORK_ERROR"
        )
      case .other:
        return APIError.internalError(
          message: "An unexpected repository error occurred",
          underlyingError: error
        )
    }
  }

  // MARK: - Batch Operation Support
  
  /**
   Executes a batch of repository operations more efficiently than individual execution.
   
   - Parameter operations: Array of operations to execute
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  public func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any] {
    var results: [String: Any] = [:]
    
    // Group operations by type for more efficient processing
    let groupedOperations = Dictionary(grouping: operations) { type(of: $0) }
    
    // Log batch operation start
    await baseDomainHandler.logDebug(
      message: "Starting batch repository operation",
      operationName: "batchExecution",
      source: "RepositoryDomainHandler",
      additionalMetadata: LogMetadataDTOCollection()
        .withPublic(key: "operationCount", value: String(operations.count))
        .withPublic(key: "operationTypes", value: String(describing: groupedOperations.keys))
    )
    
    do {
      // Process each group of operations
      for (_, operationsOfType) in groupedOperations {
        if let firstOp = operationsOfType.first {
          // Process based on operation type
          if firstOp is ListRepositoriesOperation {
            // Example: Batch process all list operations together
            let batchResult = try await batchListRepositories(
              operationsOfType.compactMap { $0 as? ListRepositoriesOperation }
            )
            for (id, result) in batchResult {
              results[id] = result
            }
          } else {
            // Fall back to individual processing for other types
            for operation in operationsOfType {
              let result = try await executeRepositoryOperation(operation)
              results[operation.operationId] = result
            }
          }
        }
      }
      
      // Log batch operation success
      await baseDomainHandler.logDebug(
        message: "Batch repository operation completed successfully",
        operationName: "batchExecution",
        source: "RepositoryDomainHandler",
        additionalMetadata: LogMetadataDTOCollection()
          .withPublic(key: "operationCount", value: String(operations.count))
          .withPublic(key: "resultsCount", value: String(results.count))
      )
      
      return results
    } catch {
      // Log batch operation failure
      await baseDomainHandler.logOperationFailure(
        operationName: "batchExecution",
        error: error,
        source: "RepositoryDomainHandler"
      )
      
      throw mapToAPIError(error)
    }
  }
  
  /**
   Processes multiple list repositories operations in a batch for better performance.
   
   - Parameter operations: Array of ListRepositoriesOperation to process
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  private func batchListRepositories(_ operations: [ListRepositoriesOperation]) async throws -> [String: [RepositoryInfo]] {
    var results: [String: [RepositoryInfo]] = [:]
    
    // Get all repositories in one call
    let allRepositories = try await repositoryService.listRepositories(includeDetails: true)
    
    // Apply filters for each operation
    for operation in operations {
      let filteredRepositories: [RepositoryInfo]
      
      // Apply any operation-specific filtering
      if operation.includeDetails {
        filteredRepositories = allRepositories
      } else {
        // If details aren't needed, create simplified versions
        filteredRepositories = allRepositories.map { repo in
          RepositoryInfo(
            id: repo.id,
            name: repo.name,
            type: repo.type,
            status: repo.status,
            creationDate: repo.creationDate,
            lastModified: repo.lastModified
          )
        }
      }
      
      // Store the result for this operation
      results[operation.operationId] = filteredRepositories
    }
    
    return results
  }

  /**
   Handles the list repositories operation.

   - Parameter operation: The operation to execute
   - Returns: Array of repository information
   - Throws: APIError if the operation fails
   */
  private func handleListRepositories(_ operation: ListRepositoriesOperation) async throws
  -> [RepositoryInfo] {
    // Create privacy-aware logging metadata
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: "listRepositories")
      .withPublic(key: "include_details", value: operation.includeDetails.description)

    await baseDomainHandler.logDebug(
      message: "Listing repositories",
      operationName: "listRepositories",
      source: "RepositoryDomainHandler",
      additionalMetadata: metadata
    )

    // Get all repositories from the service
    let repositories=await repositoryService.getAllRepositories()

    if repositories.isEmpty {
      await baseDomainHandler.logDebug(
        message: "No repositories found",
        operationName: "listRepositories",
        source: "RepositoryDomainHandler",
        additionalMetadata: metadata
      )
      return []
    }

    // Apply status filter if requested
    let statusFilterValue=operation.statusFilter
    let filteredRepositories=repositories.filter { (_, repository) in
      guard let statusFilter=statusFilterValue else {
        return true // Include all repositories if no status filter
      }

      // Status filter needs to be handled differently as it's a string in the API
      // but an enum in the repository service
      // Get the state from the repository synchronously to use in the filter
      let state=getRepositoryState(repository)
      return statusFilter == mapStatus(state).rawValue
    }

    // Map each repository to the API model
    var resultList=[RepositoryInfo]()
    for (id, repository) in filteredRepositories {
      try await resultList.append(
        RepositoryInfo(
          id: id,
          name: repository.identifier, // Placeholder: Use identifier as name
          // name: repository.getName() ?? repository.identifier,
          status: mapStatus(Task.detached { repository.state }.value),
          creationDate: Date(), // Placeholder: Use current date
          // creationDate: repository.getCreationDate() ?? Date(),
          lastAccessDate: Date() // Placeholder: Use current date
          // lastAccessDate: repository.getLastAccessDate() ?? Date()
        )
      )
    }

    await baseDomainHandler.logDebug(
      message: "Found \(resultList.count) repositories",
      operationName: "listRepositories",
      source: "RepositoryDomainHandler",
      additionalMetadata: metadata.with(
        key: "count",
        value: String(resultList.count),
        privacyLevel: .public
      )
    )

    return resultList
  }

  /**
   Handles the get repository operation.

   - Parameter operation: The operation to execute
   - Returns: Detailed repository information
   - Throws: APIError if the operation fails
   */
  private func handleGetRepository(_ operation: GetRepositoryOperation) async throws
  -> RepositoryDetails {
    // Check if the repository exists
    if await !repositoryService.isRegistered(identifier: operation.repositoryID) {
      throw APIError.resourceNotFound(
        message: "Repository not found: \(operation.repositoryID)",
        identifier: operation.repositoryID
      )
    }

    // Get the repository
    let repository=try await repositoryService.getRepository(identifier: operation.repositoryID)

    // Get the repository stats
    let stats=try await repository.getStats()

    // Create the repository details
    let details=try await RepositoryDetails(
      id: repository.identifier,
      name: repository.identifier, // Placeholder: Use identifier as name
      // name: repository.getName() ?? repository.identifier,
      status: mapStatus(Task.detached { repository.state }.value),
      creationDate: Date(), // Placeholder: Use current date
      // creationDate: repository.getCreationDate() ?? Date(),
      lastAccessDate: Date(), // Placeholder: Use current date
      // lastAccessDate: repository.getLastAccessDate() ?? Date(),
      snapshotCount: Int(stats.snapshotCount),
      totalSize: Int(stats.totalSize),
      location: repository.location.absoluteString
    )

    await baseDomainHandler.logDebug(
      message: "Retrieved repository details",
      operationName: "getRepository",
      source: "RepositoryDomainHandler",
      additionalMetadata: LogMetadataDTOCollection()
        .withPublic(key: "repository_id", value: operation.repositoryID)
    )

    return details
  }

  /**
   Handles the create repository operation.

   - Parameter operation: The operation to execute
   - Returns: Basic repository information
   - Throws: APIError if the operation fails
   */
  private func handleCreateRepository(_ operation: CreateRepositoryOperation) async throws
  -> RepositoryInfo {
    // Extract parameters
    let params=operation.parameters

    // Try to create repository
    let repository=try await repositoryService.createRepository(
      at: operation.parameters.location
    )

    // Apply name and other metadata if needed
    // try await repository.setName(params.name)
    // try await repository.setMetadata([
    //  "name": params.name,
    //  "location": params.location.path,
    // ])

    // Return repository info
    let info=try await RepositoryInfo(
      id: repository.identifier,
      name: repository.identifier, // Placeholder: Use identifier as name
      // name: repository.getName() ?? repository.identifier,
      status: mapStatus(Task.detached { repository.state }.value),
      creationDate: Date(), // Placeholder: Use current date
      // creationDate: repository.getCreationDate() ?? Date(),
      lastAccessDate: Date() // Placeholder: Use current date
      // lastAccessDate: repository.getLastAccessDate() ?? Date()
    )

    await baseDomainHandler.logDebug(
      message: "Repository created successfully",
      operationName: "createRepository",
      source: "RepositoryDomainHandler",
      additionalMetadata: LogMetadataDTOCollection()
        .withPublic(key: "repository_id", value: repository.identifier)
        .withPublic(key: "repository_name", value: repository.name)
    )

    return info
  }

  /**
   Handles the update repository operation.

   - Parameter operation: The operation to execute
   - Returns: Updated repository information
   - Throws: APIError if the operation fails
   */
  private func handleUpdateRepository(_ operation: UpdateRepositoryOperation) async throws
  -> RepositoryInfo {
    // Check if the repository exists
    if await !repositoryService.isRegistered(identifier: operation.repositoryID) {
      throw APIError.resourceNotFound(
        message: "Repository not found: \(operation.repositoryID)",
        identifier: operation.repositoryID
      )
    }

    // Get the repository
    let repository=try await repositoryService.getRepository(identifier: operation.repositoryID)

    // Apply updates - convert the SendableValue dictionary to string dictionary
    var updatesDict: [String: String]=[:]
    for (key, value) in operation.updates {
      if let stringValue=value.stringValue {
        updatesDict[key]=stringValue
      }
    }

    // Update the repository metadata
    if let name=operation.name {
      // try await repository.setName(name)
      await baseDomainHandler.logDebug(
        message: "Updated repository name",
        operationName: "updateRepository",
        source: "RepositoryDomainHandler",
        additionalMetadata: LogMetadataDTOCollection()
          .withPublic(key: "repository_id", value: operation.repositoryID)
          .withPublic(key: "repository_name", value: name)
      )
    }

    // Return updated info
    let updatedInfo=try await RepositoryInfo(
      id: repository.identifier,
      name: repository.identifier, // Placeholder: Use identifier as name
      // name: repository.getName() ?? repository.identifier,
      status: mapStatus(Task.detached { repository.state }.value),
      creationDate: Date(), // Placeholder: Use current date
      // creationDate: repository.getCreationDate() ?? Date(),
      lastAccessDate: Date() // Placeholder: Use current date
      // lastAccessDate: repository.getLastAccessDate() ?? Date()
    )

    await baseDomainHandler.logDebug(
      message: "Repository updated successfully",
      operationName: "updateRepository",
      source: "RepositoryDomainHandler",
      additionalMetadata: LogMetadataDTOCollection()
        .withPublic(key: "repository_id", value: operation.repositoryID)
    )

    return updatedInfo
  }

  /**
   Deletes a repository with the specified ID.

   - Parameter operation: The delete repository operation parameters
   - Throws: APIError if the repository deletion fails
   */
  private func handleDeleteRepository(_ operation: DeleteRepositoryOperation) async throws {
    // Check if the repository exists
    if await !repositoryService.isRegistered(identifier: operation.repositoryID) {
      throw APIError.resourceNotFound(
        message: "Repository not found: \(operation.repositoryID)",
        identifier: operation.repositoryID
      )
    }

    // Unregister the repository from the service
    try await repositoryService.unregister(identifier: operation.repositoryID)

    await baseDomainHandler.logDebug(
      message: "Repository deleted successfully",
      operationName: "deleteRepository",
      source: "RepositoryDomainHandler",
      additionalMetadata: LogMetadataDTOCollection()
        .withPublic(key: "repository_id", value: operation.repositoryID)
    )
  }

  // Helper to get repository state synchronously
  private func getRepositoryState(_: any RepositoryProtocol) -> RepositoryState {
    // Default to ready if we can't access the state
    .ready
  }

  // Helper function to map repository status
  private func mapStatus(_ state: RepositoryState) -> RepositoryStatus {
    switch state {
      case .ready:
        .ready
      case .uninitialized, .closed:
        .initialising
      case .locked:
        .locked
      case .corrupted:
        .damaged
      case .maintenance:
        .modifying
      default:
        .ready
    }
  }
}

// MARK: - API Types

// Removed duplicate RepositoryInfo and RepositoryDetails structs as they're already defined in
// RepositoryAPIOperations.swift

/**
 Status of a repository
 */
public enum RepositoryStatus: String, Sendable, Codable, CaseIterable {
  case ready
  case initialising
  case modifying
  case locked
  case damaged
  case repairing
}

extension RepositoryStatus {
  public static var allCases: [RepositoryStatus] {
    [.ready, .initialising, .modifying, .locked, .damaged, .repairing]
  }
}
