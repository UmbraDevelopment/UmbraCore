import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Base protocol for all backup operation commands.

 This protocol defines the contract that all backup command implementations
 must fulfil, following the command pattern to encapsulate backup operations in
 discrete command objects with a consistent interface.
 */
public protocol BackupCommand {
  /// The type of result returned by this command when executed
  associatedtype ResultType

  /**
   Executes the backup operation.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  func execute(
    context: LogContextDTO,
    operationID: String
  ) async -> Result<ResultType, BackupOperationError>
}

/**
 Base class for backup commands providing common functionality.

 This abstract base class provides shared functionality for all backup commands,
 including access to the Restic service, standardised logging, and utility methods
 that are commonly needed across backup operations.
 */
public class BaseBackupCommand {
  /// The Restic service to use for operations
  protected let resticService: ResticServiceProtocol

  /// Repository connection information
  protected let repositoryInfo: RepositoryInfo

  /// The command factory for creating Restic commands
  protected let commandFactory: BackupCommandFactory

  /// Parser for Restic command results
  protected let resultParser: BackupResultParser

  /// Optional logger for operation tracking
  protected let logger: LoggingProtocol?

  /// Error mapper for translating errors
  protected let errorMapper: BackupErrorMapper

  /**
   Initialises a new base backup command.

   - Parameters:
      - resticService: The Restic service to use for operations
      - repositoryInfo: Repository connection information
      - commandFactory: Factory for creating Restic commands
      - resultParser: Parser for command results
      - errorMapper: Error mapper for translating errors
      - logger: Optional logger for tracking operations
   */
  public init(
    resticService: ResticServiceProtocol,
    repositoryInfo: RepositoryInfo,
    commandFactory: BackupCommandFactory,
    resultParser: BackupResultParser,
    errorMapper: BackupErrorMapper,
    logger: LoggingProtocol?=nil
  ) {
    self.resticService=resticService
    self.repositoryInfo=repositoryInfo
    self.commandFactory=commandFactory
    self.resultParser=resultParser
    self.errorMapper=errorMapper
    self.logger=logger
  }

  /**
   Creates a logging context with standardised metadata.

   - Parameters:
      - operation: The name of the operation
      - correlationID: Unique identifier for correlation
      - additionalMetadata: Additional metadata for the log context
   - Returns: A configured log context
   */
  protected func createLogContext(
    operation: String,
    correlationID: String,
    additionalMetadata: [(key: String, value: (value: String, privacyLevel: PrivacyLevel))]=[]
  ) -> LogContextDTO {
    // Create a base context
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "correlationID", value: correlationID)
      .withPublic(key: "component", value: "BackupService")

    // Add additional metadata with specified privacy levels
    for item in additionalMetadata {
      switch item.value.privacyLevel {
        case .public:
          metadata=metadata.withPublic(key: item.key, value: item.value.value)
        case .protected:
          metadata=metadata.withProtected(key: item.key, value: item.value.value)
        case .private:
          metadata=metadata.withPrivate(key: item.key, value: item.value.value)
      }
    }

    return LogContextDTO(metadata: metadata)
  }

  /**
   Creates a progress stream for tracking backup progress.

   - Returns: A tuple containing the progress stream and its continuation
   */
  protected func createProgressStream()
  -> (AsyncStream<BackupProgressInfo>, AsyncStream<BackupProgressInfo>.Continuation) {
    var continuation: AsyncStream<BackupProgressInfo>.Continuation!
    let stream=AsyncStream<BackupProgressInfo> { cont in
      continuation=cont
    }
    return (stream, continuation)
  }

  /**
   Logs a debug message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logDebug(_ message: String, context: LogContextDTO) async {
    await logger?.log(.debug, message, context: context)
  }

  /**
   Logs an info message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logInfo(_ message: String, context: LogContextDTO) async {
    await logger?.log(.info, message, context: context)
  }

  /**
   Logs a warning message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logWarning(_ message: String, context: LogContextDTO) async {
    await logger?.log(.warning, message, context: context)
  }

  /**
   Logs an error message with the given context.

   - Parameters:
      - message: The message to log
      - context: The logging context
   */
  protected func logError(_ message: String, context: LogContextDTO) async {
    await logger?.log(.error, message, context: context)
  }

  /**
   Creates a cancellation token for the operation.

   - Parameter operationID: The unique identifier for the operation
   - Returns: A cancellation token implementation
   */
  protected func createCancellationToken(operationID: String)
  -> BackupOperationCancellationTokenImpl {
    BackupOperationCancellationTokenImpl(operationID: operationID)
  }
}
