import Foundation
import UmbraErrors
import UmbraErrorsCore

/// A protocol for mapping between error types
public protocol ErrorMapper {
  /// The source error type that this mapper can handle
  associatedtype SourceError: Error

  /// The target error type that this mapper produces
  associatedtype TargetError: Error

  /// Maps an error from the source type to the target type
  /// - Parameter error: The source error to map
  /// - Returns: The mapped target error
  func map(_ error: SourceError) -> TargetError

  /// Checks if this mapper can handle a given error
  /// - Parameter error: The error to check
  /// - Returns: True if this mapper can handle the error, false otherwise
  func canMap(_ error: Error) -> Bool
}

/// Default implementation of ErrorMapper
extension ErrorMapper {
  /// Default implementation of canMap that checks if the error is of the source type
  public func canMap(_ error: Error) -> Bool {
    error is SourceError
  }
}

/// A type-erased error mapper that can map from any error to any error
public struct AnyErrorMapper<Target: Error>: ErrorMapper {
  /// The mapping function
  private let _map: (Error) -> Target

  /// The canMap function
  private let _canMap: (Error) -> Bool

  /// Source type is any Error
  public typealias SourceError=Error

  /// Target type is specified by the generic parameter
  public typealias TargetError=Target

  /// Creates a new AnyErrorMapper instance
  /// - Parameters:
  ///   - map: The mapping function
  ///   - canMap: The function that determines if this mapper can handle a given error
  public init(map: @escaping (Error) -> Target, canMap: @escaping (Error) -> Bool={ _ in true }) {
    _map=map
    _canMap=canMap
  }

  /// Maps an error from the source type to the target type
  /// - Parameter error: The source error to map
  /// - Returns: The mapped target error
  public func map(_ error: Error) -> Target {
    _map(error)
  }

  /// Checks if this mapper can handle a given error
  /// - Parameter error: The error to check
  /// - Returns: True if this mapper can handle the error, false otherwise
  public func canMap(_ error: Error) -> Bool {
    _canMap(error)
  }
}

/// Creates a type-erased error mapper from a concrete mapper
/// - Parameter mapper: The concrete mapper to type-erase
/// - Returns: A type-erased mapper with the same behavior
public func anyMapper<M: ErrorMapper>(_ mapper: M) -> AnyErrorMapper<M.TargetError> {
  AnyErrorMapper { error in
    guard let sourceError=error as? M.SourceError else {
      fatalError(
        "Cannot map error of type \(type(of: error)) with mapper for \(M.SourceError.self)"
      )
    }
    return mapper.map(sourceError)
  } canMap: { error in
    mapper.canMap(error)
  }
}

/// A composable error mapper that chains multiple mappers
public struct CompositeErrorMapper<Target: Error>: ErrorMapper {
  /// The mappers to use, in order
  private let mappers: [AnyErrorMapper<Target>]

  /// Source type is any Error
  public typealias SourceError=Error

  /// Target type is specified by the generic parameter
  public typealias TargetError=Target

  /// Creates a new CompositeErrorMapper instance
  /// - Parameter mappers: The mappers to use, in order
  public init(mappers: [AnyErrorMapper<Target>]) {
    self.mappers=mappers
  }

  /// Maps an error using the first mapper that can handle it
  /// - Parameter error: The error to map
  /// - Returns: The mapped error
  /// - Throws: If no mapper can handle the error, it is passed through unchanged
  public func map(_ error: Error) -> Target {
    for mapper in mappers {
      if mapper.canMap(error) {
        return mapper.map(error)
      }
    }

    // If we reach here, no mapper could handle this error
    // We should ideally return a sensible default or throw an error
    fatalError("No mapper found for error: \(error)")
  }

  /// Checks if any mapper can handle the error
  /// - Parameter error: The error to check
  /// - Returns: True if any mapper can handle the error, false otherwise
  public func canMap(_ error: Error) -> Bool {
    mappers.contains { $0.canMap(error) }
  }
}
