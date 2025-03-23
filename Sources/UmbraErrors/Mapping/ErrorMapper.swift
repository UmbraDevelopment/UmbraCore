import Foundation

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

  /// Creates a type-erased wrapper around a concrete error mapper
  /// - Parameter mapper: The concrete mapper to wrap
  public init<M: ErrorMapper>(_ mapper: M) where M.TargetError == Target {
    _map={ error in
      guard let sourceError=error as? M.SourceError else {
        // This should never happen if canMap is implemented correctly
        fatalError("Error type mismatch in AnyErrorMapper")
      }
      return mapper.map(sourceError)
    }
    _canMap=mapper.canMap
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

/// A bidirectional error mapper that can map between two error types in both directions
public struct BidirectionalErrorMapper<A: Error, B: Error> {
  /// Mapper from A to B
  private let forwardMapper: AnyErrorMapper<B>

  /// Mapper from B to A
  private let reverseMapper: AnyErrorMapper<A>

  /// Creates a new BidirectionalErrorMapper instance
  /// - Parameters:
  ///   - forwardMapper: Mapper from A to B
  ///   - reverseMapper: Mapper from B to A
  public init(forwardMapper: AnyErrorMapper<B>, reverseMapper: AnyErrorMapper<A>) {
    self.forwardMapper=forwardMapper
    self.reverseMapper=reverseMapper
  }

  /// Creates a new BidirectionalErrorMapper instance with mapping functions
  /// - Parameters:
  ///   - forwardMap: Function to map from A to B
  ///   - reverseMap: Function to map from B to A
  public init(forwardMap: @escaping (A) -> B, reverseMap: @escaping (B) -> A) {
    forwardMapper=AnyErrorMapper { error in
      guard let a=error as? A else {
        fatalError("Error type mismatch in BidirectionalErrorMapper")
      }
      return forwardMap(a)
    }
    reverseMapper=AnyErrorMapper { error in
      guard let b=error as? B else {
        fatalError("Error type mismatch in BidirectionalErrorMapper")
      }
      return reverseMap(b)
    }
  }

  /// Maps from A to B
  /// - Parameter a: The A error to map
  /// - Returns: The mapped B error
  public func mapForward(_ a: A) -> B {
    forwardMapper.map(a)
  }

  /// Maps from B to A
  /// - Parameter b: The B error to map
  /// - Returns: The mapped A error
  public func mapReverse(_ b: B) -> A {
    reverseMapper.map(b)
  }

  /// Maps an arbitrary error to B if possible
  /// - Parameter error: The error to map
  /// - Returns: The mapped B error if the input is A, nil otherwise
  public func tryMapForward(_ error: Error) -> B? {
    guard forwardMapper.canMap(error) else {
      return nil
    }
    return forwardMapper.map(error)
  }

  /// Maps an arbitrary error to A if possible
  /// - Parameter error: The error to map
  /// - Returns: The mapped A error if the input is B, nil otherwise
  public func tryMapReverse(_ error: Error) -> A? {
    guard reverseMapper.canMap(error) else {
      return nil
    }
    return reverseMapper.map(error)
  }
}
