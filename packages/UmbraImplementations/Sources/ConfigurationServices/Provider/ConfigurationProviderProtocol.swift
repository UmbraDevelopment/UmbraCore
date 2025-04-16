import ConfigurationInterfaces
import CoreDTOs
import Foundation
import LoggingInterfaces

/**
 Protocol defining the configuration provider operations.

 This protocol serves as the internal interface for different configuration
 provider implementations (local file, remote, etc.)
 */
public protocol ConfigurationProviderProtocol {
  /**
   Loads configuration from a source.

   - Parameters:
      - source: The source from which to load the configuration
      - context: The logging context for the operation
   - Returns: The loaded configuration
   - Throws: ConfigurationError if loading fails
   */
  func loadConfiguration(
    from source: ConfigSourceDTO,
    context: LogContextDTO
  ) async throws -> ConfigurationDTO

  /**
   Saves configuration to a destination.

   - Parameters:
      - configuration: The configuration to save
      - destination: Where to save the configuration
      - context: The logging context for the operation
   - Returns: Success indicator with metadata
   - Throws: ConfigurationError if saving fails
   */
  func saveConfiguration(
    configuration: ConfigurationDTO,
    to destination: ConfigSourceDTO,
    context: LogContextDTO
  ) async throws -> ConfigSaveResultDTO

  /**
   Validates a configuration against a schema or rules.

   - Parameters:
      - configuration: The configuration to validate
      - schema: Optional schema to validate against
      - context: The logging context for the operation
   - Returns: Validation results indicating any issues
   - Throws: ConfigurationError if validation fails
   */
  func validateConfiguration(
    configuration: ConfigurationDTO,
    schema: ConfigSchemaDTO?,
    context: LogContextDTO
  ) async throws -> ConfigValidationResultDTO

  /**
   Exports configuration to a specific format.

   - Parameters:
      - configuration: The configuration to export
      - format: The format to export to
      - context: The logging context for the operation
   - Returns: The exported configuration data
   - Throws: ConfigurationError if export fails
   */
  func exportConfiguration(
    configuration: ConfigurationDTO,
    to format: ConfigFormatType,
    context: LogContextDTO
  ) async throws -> Data

  /**
   Imports configuration from external data.

   - Parameters:
      - data: The configuration data to import
      - format: The format of the data
      - context: The logging context for the operation
   - Returns: The imported configuration
   - Throws: ConfigurationError if import fails
   */
  func importConfiguration(
    from data: Data,
    format: ConfigFormatType,
    context: LogContextDTO
  ) async throws -> ConfigurationDTO

  /**
   Gets the source type that this provider can handle.

   - Returns: The type of configuration source this provider can handle
   */
  func canHandleSourceType() -> ConfigSourceType
}

/**
 Result of saving a configuration.

 Contains information about the save operation result.
 */
public struct ConfigSaveResultDTO: Codable, Equatable, Sendable {
  /// Whether the save operation was successful
  public let success: Bool

  /// Path or identifier where configuration was saved
  public let savedLocation: String

  /// Timestamp when the save occurred
  public let timestamp: Date

  /// Additional result metadata
  public let metadata: [String: String]

  /**
   Initialises a configuration save result.

   - Parameters:
      - success: Whether the save operation was successful
      - savedLocation: Path or identifier where configuration was saved
      - timestamp: Timestamp when the save occurred
      - metadata: Additional result metadata
   */
  public init(
    success: Bool,
    savedLocation: String,
    timestamp: Date=Date(),
    metadata: [String: String]=[:]
  ) {
    self.success=success
    self.savedLocation=savedLocation
    self.timestamp=timestamp
    self.metadata=metadata
  }

  /// Returns a successful save result
  public static func success(location: String) -> ConfigSaveResultDTO {
    ConfigSaveResultDTO(success: true, savedLocation: location)
  }

  /// Returns a failed save result
  public static func failure(location: String, reason: String) -> ConfigSaveResultDTO {
    ConfigSaveResultDTO(
      success: false,
      savedLocation: location,
      metadata: ["error": reason]
    )
  }
}
