import Foundation

/// Protocol defining the basic requirements for error mapping
///
/// This protocol establishes a consistent interface for transforming
/// errors between different representations across the UmbraCore framework.
public protocol ErrorMapper {
  /// The source error type this mapper transforms from
  associatedtype SourceError: Error

  /// The target error type this mapper transforms to
  associatedtype TargetError: Error

  /// Maps from source error type to target error type
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  func map(_ error: SourceError) -> TargetError

  /// Maps from a general Error to target error type
  /// - Parameter error: Any error
  /// - Returns: The mapped target error, if possible
  func mapAnyError(_ error: Error) -> TargetError?
}

/// Default implementation for common error mapper functionality
extension ErrorMapper {
  public func mapAnyError(_ error: Error) -> TargetError? {
    // If the error is already the right type, just cast it
    if let targetError=error as? TargetError {
      return targetError
    }

    // If the error is the source type, map it
    if let sourceError=error as? SourceError {
      return map(sourceError)
    }

    // Couldn't map the error
    return nil
  }
}

/// Protocol for bidirectional error mapping
public protocol BidirectionalErrorMapper: ErrorMapper {
  /// Maps from target error type back to source error type
  /// - Parameter error: The target error
  /// - Returns: The mapped source error
  func mapReverse(_ error: TargetError) -> SourceError

  /// Maps from a general Error to source error type
  /// - Parameter error: Any error
  /// - Returns: The mapped source error, if possible
  func mapAnyErrorReverse(_ error: Error) -> SourceError?
}

/// Default implementation for bidirectional error mapper functionality
extension BidirectionalErrorMapper {
  public func mapAnyErrorReverse(_ error: Error) -> SourceError? {
    // If the error is already the right type, just cast it
    if let sourceError=error as? SourceError {
      return sourceError
    }

    // If the error is the target type, map it
    if let targetError=error as? TargetError {
      return mapReverse(targetError)
    }

    // Couldn't map the error
    return nil
  }
}

/// Registry for error mappers
public protocol ErrorMapperRegistry {
  /// Register an error mapper factory
  /// - Parameters:
  ///   - sourceType: The source error type
  ///   - targetType: The target error type
  ///   - factory: A factory function that creates a mapper
  func registerMapper<S: Error, T: Error>(
    sourceType: S.Type,
    targetType: T.Type,
    factory: @escaping () -> Any
  )

  /// Get a mapper for the specified source and target types
  /// - Parameters:
  ///   - sourceType: The source error type
  ///   - targetType: The target error type
  /// - Returns: An error mapper, or nil if none is registered
  func mapper<S: Error, T: Error>(sourceType: S.Type, targetType: T.Type) -> Any?

  /// Remove a mapper registration
  /// - Parameters:
  ///   - sourceType: The source error type
  ///   - targetType: The target error type
  func removeMapper<S: Error, T: Error>(sourceType: S.Type, targetType: T.Type)
}
