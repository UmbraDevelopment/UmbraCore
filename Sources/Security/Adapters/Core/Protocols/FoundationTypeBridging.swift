import SecurityProtocolsCore
import UmbraCoreTypes

/// Protocol for bridging between Foundation-free and Foundation-dependent types
/// This is designed to be implemented by types that can convert to/from Foundation types
public protocol FoundationTypeBridging {
  /// The Foundation type this can convert to/from
  associatedtype FoundationType

  /// Convert from the Foundation type
  /// - Parameter foundation: The Foundation type to convert from
  /// - Returns: The Foundation-free equivalent
  static func fromFoundation(_ foundation: FoundationType) -> Self

  /// Convert to the Foundation type
  /// - Returns: The Foundation type equivalent
  func toFoundation() -> FoundationType
}

/// Errors that can occur during type bridging
public enum TypeBridgingError: Error, Sendable {
  /// Failed to convert to the target type
  case conversionFailed(reason: String)
  /// Invalid input format
  case invalidFormat(reason: String)
  /// Unsupported operation
  case unsupportedOperation(reason: String)
}

/// Extension with helper methods for handling common bridging operations
extension FoundationTypeBridging {
  /// Attempt to convert a value or return an error
  /// - Parameter foundation: The Foundation type to convert
  /// - Returns: The Foundation-free equivalent or an error
  public static func tryFromFoundation(_ foundation: FoundationType)
  -> Result<Self, TypeBridgingError> {
    // Simply call the non-throwing method since we know it won't throw
    // In a real implementation, this would likely use a throwing method
    .success(fromFoundation(foundation))
  }

  /// Attempt to convert self to Foundation type or return an error
  /// - Returns: The Foundation type or an error
  public func tryToFoundation() -> Result<FoundationType, TypeBridgingError> {
    // Simply call the non-throwing method since we know it won't throw
    // In a real implementation, this would likely use a throwing method
    .success(toFoundation())
  }
}
