import CoreDTOs
import Foundation

/**
 Type of configuration format.

 Represents the various serialisation formats supported for configuration.
 */
public enum ConfigFormatType: String, Codable, Sendable {
  /// JavaScript Object Notation
  case json
  /// YAML Ain't Markup Language
  case yaml
  /// Property List (Apple)
  case plist
  /// Environment variables
  case env
  /// Command line arguments
  case args
  /// INI file format
  case ini
  /// TOML format
  case toml
  /// Custom format (requires custom parser)
  case custom
}

/**
 Type of configuration source.

 Represents the various sources from which configuration can be loaded.
 */
public enum ConfigSourceType: String, Codable, Sendable {
  /// Local file system source
  case localFile
  /// Remote HTTP/HTTPS endpoint
  case remote
  /// Default built-in configuration
  case `default`
  /// Environment variables
  case environment
  /// Command line arguments
  case commandLine
  /// In-memory configuration
  case memory
  /// User preferences (app settings)
  case userPreferences
  /// Database-stored configuration
  case database
  /// Secure storage (keychain, etc.)
  case secureStorage
  /// Custom source
  case custom
}

/**
 Represents a configuration source.

 This struct contains information about where configuration comes from
 or where it should be saved to.
 */
public struct ConfigSourceDTO: Codable, Equatable, Sendable {
  /// Type of configuration source
  public let sourceType: ConfigSourceType

  /// Format of the configuration data
  public let format: ConfigFormatType

  /// Location or identifier for the source
  public let location: String

  /// Additional parameters for the source
  public let parameters: [String: String]

  /**
   Initialises a new configuration source.

   - Parameters:
      - sourceType: Type of configuration source
      - format: Format of the configuration data
      - location: Location or identifier for the source
      - parameters: Additional parameters for the source
   */
  public init(
    sourceType: ConfigSourceType,
    format: ConfigFormatType,
    location: String,
    parameters: [String: String]=[:]
  ) {
    self.sourceType=sourceType
    self.format=format
    self.location=location
    self.parameters=parameters
  }

  /**
   Creates a local file configuration source.

   - Parameters:
      - filePath: Path to the configuration file
      - format: Format of the configuration file
   - Returns: A configuration source for the local file
   */
  public static func localFile(
    filePath: String,
    format: ConfigFormatType
  ) -> ConfigSourceDTO {
    ConfigSourceDTO(
      sourceType: .localFile,
      format: format,
      location: filePath
    )
  }

  /**
   Creates a remote configuration source.

   - Parameters:
      - url: URL to the remote configuration
      - format: Format of the configuration data
      - headers: HTTP headers to include in the request
   - Returns: A configuration source for the remote endpoint
   */
  public static func remote(
    url: URL,
    format: ConfigFormatType,
    headers: [String: String]=[:]
  ) -> ConfigSourceDTO {
    ConfigSourceDTO(
      sourceType: .remote,
      format: format,
      location: url.absoluteString,
      parameters: headers
    )
  }

  /**
   Creates a default configuration source.

   - Parameters:
      - identifier: Identifier for the default configuration
      - format: Format of the default configuration
   - Returns: A configuration source for default configuration
   */
  public static func `default`(
    identifier: String="default",
    format: ConfigFormatType = .json
  ) -> ConfigSourceDTO {
    ConfigSourceDTO(
      sourceType: .default,
      format: format,
      location: identifier
    )
  }

  /**
   Creates an environment variables configuration source.

   - Parameters:
      - prefix: Optional prefix for environment variables to include
   - Returns: A configuration source for environment variables
   */
  public static func environment(
    prefix: String?=nil
  ) -> ConfigSourceDTO {
    let parameters=prefix != nil ? ["prefix": prefix!] : [:]
    return ConfigSourceDTO(
      sourceType: .environment,
      format: .env,
      location: "env",
      parameters: parameters
    )
  }
}
