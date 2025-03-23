import Foundation

/// A centralised registry for error mappers
@MainActor
public final class ErrorRegistry {
  /// Shared instance of the error registry
  public static let shared=ErrorRegistry()

  /// Storage for the error mappers
  private var mappers: [String: Any]=[:]

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /// Generates a key for storing a mapper in the registry
  /// - Parameters:
  ///   - sourceType: The source error type
  ///   - targetType: The target error type
  /// - Returns: A unique key for the mapper
  private func key(sourceType: (some Error).Type, targetType: (some Error).Type) -> String {
    "\(String(describing: sourceType))->\(String(describing: targetType))"
  }

  /// Registers a mapper for mapping between source and target error types
  /// - Parameters:
  ///   - mapper: The mapper to register
  ///   - sourceType: The source error type
  ///   - targetType: The target error type
  public func register<M: ErrorMapper>(
    mapper: M,
    sourceType: M.SourceType.Type=M.SourceType.self,
    targetType: M.TargetType.Type=M.TargetType.self
  ) {
    let key=key(sourceType: sourceType, targetType: targetType)
    mappers[key]=AnyErrorMapper(mapper: mapper)
  }

  /// Registers a bidirectional mapper for mapping between two error types
  /// - Parameters:
  ///   - mapper: The bidirectional mapper to register
  ///   - typeA: The first error type
  ///   - typeB: The second error type
  public func register<M: BidirectionalErrorMapper>(
    mapper: M,
    typeA: M.ErrorTypeA.Type=M.ErrorTypeA.self,
    typeB: M.ErrorTypeB.Type=M.ErrorTypeB.self
  ) {
    // Register A->B mapping
    let keyAB=key(sourceType: typeA, targetType: typeB)
    mappers[keyAB]=AnyErrorMapper(mapper: mapper)

    // Register B->A mapping
    let keyBA=key(sourceType: typeB, targetType: typeA)
    mappers[keyBA]=AnyErrorMapper(mapper: BtoAAdapter(mapper: mapper))
  }

  /// Gets a mapper for mapping from source to target error types
  /// - Parameters:
  ///   - sourceType: The source error type
  ///   - targetType: The target error type
  /// - Returns: A mapper if registered, or nil if no mapper is found
  public func mapper<Source: Error, Target: Error>(
    sourceType: Source.Type=Source.self,
    targetType: Target.Type=Target.self
  ) -> AnyErrorMapper<Source, Target>? {
    let key=key(sourceType: sourceType, targetType: targetType)
    return mappers[key] as? AnyErrorMapper<Source, Target>
  }

  /// Maps an error from source type to target type
  /// - Parameters:
  ///   - error: The source error to map
  ///   - targetType: The target error type
  /// - Returns: The mapped error, or nil if no mapper is found
  public func map<Source: Error, Target: Error>(
    _ error: Source,
    to targetType: Target.Type=Target.self
  ) -> Target? {
    guard let mapper=mapper(sourceType: Source.self, targetType: targetType) else {
      return nil
    }

    return mapper.mapError(error)
  }

  /// Maps an error from source type to target type, using a default value if no mapper is found
  /// - Parameters:
  ///   - error: The source error to map
  ///   - targetType: The target error type
  ///   - defaultValue: A closure that returns a default value if no mapper is found
  /// - Returns: The mapped error, or the default value if no mapper is found
  public func map<Target: Error>(
    _ error: some Error,
    to targetType: Target.Type=Target.self,
    default defaultValue: @autoclosure () -> Target
  ) -> Target {
    map(error, to: targetType) ?? defaultValue()
  }

  /// Clears all registered mappers
  public func clearAll() {
    mappers.removeAll()
  }
}

/// Private adapter to create an ErrorMapper from the B->A direction of a BidirectionalErrorMapper
private struct BtoAAdapter<M: BidirectionalErrorMapper>: ErrorMapper {
  typealias SourceType=M.ErrorTypeB
  typealias TargetType=M.ErrorTypeA

  private let mapper: M

  init(mapper: M) {
    self.mapper=mapper
  }

  func mapError(_ error: M.ErrorTypeB) -> M.ErrorTypeA {
    mapper.mapBtoA(error)
  }
}
