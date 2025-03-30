import ErrorCoreTypes
import Foundation

/**
 # ErrorDomainProtocol

 Protocol defining requirements for error domain types.

 This protocol establishes a consistent interface for domain-specific errors,
 ensuring they all provide the necessary information for proper error handling
 and reporting. It follows the Alpha Dot Five architecture by providing a
 clear separation between error domain interfaces and implementations.
 */
public protocol ErrorDomainProtocol: Error, Sendable {
  /// The error domain identifier
  static var domain: ErrorDomainType { get }

  /// The error code within this domain
  var code: Int { get }

  /// Human-readable description of the error
  var localizedDescription: String { get }

  /// Optional context providing additional information about the error
  var context: ErrorContext? { get }

  /**
   Creates an error with additional context information.

   - Parameter context: The context to associate with this error
   - Returns: A new error instance with the provided context
   */
  func withContext(_ context: ErrorContext) -> Self
}
