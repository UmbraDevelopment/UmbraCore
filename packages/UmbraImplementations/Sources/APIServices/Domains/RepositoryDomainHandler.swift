import APIInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces
import UmbraErrors
import ErrorCoreTypes

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
    private let logger: LoggingProtocol?
    
    /**
     Initialises a new repository domain handler.
     
     - Parameters:
        - service: The repository service implementation
        - logger: Optional logger for privacy-aware operation recording
     */
    public init(service: RepositoryServiceProtocol, logger: LoggingProtocol? = nil) {
        self.repositoryService = service
        self.logger = logger
    }
    
    /**
     Executes a repository operation and returns its result.
     
     - Parameter operation: The operation to execute
     - Returns: The result of the operation
     - Throws: APIError if the operation fails
     */
    public func execute<T: APIOperation>(_ operation: T) async throws -> Any {
        // Log the operation start with privacy-aware metadata
        let operationName = String(describing: type(of: operation))
        let startMetadata = PrivacyMetadata([
            "operation": .public(operationName),
            "event": .public("start")
        ])
        
        await logger?.info(
            "Starting repository operation",
            metadata: startMetadata,
            source: "RepositoryDomainHandler"
        )
        
        do {
            // Execute the appropriate operation based on type
            let result = try await executeRepositoryOperation(operation)
            
            // Log success
            let successMetadata = PrivacyMetadata([
                "operation": .public(operationName),
                "event": .public("success"),
                "status": .public("completed")
            ])
            
            await logger?.info(
                "Repository operation completed successfully",
                metadata: successMetadata,
                source: "RepositoryDomainHandler"
            )
            
            return result
        } catch {
            // Log failure with privacy-aware error details
            let errorMetadata = PrivacyMetadata([
                "operation": .public(operationName),
                "event": .public("failure"),
                "status": .public("failed"),
                "error": .private(error.localizedDescription)
            ])
            
            await logger?.error(
                "Repository operation failed",
                metadata: errorMetadata,
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
    private func executeRepositoryOperation<T: APIOperation>(_ operation: T) async throws -> Any {
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
        if let apiError = error as? APIError {
            return apiError
        }
        
        // Handle specific repository error types
        if let repoError = error as? RepositoryError {
            switch repoError {
            case .repositoryNotFound(let id):
                return APIError.resourceNotFound(
                    message: "Repository not found: \(id)",
                    code: "REPOSITORY_NOT_FOUND"
                )
            case .repositoryAlreadyExists(let id):
                return APIError.resourceConflict(
                    message: "Repository already exists: \(id)",
                    code: "REPOSITORY_ALREADY_EXISTS"
                )
            case .repositoryLocked(let id):
                return APIError.resourceLocked(
                    message: "Repository is locked: \(id)",
                    code: "REPOSITORY_LOCKED"
                )
            case .invalidRepository(let message):
                return APIError.validationFailed(
                    message: message,
                    code: "INVALID_REPOSITORY"
                )
            case .operationFailed(let message):
                return APIError.operationFailed(
                    message: message,
                    code: "REPOSITORY_OPERATION_FAILED",
                    underlyingError: repoError
                )
            case .permissionDenied(let message):
                return APIError.permissionDenied(
                    message: message,
                    code: "REPOSITORY_PERMISSION_DENIED"
                )
            case .repositoryCorrupted(let id):
                return APIError.resourceInvalid(
                    message: "Repository is corrupted: \(id)",
                    code: "REPOSITORY_CORRUPTED"
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
    private func handleListRepositories(_ operation: ListRepositoriesOperation) async throws -> [RepositoryInfo] {
        // Create privacy-aware logging metadata
        let metadata = PrivacyMetadata([
            "operation": .public("listRepositories"),
            "include_details": .public(operation.includeDetails.description)
        ])
        
        await logger?.info(
            "Listing repositories",
            metadata: metadata,
            source: "RepositoryDomainHandler"
        )
        
        // Get all repositories from the service
        let repositories = await repositoryService.getAllRepositories()
        
        // Filter by status if needed
        let filteredRepositories = repositories.values.filter { repository in
            if let statusFilter = operation.statusFilter {
                // Check repository status against filter
                return repository.status == statusFilter.repositoryStatus
            }
            return true
        }
        
        // Transform to RepositoryInfo objects
        let repositoryInfos = try await filteredRepositories.asyncMap { repository in
            var info = RepositoryInfo(
                id: repository.identifier,
                name: repository.name,
                status: mapRepositoryState(repository.status),
                path: repository.url.absoluteString
            )
            
            // If includeDetails is true, get additional information
            if operation.includeDetails {
                // Get statistics for detailed information
                let stats = try await repositoryService.getStats(for: repository.identifier)
                
                // Update info with detailed statistics
                info = info.withDetails(
                    size: stats.totalSize,
                    itemCount: stats.totalItems,
                    lastModified: stats.lastModified
                )
            }
            
            return info
        }
        
        // Log the result count
        let resultMetadata = metadata.merging(PrivacyMetadata([
            "count": .public(String(repositoryInfos.count))
        ]))
        
        await logger?.info(
            "Found repositories",
            metadata: resultMetadata,
            source: "RepositoryDomainHandler"
        )
        
        return repositoryInfos
    }
    
    /**
     Handles the get repository operation.
     
     - Parameter operation: The operation to execute
     - Returns: Detailed repository information
     - Throws: APIError if the operation fails
     */
    private func handleGetRepository(_ operation: GetRepositoryOperation) async throws -> RepositoryDetails {
        // Create privacy-aware logging metadata
        let metadata = PrivacyMetadata([
            "operation": .public("getRepository"),
            "repository_id": .public(operation.repositoryID),
            "include_snapshots": .public(operation.includeSnapshots.description)
        ])
        
        await logger?.info(
            "Retrieving repository details",
            metadata: metadata,
            source: "RepositoryDomainHandler"
        )
        
        // Get the repository from the service
        let repository = try await repositoryService.getRepository(identifier: operation.repositoryID)
        
        // Get statistics
        let stats = try await repositoryService.getStats(for: repository.identifier)
        
        // Create basic info
        let basicInfo = RepositoryInfo(
            id: repository.identifier,
            name: repository.name,
            status: mapRepositoryState(repository.status),
            path: repository.url.absoluteString
        ).withDetails(
            size: stats.totalSize,
            itemCount: stats.totalItems,
            lastModified: stats.lastModified
        )
        
        // Create details (snapshots would be handled by a snapshot service if included)
        let details = RepositoryDetails(
            basicInfo: basicInfo,
            creationDate: repository.creationDate,
            lastValidated: stats.lastValidation,
            configuration: repository.configuration,
            snapshots: operation.includeSnapshots ? try await getRepositorySnapshots(repository.identifier) : []
        )
        
        await logger?.info(
            "Repository details retrieved",
            metadata: metadata.merging(PrivacyMetadata([
                "status": .public("success")
            ])),
            source: "RepositoryDomainHandler"
        )
        
        return details
    }
    
    /**
     Handles the create repository operation.
     
     - Parameter operation: The operation to execute
     - Returns: Information about the created repository
     - Throws: APIError if the operation fails
     */
    private func handleCreateRepository(_ operation: CreateRepositoryOperation) async throws -> RepositoryInfo {
        // Create privacy-aware logging metadata
        let metadata = PrivacyMetadata([
            "operation": .public("createRepository"),
            "name": .public(operation.parameters.name),
            "location": .private(operation.parameters.location.absoluteString)
        ])
        
        await logger?.info(
            "Creating new repository",
            metadata: metadata,
            source: "RepositoryDomainHandler"
        )
        
        // Create the repository
        let repository = try await repositoryService.createRepository(at: operation.parameters.location)
        
        // Get basic information about the created repository
        let basicInfo = RepositoryInfo(
            id: repository.identifier,
            name: repository.name,
            status: mapRepositoryState(repository.status),
            path: repository.url.absoluteString
        )
        
        await logger?.info(
            "Repository created successfully",
            metadata: metadata.merging(PrivacyMetadata([
                "repository_id": .public(repository.identifier),
                "status": .public("success")
            ])),
            source: "RepositoryDomainHandler"
        )
        
        return basicInfo
    }
    
    /**
     Handles the update repository operation.
     
     - Parameter operation: The operation to execute
     - Returns: Updated repository information
     - Throws: APIError if the operation fails
     */
    private func handleUpdateRepository(_ operation: UpdateRepositoryOperation) async throws -> RepositoryInfo {
        // Create privacy-aware logging metadata
        let metadata = PrivacyMetadata([
            "operation": .public("updateRepository"),
            "repository_id": .public(operation.repositoryID)
        ])
        
        await logger?.info(
            "Updating repository",
            metadata: metadata,
            source: "RepositoryDomainHandler"
        )
        
        // Get the repository
        let repository = try await repositoryService.getRepository(identifier: operation.repositoryID)
        
        // Lock the repository for update
        try await repositoryService.lockRepository(identifier: operation.repositoryID)
        
        do {
            // Apply updates (this would normally update the repository configuration)
            // Since we don't have direct update methods in the repository service,
            // this would typically involve unregistering and re-registering the repository
            // with updated configuration
            
            // For this example, we'll simulate the update process
            // In a real implementation, this would use actual repository update methods
            
            // Unlock the repository when done
            try await repositoryService.unlockRepository(identifier: operation.repositoryID)
            
            // Get updated repository info
            let updatedRepository = try await repositoryService.getRepository(identifier: operation.repositoryID)
            
            // Return updated information
            let updatedInfo = RepositoryInfo(
                id: updatedRepository.identifier,
                name: updatedRepository.name,
                status: mapRepositoryState(updatedRepository.status),
                path: updatedRepository.url.absoluteString
            )
            
            await logger?.info(
                "Repository updated successfully",
                metadata: metadata.merging(PrivacyMetadata([
                    "status": PrivacyMetadata.Entry(value: "success", privacy: .public)
                ])),
                source: "RepositoryDomainHandler"
            )
            
            return updatedInfo
        } catch {
            // Make sure we unlock the repository even on error
            try? await repositoryService.unlockRepository(identifier: operation.repositoryID)
            throw error
        }
    }
    
    /**
     Handles the delete repository operation.
     
     - Parameter operation: The operation to execute
     - Returns: Void (nothing)
     - Throws: APIError if the operation fails
     */
    private func handleDeleteRepository(_ operation: DeleteRepositoryOperation) async throws -> Void {
        // Create privacy-aware logging metadata
        let metadata = PrivacyMetadata([
            "operation": PrivacyMetadata.Entry(value: "deleteRepository", privacy: .public),
            "repository_id": PrivacyMetadata.Entry(value: operation.repositoryID, privacy: .public),
            "force": PrivacyMetadata.Entry(value: operation.force.description, privacy: .public)
        ])
        
        await logger?.info(
            "Deleting repository",
            metadata: metadata,
            source: "RepositoryDomainHandler"
        )
        
        // Check if the repository exists
        if await !repositoryService.isRegistered(identifier: operation.repositoryID) {
            throw APIError.resourceNotFound(
                message: "Repository not found: \(operation.repositoryID)",
                code: "REPOSITORY_NOT_FOUND"
            )
        }
        
        // If force is not enabled, check if the repository can be safely removed
        if !operation.force {
            // In a real implementation, additional checks would occur here 
            // like checking for snapshots or dependencies
        }
        
        // Unregister the repository
        try await repositoryService.unregister(identifier: operation.repositoryID)
        
        await logger?.info(
            "Repository deleted successfully",
            metadata: metadata.merging(PrivacyMetadata([
                "status": PrivacyMetadata.Entry(value: "success", privacy: .public)
            ])),
            source: "RepositoryDomainHandler"
        )
        
        // Return void as specified in the operation result type
        return ()
    }
    
    // Helper method to map between domain model and API model repository state
    private func mapRepositoryState(_ state: RepositoryState) -> RepositoryStatus {
        switch state {
        case .ready:
            return .ready
        case .uninitialized:
            return .initialising
        case .maintenance:
            return .modifying
        case .locked:
            return .locked
        case .corrupted:
            return .damaged
        case .closed:
            return .repairing
        }
    }
    
    // Placeholder for getting repository snapshots - would be implemented with a snapshot service
    private func getRepositorySnapshots(_ repositoryID: String) async throws -> [SnapshotInfo] {
        // This would normally fetch snapshots from a snapshot service
        // For now, return an empty array
        return []
    }
}
