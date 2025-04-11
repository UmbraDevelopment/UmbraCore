import Foundation
import PersistenceInterfaces
import LoggingInterfaces
import CoreDTOs

/**
 Command for applying a database migration.
 
 This command encapsulates the logic for applying schema and data migrations,
 following the command pattern architecture.
 */
public class ApplyMigrationCommand: BasePersistenceCommand, PersistenceCommand {
    /// The result type for this command
    public typealias ResultType = MigrationResultDTO
    
    /// The migration to apply
    private let migration: MigrationDTO
    
    /**
     Initialises a new apply migration command.
     
     - Parameters:
        - migration: The migration to apply
        - provider: Provider for persistence operations
        - logger: Logger instance for logging operations
     */
    public init(
        migration: MigrationDTO,
        provider: PersistenceProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.migration = migration
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the apply migration command.
     
     - Parameters:
        - context: The persistence context for the operation
     - Returns: The result of the migration operation
     - Throws: PersistenceError if the operation fails
     */
    public func execute(context: PersistenceContextDTO) async throws -> MigrationResultDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "applyMigration",
            entityType: "Migration",
            entityId: migration.id,
            additionalMetadata: [
                ("migrationName", (value: migration.name, privacyLevel: .public)),
                ("fromVersion", (value: String(migration.fromVersion), privacyLevel: .public)),
                ("toVersion", (value: String(migration.toVersion), privacyLevel: .public)),
                ("migrationType", (value: migration.type.rawValue, privacyLevel: .public)),
                ("timestamp", (value: "\(Date())", privacyLevel: .public))
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "applyMigration", context: operationContext)
        
        do {
            // Verify current schema version matches the migration's fromVersion
            let currentVersion = try await provider.getCurrentSchemaVersion()
            
            if currentVersion != migration.fromVersion {
                throw PersistenceError.migrationFailed(
                    "Current schema version (\(currentVersion)) does not match migration's fromVersion (\(migration.fromVersion))"
                )
            }
            
            // Check for required dependencies
            if let dependencies = migration.dependencies, !dependencies.isEmpty {
                let migrationHistory = try await provider.getMigrationHistory()
                let appliedMigrationIds = Set(migrationHistory.map { $0.id })
                
                // Verify all dependencies have been applied
                let missingDependencies = dependencies.filter { !appliedMigrationIds.contains($0) }
                
                if !missingDependencies.isEmpty {
                    throw PersistenceError.migrationFailed(
                        "Missing required dependencies for migration: \(missingDependencies.joined(separator: ", "))"
                    )
                }
            }
            
            // Apply the migration using the provider
            let migrationResult = try await provider.applyMigration(migration: migration)
            
            // Log success or warnings
            if migrationResult.success {
                let successContext = operationContext.withMetadata(
                    LogMetadataDTOCollection().withPublic(
                        key: "executionTime",
                        value: String(format: "%.3f", migrationResult.executionTime)
                    ).withPublic(
                        key: "currentVersion",
                        value: String(migrationResult.currentVersion)
                    )
                )
                
                // Log any warnings
                if !migrationResult.warnings.isEmpty {
                    await logger.log(
                        .warning,
                        "Migration completed with warnings: \(migrationResult.warnings.joined(separator: "; "))",
                        context: successContext
                    )
                } else {
                    await logOperationSuccess(
                        operation: "applyMigration",
                        context: successContext
                    )
                }
            } else if let error = migrationResult.error {
                await logOperationFailure(
                    operation: "applyMigration",
                    error: PersistenceError.migrationFailed(error),
                    context: operationContext
                )
            }
            
            return migrationResult
            
        } catch let error as PersistenceError {
            // Log failure
            await logOperationFailure(
                operation: "applyMigration",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to PersistenceError
            let persistenceError = PersistenceError.migrationFailed(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "applyMigration",
                error: persistenceError,
                context: operationContext
            )
            
            throw persistenceError
        }
    }
}
