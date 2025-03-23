import Foundation
import OSLog

/// A centralised registry for error mappers that provides a single point for error transformation
public final class ErrorRegistry {
  /// Singleton instance of the registry
  public static let shared = ErrorRegistry()

  /// Logger for the error registry
  private let logger = Logger(subsystem: "com.umbracorp.UmbraCore", category: "ErrorRegistry")

  /// All registered mappers
  private var mappers: [String: [AnyErrorMapper<Error>]] = [:]

  /// Creates a new ErrorRegistry instance
  public init() {}

  /// Registers a mapper for a specific target domain
  /// - Parameters:
  ///   - targetDomain: The domain to register the mapper for
  ///   - mapper: The mapper to register
  public func register<M: ErrorMapper>(targetDomain: String, mapper: M) {
    let anyMapper = AnyErrorMapper<Error> { error in
      guard let sourceError = error as? M.SourceError else {
        fatalError("Error type mismatch in ErrorRegistry")
      }
      return mapper.map(sourceError) as Error
    }

    if mappers[targetDomain] == nil {
      mappers[targetDomain] = []
    }

    mappers[targetDomain]?.append(anyMapper)
    logger.debug("Registered mapper for domain: \(targetDomain)")
  }

  /// Maps an error to a specific domain
  /// - Parameters:
  ///   - error: The error to map
  ///   - targetDomain: The domain to map to
  /// - Returns: The mapped error, or the original error if no mapper is found
  public func mapError(_ error: Error, to targetDomain: String) -> Error {
    guard let domainMappers = mappers[targetDomain] else {
      logger.warning("No mappers registered for domain: \(targetDomain)")
      return error
    }

    for mapper in domainMappers {
      if mapper.canMap(error) {
        let mappedError = mapper.map(error)
        logger.debug("Mapped error to domain: \(targetDomain)")
        return mappedError
      }
    }

    logger.warning("No suitable mapper found for error: \(String(describing: error))")
    return error
  }

  /// Maps an error to a specific error type
  /// - Parameters:
  ///   - error: The error to map
  ///   - targetType: The type to map to
  /// - Returns: The mapped error if a mapper is found, or nil otherwise
  public func mapError<T: Error>(_ error: Error, to _: T.Type) -> T? {
    for (domain, domainMappers) in mappers {
      for mapper in domainMappers {
        if mapper.canMap(error) {
          let mappedError = mapper.map(error)
          if let typedError = mappedError as? T {
            logger.debug("Mapped error to type \(String(describing: T.self)) in domain: \(domain)")
            return typedError
          }
        }
      }
    }

    logger
      .warning(
        "No suitable mapper found for error: \(String(describing: error)) to type \(String(describing: T.self))"
      )
    return nil
  }

  /// Clears all registered mappers
  public func clearMappers() {
    mappers.removeAll()
    logger.debug("Cleared all mappers")
  }

  /// Removes all mappers for a specific domain
  /// - Parameter domain: The domain to clear mappers for
  public func clearMappers(for domain: String) {
    mappers.removeValue(forKey: domain)
    logger.debug("Cleared mappers for domain: \(domain)")
  }
}

/// Extension to provide conveniences for error mapping
extension Error {
  /// Maps this error to the specified domain using the shared ErrorRegistry
  /// - Parameter targetDomain: The domain to map to
  /// - Returns: The mapped error
  public func mapped(to targetDomain: String) -> Error {
    ErrorRegistry.shared.mapError(self, to: targetDomain)
  }

  /// Maps this error to the specified type using the shared ErrorRegistry
  /// - Parameter targetType: The type to map to
  /// - Returns: The mapped error if a mapper is found, or nil otherwise
  public func mapped<T: Error>(to targetType: T.Type) -> T? {
    ErrorRegistry.shared.mapError(self, to: targetType)
  }
}
