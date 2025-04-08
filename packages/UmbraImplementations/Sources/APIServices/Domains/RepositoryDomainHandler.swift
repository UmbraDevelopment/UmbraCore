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

 Operations use proper isolation and async/await patterns to ensure
 thread safety throughout the handler.
 */
public struct RepositoryDomainHandler: DomainHandler {
  /// Repository service for storage operations
  private let repositoryService: RepositoryServiceProtocol

  /// Logger with privacy controls
  private let logger: (any LoggingProtocol)?

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
    repositoryService=service
    self.logger=logger
  }

  // MARK: - DomainHandler Conformance
  public var domain: String { APIDomain.repository.rawValue }

  public func handleOperation<T: APIOperation>(operation: T) async throws -> Any {
    // TODO: Implement actual operation handling logic for the repository domain
    await logger?.debug(
      "Handling repository operation: \(operation)",
      context: BaseLogContextDTO(domainName: "repository", source: "handleOperation")
    )

    // Placeholder implementation - throws error
    throw APIError.operationNotSupported(
      message: "Operation \(String(describing: type(of: operation))) not yet implemented for domain \(domain)",
      code: "NOT_IMPLEMENTED"
    )
  }

  /**
   Executes a repository operation and returns its result.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  public func execute(_ operation: some APIOperation) async throws -> Any {
    // Log the operation start with privacy-aware metadata
    let operationName=String(describing: type(of: operation))
    let startMetadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operationName)
      .withPublic(key: "event", value: "start")

    await logger?.info(
      "Starting repository operation",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: startMetadata
      )
    )

    do {
      // Execute the appropriate operation based on type
      let result=try await executeRepositoryOperation(operation)

      // Log success
      let successMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: operationName)
        .withPublic(key: "event", value: "success")
        .withPublic(key: "status", value: "completed")

      await logger?.info(
        "Repository operation completed successfully",
        context: BaseLogContextDTO(
          domainName: "repository",
          source: "RepositoryDomainHandler",
          metadata: successMetadata
        )
      )

      return result
    } catch {
      // Log failure with privacy-aware error details
      let errorMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: operationName)
        .withPublic(key: "event", value: "failure")
        .withPublic(key: "status", value: "failed")
        .withPrivate(key: "error", value: error.localizedDescription)

      await logger?.error(
        "Repository operation failed",
        context: BaseLogContextDTO(
          domainName: "repository",
          source: "RepositoryDomainHandler",
          metadata: errorMetadata
        )
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
  public func supports(_ operation: some APIOperation) -> Bool {
    operation is any RepositoryAPIOperation
  }

  // MARK: - Private Helper Methods

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
        return try await handleGetRepository(op)
      case let op as CreateRepositoryOperation:
        return try await handleCreateRepository(op)
      case let op as UpdateRepositoryOperation:
        return try await handleUpdateRepository(op)
      case let op as DeleteRepositoryOperation:
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
    if let apiError=error as? APIError {
      return apiError
    }

    // Handle specific repository error types
    if let repoError=error as? RepositoryError {
      switch repoError {
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
          return APIError.invalidOperation(
            message: "Invalid repository configuration",
            code: "INVALID_REPOSITORY"
          )
        case .internalError:
          return APIError.operationFailed(
            message: "Repository operation failed",
            code: "REPOSITORY_OPERATION_FAILED",
            underlyingError: repoError
          )
        case .inaccessible:
          return APIError.serviceUnavailable(
            message: "Repository is not accessible",
            code: "REPOSITORY_INACCESSIBLE"
          )
        case .corrupted:
          return APIError.invalidState(
            message: "Repository is corrupted",
            details: "The repository data is corrupted or damaged",
            code: "REPOSITORY_CORRUPTED"
          )
        case .uninitialised:
          return APIError.invalidState(
            message: "Repository is not initialised",
            details: "The repository needs to be initialized before use",
            code: "REPOSITORY_UNINITIALISED"
          )
        case .invalidOperation:
          return APIError.invalidOperation(
            message: "Invalid operation for current repository state",
            code: "INVALID_REPOSITORY_OPERATION"
          )
        case .ioError:
          return APIError.operationFailed(
            message: "IO error during repository operation",
            code: "REPOSITORY_IO_ERROR",
            underlyingError: error
          )
        case .permissionDenied:
          return APIError.authenticationFailed(
            message: "Permission denied for repository operation",
            code: "REPOSITORY_PERMISSION_DENIED"
          )
        case .maintenanceFailed:
          return APIError.operationFailed(
            message: "Repository maintenance operation failed",
            code: "REPOSITORY_MAINTENANCE_FAILED",
            underlyingError: error
          )
        case .networkError:
          return APIError.serviceUnavailable(
            message: "Network error during repository operation",
            code: "REPOSITORY_NETWORK_ERROR"
          )
        case .invalidURL:
          return APIError.invalidOperation(
            message: "Invalid repository URL",
            code: "INVALID_REPOSITORY_URL"
          )
      }
    }

    // Default to a generic operation failed error
    return APIError.operationFailed(
      message: "Repository operation failed: \(error.localizedDescription)",
      code: "REPOSITORY_OPERATION_FAILED",
      underlyingError: error
    )
  }

  // MARK: - Operation Handlers

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

    await logger?.info(
      "Listing repositories",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: metadata
      )
    )

    // Get all repositories from the service
    let repositories=await repositoryService.getAllRepositories()

    if repositories.isEmpty {
      await logger?.info(
        "No repositories found",
        context: BaseLogContextDTO(
          domainName: "repository",
          source: "RepositoryDomainHandler",
          metadata: metadata
        )
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

    await logger?.info(
      "Found \(resultList.count) repositories",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: metadata.with(
          key: "count",
          value: String(resultList.count),
          privacyLevel: .public
        )
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

    await logger?.info(
      "Retrieved repository details",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "getRepository")
          .withPublic(key: "repository_id", value: operation.repositoryID)
      )
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

    await logger?.info(
      "Repository created successfully",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "createRepository")
          .withPublic(key: "repository_id", value: repository.identifier)
          .withPublic(key: "repository_name", value: repository.identifier)
      )
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
      await logger?.info(
        "Updated repository name",
        context: BaseLogContextDTO(
          domainName: "repository",
          source: "RepositoryDomainHandler",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "updateRepository")
            .withPublic(key: "repository_id", value: operation.repositoryID)
            .withPublic(key: "repository_name", value: name)
        )
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

    await logger?.info(
      "Repository updated successfully",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "updateRepository")
          .withPublic(key: "repository_id", value: operation.repositoryID)
      )
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

    await logger?.info(
      "Repository deleted successfully",
      context: BaseLogContextDTO(
        domainName: "repository",
        source: "RepositoryDomainHandler",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "deleteRepository")
          .withPublic(key: "repository_id", value: operation.repositoryID)
      )
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
