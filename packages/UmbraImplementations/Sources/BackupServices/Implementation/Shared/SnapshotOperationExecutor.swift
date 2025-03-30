import BackupInterfaces
import Foundation
import LoggingTypes
import ResticInterfaces

/**
 * Type alias to clarify we're using the DTO version of parameters
 */
typealias OperationParametersType = BackupServices.SnapshotOperationParameters

/**
 * Executor for snapshot operations that provides consistent
 * error handling, logging, and metric collection.
 *
 * This follows the Alpha Dot Five architecture pattern of using
 * a dedicated component for operation execution with cross-cutting
 * concerns like logging separated from business logic.
 */
public actor SnapshotOperationExecutor {
    // MARK: - Dependencies
    
    /// Service for executing Restic commands
    private let resticService: ResticServiceProtocol
    
    /// Handler for operation cancellation
    private let cancellationHandler: CancellationHandlerProtocol
    
    /// Collector for operation metrics
    private let metricsCollector: BackupMetricsCollector
    
    /// Logger for operation events
    private let logger: BackupLoggerProtocol
    
    /// Error mapper for consistent error handling
    private let errorMapper: BackupErrorMapper
    
    // MARK: - Initialization
    
    /**
     * Initializes a new snapshot operation executor.
     *
     * - Parameters:
     *   - resticService: Service to execute Restic commands
     *   - cancellationHandler: Handler for operation cancellation
     *   - metricsCollector: Collector for operation metrics
     *   - logger: Logger for operation events
     *   - errorMapper: Error mapper for consistent error handling
     */
    public init(
        resticService: ResticServiceProtocol,
        cancellationHandler: CancellationHandlerProtocol,
        metricsCollector: BackupMetricsCollector,
        logger: BackupLoggerProtocol,
        errorMapper: BackupErrorMapper
    ) {
        self.resticService = resticService
        self.cancellationHandler = cancellationHandler
        self.metricsCollector = metricsCollector
        self.logger = logger
        self.errorMapper = errorMapper
    }
    
    // MARK: - Public Methods
    
    /**
     * Executes a snapshot operation with consistent logging and error handling.
     *
     * - Parameters:
     *   - parameters: Parameters for the operation
     *   - progressReporter: Reporter for progress updates
     *   - cancellationToken: Token for cancellation
     *   - operation: The operation to execute
     * - Returns: The result of the operation
     * - Throws: BackupError if the operation fails
     */
    public func execute<P: SnapshotOperationParameters, R>(
        parameters: P,
        progressReporter: BackupProgressReporter?,
        cancellationToken: AlphaDotFiveCancellationToken?,
        operation: @escaping (P, BackupProgressReporter?, AlphaDotFiveCancellationToken?) async throws -> R
    ) async throws -> R {
        // Extract operation type and snapshot ID for use throughout the method
        let operationType = parameters.operationType
        let snapshotID = parameters.getSnapshotID?() ?? "unknown"
        
        // Create log context
        let logContext = parameters.createLogContext()
        
        // Create SnapshotLogContext for the logger
        let context = SnapshotLogContext()
            .withOperationType(operationType.rawValue)
            .withSnapshotID(snapshotID)
        
        // Start time for metrics
        let startTime = Date()
        
        // Log operation start
        logger.info("Starting snapshot operation: \(operationType.rawValue)", context: logContext)
        
        do {
            // Validate operation parameters
            try parameters.validate()
            
            // Report progress start
            progressReporter?.reportProgress(
                BackupInterfaces.BackupProgress(
                    phase: .started,
                    percentComplete: 0.0
                ),
                for: operationType
            )
            
            // Execute the operation
            let result = try await operation(parameters, progressReporter, cancellationToken)
            
            // Report progress complete
            progressReporter?.reportProgress(
                BackupInterfaces.BackupProgress(
                    phase: .completed,
                    percentComplete: 1.0
                ),
                for: operationType
            )
            
            // Log operation success
            logger.info("Completed snapshot operation: \(operationType.rawValue)", context: logContext)
            
            // Record metrics
            await metricsCollector.recordOperationMetrics(
                type: operationType.rawValue,
                startTime: startTime,
                endTime: Date(),
                success: true
            )
            
            return result
        } catch {
            // Map the error to ensure consistency
            let backupError = errorMapper.mapError(error, context: logContext)
            
            // Log operation failure
            logger.error("Failed snapshot operation: \(operationType.rawValue), error: \(backupError.localizedDescription)", context: logContext)
            
            // Report progress failure
            progressReporter?.reportProgress(
                BackupInterfaces.BackupProgress(
                    phase: .failed,
                    percentComplete: 1.0
                ),
                for: operationType
            )
            
            // Record metrics
            await metricsCollector.recordErrorMetrics(
                type: operationType.rawValue,
                error: error.localizedDescription,
                startTime: startTime,
                endTime: Date()
            )
            
            throw backupError
        }
    }
}
