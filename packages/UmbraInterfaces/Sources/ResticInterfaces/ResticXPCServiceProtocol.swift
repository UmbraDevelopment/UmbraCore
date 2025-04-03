import Foundation
import XPCProtocolsCore

/**
 # Restic XPC Service Protocol
 
 Defines the interface for executing Restic commands through an XPC service.
 This protocol ensures that Restic operations are executed in a separate process
 with appropriate permissions, maintaining sandbox compliance.
 
 ## Security Considerations
 
 All implementations must handle sensitive data (like repository passwords)
 according to secure coding guidelines and ensure that file operations
 respect sandbox constraints.
 */
public protocol ResticXPCServiceProtocol: XPCServiceProtocol {
    /**
     Executes a Restic command through the XPC service.
     
     - Parameters:
        - command: The command to execute
        - environment: Optional environment variables to set
     
     - Returns: The command output as a string
     - Throws: XPCServiceError if the command fails to execute
     */
    func executeCommand(
        _ command: any ResticCommand,
        environment: [String: String]?
    ) async throws -> String
    
    /**
     Validates that a repository exists at the specified location.
     
     - Parameter location: The repository location to check
     
     - Returns: True if the repository exists and is valid
     - Throws: XPCServiceError if validation fails
     */
    func validateRepository(at location: String) async throws -> Bool
    
    /**
     Creates a new Restic repository at the specified location.
     
     - Parameters:
        - location: The repository location
        - password: The repository password
     
     - Throws: XPCServiceError if repository creation fails
     */
    func createRepository(at location: String, password: String) async throws
    
    /**
     Lists snapshots from a repository with optional filtering.
     
     - Parameters:
        - repository: The repository location
        - password: The repository password
        - host: Optional host filter
        - paths: Optional path filters
        - tags: Optional tag filters
     
     - Returns: Snapshot information as JSON string
     - Throws: XPCServiceError if fetching snapshots fails
     */
    func listSnapshots(
        repository: String,
        password: String,
        host: String?,
        paths: [String]?,
        tags: [String]?
    ) async throws -> String
    
    /**
     Creates a backup with the specified parameters.
     
     - Parameters:
        - repository: The repository location
        - password: The repository password
        - paths: Paths to include in the backup
        - excludes: Paths to exclude from the backup
        - tags: Optional tags to apply to the snapshot
     
     - Returns: Backup operation result
     - Throws: XPCServiceError if backup fails
     */
    func createBackup(
        repository: String,
        password: String,
        paths: [String],
        excludes: [String]?,
        tags: [String]?
    ) async throws -> String
    
    /**
     Restores files from a backup.
     
     - Parameters:
        - repository: The repository location
        - password: The repository password
        - snapshot: The snapshot ID to restore from
        - targetPath: The path to restore to
        - includePaths: Optional paths to include in the restore
     
     - Returns: Restore operation result
     - Throws: XPCServiceError if restore fails
     */
    func restoreFiles(
        repository: String,
        password: String,
        snapshot: String,
        targetPath: String,
        includePaths: [String]?
    ) async throws -> String
}
