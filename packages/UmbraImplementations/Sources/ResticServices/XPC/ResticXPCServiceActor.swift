import CoreDTOs
import Foundation
import LoggingInterfaces
import ResticInterfaces
import UmbraErrors
import XPCProtocolsCore
import XPCServices

/**
 # Restic XPC Service Actor
 
 Implementation of the ResticXPCServiceProtocol to execute Restic commands
 through an XPC service. This actor manages the secure execution of commands
 with proper actor isolation and structured concurrency.
 */
public actor ResticXPCServiceActor: XPCServiceProtocol, ResticXPCServiceProtocol {
    /// Underlying XPC service
    private let xpcService: XPCServiceProtocol
    
    /// Logger for recording service operations
    private let logger: DomainLogger
    
    /// Service name for endpoint identification
    private static let serviceName = "dev.mpy.UmbraResticService"
    
    /// Endpoint for command execution
    private static let commandEndpoint = XPCEndpointIdentifier(name: "execute-command")
    
    /// Endpoint for repository validation
    private static let validationEndpoint = XPCEndpointIdentifier(name: "validate-repository")
    
    /// Endpoint for repository creation
    private static let createRepoEndpoint = XPCEndpointIdentifier(name: "create-repository")
    
    /// Endpoint for listing snapshots
    private static let snapshotsEndpoint = XPCEndpointIdentifier(name: "list-snapshots")
    
    /// Endpoint for creating backups
    private static let backupEndpoint = XPCEndpointIdentifier(name: "create-backup")
    
    /// Endpoint for restoring files
    private static let restoreEndpoint = XPCEndpointIdentifier(name: "restore-files")
    
    /**
     Initializes a new ResticXPCServiceActor.
     
     - Parameters:
        - xpcService: The XPC service to communicate with
        - logger: The logger for recording operations
     */
    public init(
        xpcService: XPCServiceProtocol,
        logger: DomainLogger
    ) {
        self.xpcService = xpcService
        self.logger = logger
    }
    
    /**
     Starts the XPC service if it's not already running.
     
     - Throws: XPCServiceError if the service fails to start
     */
    public func start() async throws {
        do {
            try await xpcService.start()
            await log(.info, "Restic XPC service started successfully")
        } catch {
            await log(.error, "Failed to start Restic XPC service: \(error)")
            throw error
        }
    }
    
    /**
     Stops the XPC service if it's running.
     */
    public func stop() async {
        // Note that XPCServiceProtocol.stop() doesn't throw
        await xpcService.stop()
        await log(.info, "Restic XPC service stopped successfully")
    }
    
    /**
     Indicates whether the service is currently running.
     
     - Returns: True if the service is running, false otherwise
     */
    public func isRunning() async -> Bool {
        return await xpcService.isRunning()
    }
    
    /**
     Gets the endpoint identifier for the XPC service listener.
     
     - Returns: The endpoint identifier or nil if the service is not running
     */
    public func getListenerEndpoint() async -> XPCEndpointIdentifier? {
        return await xpcService.getListenerEndpoint()
    }
    
    /**
     Registers a handler for the specified endpoint.
     
     - Parameters:
        - endpoint: The endpoint to register the handler for
        - handler: The handler function
     
     - Throws: XPCServiceError if the handler cannot be registered
     */
    public func registerHandler<T: Sendable, R: Sendable>(
        for endpoint: XPCEndpointIdentifier,
        handler: @Sendable @escaping (T) async throws -> R
    ) async throws {
        try await xpcService.registerHandler(for: endpoint, handler: handler)
    }
    
    /**
     Sends a message to the XPC service and awaits a response.
     
     - Parameters:
        - message: The message to send
        - endpoint: Optional endpoint identifier for routing the message
     
     - Returns: The response data
     - Throws: XPCServiceError if the message cannot be sent or processed
     */
    public func sendMessage<T: Sendable, R: Sendable>(
        _ message: T,
        to endpoint: XPCEndpointIdentifier?
    ) async throws -> R {
        return try await xpcService.sendMessage(message, to: endpoint)
    }
    
    /**
     Logs a message with the specified level.
     
     - Parameters:
        - level: The log level
        - message: The message to log
     */
    private func log(_ level: LogLevel, _ message: String) async {
        // Use the domain logger to log messages with the appropriate metadata and source
        await logger.log(level, message, metadata: nil, source: "ResticXPCService")
    }
    
    /**
     Executes a Restic command through the XPC service.
     
     - Parameters:
        - command: The command to execute
        - environment: Optional environment variables to set
     
     - Returns: The command output as a string
     - Throws: XPCServiceError if the command fails to execute
     */
    public func executeCommand(
        _ command: any ResticInterfaces.ResticCommand,
        environment: [String: String]?
    ) async throws -> String {
        // Create the command execution message
        let message = SimpleCommandExecutionMessage(
            commandAction: String(describing: type(of: command)),
            repository: command.environment["RESTIC_REPOSITORY"] ?? "",
            password: command.environment["RESTIC_PASSWORD"],
            arguments: command.arguments.joined(separator: " "),
            environment: environment ?? [:]
        )
        
        await log(
            .debug,
            "Executing Restic command for repository"
        )
        
        do {
            let response: CommandExecutionResponse = try await sendMessage(
                message,
                to: Self.commandEndpoint
            )
            
            if response.success {
                await log(.debug, "Command executed successfully")
                return response.output
            } else {
                await log(.error, "Command execution failed: \(response.errorMessage ?? "Unknown error")")
                throw XPCServiceError.handlerError(
                    "Restic command failed: \(response.errorMessage ?? "Unknown error")",
                    NSError(domain: "ResticXPCService", code: 1, userInfo: nil)
                )
            }
        } catch {
            await log(.error, "Failed to execute command: \(error)")
            throw error
        }
    }
    
    /**
     Validates that a repository exists at the specified location.
     
     - Parameter location: The repository location to check
     
     - Returns: True if the repository exists and is valid
     - Throws: XPCServiceError if validation fails
     */
    public func validateRepository(at location: String) async throws -> Bool {
        let message = RepositoryValidationMessage(location: location)
        
        await log(.debug, "Validating repository at location: \(location)")
        
        do {
            let response: RepositoryValidationResponse = try await sendMessage(
                message,
                to: Self.validationEndpoint
            )
            
            await log(.debug, "Repository validation result: \(response.isValid)")
            return response.isValid
        } catch {
            await log(.error, "Failed to validate repository: \(error)")
            throw error
        }
    }
    
    /**
     Creates a new Restic repository at the specified location.
     
     - Parameters:
        - location: The repository location
        - password: The repository password
     
     - Throws: XPCServiceError if repository creation fails
     */
    public func createRepository(
        at location: String,
        password: String
    ) async throws {
        let message = CreateRepositoryMessage(
            location: location,
            password: password
        )
        
        await log(.debug, "Creating repository at location: \(location)")
        
        do {
            let response: CreateRepositoryResponse = try await sendMessage(
                message,
                to: Self.createRepoEndpoint
            )
            
            if !response.success {
                await log(.error, "Failed to create repository: \(response.errorMessage ?? "Unknown error")")
                throw XPCServiceError.handlerError(
                    "Failed to create repository: \(response.errorMessage ?? "Unknown error")",
                    NSError(domain: "ResticXPCService", code: 2, userInfo: nil)
                )
            }
            
            await log(.info, "Repository created successfully at \(location)")
        } catch {
            await log(.error, "Failed to create repository: \(error)")
            throw error
        }
    }
    
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
    public func listSnapshots(
        repository: String,
        password: String,
        host: String? = nil,
        paths: [String]? = nil,
        tags: [String]? = nil
    ) async throws -> String {
        let message = ListSnapshotsMessage(
            repository: repository,
            password: password,
            host: host,
            paths: paths ?? [],
            tags: tags ?? []
        )
        
        await log(.debug, "Listing snapshots in repository: \(repository)")
        
        do {
            let response: ListSnapshotsResponse = try await sendMessage(
                message,
                to: Self.snapshotsEndpoint
            )
            
            if response.success {
                await log(.debug, "Successfully listed snapshots")
                return response.snapshotsJson
            } else {
                await log(.error, "Failed to list snapshots: \(response.errorMessage ?? "Unknown error")")
                throw XPCServiceError.handlerError(
                    "Failed to list snapshots: \(response.errorMessage ?? "Unknown error")",
                    NSError(domain: "ResticXPCService", code: 3, userInfo: nil)
                )
            }
        } catch {
            await log(.error, "Failed to list snapshots: \(error)")
            throw error
        }
    }
    
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
    public func createBackup(
        repository: String,
        password: String,
        paths: [String],
        excludes: [String]? = nil,
        tags: [String]? = nil
    ) async throws -> String {
        let message = CreateBackupMessage(
            repository: repository,
            password: password,
            paths: paths,
            excludes: excludes ?? [],
            tags: tags ?? []
        )
        
        await log(.debug, "Performing backup to repository: \(repository)")
        
        do {
            let response: CreateBackupResponse = try await sendMessage(
                message,
                to: Self.backupEndpoint
            )
            
            if response.success {
                await log(.info, "Backup completed successfully")
                return response.output
            } else {
                await log(.error, "Backup failed: \(response.errorMessage ?? "Unknown error")")
                throw XPCServiceError.handlerError(
                    "Backup failed: \(response.errorMessage ?? "Unknown error")",
                    NSError(domain: "ResticXPCService", code: 4, userInfo: nil)
                )
            }
        } catch {
            await log(.error, "Failed to perform backup: \(error)")
            throw error
        }
    }
    
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
    public func restoreFiles(
        repository: String,
        password: String,
        snapshot: String,
        targetPath: String,
        includePaths: [String]? = nil
    ) async throws -> String {
        let message = RestoreFilesMessage(
            repository: repository,
            password: password,
            snapshot: snapshot,
            targetPath: targetPath,
            includePaths: includePaths ?? []
        )
        
        await log(.debug, "Performing restore from repository: \(repository)")
        
        do {
            let response: RestoreFilesResponse = try await sendMessage(
                message,
                to: Self.restoreEndpoint
            )
            
            if response.success {
                await log(.info, "Restore completed successfully")
                return response.output
            } else {
                await log(.error, "Restore failed: \(response.errorMessage ?? "Unknown error")")
                throw XPCServiceError.handlerError(
                    "Restore failed: \(response.errorMessage ?? "Unknown error")",
                    NSError(domain: "ResticXPCService", code: 5, userInfo: nil)
                )
            }
        } catch {
            await log(.error, "Failed to perform restore: \(error)")
            throw error
        }
    }
}

/**
 # XPC Message Types
 
 These structs define the message format for communicating with the XPC service.
 */

/**
 Simple command execution message.
 */
struct SimpleCommandExecutionMessage: Codable, Sendable {
    /// Command action (e.g., "backup", "restore")
    let commandAction: String
    
    /// Repository location
    let repository: String
    
    /// Repository password (if needed)
    let password: String?
    
    /// Command arguments as a single string
    let arguments: String
    
    /// Additional environment variables
    let environment: [String: String]
}

/**
 Response for command execution.
 */
struct CommandExecutionResponse: Codable, Sendable {
    /// Whether the command succeeded
    let success: Bool
    
    /// Command output if successful
    let output: String
    
    /// Error message if failed
    let errorMessage: String?
}

/**
 Repository validation message.
 */
struct RepositoryValidationMessage: Codable, Sendable {
    /// Repository location to validate
    let location: String
}

/**
 Response for repository validation.
 */
struct RepositoryValidationResponse: Codable, Sendable {
    /// Whether the repository is valid
    let isValid: Bool
    
    /// Additional validation information
    let validationInfo: String?
}

/**
 Repository creation message.
 */
struct CreateRepositoryMessage: Codable, Sendable {
    /// Repository location to create
    let location: String
    
    /// Repository password
    let password: String
}

/**
 Response for repository creation.
 */
struct CreateRepositoryResponse: Codable, Sendable {
    /// Whether creation succeeded
    let success: Bool
    
    /// Error message if failed
    let errorMessage: String?
}

/**
 Snapshot listing message.
 */
struct ListSnapshotsMessage: Codable, Sendable {
    /// Repository location
    let repository: String
    
    /// Repository password
    let password: String
    
    /// Optional host filter
    let host: String?
    
    /// Optional path filters
    let paths: [String]
    
    /// Optional tag filters
    let tags: [String]
}

/**
 Response for snapshot listing.
 */
struct ListSnapshotsResponse: Codable, Sendable {
    /// Whether listing succeeded
    let success: Bool
    
    /// JSON string with snapshot information
    let snapshotsJson: String
    
    /// Error message if failed
    let errorMessage: String?
}

/**
 Backup operation message.
 */
struct CreateBackupMessage: Codable, Sendable {
    /// Repository location
    let repository: String
    
    /// Repository password
    let password: String
    
    /// Paths to back up
    let paths: [String]
    
    /// Paths to exclude from the backup
    let excludes: [String]
    
    /// Optional tags
    let tags: [String]
}

/**
 Response for backup operation.
 */
struct CreateBackupResponse: Codable, Sendable {
    /// Whether backup succeeded
    let success: Bool
    
    /// Command output
    let output: String
    
    /// Error message if failed
    let errorMessage: String?
}

/**
 Restore operation message.
 */
struct RestoreFilesMessage: Codable, Sendable {
    /// Repository location
    let repository: String
    
    /// Repository password
    let password: String
    
    /// Snapshot ID to restore from
    let snapshot: String
    
    /// Target path to restore to
    let targetPath: String
    
    /// Paths to include in the restore
    let includePaths: [String]
}

/**
 Response for restore operation.
 */
struct RestoreFilesResponse: Codable, Sendable {
    /// Whether restore succeeded
    let success: Bool
    
    /// Command output
    let output: String
    
    /// Error message if failed
    let errorMessage: String?
}
