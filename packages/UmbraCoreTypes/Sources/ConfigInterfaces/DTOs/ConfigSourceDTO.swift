/// ConfigSourceDTO
///
/// Represents a configuration source in the UmbraCore framework.
/// This DTO defines how configuration data is loaded from various
/// sources such as files, environment variables, or remote endpoints.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct ConfigSourceDTO: Sendable, Equatable {
  /// Unique identifier for the configuration source
  public let identifier: String

  /// Human-readable name for the configuration source
  public let name: String

  /// Type of the configuration source
  public let sourceType: ConfigSourceType

  /// Source-specific location information
  public let location: String

  /// Whether the source is read-only
  public let isReadOnly: Bool

  /// Whether the source stores sensitive information and requires secure handling
  public let isSecure: Bool

  /// Optional source-specific configuration options
  public let options: [String: String]?

  /// Creates a new ConfigSourceDTO instance
  /// - Parameters:
  ///   - identifier: Unique identifier for the source
  ///   - name: Human-readable name
  ///   - sourceType: Type of the configuration source
  ///   - location: Source-specific location information
  ///   - isReadOnly: Whether the source is read-only
  ///   - isSecure: Whether the source contains sensitive information
  ///   - options: Optional source-specific configuration options
  public init(
    identifier: String,
    name: String,
    sourceType: ConfigSourceType,
    location: String,
    isReadOnly: Bool=false,
    isSecure: Bool=false,
    options: [String: String]?=nil
  ) {
    self.identifier=identifier
    self.name=name
    self.sourceType=sourceType
    self.location=location
    self.isReadOnly=isReadOnly
    self.isSecure=isSecure
    self.options=options
  }

  /// Creates a JSON file configuration source
  /// - Parameters:
  ///   - identifier: Unique identifier for the source
  ///   - name: Human-readable name
  ///   - filePath: Path to the JSON file
  ///   - isReadOnly: Whether the source is read-only
  /// - Returns: A configured ConfigSourceDTO
  public static func jsonFile(
    identifier: String,
    name: String,
    filePath: String,
    isReadOnly: Bool=false
  ) -> ConfigSourceDTO {
    ConfigSourceDTO(
      identifier: identifier,
      name: name,
      sourceType: .jsonFile,
      location: filePath,
      isReadOnly: isReadOnly,
      isSecure: false
    )
  }

  /// Creates a secure keychain configuration source
  /// - Parameters:
  ///   - identifier: Unique identifier for the source
  ///   - name: Human-readable name
  ///   - serviceName: The keychain service name
  /// - Returns: A configured ConfigSourceDTO
  public static func keychain(
    identifier: String,
    name: String,
    serviceName: String
  ) -> ConfigSourceDTO {
    ConfigSourceDTO(
      identifier: identifier,
      name: name,
      sourceType: .keychain,
      location: serviceName,
      isReadOnly: false,
      isSecure: true
    )
  }

  /// Creates an environment variables configuration source
  /// - Parameters:
  ///   - identifier: Unique identifier for the source
  ///   - name: Human-readable name
  ///   - prefix: Optional prefix for environment variables
  /// - Returns: A configured ConfigSourceDTO
  public static func environment(
    identifier: String,
    name: String,
    prefix: String?=nil
  ) -> ConfigSourceDTO {
    var options: [String: String]?=nil
    if let prefix {
      options=["prefix": prefix]
    }

    return ConfigSourceDTO(
      identifier: identifier,
      name: name,
      sourceType: .environment,
      location: "system",
      isReadOnly: true,
      isSecure: false,
      options: options
    )
  }

  /// Creates an in-memory configuration source
  /// - Parameters:
  ///   - identifier: Unique identifier for the source
  ///   - name: Human-readable name
  /// - Returns: A configured ConfigSourceDTO
  public static func memory(
    identifier: String,
    name: String
  ) -> ConfigSourceDTO {
    ConfigSourceDTO(
      identifier: identifier,
      name: name,
      sourceType: .memory,
      location: "memory",
      isReadOnly: false,
      isSecure: false
    )
  }
}

/// Represents the types of configuration sources available
public enum ConfigSourceType: String, Sendable, Equatable, CaseIterable {
  case jsonFile
  case propertyList
  case yaml
  case keychain
  case environment
  case memory
  case remote
  case database
}
