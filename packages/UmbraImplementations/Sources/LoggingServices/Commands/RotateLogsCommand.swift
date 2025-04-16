import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for rotating logs in a destination.

 This command encapsulates the logic for rotating logs in a destination,
 following the command pattern architecture.
 */
public class RotateLogsCommand: BaseCommand, LogCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// The ID of the destination to rotate logs for
  private let destinationID: String

  /// Options for rotating logs
  private let options: LoggingInterfaces.RotateLogsOptionsDTO

  /// Provider for logging operations
  private let provider: LoggingProviderProtocol

  /**
   Initialises a new rotate logs command.

   - Parameters:
      - destinationId: The ID of the destination to rotate logs for
      - options: Options for rotating logs
      - provider: Provider for rotation operations
      - loggingServices: The logging services actor
   */
  public init(
    destinationID: String,
    options: LoggingInterfaces.RotateLogsOptionsDTO = .default,
    provider: LoggingProviderProtocol,
    loggingServices: LoggingServicesActor
  ) {
    self.destinationID=destinationID
    self.options=options
    self.provider=provider

    super.init(loggingServices: loggingServices)
  }

  /**
   Executes the rotate logs command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: Whether the operation was successful
   - Throws: LoggingError if the operation fails
   */
  public func execute(context _: LoggingInterfaces.LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    _=LoggingInterfaces.BaseLogContextDTO(
      domainName: "LoggingServices",
      operation: "rotateLogs",
      category: "LogRotation",
      source: "UmbraCore",
      metadata: LoggingInterfaces.LogMetadataDTOCollection()
        .withPublic(key: "destinationId", value: destinationID)
        .withPublic(key: "forceRotation", value: String(options.forceRotation))
    )

    // Log operation start
    await logInfo("Starting log rotation for destination '\(destinationID)'")

    do {
      // Check if destination exists
      guard let destination=await getDestination(id: destinationID) else {
        throw LoggingTypes.LoggingError
          .destinationNotFound("Destination with ID \(destinationID) not found")
      }

      // Check if the destination type supports rotation
      guard destination.type == .file else {
        throw LoggingTypes.LoggingError.invalidDestinationConfig(
          "Log rotation is only supported for file destinations"
        )
      }

      // Rotate logs using provider
      let success=try await provider.rotateLogs(
        for: destination,
        options: options
      )

      // Log success or failure
      if success {
        await logInfo("Successfully rotated logs for destination '\(destinationID)'")
      } else {
        await logWarning("Failed to rotate logs for destination '\(destinationID)'")
      }

      return success

    } catch {
      // Log failure
      await logError("Log rotation failed: \(error.localizedDescription)")
      throw error
    }
  }
}
