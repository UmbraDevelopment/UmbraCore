import Foundation

/// A protocol for defining a one-way mapping between error types
public protocol ErrorMapper<SourceType, TargetType> {
  /// The source error type
  associatedtype SourceType: Error

  /// The target error type
  associatedtype TargetType: Error

  /// Maps from the source error type to the target error type
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  func mapError(_ error: SourceType) -> TargetType
}

/// A protocol for defining a bidirectional mapping between error types
public protocol BidirectionalErrorMapper<ErrorTypeA, ErrorTypeB>: ErrorMapper {
  /// The first error type
  associatedtype ErrorTypeA: Error

  /// The second error type
  associatedtype ErrorTypeB: Error

  /// Maps from ErrorTypeA to ErrorTypeB
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  func mapAtoB(_ error: ErrorTypeA) -> ErrorTypeB

  /// Maps from ErrorTypeB to ErrorTypeA
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  func mapBtoA(_ error: ErrorTypeB) -> ErrorTypeA
}

/// A type that erases the specific type of an ErrorMapper
public struct AnyErrorMapper<Source: Error, Target: Error>: ErrorMapper {
  private let _mapError: (Source) -> Target

  /// Initialises with any mapper that can map from Source to Target
  /// - Parameter mapper: The mapper to use
  public init<M: ErrorMapper>(mapper: M) where M.SourceType == Source, M.TargetType == Target {
    _mapError=mapper.mapError
  }

  /// Maps from the source error type to the target error type
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  public func mapError(_ error: Source) -> Target {
    _mapError(error)
  }
}

/// A type that erases the specific type of a BidirectionalErrorMapper
public struct AnyBidirectionalErrorMapper<A: Error, B: Error>: BidirectionalErrorMapper {
  private let _mapAtoB: (A) -> B
  private let _mapBtoA: (B) -> A

  /// Initialises with any bidirectional mapper between A and B
  /// - Parameter mapper: The bidirectional mapper to use
  public init<M: BidirectionalErrorMapper>(mapper: M) where M.ErrorTypeA == A, M.ErrorTypeB == B {
    _mapAtoB=mapper.mapAtoB
    _mapBtoA=mapper.mapBtoA
  }

  /// Maps from ErrorTypeA to ErrorTypeB
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  public func mapAtoB(_ error: A) -> B {
    _mapAtoB(error)
  }

  /// Maps from ErrorTypeB to ErrorTypeA
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  public func mapBtoA(_ error: B) -> A {
    _mapBtoA(error)
  }

  /// Maps from the source error type to the target error type (implementation of ErrorMapper)
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  public func mapError(_ error: A) -> B {
    mapAtoB(error)
  }
}
