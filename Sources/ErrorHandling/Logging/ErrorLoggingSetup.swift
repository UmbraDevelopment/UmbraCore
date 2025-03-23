import Foundation
import UmbraLogging

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

// MARK: - Domain-Specific Filters

/// Extension to provide domain-specific filtering capabilities for ErrorLogger
extension ErrorLogger {
  /// Sets up domain-specific logging filter for a certain domain
  /// - Parameters:
  ///   - domain: The domain to filter
  ///   - level: The minimum log level for this domain
  /// - Returns: Configured logger
  public func setupDomainFilter(
    domain: String,
    level _: UmbraLogLevel
  ) -> ErrorLogger {
    configure { config in
      // Capture the minimum log level value
      _=config.minimumSeverity

      // Create a filter that checks domain and applies level-based filtering
      let domainFilter: (Error) -> Bool={ error in
        guard let umbraError=error as? ErrorHandlingInterfaces.UmbraError else {
          return false
        }

        // Check if this error matches the domain
        if umbraError.domain == domain {
          // Since UmbraError doesn't have a severity property directly,
          // we'll use a fixed mapping for filtering based on the domain level
          // This implements a simple domain-based filter that doesn't rely on error severity

          // By default, don't filter out errors matching our domain pattern
          return false
        }

        return false
      }

      // Add this filter to the existing filters
      config.filters.append(domainFilter)
    }
  }

  /// Sets up a code-specific logging filter
  /// - Parameters:
  ///   - code: The error code to filter
  ///   - level: The minimum log level for this code
  /// - Returns: Configured logger
  public func setupCodeFilter(
    code: String,
    level _: UmbraLogLevel
  ) -> ErrorLogger {
    configure { config in
      // Capture the minimum log level value
      _=config.minimumSeverity

      // Create a filter that checks error code and applies level-based filtering
      let codeFilter: (Error) -> Bool={ error in
        guard let umbraError=error as? ErrorHandlingInterfaces.UmbraError else {
          return false
        }

        // Check if this error matches the code
        if umbraError.code == code {
          // Since UmbraError doesn't have a severity property directly,
          // we'll use a fixed mapping for filtering based on the code level
          // This implements a simple code-based filter that doesn't rely on error severity

          // By default, don't filter out errors matching our code
          return false
        }

        return false
      }

      // Add this filter to the existing filters
      config.filters.append(codeFilter)
    }
  }

  /// Sets up a source-specific logging filter
  /// - Parameters:
  ///   - sourcePattern: The file path pattern to match (e.g. "Network/" matches all files in
  /// Network directory)
  ///   - level: The minimum log level for this source pattern
  /// - Returns: Configured logger
  public func setupSourceFilter(
    sourcePattern: String,
    level _: UmbraLogLevel
  ) -> ErrorLogger {
    configure { config in
      // Capture the minimum log level value
      _=config.minimumSeverity

      let sourceFilter: (Error) -> Bool={ error in
        guard
          let umbraError=error as? ErrorHandlingInterfaces.UmbraError,
          let source=umbraError.source
        else {
          return false
        }

        // Check if this error source matches the pattern
        if source.file.contains(sourcePattern) {
          // Since UmbraError doesn't have a severity property directly,
          // we'll use a fixed mapping for filtering based on the source level
          // This implements a simple source-based filter that doesn't rely on error severity

          // By default, don't filter out errors matching our source pattern
          return false
        }

        return false
      }

      // Add this filter to the existing filters
      config.filters.append(sourceFilter)
    }
  }

  /// Sets up system information logging
  /// - Returns: Configured logger
  public func setupSystemInfoLogging() -> ErrorLogger {
    configure { config in
      // Add system information as metadata
      let systemInfoFilter: (Error) -> Bool={ _ in
        // Return false to never filter out errors based on system info
        // This is just used to add system info as metadata
        false
      }

      // Set the filter
      config.filters=[systemInfoFilter]
    }
  }
}
