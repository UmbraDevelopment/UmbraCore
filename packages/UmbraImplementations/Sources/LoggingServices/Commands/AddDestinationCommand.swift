import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for adding a new log destination.

 This command encapsulates the logic for registering a new destination,
 validating its configuration, and performing a test write if requested.
 */
public class AddDestinationCommand: BaseCommand, LogCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// The destination to add
  private let destination: LoggingInterfaces.LogDestinationDTO

  /// Options for adding the destination
  private let options: LoggingInterfaces.AddDestinationOptionsDTO

  /// Provider for logging operations
  private let provider: LoggingProviderProtocol

  /**
   Initialises a new add destination command.

   - Parameters:
      - destination: The destination to add
      - options: Options for adding the destination
      - provider: Provider for destination operations
      - loggingServices: The logging services actor
   */
  public init(
    destination: LoggingInterfaces.LogDestinationDTO,
    options: LoggingInterfaces.AddDestinationOptionsDTO = .default,
    provider: LoggingProviderProtocol,
    loggingServices: LoggingServicesActor
  ) {
    self.destination=destination
    self.options=options
    self.provider=provider

    super.init(loggingServices: loggingServices)
  }

  /**
   Executes the add destination command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: Whether the operation was successful
   - Throws: LoggingError if the operation fails
   */
  public func execute(context _: LoggingInterfaces.LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    _=LoggingInterfaces.BaseLogContextDTO(
      domainName: "LoggingServices",
      operation: "addDestination",
      category: "Command",
      source: "AddDestinationCommand",
      metadata: LoggingInterfaces.LogMetadataDTOCollection()
    )

    // Validate provider is available
    guard let provider=await loggingServices.getProvider(for: destination.type) else {
      throw LoggingTypes.LoggingError
        .invalidDestinationConfig("Unsupported destination type: \(destination.type)")
    }

    do {
      // Check if destination already exists
      if await getDestination(id: destination.id) != nil {
        throw LoggingTypes.LoggingError.destinationAlreadyExists(identifier: destination.id)
      }

      // Validate destination configuration if requested
      if options.validateConfiguration {
        // Use a local copy to avoid data races with actor-isolated access
        let localProvider=provider
        let validationResult=await loggingServices.validateDestination(
          destination,
          for: localProvider
        )

        if !validationResult.isValid {
          throw LoggingTypes.LoggingError.invalidDestinationConfig(
            "Invalid destination configuration: \(validationResult.errors.joined(separator: ", "))"
          )
        }
      }

      // Test write to destination if requested
      if options.testDestination {
        await logInfo(
          "Performing test write to destination '\(destination.name)'"
        )

        let testEntry=LoggingInterfaces.LogEntryDTO(
          timestamp: Date().timeIntervalSince1970,
          level: .info,
          message: "Test log entry from UmbraCore",
          category: "Test",
          metadata: LoggingInterfaces.LogMetadataDTOCollection()
            .withPublic(key: "test", value: "true"),
          source: "LoggingServices",
          entryID: UUID().uuidString
        )

        let success=try await provider.writeLog(
          entry: testEntry,
          to: destination
        )

        if !success {
          throw LoggingTypes.LoggingError.writeFailure(
            "Test write to destination failed"
          )
        }

        await logInfo(
          "Test write to destination '\(destination.name)' was successful"
        )
      }

      // Register the destination
      let success=try await loggingServices.addDestination(destination)

      // Log success
      if success {
        await logInfo("Successfully added destination '\(destination.name)' (\(destination.id))")
      } else {
        await logWarning("Failed to add destination '\(destination.name)' (\(destination.id))")
      }

      return success

    } catch {
      // Log failure
      await logError("Failed to add destination: \(error.localizedDescription)")
      throw error
    }
  }
}
