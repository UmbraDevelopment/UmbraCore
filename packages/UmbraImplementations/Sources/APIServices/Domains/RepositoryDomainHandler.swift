import APIInterfaces
import Foundation
import RepositoryInterfaces
import UmbraErrors

/**
 # Repository Domain Handler
 
 Handles repository-related API operations by delegating to the underlying
 repository service. This handler follows the Alpha Dot Five architecture
 with proper thread safety and structured error handling.
 
 ## Operation Processing
 
 Each repository operation is processed by mapping it to the appropriate
 repository service methods, with proper error handling and result conversion.
 */
public struct RepositoryDomainHandler: DomainHandler {
    /// The repository service for performing operations
    private let service: RepositoryServiceProtocol
    
    /**
     Initialises a new repository domain handler.
     
     - Parameter service: The repository service
     */
    public init(service: RepositoryServiceProtocol) {
        self.service = service
    }
    
    /**
     Executes a repository operation and returns the result.
     
     - Parameter operation: The operation to execute
     
     - Returns: The result of the operation
     - Throws: Error if the operation fails
     */
    public func execute<T: APIOperation>(_ operation: T) async throws -> Any {
        // Handle specific repository operations
        if let op = operation as? ListRepositoriesOperation {
            return try await handleListRepositories(op)
        } else if let op = operation as? GetRepositoryOperation {
            return try await handleGetRepository(op)
        } else if let op = operation as? CreateRepositoryOperation {
            return try await handleCreateRepository(op)
        } else if let op = operation as? UpdateRepositoryOperation {
            return try await handleUpdateRepository(op)
        } else if let op = operation as? DeleteRepositoryOperation {
            return try await handleDeleteRepository(op)
        }
        
        // Unsupported operation
        throw APIError.operationNotSupported("Unsupported repository operation: \(String(describing: T.self))")
    }
    
    /**
     Checks if this handler supports the given operation.
     
     - Parameter operation: The operation to check
     
     - Returns: True if the operation is supported, false otherwise
     */
    public func supports<T: APIOperation>(_ operation: T) -> Bool {
        return operation is RepositoryAPIOperation
    }
    
    // MARK: - Operation Handlers
    
    /**
     Handles the list repositories operation.
     
     - Parameter operation: The operation to handle
     
     - Returns: Array of repository information
     - Throws: Error if the operation fails
     */
    private func handleListRepositories(_ operation: ListRepositoriesOperation) async throws -> [RepositoryInfo] {
        // Get repositories from the service
        let repositories = try await service.listRepositories(includingDetails: operation.includeDetails)
        
        // Filter by status if specified
        let filteredRepositories = operation.statusFilter.map { status in
            repositories.filter { mapRepositoryStatus($0.status) == status }
        } ?? repositories
        
        // Convert to API models
        return filteredRepositories.map { repository in
            RepositoryInfo(
                id: repository.id,
                name: repository.name,
                status: mapRepositoryStatus(repository.status),
                path: repository.path
            )
        }
    }
    
    /**
     Handles the get repository operation.
     
     - Parameter operation: The operation to handle
     
     - Returns: Repository details
     - Throws: Error if the operation fails
     */
    private func handleGetRepository(_ operation: GetRepositoryOperation) async throws -> RepositoryDetails {
        // Get repository from the service
        let repository = try await service.getRepository(withID: operation.repositoryID)
        
        // Get snapshot count if requested
        let snapshotCount: Int
        if operation.includeSnapshots {
            let snapshots = try await service.listSnapshots(forRepositoryID: operation.repositoryID)
            snapshotCount = snapshots.count
        } else {
            snapshotCount = 0
        }
        
        // Get repository statistics
        let stats = try await service.getRepositoryStatistics(forRepositoryID: operation.repositoryID)
        
        // Convert to API model
        let info = RepositoryInfo(
            id: repository.id,
            name: repository.name,
            status: mapRepositoryStatus(repository.status),
            path: repository.path
        )
        
        return RepositoryDetails(
            info: info,
            createdAt: repository.creationDate,
            lastModifiedAt: repository.lastModifiedDate,
            totalSizeBytes: stats.totalSizeBytes,
            snapshotCount: snapshotCount,
            isEncrypted: repository.isEncrypted
        )
    }
    
    /**
     Handles the create repository operation.
     
     - Parameter operation: The operation to handle
     
     - Returns: Repository information
     - Throws: Error if the operation fails
     */
    private func handleCreateRepository(_ operation: CreateRepositoryOperation) async throws -> RepositoryInfo {
        // Create options for the repository
        let options = RepositoryCreationOptions(
            name: operation.parameters.name,
            path: operation.parameters.path,
            encryption: operation.parameters.encrypt,
            password: operation.parameters.password
        )
        
        // Create the repository
        let repository = try await service.createRepository(options: options)
        
        // Convert to API model
        return RepositoryInfo(
            id: repository.id,
            name: repository.name,
            status: mapRepositoryStatus(repository.status),
            path: repository.path
        )
    }
    
    /**
     Handles the update repository operation.
     
     - Parameter operation: The operation to handle
     
     - Returns: Updated repository information
     - Throws: Error if the operation fails
     */
    private func handleUpdateRepository(_ operation: UpdateRepositoryOperation) async throws -> RepositoryInfo {
        // Create options for the update
        let options = RepositoryUpdateOptions(
            name: operation.parameters.name
        )
        
        // Update the repository
        let repository = try await service.updateRepository(
            withID: operation.repositoryID,
            options: options
        )
        
        // Convert to API model
        return RepositoryInfo(
            id: repository.id,
            name: repository.name,
            status: mapRepositoryStatus(repository.status),
            path: repository.path
        )
    }
    
    /**
     Handles the delete repository operation.
     
     - Parameter operation: The operation to handle
     
     - Throws: Error if the operation fails
     */
    private func handleDeleteRepository(_ operation: DeleteRepositoryOperation) async throws {
        try await service.deleteRepository(
            withID: operation.repositoryID,
            force: operation.force
        )
    }
    
    // MARK: - Helper Methods
    
    /**
     Maps repository status from service model to API model.
     
     - Parameter status: The service model status
     
     - Returns: The API model status
     */
    private func mapRepositoryStatus(_ status: RepositoryInterfaces.RepositoryStatus) -> APIInterfaces.RepositoryStatus {
        switch status {
        case .ready:
            return .ready
        case .initialising:
            return .initialising
        case .modifying:
            return .modifying
        case .locked:
            return .locked
        case .damaged:
            return .damaged
        case .repairing:
            return .repairing
        }
    }
}
